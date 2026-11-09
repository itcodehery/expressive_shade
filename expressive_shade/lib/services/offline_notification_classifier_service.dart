import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;
import '../models/notification_model.dart';

class NotificationClassificationInput {
  final String appName;
  final String packageName;
  final String title;
  final String content;
  final String channelId;
  final String androidCategory;
  final bool isConversation;
  final bool isMessagingStyle;
  final bool hasReplyAction;

  const NotificationClassificationInput({
    required this.appName,
    required this.packageName,
    required this.title,
    required this.content,
    this.channelId = '',
    this.androidCategory = '',
    this.isConversation = false,
    this.isMessagingStyle = false,
    this.hasReplyAction = false,
  });
}

class NotificationClassificationResult {
  final NotificationCategory category;
  final double confidence;
  final String? extractedOtp;
  final bool isUserOverride;

  const NotificationClassificationResult({
    required this.category,
    required this.confidence,
    this.extractedOtp,
    this.isUserOverride = false,
  });
}

/// Offline Notification Classifier Service
///
/// Features:
/// - 7 classes: Realtime, Security, Conversations, Socials, Updates, Promotions, Silent
/// - "All" view with priority 0
/// - Isolate batch/single execution preventing UI jank
/// - Fast O(1) LRU classification cache & channel cache
/// - Configurable confidence threshold (0.6) with fallback class ("Updates")
/// - Exact input template formatting: "{app} | {channel} | {title} | {body}"
/// - On-device dynamic head updates and continuous learning from user corrections
class OfflineNotificationClassifierService {
  OfflineNotificationClassifierService._();

  static bool isEnabled = true;

  static const double confidenceThreshold = 0.60;
  static const NotificationCategory fallbackCategory = NotificationCategory.updates;
  static const String inputTemplate = '{app} | {channel} | {title} | {body}';

  static final Map<NotificationCategory, int> priorityMap = {
    NotificationCategory.realtime: 1,
    NotificationCategory.security: 1,
    NotificationCategory.conversations: 2,
    NotificationCategory.socials: 3,
    NotificationCategory.updates: 4,
    NotificationCategory.promotions: 5,
    NotificationCategory.silent: 6,
  };

  /// User-assigned overrides keyed by "$packageName|$channelId" or "$packageName"
  static final Map<String, NotificationCategory> _userOverrides = {};

  /// High-confidence channel cache keyed by "$packageName|$channelId"
  static final Map<String, NotificationCategory> _learnedChannelCache = {};

  /// LRU cache for recent notification classifications (max 256 entries)
  static final LinkedHashMap<String, NotificationClassificationResult> _lruCache =
      LinkedHashMap<String, NotificationClassificationResult>();
  static const int _maxLruEntries = 256;

  /// On-device dynamic weight/bias deltas learned from user corrections
  static final Map<NotificationCategory, Map<String, double>> _dynamicWeights = {};
  static final Map<NotificationCategory, double> _dynamicBiases = {};

  static String _channelKey(String packageName, String channelId) {
    final pkg = packageName.trim().toLowerCase();
    final ch = channelId.trim().toLowerCase();
    return ch.isNotEmpty ? '$pkg|$ch' : pkg;
  }

  static String _lruKey({
    required String packageName,
    required String channelId,
    required String title,
    required String content,
    required bool isConversation,
    required bool hasReplyAction,
  }) {
    return '$packageName|$channelId|${title.hashCode}|${content.hashCode}|$isConversation|$hasReplyAction';
  }

  static String formatInput({
    required String app,
    required String channel,
    required String title,
    required String body,
  }) {
    return '$app | $channel | $title | $body';
  }

  static int getPriority(NotificationCategory category) {
    return priorityMap[category] ?? category.priorityRank;
  }

  static void loadOverrides(Map<String, dynamic> raw) {
    _userOverrides.clear();
    raw.forEach((key, value) {
      final cat = NotificationCategory.fromString(value.toString());
      _userOverrides[key.toLowerCase()] = cat;
    });
  }

  static Map<String, String> exportOverrides() {
    return _userOverrides.map((k, v) => MapEntry(k, v.name));
  }

  static void loadLearningState(Map<String, dynamic> raw) {
    _dynamicBiases.clear();
    _dynamicWeights.clear();

    final biases = raw['biases'];
    if (biases is Map) {
      biases.forEach((k, v) {
        final cat = NotificationCategory.fromString(k.toString());
        if (v is num) _dynamicBiases[cat] = v.toDouble();
      });
    }

    final weights = raw['weights'];
    if (weights is Map) {
      weights.forEach((k, v) {
        final cat = NotificationCategory.fromString(k.toString());
        if (v is Map) {
          final map = <String, double>{};
          v.forEach((feat, val) {
            if (val is num) map[feat.toString()] = val.toDouble();
          });
          _dynamicWeights[cat] = map;
        }
      });
    }
  }

  static Map<String, dynamic> exportLearningState() {
    return {
      'biases': _dynamicBiases.map((k, v) => MapEntry(k.name, v)),
      'weights': _dynamicWeights.map((k, v) => MapEntry(k.name, v)),
    };
  }

  static void setUserOverride({
    required String packageName,
    String channelId = '',
    required NotificationCategory category,
  }) {
    final pkg = packageName.trim().toLowerCase();
    if (pkg.isEmpty) return;
    if (channelId.trim().isNotEmpty) {
      _userOverrides[_channelKey(pkg, channelId)] = category;
    }
    _userOverrides[pkg] = category;
    _learnedChannelCache[_channelKey(pkg, channelId)] = category;
    _invalidateCacheFor(pkg);
  }

  static NotificationCategory? getUserOverride(
    String packageName, [
    String channelId = '',
  ]) {
    final pkg = packageName.trim().toLowerCase();
    if (pkg.isEmpty) return null;
    if (channelId.trim().isNotEmpty) {
      final byChannel = _userOverrides[_channelKey(pkg, channelId)];
      if (byChannel != null) return byChannel;
    }
    return _userOverrides[pkg];
  }

  static void recordUserCorrection({
    required String packageName,
    String channelId = '',
    required String title,
    required String content,
    required NotificationCategory targetCategory,
    NotificationCategory? previousCategory,
  }) {
    setUserOverride(
      packageName: packageName,
      channelId: channelId,
      category: targetCategory,
    );

    // Online gradient adjustment: reinforce target category, penalize previous
    final feats = _extractFeatures(
      appName: packageName,
      packageName: packageName,
      channelId: channelId,
      androidCategory: '',
      title: title,
      content: content,
      isConversation: false,
      hasReplyAction: false,
    );

    const learningRate = 0.35;
    final targetW = _dynamicWeights.putIfAbsent(targetCategory, () => {});
    _dynamicBiases[targetCategory] = (_dynamicBiases[targetCategory] ?? 0.0) + learningRate;
    feats.forEach((feat, val) {
      targetW[feat] = (targetW[feat] ?? 0.0) + (learningRate * val);
    });

    if (previousCategory != null && previousCategory != targetCategory) {
      final prevW = _dynamicWeights.putIfAbsent(previousCategory, () => {});
      _dynamicBiases[previousCategory] = (_dynamicBiases[previousCategory] ?? 0.0) - learningRate;
      feats.forEach((feat, val) {
        prevW[feat] = (prevW[feat] ?? 0.0) - (learningRate * val);
      });
    }
  }

  static void _invalidateCacheFor(String packageName) {
    final pkg = packageName.toLowerCase();
    _lruCache.removeWhere((k, _) => k.startsWith(pkg));
  }

  static void clearCache() {
    _lruCache.clear();
    _learnedChannelCache.clear();
  }

  // ---------------------------------------------------------------------------
  // Regex Pattern Detectors
  // ---------------------------------------------------------------------------
  static final RegExp _otpCueRegex = RegExp(
    r'\b(otp|verification|verify|security\s+code|login\s+code|passcode|one[-\s]?time|auth(?:entication)?\s+code|2fa|two[-\s]?factor|confirmation\s+code|pin\s+is|code\s+is|your\s+code)\b',
    caseSensitive: false,
  );

  static final RegExp _otpDigitsRegex = RegExp(
    r'(?<![$\u20B9\u20AC\u00A3\d/])\b(\d{4,8})\b(?!\.\d|/\d|%)',
  );

  static String? extractOtp(String title, String content) {
    final combined = '$title $content';
    if (!_otpCueRegex.hasMatch(combined)) return null;

    final matches = _otpDigitsRegex.allMatches(combined);
    for (final m in matches) {
      final candidate = m.group(1);
      if (candidate == null) continue;
      if (candidate.length == 4 &&
          (candidate.startsWith('202') || candidate.startsWith('199'))) {
        final prefixStart = math.max(0, m.start - 18);
        final prefix = combined.substring(prefixStart, m.start).toLowerCase();
        if (!prefix.contains('code') &&
            !prefix.contains('otp') &&
            !prefix.contains('pin') &&
            !prefix.contains(':')) {
          continue;
        }
      }
      return candidate;
    }
    return null;
  }

  static final RegExp _dltSenderRegex = RegExp(
    r'^[a-z]{2}-[a-z0-9]{3,10}(?:-[pstg])?$',
    caseSensitive: false,
  );
  static final RegExp _dltPromoRegex = RegExp(
    r'^[a-z]{2}-[a-z0-9]{3,10}-p$',
    caseSensitive: false,
  );
  static final RegExp _shortcodeSenderRegex = RegExp(r'^\d{5,6}$');

  static final RegExp _securityConceptRegex = RegExp(
    r'(\b(?:otp|verification\s+code|security\s+code|login\s+code|passcode|one[-\s]?time\s+password|'
    r'debited\s+(?:from|by|rs|inr|\$)|credited\s+(?:to|with|rs|inr|\$)|spent\s+on\s+.*?\s+card|'
    r'via\s+upi|upi\s+ref|neft|imps|payment\s+successful|paid\s+(?:rs|inr|[\u20B9\$\u20AC\u00A3])\s*\d+|'
    r'received\s+(?:rs|inr|[\u20B9\$\u20AC\u00A3])\s*\d+|money\s+(?:received|sent|transferred)|'
    r'transaction\s+(?:alert|declined|successful|id)|card\s+.*?\s+declined|blocked\s+.*?\s+card|'
    r'avl\s*bal|available\s+balance|available\s+limit|e[-\s]?statement|'
    r'security\s+alert|critical\s+security|new\s+sign[-\s]?in|unrecognized\s+device|'
    r'suspicious\s+(?:activity|login)|unauthorized\s+(?:login|transaction|access)|'
    r'compromised\s+password|data\s+breach|password\s+reset\s+request|account\s+(?:locked|blocked))\b)',
    caseSensitive: false,
  );

  static final RegExp _realtimeConceptRegex = RegExp(
    r'(\b(?:incoming\s+(?:voice\s+|video\s+)?call|is\s+calling\s+you|missed\s+(?:voice\s+|video\s+)?call|'
    r'turn\s+(?:right|left|around)|head\s+(?:north|south|east|west)|in\s+\d+\s*(?:m|km|meters?)\s+turn|'
    r'your\s+driver\s+is\s+arriving|driver\s+arrived|trip\s+started|heading\s+to\s+.*?\s+eta|'
    r'order\s+(?:on\s+the\s+way|is\s+being\s+prepared)|delivery\s+partner\s+(?:nearby|is\s+on\s+the\s+way)|'
    r'your\s+food\s+will\s+arrive\s+in|food\s+is\s+arriving|'
    r'alarm\s+ringing|wake\s+up\s+alarm|timer\s+(?:expired|finished|is\s+up)|'
    r'boarding\s+(?:started|closes|gate\s+changed)|gate\s+change|final\s+call\s+for\s+boarding|'
    r'meeting\s+starting\s+in|starts?\s+in\s+\d+\s*min|leave\s+now\s+to\s+arrive)\b)',
    caseSensitive: false,
  );

  static final RegExp _conversationsConceptRegex = RegExp(
    r'(\b(?:sent\s+(?:a\s+|you\s+a\s+)?(?:photo|video|voice\s+message|audio|sticker|gif|reel|post|attachment)|'
    r'\u{1F4F7}\s*photo|\u{1F3A4}\s*voice\s+message|\u{1F3A5}\s*video|reacted\s+\S+\s+to|'
    r'are\s+you\s+(?:coming|free|still|down|there|home|awake)|are\s+we\s+(?:still|meeting|playing|going)|'
    r'where\s+are\s+you|wya|omw|on\s+my\s+way|see\s+you\s+(?:at|soon|tomorrow|tonight|outside)|'
    r'let.?s\s+(?:meet|catch\s+up|do\s+it|go)|call\s+me\s+when|text\s+me\s+when|did\s+you\s+(?:reach|pick\s+up|see|get)|'
    r'can\s+you\s+(?:send|share|review|take\s+a\s+look|call)|'
    r'kab\s+(?:aa|pahunch)|kya\s+kar|kha(?:na)?\s+bana|milte\s+hai|pahunch\s+raha|chal(?:te)?\s+hai)\b)',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _socialsConceptRegex = RegExp(
    r'(\b(?:liked\s+your\s+(?:post|photo|reel|story|reply|comment|thread|video)|'
    r'commented\s+on\s+your\s+(?:post|photo|reel|video)|replied\s+to\s+your\s+(?:comment|thread|post)|'
    r'started\s+following\s+you|followed\s+you(?:\s+back)?|new\s+follower|friend\s+request|wants\s+to\s+connect|connection\s+invitation|'
    r'mentioned\s+you\s+in\s+(?:their\s+story|a\s+comment|a\s+post)|tagged\s+you\s+in|'
    r'reposted\s+your|retweeted\s+your|upvoted\s+your|reached\s+\d+\s+upvotes|'
    r'uploaded\s+a\s+(?:new\s+)?video|started\s+a\s+live\s+video|is\s+live\s+now|'
    r'viewed\s+your\s+profile|impressions\s+and\s+\d+\s+reactions|saved\s+your\s+pin|'
    r'added\s+to\s+their\s+story|posted\s+to\s+their\s+story|birthday\s+today|trending\s+(?:on|in)\s+r/)\b)',
    caseSensitive: false,
  );

  static final RegExp _updatesConceptRegex = RegExp(
    r'(\b(?:out\s+for\s+delivery|in\s+transit|has\s+(?:shipped|been\s+dispatched)|dispatched\s+via|'
    r'order\s+(?:confirmed|picked\s+up|delivered|has\s+shipped)|package\s+will\s+arrive|'
    r'awb\s*#?\s*\d+|waybill|track(?:ing)?\s+(?:package|id|number)|return\s+picked\s+up|refund\s+(?:initiated|processed)|'
    r'pnr\s+\d+|chart\s+prepared|booking\s+confirmed|ticket\s+confirmed|seat\s+confirmed|'
    r'pull\s+request|merged\s+#?\d+|workflow\s+run|pipeline\s+#?\d+|moved\s+to\s+in\s+review|'
    r'\d+\s+apps?\s+can\s+be\s+updated|\d+\s+apps?\s+updated|event\s+reminder|team\s+sync|dropped\s+a\s+new\s+album|new\s+memory)\b)',
    caseSensitive: false,
  );

  static final RegExp _promotionsConceptRegex = RegExp(
    r'(\b\d{1,3}\s*%\s*(?:off|discount|cashback|save|back)\b|'
    r'(?:flat|save|extra|get|upto|up\s+to)\s*(?:[\u20B9\$\u20AC\u00A3]|rs\.?|inr|usd)\s*\d+|'
    r'\b(?:[\u20B9\$\u20AC\u00A3]|rs\.?|inr|usd)\s*\d+\s*(?:off|cashback|discount|voucher|coupon|back|free)\b|'
    r'\b(?:promo\s*code|coupon\s*code|discount\s*code|use\s+code|apply\s+code|voucher|flash\s+sale|mega\s+sale|'
    r'clearance\s+sale|end\s+of\s+season|big\s+billion|great\s+indian\s+festival|buy\s+\d+\s+get\s+\d+|bogo|'
    r'free\s+delivery|free\s+shipping|free\s+trial|try\s+.*?\s+free|months?\s+of\s+.*?\s+premium|upgrade\s+to\s+premium|'
    r'ad[-\s]?free|pre[-\s]?approved\s+loan|zero\s+processing\s+fee|lifetime\s+free|shop\s+now|order\s+now|book\s+now|'
    r'claim\s+now|avail\s+now|apply\s+now|don.?t\s+miss|limited\s+time\s+(?:offer|deal)|special\s+offer|exclusive\s+(?:offer|deal)|'
    r'price\s+drop|wishlist\s+.*?\s+sale|unsubscribe|reply\s+stop|sponsored|ride\s+more\s+save\s+more)\b)',
    caseSensitive: false,
  );

  static final RegExp _silentConceptRegex = RegExp(
    r'(\b(?:charging\s+(?:rapidly|slowly|wirelessly|this\s+device)|battery\s+full|usb\s+debugging|'
    r'vpn\s+(?:is\s+connected|is\s+active|connected|activated)|steps?\s+(?:today|and\s+burned)|'
    r'now\s+playing|song\s+title|report\.pdf|download\s+complete|upload\s+complete|'
    r'\d+\u00B0[cf]\b|partly\s+cloudy|mostly\s+sunny|screen\s+time|screenshot\s+saved)\b)',
    caseSensitive: false,
  );

  static final RegExp _tokenSplitRegex = RegExp(r'[^a-z0-9%$\u20B9\u20AC\u00A3]+');

  static const List<String> _chatPkgs = [
    'whatsapp', 'telegram', 'signal', 'messaging', 'mms', 'sms',
    'discord', 'slack', 'messenger', 'teams', 'orca', 'viber',
  ];
  static const List<String> _socialPkgs = [
    'instagram', 'twitter', 'x.android', 'tiktok', 'musically', 'reddit',
    'facebook', 'katana', 'linkedin', 'barcelona', 'threads', 'snapchat',
    'youtube', 'pinterest', 'bluesky', 'mastodon',
  ];
  static const List<String> _commercePkgs = [
    'amazon', 'flipkart', 'swiggy', 'zomato', 'ubereats', 'doordash',
    'blinkit', 'grofers', 'zepto', 'bigbasket', 'myntra', 'nykaa',
    'meesho', 'ajio', 'ebay', 'shopify', 'dominos', 'lenskart',
  ];
  static const List<String> _realtimePkgs = [
    'dialer', 'telecom', 'incall', 'maps', 'navigation', 'clock',
    'deskclock', 'alarm', 'timer',
  ];
  static const List<String> _financePkgs = [
    'gpay', 'paisa', 'phonepe', 'paytm', 'bhim', 'bank', 'hdfc',
    'icici', 'sbi', 'axis', 'kotak', 'paypal', 'stripe', 'revolut',
    'zerodha', 'kite', 'groww', 'upstox', 'cred', 'yono',
  ];
  static const List<String> _silentPkgs = [
    'systemui', 'system', 'fitness', 'chrome', 'download', 'vpn',
    'weather', 'wellbeing',
  ];

  static String _normalizeStem(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('ing') && word.length > 5) {
      var base = word.substring(0, word.length - 3);
      if (base.length >= 3 &&
          base.codeUnitAt(base.length - 1) == base.codeUnitAt(base.length - 2)) {
        base = base.substring(0, base.length - 1);
      }
      return base;
    }
    if (word.endsWith('ed') && word.length > 4) {
      var base = word.substring(0, word.length - 2);
      if (base.length >= 3 &&
          base.codeUnitAt(base.length - 1) == base.codeUnitAt(base.length - 2)) {
        base = base.substring(0, base.length - 1);
      }
      return base;
    }
    if (word.endsWith('s') &&
        word.length > 3 &&
        !word.endsWith('ss') &&
        !word.endsWith('us') &&
        !word.endsWith('is')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  static List<String> _tokenize(String text) {
    if (text.isEmpty) return const [];
    final raw = text.toLowerCase().split(_tokenSplitRegex);
    final result = <String>[];
    for (final tok in raw) {
      if (tok.length < 2) continue;
      if (int.tryParse(tok) != null) continue;
      result.add(_normalizeStem(tok));
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Classification
  // ---------------------------------------------------------------------------
  static NotificationClassificationResult classify({
    required String appName,
    required String packageName,
    required String title,
    required String content,
    String channelId = '',
    String androidCategory = '',
    bool isConversation = false,
    bool isMessagingStyle = false,
    bool hasReplyAction = false,
  }) {
    if (!isEnabled) {
      final override = getUserOverride(packageName, channelId);
      if (override != null) {
        return NotificationClassificationResult(
          category: override,
          confidence: 1.0,
          extractedOtp: null,
          isUserOverride: true,
        );
      }
      return const NotificationClassificationResult(
        category: NotificationCategory.silent,
        confidence: 0.0,
        extractedOtp: null,
      );
    }

    final otp = extractOtp(title, content);

    // 0. User override (highest priority)
    final override = getUserOverride(packageName, channelId);
    if (override != null) {
      return NotificationClassificationResult(
        category: override,
        confidence: 1.0,
        extractedOtp: otp,
        isUserOverride: true,
      );
    }

    // 1. Fast-path OTP -> Security
    if (otp != null) {
      return NotificationClassificationResult(
        category: NotificationCategory.security,
        confidence: 0.99,
        extractedOtp: otp,
      );
    }

    // 2. LRU Cache lookup
    final cacheKey = _lruKey(
      packageName: packageName,
      channelId: channelId,
      title: title,
      content: content,
      isConversation: isConversation,
      hasReplyAction: hasReplyAction,
    );
    final cached = _lruCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    // 3. Learned channel cache lookup
    final chKey = _channelKey(packageName, channelId);
    if (channelId.isNotEmpty && _learnedChannelCache.containsKey(chKey)) {
      final cat = _learnedChannelCache[chKey]!;
      final res = NotificationClassificationResult(
        category: cat,
        confidence: 0.95,
      );
      _putLru(cacheKey, res);
      return res;
    }

    // 4. Feature Extraction & Softmax Linear Model
    final feats = _extractFeatures(
      appName: appName,
      packageName: packageName,
      channelId: channelId,
      androidCategory: androidCategory,
      title: title,
      content: content,
      isConversation: isConversation || isMessagingStyle,
      hasReplyAction: hasReplyAction,
    );

    final logits = <NotificationCategory, double>{};
    double maxLogit = -1e9;

    for (final cat in NotificationCategory.values) {
      final baseBias = _trainedBiases[cat] ?? 0.0;
      final dynBias = _dynamicBiases[cat] ?? 0.0;
      final baseWeights = _trainedWeights[cat] ?? const {};
      final dynWeights = _dynamicWeights[cat] ?? const {};

      double score = baseBias + dynBias;
      feats.forEach((feat, val) {
        final w = (baseWeights[feat] ?? 0.0) + (dynWeights[feat] ?? 0.0);
        if (w != 0.0) {
          score += w * val;
        }
      });
      logits[cat] = score;
      if (score > maxLogit) {
        maxLogit = score;
      }
    }

    double sumExp = 0.0;
    final probs = <NotificationCategory, double>{};
    for (final cat in NotificationCategory.values) {
      final e = math.exp(logits[cat]! - maxLogit);
      probs[cat] = e;
      sumExp += e;
    }

    NotificationCategory bestCat = fallbackCategory;
    double bestProb = 0.0;
    for (final cat in NotificationCategory.values) {
      final p = probs[cat]! / sumExp;
      probs[cat] = p;
      if (p > bestProb) {
        bestProb = p;
        bestCat = cat;
      }
    }

    // Apply confidence threshold: fallback if prediction uncertainty is high
    final calibrated = bestProb.clamp(0.50, 0.99);
    final finalCat = calibrated >= confidenceThreshold ? bestCat : fallbackCategory;

    if (channelId.isNotEmpty && calibrated >= 0.92) {
      _learnedChannelCache[chKey] = finalCat;
    }

    final result = NotificationClassificationResult(
      category: finalCat,
      confidence: calibrated,
      extractedOtp: otp,
    );

    _putLru(cacheKey, result);
    return result;
  }

  static void _putLru(String key, NotificationClassificationResult result) {
    if (_lruCache.length >= _maxLruEntries) {
      _lruCache.remove(_lruCache.keys.first);
    }
    _lruCache[key] = result;
  }

  /// Asynchronously classify on a background isolate
  static Future<NotificationClassificationResult> classifyAsync({
    required String appName,
    required String packageName,
    required String title,
    required String content,
    String channelId = '',
    String androidCategory = '',
    bool isConversation = false,
    bool isMessagingStyle = false,
    bool hasReplyAction = false,
  }) async {
    if (!isEnabled) {
      return classify(
        appName: appName,
        packageName: packageName,
        title: title,
        content: content,
        channelId: channelId,
        androidCategory: androidCategory,
        isConversation: isConversation,
        isMessagingStyle: isMessagingStyle,
        hasReplyAction: hasReplyAction,
      );
    }
    // Fast path: User overrides and cached results resolve synchronously
    final override = getUserOverride(packageName, channelId);
    if (override != null) {
      return NotificationClassificationResult(
        category: override,
        confidence: 1.0,
        extractedOtp: extractOtp(title, content),
        isUserOverride: true,
      );
    }

    final cacheKey = _lruKey(
      packageName: packageName,
      channelId: channelId,
      title: title,
      content: content,
      isConversation: isConversation,
      hasReplyAction: hasReplyAction,
    );
    final cached = _lruCache[cacheKey];
    if (cached != null) return cached;

    return await Isolate.run(() {
      return classify(
        appName: appName,
        packageName: packageName,
        title: title,
        content: content,
        channelId: channelId,
        androidCategory: androidCategory,
        isConversation: isConversation,
        isMessagingStyle: isMessagingStyle,
        hasReplyAction: hasReplyAction,
      );
    });
  }

  /// Batch classify notifications asynchronously on a background isolate
  static Future<List<NotificationClassificationResult>> classifyBatchAsync(
    List<NotificationClassificationInput> inputs,
  ) async {
    if (inputs.isEmpty) return const [];
    return await Isolate.run(() {
      return inputs
          .map((i) => classify(
                appName: i.appName,
                packageName: i.packageName,
                title: i.title,
                content: i.content,
                channelId: i.channelId,
                androidCategory: i.androidCategory,
                isConversation: i.isConversation,
                isMessagingStyle: i.isMessagingStyle,
                hasReplyAction: i.hasReplyAction,
              ))
          .toList();
    });
  }

  static Map<String, double> _extractFeatures({
    required String appName,
    required String packageName,
    required String channelId,
    required String androidCategory,
    required String title,
    required String content,
    required bool isConversation,
    required bool hasReplyAction,
  }) {
    final feats = <String, double>{};
    void addFeat(String key, double delta) {
      feats[key] = (feats[key] ?? 0.0) + delta;
    }

    final app = appName.toLowerCase().trim();
    final pkg = packageName.toLowerCase().trim();
    final ch = channelId.toLowerCase().trim();
    final titleLower = title.toLowerCase();
    final contentLower = content.toLowerCase();
    final combined = '$titleLower $contentLower';

    for (final tok in _tokenize(ch)) {
      addFeat('__ch_$tok', 1.0);
    }

    // 1. Concept Detectors
    final hasOtp = _otpCueRegex.hasMatch(combined);
    final hasPromo = _promotionsConceptRegex.hasMatch(combined) ||
        _dltPromoRegex.hasMatch(title.trim());
    final hasSecurity = _securityConceptRegex.hasMatch(combined) || hasOtp;
    final hasRealtime = _realtimeConceptRegex.hasMatch(combined);
    final hasConversations = _conversationsConceptRegex.hasMatch(combined);
    final hasSocials = _socialsConceptRegex.hasMatch(combined);
    final hasUpdates = _updatesConceptRegex.hasMatch(combined);
    final hasSilent = _silentConceptRegex.hasMatch(combined);

    if (hasOtp) addFeat('__concept_otp', 5.0);
    if (hasSecurity && !hasPromo) addFeat('__concept_security', 4.5);
    if (hasRealtime && !hasPromo) addFeat('__concept_realtime', 4.5);
    if (hasPromo && !hasOtp) addFeat('__concept_promo', 4.5);
    if (hasUpdates && !hasPromo && !hasSecurity) addFeat('__concept_update', 4.0);
    if (hasSocials && !hasPromo) addFeat('__concept_social', 4.0);
    if (hasConversations && !hasPromo && !hasUpdates && !hasOtp) {
      addFeat('__concept_conversation', 4.0);
    }
    if (hasSilent) addFeat('__concept_silent', 4.2);

    // 2. Package Priors
    final pkgApp = '$pkg $app';
    if (_chatPkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_chat', 1.8);
    if (_socialPkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_social', 1.8);
    if (_commercePkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_commerce', 1.4);
    if (_realtimePkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_realtime', 2.0);
    if (_financePkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_finance', 2.0);
    if (_silentPkgs.any((k) => pkgApp.contains(k))) addFeat('__pkg_silent', 2.0);

    // 3. Sender / Conversational hints
    final isDlt = _dltSenderRegex.hasMatch(title.trim()) ||
        _shortcodeSenderRegex.hasMatch(title.trim());
    if (isDlt) addFeat('__sender_dlt', 2.0);

    final isChatApp = _chatPkgs.any((k) => pkgApp.contains(k));
    if ((isChatApp || isConversation || hasReplyAction) &&
        !hasPromo &&
        !hasUpdates &&
        !hasSocials &&
        !hasSecurity &&
        !hasRealtime) {
      addFeat('__sender_human_person', 3.0);
    }

    // 4. Tokenized Unigrams & Bigrams
    final tToks = _tokenize(titleLower);
    final cToks = _tokenize(contentLower);

    for (final tok in tToks) {
      addFeat(tok, 1.2);
    }
    for (var i = 0; i < tToks.length - 1; i++) {
      addFeat('${tToks[i]}_${tToks[i + 1]}', 1.4);
    }

    for (final tok in cToks) {
      addFeat(tok, 1.0);
    }
    for (var i = 0; i < cToks.length - 1; i++) {
      addFeat('${cToks[i]}_${cToks[i + 1]}', 1.2);
    }

    return feats;
  }

  // ---------------------------------------------------------------------------
  // Trained Biases and Weights
  // ---------------------------------------------------------------------------
  static const Map<NotificationCategory, double> _trainedBiases = {
    NotificationCategory.realtime: 0.35,
    NotificationCategory.security: 0.45,
    NotificationCategory.conversations: -0.20,
    NotificationCategory.socials: -0.10,
    NotificationCategory.updates: 0.30,
    NotificationCategory.promotions: -0.35,
    NotificationCategory.silent: -0.15,
  };

  static const Map<NotificationCategory, Map<String, double>> _trainedWeights = {
    NotificationCategory.realtime: {
      '__concept_realtime': 3.5, '__pkg_realtime': 2.8, 'call': 2.0, 'incoming': 1.8,
      'turn': 2.0, 'right': 1.5, 'left': 1.5, 'driver': 2.2, 'arriving': 2.0,
      'eta': 1.8, 'trip': 1.8, 'started': 1.5, 'alarm': 2.2, 'timer': 2.2,
      'ringing': 1.8, 'food': 1.5, 'partner': 1.5, 'nearby': 1.8, 'boarding': 2.0,
    },
    NotificationCategory.security: {
      '__concept_security': 3.8, '__concept_otp': 4.5, '__pkg_finance': 2.5, 'otp': 2.5,
      'code': 2.0, 'verification': 2.2, 'security': 2.2, 'alert': 1.8, 'debited': 2.2,
      'credited': 2.0, 'upi': 2.2, 'login': 2.0, 'sign_in': 2.2, 'password': 2.0,
      'declined': 2.0, 'blocked': 2.0, 'unauthorized': 2.5, 'balance': 1.8,
      '__sender_dlt': 1.5,
    },
    NotificationCategory.conversations: {
      '__concept_conversation': 3.5, '__sender_human_person': 3.0, '__pkg_chat': 2.5,
      'hi': 1.5, 'hey': 1.5, 'are_we': 1.8, 'are_you': 1.8, 'call_me': 1.8,
      'meet': 1.6, 'see_you': 1.8, 'sent_photo': 1.5, 'voice_message': 1.8,
    },
    NotificationCategory.socials: {
      '__concept_social': 3.5, '__pkg_social': 2.5, 'liked': 2.2, 'commented': 2.2,
      'mentioned': 2.2, 'follower': 2.0, 'photo': 1.5, 'profile': 1.8, 'post': 1.5,
      'friend_request': 2.2, 'retweeted': 2.2, 'upvoted': 2.0, 'replied': 1.5,
    },
    NotificationCategory.updates: {
      '__concept_update': 3.2, '__pkg_commerce': 1.8, 'order': 2.0, 'shipped': 2.2,
      'delivery': 1.8, 'package': 2.0, 'confirmed': 2.0, 'booking': 2.2, 'pnr': 2.5,
      'updates': 2.0, 'apps': 2.0, 'reminder': 1.8, 'event': 1.8, 'merged': 2.0,
    },
    NotificationCategory.promotions: {
      '__concept_promo': 3.8, 'off': 2.2, 'sale': 2.5, 'discount': 2.5, 'coupon': 2.5,
      'promo': 2.5, 'code': 1.2, 'free': 1.8, 'save': 2.0, 'deal': 2.0, 'bogo': 2.5,
      'cashback': 2.0, 'shop_now': 2.2, 'order_now': 2.0, 'flat': 1.8,
    },
    NotificationCategory.silent: {
      '__concept_silent': 3.5, '__pkg_silent': 2.5, 'charging': 2.5, 'rapidly': 2.0,
      'usb': 2.5, 'debugging': 2.5, 'vpn': 2.5, 'connected': 1.8, 'steps': 2.2,
      'playing': 2.0, 'download': 2.0, 'complete': 1.8,
    },
  };
}
