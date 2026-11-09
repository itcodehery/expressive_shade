"""
Train a notification classifier head on frozen all-MiniLM-L6-v2 embeddings,
export the quantized ONNX encoder, and emit everything the Flutter app needs.

Setup:
    pip install sentence-transformers scikit-learn pandas onnxruntime \
                "optimum[onnxruntime]" transformers

Usage:
    python train.py --data seed_notifications.csv

Outputs (in ./build):
    minilm_int8.onnx      quantized encoder      -> Flutter asset
    vocab.txt             WordPiece vocab        -> Flutter asset
    head.json             classifier weights     -> Flutter asset
    golden_tokens.json    tokenizer test cases   -> used by the Dart test
"""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

import numpy as np
import onnxruntime as ort
import pandas as pd
from onnxruntime.quantization import QuantType, quantize_dynamic
from sentence_transformers import SentenceTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split
from transformers import AutoTokenizer

MODEL = "sentence-transformers/all-MiniLM-L6-v2"
MAX_LEN = 64
OUT = Path("build")


def make_text(row) -> str:
    # The Dart side MUST build exactly the same string.
    return f"{row['app']} | {row['channel']} | {row['title']} | {row['body']}"


def load_data(path, classes):
    df = pd.read_csv(path).fillna("")
    unknown = set(df["label"]) - set(classes)
    if unknown:
        raise SystemExit(f"Labels not in categories.json: {unknown}")
    df["text"] = df.apply(make_text, axis=1)
    return df


def mean_pool(token_emb, mask):
    m = mask[..., None].astype(np.float32)
    pooled = (token_emb * m).sum(1) / np.clip(m.sum(1), 1e-9, None)
    return pooled / (np.linalg.norm(pooled, axis=1, keepdims=True) + 1e-12)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True)
    ap.add_argument("--categories", default="categories.json")
    args = ap.parse_args()

    OUT.mkdir(exist_ok=True)
    cfg = json.load(open(args.categories))
    classes = cfg["classes"]
    df = load_data(args.data, classes)

    # ---- 1. Embed ----------------------------------------------------
    enc = SentenceTransformer(MODEL)
    enc.max_seq_length = MAX_LEN
    X = enc.encode(df["text"].tolist(), normalize_embeddings=True, show_progress_bar=True)
    y = df["label"].values

    # ---- 2. Evaluate, then refit on everything -----------------------
    def new_clf():
        return LogisticRegression(C=10, max_iter=3000, class_weight="balanced")

    min_count = pd.Series(y).value_counts().min()
    if len(df) >= 100 and min_count >= 5:
        Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, stratify=y, random_state=0)
        print(classification_report(yte, new_clf().fit(Xtr, ytr).predict(Xte), zero_division=0))
    else:
        print("Dataset too small for a meaningful holdout. Add more labeled data (aim for 100+ per class).")

    clf = new_clf().fit(X, y)

    head = {
        "labels": list(clf.classes_),
        "w": clf.coef_.tolist(),
        "b": clf.intercept_.tolist(),
        "threshold": cfg["confidence_threshold"],
        "fallback": cfg["fallback_class"],
        "priority": cfg["priority"],
        "max_len": MAX_LEN,
        "template": "{app} | {channel} | {title} | {body}",
    }
    json.dump(head, open(OUT / "head.json", "w"))

    # ---- 3. Export + quantize encoder --------------------------------
    onnx_dir = OUT / "onnx"
    subprocess.run(
        ["optimum-cli", "export", "onnx", "--model", MODEL, str(onnx_dir)], check=True
    )
    quantize_dynamic(
        str(onnx_dir / "model.onnx"), str(OUT / "minilm_int8.onnx"), weight_type=QuantType.QInt8
    )

    tok = AutoTokenizer.from_pretrained(MODEL)
    tok.save_pretrained(OUT / "tok")
    shutil.copy(OUT / "tok" / "vocab.txt", OUT / "vocab.txt")

    # ---- 4. Sanity check: int8 ONNX + our pooling vs. original -------
    sess = ort.InferenceSession(str(OUT / "minilm_int8.onnx"))
    sample = df["text"].tolist()[:20]
    t = tok(sample, padding=True, truncation=True, max_length=MAX_LEN, return_tensors="np")
    feeds = {k: t[k].astype(np.int64) for k in ["input_ids", "attention_mask", "token_type_ids"]}
    hidden = sess.run(None, feeds)[0]
    onnx_vecs = mean_pool(hidden, t["attention_mask"])
    cos = (onnx_vecs * X[:20]).sum(1)
    print(f"Mean cosine, int8 ONNX vs original: {cos.mean():.4f} (min {cos.min():.4f})")

    # ---- 5. Golden tokenizer cases for the Dart test -----------------
    edge = [
        "Don't miss 50% off!",
        "com.whatsapp_business | messages | Hi | See you at 5:30pm",
        "UPI: Rs.1,200.50 debited",
        "!!! URGENT !!!",
        "a" * 300,
    ]
    cases = df["text"].tolist()[:40] + edge
    golden = [
        {"text": s, "ids": tok(s, truncation=True, max_length=MAX_LEN)["input_ids"]}
        for s in cases
    ]
    json.dump(golden, open(OUT / "golden_tokens.json", "w"))

    print(f"\nDone. Copy minilm_int8.onnx, vocab.txt, head.json into your Flutter assets/.")
    print("Copy golden_tokens.json and vocab.txt next to the Dart test.")


if __name__ == "__main__":
    main()
