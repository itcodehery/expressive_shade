import 'dart:math' as math;
import '../models/notification_model.dart';

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

/// On-device smart notification categorization engine trained via a two-stage
/// L2-regularized Multinomial Logistic Regression + Semantic Concept Ensemble
/// (2,100+ lexical, bigram, package, and structural weights across 6 categories).
class SmartNotificationClassifier {
  SmartNotificationClassifier._();

  /// User-assigned overrides keyed by `"$packageName|$channelId"` or `"$packageName"`.
  static final Map<String, NotificationCategory> _userOverrides = {};

  /// High-confidence channel cache keyed by `"$packageName|$channelId"`.
  static final Map<String, NotificationCategory> _learnedChannelCache = {};

  static String _channelKey(String packageName, String channelId) {
    final pkg = packageName.trim().toLowerCase();
    final ch = channelId.trim().toLowerCase();
    return ch.isNotEmpty ? '$pkg|$ch' : pkg;
  }

  static void loadOverrides(Map<String, dynamic> raw) {
    _userOverrides.clear();
    raw.forEach((key, value) {
      final catName = value.toString();
      final cat = NotificationCategory.values.firstWhere(
        (c) => c.name == catName,
        orElse: () => NotificationCategory.other,
      );
      _userOverrides[key.toLowerCase()] = cat;
    });
  }

  static Map<String, String> exportOverrides() {
    return _userOverrides.map((k, v) => MapEntry(k, v.name));
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

  // ---------------------------------------------------------------------------
  // OTP / Verification Code Extractor
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

  // ---------------------------------------------------------------------------
  // High-Generalization Semantic Concept Detectors
  // ---------------------------------------------------------------------------
  static final RegExp _dltSenderRegex = RegExp(
    r'^[a-z]{2}-[a-z0-9]{3,10}(?:-[pstg])?$',
    caseSensitive: false,
  );
  static final RegExp _dltPromoRegex = RegExp(
    r'^[a-z]{2}-[a-z0-9]{3,10}-p$',
    caseSensitive: false,
  );
  static final RegExp _shortcodeSenderRegex = RegExp(r'^\d{5,6}$');

  static final RegExp _promoConceptRegex = RegExp(
    r'(\b\d{1,3}\s*%\s*(?:off|discount|cashback|save|back)\b|'
    r'(?:flat|save|extra|get|upto|up\s+to)\s*(?:[\u20B9\$\u20AC\u00A3]|rs\.?|inr|usd)\s*\d+|'
    r'\b(?:[\u20B9\$\u20AC\u00A3]|rs\.?|inr|usd)\s*\d+\s*(?:off|cashback|discount|voucher|coupon|back|free)\b|'
    r'\b(?:promo\s*code|coupon\s*code|discount\s*code|use\s+code|apply\s+code|voucher|flash\s+sale|mega\s+sale|clearance\s+sale|end\s+of\s+season|big\s+billion|great\s+indian\s+festival|buy\s+\d+\s+get\s+\d+|bogo|free\s+delivery|free\s+shipping|free\s+trial|try\s+.*?\s+free|months?\s+of\s+.*?\s+premium|upgrade\s+to\s+premium|ad[-\s]?free|pre[-\s]?approved\s+loan|zero\s+processing\s+fee|lifetime\s+free|shop\s+now|order\s+now|book\s+now|claim\s+now|avail\s+now|apply\s+now|don.?t\s+miss|limited\s+time\s+(?:offer|deal)|special\s+offer|exclusive\s+(?:offer|deal)|price\s+drop|wishlist\s+.*?\s+sale|unsubscribe|reply\s+stop|sponsored|play\s+points)\b)',
    caseSensitive: false,
  );

  static final RegExp _urgentConceptRegex = RegExp(
    r'(\b(?:missed\s+(?:voice\s+|video\s+)?calls?|incoming\s+(?:voice\s+|video\s+)?call|is\s+calling\s+you|new\s+voicemail|voicemail\s+from|'
    r'security\s+alert|critical\s+security|new\s+sign[-\s]?in|unrecognized\s+device|suspicious\s+(?:activity|login)|unauthorized\s+(?:login|transaction|access)|'
    r'compromised\s+password|data\s+breach|watchtower|password\s+reset\s+request|card\s+.*?\s+declined|transaction\s+declined|blocked\s+.*?\s+card|'
    r'low\s+battery|critical\s+battery|battery\s+saver\s+turned\s+on|shut\s+down\s+in\s+\d+|'
    r'alarm\s+ringing|wake\s+up\s+alarm|timer\s+(?:expired|finished|is\s+up)|'
    r'starting\s+in\s+\d+\s*min|starts?\s+in\s+\d+\s*min|starting\s+soon|leave\s+now\s+to\s+arrive|'
    r'boarding\s+(?:started|closes|gate\s+changed)|gate\s+change|final\s+call\s+for\s+boarding|'
    r'bill\s+due\s+today|overdue\s+(?:bill|task|payment)|avoid\s+late\s+(?:fee|payment)|'
    r'extreme\s+weather|severe\s+weather|cyclone\s+warning|emergency\s+alert)\b)',
    caseSensitive: false,
  );

  static final RegExp _updateConceptRegex = RegExp(
    r'(\b(?:out\s+for\s+delivery|in\s+transit|has\s+(?:shipped|been\s+dispatched)|dispatched\s+via|arriving\s+(?:today|tomorrow|in\s+\d+\s*min)|'
    r'order\s+(?:confirmed|picked\s+up|delivered|is\s+being\s+prepared|is\s+on\s+the\s+way|#\s*[a-z0-9-]+)|'
    r'delivery\s+partner|your\s+driver\s+is\s+arriving|ride\s+completed|trip\s+started|'
    r'awb\s*#?\s*\d+|waybill|track(?:ing)?\s+(?:package|id|number)|return\s+picked\s+up|refund\s+(?:initiated|processed|credited)|'
    r'debited|credited|withdrawn\s+from\s+atm|spent\s+on\s+.*?\s+card|via\s+upi|upi\s+ref|neft|imps|fastag|avl\s*bal|available\s+limit|e[-\s]?statement|'
    r'paid\s+[\u20B9\$\u20AC\u00A3]\s*\d+|received\s+[\u20B9\$\u20AC\u00A3]\s*\d+|money\s+(?:received|sent)|bill\s+payment\s+successful|receipt\s+for|invoice\s+(?:for|sent|and\s+receipt)|'
    r'sip\s+.*?\s+(?:executed|processed)|order\s+executed|pnr\s+\d+|chart\s+prepared|ticket\s+confirmed|'
    r'pull\s+request|merged\s+#?\d+|workflow\s+run|pipeline\s+#?\d+|moved\s+to\s+in\s+review|'
    r'\d+\s+apps?\s+updated|download\s+complete|upload\s+complete|backup\s+(?:&\s+sync\s+)?complete)\b)',
    caseSensitive: false,
  );

  static final RegExp _socialConceptRegex = RegExp(
    r'(\b(?:liked\s+your\s+(?:post|photo|reel|story|reply|comment|thread|video)|'
    r'commented\s+on\s+your\s+(?:post|photo|reel|video)|replied\s+to\s+your\s+(?:comment|thread|post)|'
    r'started\s+following\s+you|followed\s+you(?:\s+back)?|new\s+follower|friend\s+request|wants\s+to\s+connect|connection\s+invitation|'
    r'mentioned\s+you\s+in\s+(?:their\s+story|a\s+comment)|tagged\s+you\s+in|'
    r'reposted\s+your|retweeted\s+your|upvoted\s+your|reached\s+\d+\s+upvotes|'
    r'uploaded\s+a\s+(?:new\s+)?video|started\s+a\s+live\s+video|is\s+live\s+now|'
    r'viewed\s+your\s+profile|impressions\s+and\s+\d+\s+reactions|saved\s+your\s+pin|'
    r'added\s+to\s+their\s+story|posted\s+to\s+their\s+story|birthday\s+today|birthdays\s+today|trending\s+(?:on|in)\s+r/)\b)',
    caseSensitive: false,
  );

  static final RegExp _humanChatConceptRegex = RegExp(
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

  static final RegExp _otherConceptRegex = RegExp(
    r'(\b(?:\d+\u00B0[cf]\b|partly\s+cloudy|mostly\s+sunny|chance\s+of\s+rain|air\s+quality|aqi\s+\d+|weather\s+outlook|'
    r'screen\s+time\s+(?:report|summary)|daily\s+step\s+goal|steps?\s+and\s+(?:burned|\d+\s+heart)|morning\s+run\s+recorded|pace\s+\d+:\d+|'
    r'usb\s+debugging|charging\s+this\s+device\s+via\s+usb|vpn\s+(?:is\s+active|activated|connected)|'
    r'screenshot\s+saved|device\s+optimization\s+complete|freed\s+up\s+\d+)\b)',
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
    'makemytrip', 'goibibo', 'irctc', 'ubercab', 'olacabs', 'rapido',
    'delhivery', 'bluedart',
  ];
  static const List<String> _financePkgs = [
    'gpay', 'paisa', 'phonepe', 'paytm', 'bhim', 'bank', 'hdfc',
    'icici', 'sbi', 'axis', 'kotak', 'paypal', 'stripe', 'revolut',
    'zerodha', 'kite', 'groww', 'upstox', 'cred',
  ];
  static const List<String> _urgentPkgs = [
    'deskclock', 'clock', 'alarm', 'calendar', 'tasks', 'todoist',
    'ticktick', 'dialer', 'truecaller', 'onepassword', 'bitwarden',
    'authenticator', 'authy', 'cellbroadcast', 'adm',
  ];
  static const List<String> _devUpdatePkgs = [
    'github', 'gitlab', 'linear', 'jira', 'vending', 'downloads',
    'docs', 'drive', 'dropbox',
  ];
  static const List<String> _otherPkgs = [
    'weather', 'accuweather', 'wellbeing', 'fitness', 'strava', 'lool',
  ];
  static const List<String> _brandSenderWords = [
    'bank', 'hdfc', 'icici', 'sbi', 'axis', 'kotak', 'swiggy', 'zomato',
    'amazon', 'flipkart', 'myntra', 'blinkit', 'zepto', 'delhivery',
    'bluedart', 'lenskart', 'makemytrip', 'uber', 'ola', 'jio', 'airtel',
    'domino', 'nykaa', 'paytm', 'phonepe', 'official', 'support',
    'alerts', 'verify', 'verification', 'security', 'store', 'team',
    'newsletter', 'digest', 'steam', 'spotify', 'coursera', 'apple',
    'stripe', 'github', 'gitlab', 'irctc', 'indigo', 'air india',
    'instagram', 'youtube', 'reddit', 'linkedin', 'facebook', 'snapchat',
    'threads', 'tiktok', 'pinterest',
  ];

  /// Morphological stemmer matching the Python training pipeline 1:1.
  static String _normalizeStem(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ies') && word.length > 4) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('ing') && word.length > 5) {
      var base = word.substring(0, word.length - 3);
      if (base.length >= 3 &&
          base.codeUnitAt(base.length - 1) ==
              base.codeUnitAt(base.length - 2)) {
        base = base.substring(0, base.length - 1);
      }
      return base;
    }
    if (word.endsWith('ed') && word.length > 4) {
      var base = word.substring(0, word.length - 2);
      if (base.length >= 3 &&
          base.codeUnitAt(base.length - 1) ==
              base.codeUnitAt(base.length - 2)) {
        base = base.substring(0, base.length - 1);
      }
      return base;
    }
    if (word.endsWith('es') &&
        word.length > 4 &&
        !word.endsWith('ses') &&
        !word.endsWith('xes') &&
        !word.endsWith('zes') &&
        !word.endsWith('ches') &&
        !word.endsWith('shes')) {
      return word.substring(0, word.length - 1);
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
  // Main Classification Entry Point
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
    final otp = extractOtp(title, content);

    // 0. User Override check (highest priority)
    final override = getUserOverride(packageName, channelId);
    if (override != null) {
      return NotificationClassificationResult(
        category: override,
        confidence: 1.0,
        extractedOtp: otp,
        isUserOverride: true,
      );
    }

    // 1. Fast-path OTP -> Urgent
    if (otp != null) {
      return NotificationClassificationResult(
        category: NotificationCategory.urgent,
        confidence: 0.99,
        extractedOtp: otp,
      );
    }

    // 2. Extract features & run trained Multi-Class Softmax Linear Ensemble
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
      final bias = _trainedBiases[cat] ?? 0.0;
      final wMap = _trainedWeights[cat] ?? const {};
      double score = bias;
      feats.forEach((feat, val) {
        final w = wMap[feat];
        if (w != null) {
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

    NotificationCategory bestCat = NotificationCategory.other;
    double bestProb = 0.0;
    for (final cat in NotificationCategory.values) {
      final p = probs[cat]! / sumExp;
      probs[cat] = p;
      if (p > bestProb) {
        bestProb = p;
        bestCat = cat;
      }
    }

    final calibrated = bestProb.clamp(0.55, 0.99);
    if (channelId.isNotEmpty && calibrated >= 0.92) {
      _learnedChannelCache[_channelKey(packageName, channelId)] = bestCat;
    }

    return NotificationClassificationResult(
      category: bestCat,
      confidence: calibrated,
    );
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
    final acat = androidCategory.toLowerCase().trim();
    final titleLower = title.toLowerCase();
    final contentLower = content.toLowerCase();
    final combined = '$titleLower $contentLower';

    // 1. High-Generalization Semantic Concept Detectors
    final hasOtp = _otpCueRegex.hasMatch(combined);
    final hasPromo = _promoConceptRegex.hasMatch(combined) ||
        _dltPromoRegex.hasMatch(title.trim());
    final hasUrgent = _urgentConceptRegex.hasMatch(combined) || hasOtp;
    final hasUpdate = _updateConceptRegex.hasMatch(combined);
    final hasSocial = _socialConceptRegex.hasMatch(combined);
    final hasHumanChat = _humanChatConceptRegex.hasMatch(combined);
    final hasOther = _otherConceptRegex.hasMatch(combined);

    if (hasOtp) addFeat('__concept_otp', 4.5);
    if (hasUrgent && !hasPromo) addFeat('__concept_urgent', 3.8);
    if (hasPromo && !hasOtp) addFeat('__concept_promo', 4.0);
    if (hasUpdate && !hasPromo && !hasOtp) addFeat('__concept_update', 3.8);
    if (hasSocial && !hasPromo) addFeat('__concept_social', 3.8);
    if (hasHumanChat && !hasPromo && !hasUpdate && !hasOtp) {
      addFeat('__concept_human_chat', 3.5);
    }
    if (hasOther) addFeat('__concept_other', 3.8);

    // 2. Sender Disambiguation
    final trimmedTitle = title.trim();
    final isDlt = _dltSenderRegex.hasMatch(trimmedTitle) ||
        _shortcodeSenderRegex.hasMatch(trimmedTitle);
    final isTitleSameAsApp =
        titleLower.trim().isNotEmpty && titleLower.trim() == app;
    final isBrandSender = isDlt ||
        isTitleSameAsApp ||
        _brandSenderWords.any((b) => titleLower.contains(b));

    final pkgApp = '$pkg $app';
    final isChatApp = _chatPkgs.any((k) => pkgApp.contains(k));
    final isSocialApp = _socialPkgs.any((k) => pkgApp.contains(k));

    if (isDlt) addFeat('__sender_dlt', 1.8);
    if (isBrandSender) {
      addFeat('__sender_brand', 1.6);
    } else if ((isChatApp || isConversation || hasReplyAction) &&
        !hasPromo &&
        !hasUpdate &&
        !hasSocial &&
        !hasUrgent) {
      addFeat('__sender_human_person', 3.0);
    }

    if (isSocialApp &&
        !isTitleSameAsApp &&
        (isConversation || hasReplyAction) &&
        !hasSocial &&
        !hasPromo) {
      addFeat('__social_direct_message', 2.8);
    }

    // 3. OS Metadata (soft features)
    if (acat.isNotEmpty) {
      addFeat('__acat_$acat', 0.9);
    }
    for (final tok in _tokenize(ch)) {
      addFeat('__ch_$tok', 0.9);
    }

    // 4. Package family priors
    if (isChatApp) addFeat('__pkg_chat', 1.0);
    if (isSocialApp) addFeat('__pkg_social', 1.2);
    if (_commercePkgs.any((k) => pkgApp.contains(k))) {
      addFeat('__pkg_commerce', 1.1);
    }
    if (_financePkgs.any((k) => pkgApp.contains(k))) {
      addFeat('__pkg_finance', 1.2);
    }
    if (_urgentPkgs.any((k) => pkgApp.contains(k))) {
      addFeat('__pkg_urgent', 1.8);
    }
    if (_devUpdatePkgs.any((k) => pkgApp.contains(k))) {
      addFeat('__pkg_dev_update', 1.6);
    }
    if (_otherPkgs.any((k) => pkgApp.contains(k))) {
      addFeat('__pkg_other', 1.8);
    }

    // 5. Stemmed Title & Content Unigrams + Bigrams
    final tToks = _tokenize(titleLower);
    final cToks = _tokenize(contentLower);

    for (final tok in tToks) {
      addFeat(tok, 1.2);
    }
    for (var i = 0; i < tToks.length - 1; i++) {
      addFeat('${tToks[i]}_${tToks[i + 1]}', 1.35);
    }

    for (final tok in cToks) {
      addFeat(tok, 1.0);
    }
    for (var i = 0; i < cToks.length - 1; i++) {
      addFeat('${cToks[i]}_${cToks[i + 1]}', 1.15);
    }

    return feats;
  }

  static const Map<NotificationCategory, double> _trainedBiases = {
    NotificationCategory.urgent: 0.449,
    NotificationCategory.people: -0.22,
    NotificationCategory.updates: 0.4,
    NotificationCategory.social: -0.097,
    NotificationCategory.promotions: -0.399,
    NotificationCategory.other: -0.132,
  };

  static const Map<NotificationCategory, Map<String, double>> _trainedWeights = {
    NotificationCategory.urgent: {
      '__pkg_urgent': 1.763, 'call': 0.893, 'login': 0.715, '__pkg_social': -0.692,
      'mis': 0.61, 'password': 0.557, 'battery': 0.534, 'google': 0.525,
      'code': 0.493, 'security': 0.489, 'block': 0.457, 'alert': 0.452,
      'verify': 0.423, '__pkg_commerce': -0.401, 'video_call': 0.399, 'card': 0.387,
      '__sender_human_person': -0.382, 'is': 0.379, 'board': 0.377, 'otp': 0.374,
      'from': 0.369, 'do_not': 0.361, 'the': -0.347, 'verification_code': 0.347,
      'due': 0.34, 'call_from': 0.338, 'to': 0.338, '__ch_security': 0.329,
      '__pkg_dev_update': -0.323, '__sender_dlt': 0.323, '__pkg_other': -0.322, 'otp_for': 0.316,
      'new': 0.316, 'mis_video': 0.315, 'for': 0.313, 'timer': 0.31,
      'gate': 0.309, 'attempt': 0.307, 'your_login': 0.307, '__concept_urgent': 0.306,
      'account': 0.304, 'alarm': 0.301, 'critical': 0.293, 'voice_call': 0.291,
      '__pkg_finance': 0.291, 'is_valid': 0.291, 'valid_for': 0.291, 'do': 0.289,
      'not': 0.289, 'on': -0.289, 'min': 0.284, 'code_to': 0.281,
      'anyone': 0.28, 'security_alert': 0.28, 'verification': 0.278, 'is_your': 0.276,
      'due_today': 0.276, 'start': 0.27, 'and': -0.269, 'of': -0.266,
      'password_reset': 0.264, 'login_attempt': 0.261, 'your_google': 0.255, '__acat_status': -0.246,
      'free': -0.246, 'order': -0.244, 'at': -0.242, 'verify_your': 0.242,
      'immediately': 0.239, 'credit_card': 0.237, 'warn': 0.235, 'sign_in': 0.234,
      'valid': 0.233, 'your_one': 0.232, 'one_time': 0.232, 'declin': 0.231,
      'or': 0.226, 'reset': 0.221, 'off': -0.219, 'payment': 0.219,
      'in_min': 0.219, 'in': 0.218, 'voice': 0.217, 'to_anyone': 0.217,
      'your_account': 0.216, 'minute': 0.215, 'video': 0.215, 'use_verification': 0.214,
      'to_authorize': 0.214, 'authorize_your': 0.214, 'your_credit': 0.214, 'card_payment': 0.214,
      'soon': 0.213, 'this_code': 0.211, 'mis_call': 0.21, 'flipkart': 0.209,
      'ax_uidai': 0.207, 'transaction': 0.206, 'mis_voice': 0.206, 'start_in': 0.205,
      'screenshot': -0.203, 'timer_finish': 0.202, 'activity': 0.2, 'access': 0.199,
      'delivery': -0.197, 'alarm_am': 0.196, 'am': 0.195, 'voicemail': 0.195,
      'was': 0.193, 'critical_battery': 0.191, 'battery_warn': 0.191, 'warn_5%': 0.191,
      'overdue': 0.191, 'your': 0.191, '__acat_social': -0.19, 'offer': -0.19,
      '__acat_event': 0.189, 'sign': 0.187, 'time': 0.187, 'one': 0.186,
      'this': 0.183, 'account_access': 0.182, 'access_block': 0.182, 'vk_sbiinb': 0.18,
      'uidai': 0.18, 'rs': -0.179, 'sent': -0.178, 'for_aadhaar': 0.173,
      'aadhaar_xx4412': 0.173, 'xx4412_authentication': 0.173, 'authentication_is': 0.173, 'for_minute': 0.173,
      'view': -0.172, 'change': 0.172, 'authorize': 0.172, 'laundry_timer': 0.168,
      'timer_is': 0.168, 'is_up': 0.168, 'vm_icicib': 0.168, 'low_battery': 0.167,
      'battery_10%': 0.167, '10%_remain': 0.167, 'to_view': -0.167, '5%': 0.166,
      'urgent_hdfc': 0.165, 'hdfc_credit': 0.165, 'card_bill': 0.165, 'bill_due': 0.165,
      'github_security': 0.165, 'instagram': -0.164, 'morn_workout': 0.163, 'workout_alarm': 0.163,
      'alarm_ring': 0.163, 'ring_now': 0.163, 'vpn': -0.161, 'phone_will': 0.159,
      'will_shut': 0.159, 'shut_down': 0.159, 'down_in': 0.159, 'minute_unless': 0.159,
      'unless_connect': 0.159, 'connect_to': 0.159, 'to_power': 0.159, 'jd_google': 0.159,
      '__acat_call': 0.159, 'detect': 0.157, '__acat_err': 0.155, 'your_internet': 0.152,
      'internet_bank': 0.152, 'bank_password': 0.152, 'password_has': 0.152, 'been_lock': 0.152,
      'lock_after': 0.152, 'after_fail': 0.152, 'fail_login': 0.152, 'get': -0.151,
      'card_transaction': 0.15, 'transaction_declin': 0.15, 'customer_otp': 0.15, 'otp_to': 0.15,
      'to_add': 0.15, 'add_beneficiary': 0.15, 'beneficiary_is': 0.15, 'is_do': 0.15,
      'not_disclose': 0.15, 'disclose_to': 0.15, 'if': 0.15, 'inr': -0.149,
      'cp': -0.148, 'critical_security': 0.147, 'board_start': 0.145, 'start_flight': 0.145,
      'flight_6e': 0.145, 'remain': 0.145, 'sav': -0.145, 'your_otp': 0.144,
      'for_netbank': 0.144, 'netbank_transaction': 0.144, 'transaction_of': 0.144, 'rs_do': 0.144,
      'not_share': 0.144, 'share_this': 0.144, 'reset_request': 0.144, 'an': 0.144,
      'github': 0.143, 'you_mis': 0.143, 'from_alex': 0.143, 'request': 0.142,
      'finish': 0.141, 'battery_may': 0.139, 'may_run': 0.139, 'out_soon': 0.139,
      'soon_turn': 0.139, 'turn_on': 0.139, 'on_battery': 0.139, 'battery_saver': 0.139,
      'saver_or': 0.139, 'or_plug': 0.139, 'plug_in': 0.139, 'in_charger': 0.139,
      'aadhaar': 0.138, 'xx4412': 0.138, 'authentication': 0.138, 'gate_change': 0.138,
      'change_alert': 0.138, 'alert_ai': 0.138, 'by': -0.138, 'pay_₹34': 0.138,
      '₹34_today': 0.138, 'today_to': 0.138, 'to_avoid': 0.138, 'avoid_late': 0.138,
      'late_fee': 0.138, 'fee_and': 0.138, 'and_interest': 0.138, 'interest_charge': 0.138,
      'new_personal': 0.138, 'personal_access': 0.138, 'access_token': 0.138, 'token_or': 0.138,
      'or_ssh': 0.138, 'ssh_key': 0.138, 'key_was': 0.138, 'was_ad': 0.138,
      'account_verify': 0.138, 'verify_activity': 0.138, 'flipkart_verify': 0.136, 'laundry': 0.135,
      'overdue_payment': 0.135, 'payment_renew': 0.135, 'renew_car': 0.135, 'car_insurance': 0.135,
      'paid': -0.134, 'discord': 0.134, 'google_security': 0.133, 'out_for': -0.133,
      'for_delivery': -0.133, 'google_verification': 0.133, 'code_never': 0.133, 'never_share': 0.133,
      'share_it': 0.133, 'it_with': 0.133, 'with_anyone': 0.133, 'screenshot_sav': -0.132,
      'suspicious_login': 0.131, 'login_block': 0.131, 'workout': 0.131, 'ring': 0.131,
      'sale': -0.13, 'login_from': 0.129, 'from_new': 0.129, 'new_location': 0.129,
      'location_your': 0.129, 'your_security': 0.129, 'security_code': 0.129, 'code_is': 0.129,
      'phone': 0.128, 'shut': 0.128, 'unless': 0.128, 'power': 0.128,
      '__sender_brand': 0.127, 'new_voicemail': 0.127, 'flight': 0.126, '6e': 0.126,
      'your_debit': 0.125, 'debit_card': 0.125, 'card_end': 0.125, 'end_was': 0.125,
      'was_declin': 0.125, 'declin_at': 0.125, 'at_pos': 0.125, 'pos_due': 0.125,
      'due_to': 0.125, 'to_insufficient': 0.125, 'insufficient_fund': 0.125, 'fund_or': 0.125,
      'or_wrong': 0.125, 'wrong_pin': 0.125, 'share': 0.124, 'telegram': 0.123,
      '__concept_update': -0.123, 'unrecogniz_device': 0.123, 'device_sign': 0.123, 'in_attempt': 0.123,
      'attempt_block': 0.123, 'block_on': 0.123, 'google_account': 0.123, 'internet': 0.122,
      'lock': 0.122, 'after': 0.122, 'fail': 0.122, 'pm': 0.121,
      'proce_immediately': 0.121, 'immediately_to': 0.121, 'to_gate': 0.121, 'gate_b14': 0.121,
      'b14_final': 0.121, 'final_call': 0.121, 'call_for': 0.121, 'for_board': 0.121,
      'upi': -0.121, 'this_week': -0.121, 'add': 0.121, 'beneficiary': 0.121,
      'disclose': 0.121, 'ax': 0.12, 'someone_request': 0.12, 'request_password': 0.12,
      'reset_for': 0.12, 'for_your': 0.12, 'account_ignore': 0.12, 'ignore_if': 0.12,
      'if_this': 0.12, 'this_wasn': 0.12, 'wasn_you': 0.12, 'unsubscribe': -0.12,
      'time_password': 0.118, 'password_for': 0.118, 'for_login': 0.118, 'login_is': 0.118,
      'for_min': 0.118, '__acat_reminder': 0.118, 'down': 0.117, 'doctor_appointment': 0.117,
      'appointment_start': 0.117, 'start_soon': 0.117, 'renew': 0.117, 'insurance': 0.117,
      'up_to': -0.116, 'urgent': 0.116, 'netbank': 0.115, 'board_gate': 0.115,
      'gate_chang': 0.115, 'chang_from': 0.115, 'from_18b': 0.115, '18b_to': 0.115,
      'to_22a': 0.115, '22a_board': 0.115, 'board_close': 0.115, 'close_in': 0.115,
      'you': -0.114, 'app': -0.114, 'suspicious': 0.114, 'time_passcode': 0.114,
      'passcode_is': 0.114, 'is_enter': 0.114, 'enter_this': 0.114, 'this_on': 0.114,
      'on_flipkart': 0.114, 'flipkart_to': 0.114, 'to_verify': 0.114, 'complete': -0.113,
      'high_priority': 0.112, 'priority_reminder': 0.112, 'reminder_policy': 0.112, 'policy_expire': 0.112,
      'expire_tonight': 0.112, 'may': 0.112, 'turn': 0.112, 'plug': 0.112,
      'charger': 0.112, 'swiggy': -0.112, '__ch_battery': 0.111, 'new_sign': 0.111,
      'in_detect': 0.111, 'detect_on': 0.111, 'on_macbook': 0.111, 'macbook_pro': 0.111,
      'pro_in': 0.111, 'in_new': 0.111, 'new_delhi': 0.111, 'delhi_review': 0.111,
      'review_activity': 0.111, 'activity_immediately': 0.111, 'submit_tax': 0.111, 'tax_declaration': 0.111,
      'declaration_due': 0.111, 'personal': 0.111, 'token': 0.111, 'ssh': 0.111,
      '₹34': 0.111, 'avoid': 0.111, 'late': 0.111, 'interest': 0.111,
      'charge': 0.111, 'car': 0.111, 'lik_your': -0.111, 'view_or': -0.11,
      'or_share': -0.11, 'share_your': -0.11, 'your_screenshot': -0.11, 'are': -0.11,
      'in_minute': 0.11, 'tomorrow': -0.11, 'we_block': 0.109, 'block_an': 0.109,
      'an_unauthoriz': 0.109, 'unauthoriz_login': 0.109, 'attempt_from': 0.109, 'from_an': 0.109,
      'an_unknown': 0.109, 'unknown_ip': 0.109, 'ip_address': 0.109, 'bank': -0.109,
      '__acat_alarm': 0.109, 'low': 0.109, 'avl_bal': -0.109, 'bal_rs': -0.109,
      'arriv_in': -0.108, '__ch_call': 0.108, 'they': 0.107, 'get_free': -0.107,
      'to_unsubscribe': -0.107, 'invoice': -0.107, 'never': 0.106, 'voicemail_from': 0.106,
      'from_office': 0.106, 'office_reception': 0.106, 'reception_tap': 0.106, 'to_listen': 0.106,
      'vpn_is': -0.105, 'is_active': -0.105, 'vm': 0.105, 'sprint_plan': 0.105,
      'plan_start': 0.105, 'key': 0.105, 'is_out': -0.104, '__concept_otp': 0.104,
      'extreme_weather': 0.104, 'weather_alert': 0.104, 'confirm': -0.104, 'daily': -0.103,
      'flutterdev': -0.103, 'location': 0.103, 'cp_icicib': -0.103, 'hdfc_bank': -0.103,
      'km': -0.103, 'alex': 0.103, 'doctor': 0.101, 'appointment': 0.101,
      'run_out': 0.101, '__ch_due': 0.101, 'with_engineer': 0.101, 'engineer_manager': 0.101,
      'manager_start': 0.101, 'pay': 0.101, 'pos': 0.101, 'insufficient': 0.101,
      'special_offer': -0.1, 'their': -0.099, 'will': 0.099, 'week': -0.099,
      'unrecogniz': 0.098, 'to_your': -0.098, 'pm_at': 0.098, 'at_manipal': 0.098,
      'manipal_hospital': 0.098, 'hospital_leave': 0.098, 'leave_now': 0.098, 'now_to': 0.098,
      'to_arrive': 0.098, 'arrive_on': 0.098, 'on_time': 0.098, 'proce': 0.097,
      'b14': 0.097, 'final': 0.097, 'sbiinb': 0.097, 'post': -0.097,
      'via': -0.097, 'your_post': -0.096, 'submit': 0.096, 'tax': 0.096,
      'declaration': 0.096, 'ignore': 0.096, 'wasn': 0.096, 'to_their': -0.095,
      'of_rs': 0.095, 'usb': -0.095, 'live': -0.095, 'tech': -0.094,
      'arriv': -0.094, 'from_priya': 0.094, 'priya_tap': 0.094, 'to_call': 0.094,
      'call_back': 0.094, 'vk': 0.093, 'overdue_task': 0.093, 'task_upload': 0.093,
      'upload_rent': 0.093, 'rent_receipt': 0.093, 'receipt_before': 0.093, 'before_pm': 0.093,
      'pm_deadline': 0.093, 'chang': 0.092, '18b': 0.092, '22a': 0.092,
      'close': 0.092, 'comment': -0.092, 'express': -0.091, 'passcode': 0.091,
      'enter': 0.091, 'friend': -0.091, 'active': -0.091, 'sprint': 0.091,
      'extreme': 0.09, 'priority': 0.09, 'reminder': 0.09, 'policy': 0.09,
    },
    NotificationCategory.people: {
      '__sender_human_person': 2.461, '__pkg_chat': 0.784, '__sender_brand': -0.719, 'your': -0.447,
      'call': -0.402, '__acat_msg': 0.401, 'mis': -0.368, 'the': 0.362,
      '__sender_dlt': -0.331, 'you': 0.33, 'is': -0.318, '__pkg_urgent': -0.305,
      'meet': 0.304, 'video_call': -0.27, 'are': 0.266, 'video': -0.256,
      'mis_video': -0.252, 'my': 0.243, 'from': -0.241, '__pkg_commerce': -0.236,
      '__pkg_other': -0.224, '__pkg_dev_update': -0.22, 'hai': 0.213, 'sent': 0.211,
      'let': 0.209, 'prof_rajesh': 0.207, 'rajesh_kumar': 0.207, 'hi_let': 0.201,
      'and': -0.201, 'me': 0.2, 'call_from': -0.2, 'we': 0.196,
      'when': 0.19, 'are_we': 0.186, 'prof': 0.179, 'rajesh': 0.179,
      'kumar': 0.179, 'today': -0.175, 're_thesis': 0.172, 'thesis_draft': 0.172,
      'draft_feedback': 0.172, 'feedback_hi': 0.172, 'let_meet': 0.172, 'meet_in': 0.172,
      'in_my': 0.172, 'my_office': 0.172, 'office_on': 0.172, 'on_thursday': 0.172,
      'thursday_at': 0.172, 'at_pm': 0.172, 'pm_to': 0.172, 'to_discuss': 0.172,
      'discuss_chapter': 0.172, 're': 0.17, 'are_you': 0.169, 'when_you': 0.165,
      '__ch_chat': 0.162, 'hi': 0.162, 'hey': 0.159, 'voice_call': -0.158,
      'in': -0.153, 'to': -0.152, '__pkg_social': -0.149, 'way': 0.146,
      'mis_voice': -0.146, '__pkg_finance': -0.143, '__acat_status': -0.142, 'hey_are': 0.141,
      'good_to': 0.14, 'thesis': 0.139, 'draft': 0.139, 'feedback': 0.139,
      'thursday': 0.139, 'discuss': 0.139, 'chapter': 0.139, 'order': -0.136,
      'now': -0.136, 'start': -0.135, 'tap_to': -0.133, 'tap': -0.13,
      'of': -0.129, 'with': -0.129, 'office': 0.126, 'request': -0.12,
      'did_you': 0.116, 'you_mis': -0.115, 'from_alex': -0.115, '__ch_private': 0.114,
      '__acat_social': -0.112, 'good': 0.112, 'sent_you': 0.111, 'off': -0.111,
      'sameer': 0.108, 'code': -0.105, 'haan_bhai': 0.104, 'bhai_kal': 0.104,
      'kal_subah': 0.104, 'subah_baje': 0.104, 'baje_turf': 0.104, 'turf_pe': 0.104,
      'pe_milte': 0.104, 'milte_hai': 0.104, 'delivery': -0.1, 'mobile_eng': 0.097,
      'arjun': 0.097, 'sent_photo': 0.096, 'vikram': 0.096, 'hery': 0.094,
      'login': -0.093, 'did': 0.093, 'you_reel': 0.093, 'reel_by': 0.093,
      'by_memesdaily': 0.093, 'memesdaily_literally': 0.093, 'literally_us': 0.093, 'us_every': 0.093,
      'every_monday': 0.093, 'voice_message': 0.092, 'for': -0.091, 'me_when': 0.091,
      'siddharth': 0.09, 'run': -0.09,
    },
    NotificationCategory.updates: {
      '__pkg_dev_update': 1.092, '__pkg_commerce': 0.718, 'order': 0.636, '__pkg_social': -0.63,
      '__sender_human_person': -0.628, 'delivery': 0.561, '__acat_status': 0.502, 'rs': 0.485,
      'confirm': 0.482, 'bank': 0.473, '__pkg_urgent': -0.46, '__sender_dlt': 0.457,
      'at': 0.451, 'has': 0.42, 'invoice': 0.399, 'paid': 0.388,
      'inr': 0.386, 'out_for': 0.379, 'for_delivery': 0.379, 'from': 0.374,
      '__pkg_other': -0.369, '__concept_update': 0.353, 'code': -0.349, 'has_been': 0.343,
      'swiggy': 0.342, 'complet': 0.342, '__pkg_finance': 0.341, 'your': 0.33,
      'download': 0.324, 'arriv_in': 0.319, 'this': -0.314, 'express': 0.312,
      'storage': 0.304, 'off': -0.301, 'to_your': 0.301, 'receipt': 0.296,
      'deliver': 0.292, 'complete': 0.289, 'is_out': 0.289, 'by': 0.285,
      'fastag': 0.28, 'arriv': 0.277, 'been': 0.275, 'you': -0.271,
      'login': -0.269, 'free': -0.267, 'your_order': 0.266, 'updat': 0.265,
      'hdfc_bank': 0.264, 'all': 0.257, 'and': 0.256, 'merg': 0.256,
      'upi': 0.252, 'new': -0.25, 'bill': 0.244, 'delivery_today': 0.24,
      'up_to': 0.239, 'ci': 0.237, 'for': 0.237, 'out': 0.236,
      'at_indiranagar': 0.236, 'apple': 0.234, 'ticket_confirm': 0.233, 'confirm_pnr': 0.233,
      'offer': -0.232, 'shipment': 0.231, 'android': 0.229, 'with': 0.228,
      'avl_bal': 0.227, 'bal_rs': 0.227, 'your_invoice': 0.225, 'invoice_and': 0.225,
      'and_receipt': 0.225, 'receipt_for': 0.225, 'for_icloud': 0.225, 'icloud_200gb': 0.225,
      '200gb_storage': 0.225, 'storage_plan': 0.225, 'plan_\$2': 0.225, 'delivery_partner': 0.216,
      'time': -0.215, 'password': -0.212, 'download_complete': 0.211, 'complete_mb': 0.211,
      'on_your': -0.205, 'now': -0.205, '__acat_progress': 0.203, 'ticket': 0.202,
      'pnr': 0.202, 'ref': 0.202, 'sip': 0.199, 'broadband_bill': 0.197,
      'bill_payment': 0.197, 'payment_successful': 0.197, 'app_updat': 0.196, 'updat_automatically': 0.196,
      'debit': 0.195, 'shatabdi_express': 0.194, 'express_coach': 0.194, 'coach_c4': 0.194,
      'c4_seat': 0.194, 'seat_confirm': 0.194, 'order_has': 0.192, 'app': 0.192,
      'indiranagar': 0.189, 'workflow_run': 0.189, 'run_succeed': 0.189, 'otp': -0.189,
      'get': -0.187, 'paid_₹180': 0.185, '₹180_to': 0.185, 'to_third': 0.185,
      'third_wave': 0.185, 'wave_coffee': 0.185, 'backup_sync': 0.185, 'sync_complete': 0.185,
      'access': -0.184, 'cp_axisbk': 0.183, 'tm_fastag': 0.182, 'use': -0.182,
      'avl': 0.182, 'bal': 0.182, 'icloud': 0.181, '200gb': 0.181,
      '\$2': 0.181, 'bluedart_express': 0.18, 'up': 0.178, 'receiv_₹2': 0.177,
      '₹2_from': 0.177, 'from_karthik': 0.177, 'credit': 0.177, 'google': -0.177,
      'android_expressive': 0.176, 'expressive_mockup': 0.176, 'mockup_zip': 0.176, 'zip_finish': 0.176,
      'finish_download': 0.176, 'customer_acct': 0.176, 'acct_xx1102': 0.176, 'xx1102_is': 0.176,
      'is_credit': 0.176, 'credit_with': 0.176, 'with_inr': 0.176, 'inr_on': 0.176,
      'on_nov': 0.176, 'nov_by': 0.176, 'by_neft': 0.176, 'neft_info': 0.176,
      'info_salary': 0.176, 'amazon': 0.174, 'share': -0.174, 'deal': -0.174,
      'partner': 0.173, 'broadband': 0.171, 'successful': 0.171, 'otp_for': -0.17,
      'ax_sbiinb': 0.17, 'automatically': 0.17, 'verification_code': -0.169, 'or': -0.168,
      'pr_merg': 0.167, 'merg_into': 0.167, 'into_main': 0.167, 'ad_delhvy': 0.167,
      '__acat_social': -0.167, 'refund': 0.165, 'initiat': 0.165, 'paid_₹999': 0.164,
      '₹999_for': 0.164, 'for_airtel': 0.164, 'airtel_xstream': 0.164, 'xstream_fiber': 0.164,
      'fiber_bill': 0.164, 'bill_receipt': 0.164, 'receipt_generat': 0.164, 'workflow': 0.164,
      'succeed': 0.164, 'all_instal': 0.164, 'instal_app': 0.164, 'app_are': 0.164,
      'are_now': 0.164, 'now_up': 0.164, 'to_date': 0.164, 'block': -0.161,
      'is_valid': -0.161, 'valid_for': -0.161, '₹180': 0.161, 'third': 0.161,
      'wave': 0.161, 'backup': 0.16, 'axisbk': 0.159, 'tm': 0.158,
      'all_ci': 0.157, 'ci_check': 0.157, 'check_pas': 0.157, 'pas_on': 0.157,
      'on_branch': 0.157, 'branch_feat': 0.157, 'feat_smart': 0.157, 'smart_classifier': 0.157,
      'lik_your': -0.157, 'shatabdi': 0.156, 'coach': 0.156, 'c4': 0.156,
      'seat': 0.156, 'issue_eng': 0.155, 'eng_mov': 0.155, 'mov_to': 0.155,
      'to_in': 0.155, 'in_review': 0.155, 'call': -0.154, 'complet_hdfc': 0.154,
      'bank_upi': 0.154, 'upi_transaction': 0.154, 'transaction_id': 0.154, 'verify': -0.154,
      'photo_and': 0.154, 'and_document': 0.154, 'document_back': 0.154, 'back_up': 0.154,
      'to_cloud': 0.154, 'cloud_storage': 0.154, 'receiv': 0.154, '₹2': 0.154,
      'sync': 0.153, 'inr_spent': 0.153, 'spent_on': 0.153, 'on_axis': 0.153,
      'axis_bank': 0.153, 'bank_credit': 0.153, 'card_xx3319': 0.153, 'xx3319_at': 0.153,
      'at_swiggy': 0.153, 'swiggy_available': 0.153, 'available_limit': 0.153, 'limit_inr': 0.153,
      'pick_up': 0.153, 'hdfc': 0.153, 'bluedart': 0.153, 'do_not': -0.153,
      'fastag_toll': 0.152, 'toll_deduction': 0.152, 'deduction_rs': 0.152, 'rs_debit': 0.152,
      'debit_at': 0.152, 'at_electronic': 0.152, 'electronic_city': 0.152, 'city_elevat': 0.152,
      'elevat_flyover': 0.152, 'flyover_plaza': 0.152, 'prepar': 0.151, 'plan': 0.151,
      'instagram': -0.151, 'shipment_waybill': 0.15, 'waybill_is': 0.15, 'today_between': 0.15,
      'between_am': 0.15, 'am_and': 0.15, 'and_pm': 0.15, 'this_week': -0.148,
      'your_driver': 0.148, 'driver_is': 0.148, 'is_arriv': 0.148, 'money_credit': 0.148,
      'credit_to': 0.148, 'your_state': 0.148, 'state_bank': 0.148, 'bank_of': 0.148,
      'of_india': 0.148, 'india_account': 0.148, 'account_xx8821': 0.148, 'sale': -0.148,
      'to': 0.147, 'tap': -0.147, 'package': 0.146, 'board': -0.146,
      'karthik': 0.145, 'pr': 0.145, 'into': 0.145, 'main': 0.145,
      'delhvy': 0.144, 'your_blinkit': 0.143, 'blinkit_order': 0.143, 'order_bl': 0.143,
      'bl_with': 0.143, 'with_milk': 0.143, 'milk_bread': 0.143, 'bread_egg': 0.143,
      'egg_is': 0.143, 'is_on': 0.143, 'the_way': 0.143, 'ride_complet': 0.142,
      'complet_invoice': 0.142, 'invoice_₹245': 0.142, 'your_x8821': 0.142, 'x8821_debit': 0.142,
      'debit_by': 0.142, 'by_rs': 0.142, 'rs_on': 0.142, 'on_08nov26': 0.142,
      '08nov26_trf': 0.142, 'trf_to': 0.142, 'to_amazon': 0.142, 'amazon_seller': 0.142,
      'seller_service': 0.142, 'service_ref': 0.142, 'ref_no': 0.142, 'tap_to': -0.142,
      'of_rs': -0.142, 'expressive': 0.141, 'mockup': 0.141, 'zip': 0.141,
      'mb': 0.141, 'acct': 0.141, 'xx1102': 0.141, 'nov': 0.141,
      'neft': 0.141, 'info': 0.141, 'salary': 0.141, 'jd_kotakb': 0.141,
      'security': -0.14, 'ci_bot': 0.139, 'bot_merg': 0.139, 'merg_pull': 0.139,
      'pull_request': 0.139, 'request_optimize': 0.139, 'optimize_notification': 0.139, 'notification_list': 0.139,
      'list_sort': 0.139, 'delhivery_shipment': 0.139, 'shipment_awb': 0.139, 'awb_from': 0.139,
      'from_nykaa': 0.139, 'nykaa_is': 0.139, 'delivery_with': 0.139, 'with_agent': 0.139,
      'agent_ramesh': 0.139, 'tomorrow': -0.139, 'screenshot': -0.138, 'is_your': -0.136,
      'verification': -0.136, '__ch_update': 0.135, 'issue': 0.134, 'mov': 0.134,
      'vk_indusb': 0.133, '₹999': 0.132, 'xstream': 0.132, 'fiber': 0.132,
      'generat': 0.132, 'pick': 0.132, 'instal': 0.131, 'date': 0.131,
      'off_on': -0.131, 'sip_order': 0.13, 'order_execut': 0.13, 'battery': -0.13,
      'assign_to': 0.129, 'to_you': 0.129, 'you_updat': 0.129, 'updat_status': 0.129,
      'status_on': 0.129, 'on_android': 0.129, 'android_shade': 0.129, 'shade_polish': 0.129,
      'valid': -0.129, 'save': -0.129, 'driver': 0.128, 'order_deliver': 0.128,
      'deliver_at': 0.128, 'at_doorstep': 0.128, 'vpn': -0.128, 'post': -0.128,
      'flat': -0.127, 'your_post': -0.127, 'lik': -0.127, 'pas': 0.126,
      'feat': 0.126, 'smart': 0.126, 'classifier': 0.126, '__ch_order': 0.126,
      'on_the': 0.125, 'week': -0.124, 'id': 0.124, 'in_minute': 0.124,
      'meet_suresh': 0.123, 'suresh_in': 0.123, 'in_silver': 0.123, 'silver_hyundai': 0.123,
      'hyundai_aura': 0.123, 'aura_ka': 0.123, 'ka_mn': 0.123, 'mn_at': 0.123,
      'the_pickup': 0.123, 'pickup_point': 0.123, 'document': 0.123, 'cloud': 0.123,
      'ride': 0.123, '₹245': 0.123, 'spent': 0.123, 'axis': 0.123,
      'xx3319': 0.123, 'check': 0.122, 'do': -0.122, 'not': -0.122,
      'kotakb': 0.122, 'toll': 0.122, 'deduction': 0.122, 'city': 0.122,
      'elevat': 0.122, 'flyover': 0.122, 'plaza': 0.122, 'view': -0.121,
      'due': -0.121, 'code_to': -0.12, 'waybill': 0.12, 'between': 0.12,
      'comment': -0.12, 'device': -0.12, 'your_swiggy': 0.119, 'swiggy_instamart': 0.119,
      'instamart_order': 0.119, 'been_deliver': 0.119, 'deliver_total': 0.119, 'total_invoice': 0.119,
      'invoice_paid': 0.119, 'paid_₹542': 0.119, 'money': 0.119, 'state': 0.119,
      'india': 0.119, 'xx8821': 0.119, 'trip_start': 0.118, 'start_at': 0.118,
      'indiranagar_and': 0.118, 'and_complet': 0.118, 'complet_at': 0.118, 'at_airport': 0.118,
      'airport_terminal': 0.118, 'rs_withdrawn': 0.117, 'withdrawn_from': 0.117, 'from_atm': 0.117,
      'atm_at': 0.117, 'indiranagar_from': 0.117, 'from_kotak': 0.117, 'kotak_card': 0.117,
      'card_xx7712': 0.117, 'xx7712_avl': 0.117, 'alert': -0.117, 'coffee': 0.117,
      '__ch_security': -0.116, 'indusb': 0.116, 'eng': 0.116, 'ax_uidai': -0.115,
      'flutterdev': -0.115, 'is': 0.115, 'blinkit': 0.115, 'bl': 0.115,
      'milk': 0.115, 'bread': 0.115, 'egg': 0.115, '__pkg_chat': 0.114,
      'x8821': 0.114, '08nov26': 0.114, 'trf': 0.114, 'seller': 0.114,
      'service': 0.114, 'connect': -0.114, 'at_the': 0.113, 'attempt': -0.113,
      'execut': 0.113, 'anyone': -0.112, 'fee': -0.112, 'login_attempt': -0.112,
      'branch': 0.112, 'bot': 0.111, 'pull': 0.111, 'optimize': 0.111,
      'notification': 0.111, 'list': 0.111, 'sort': 0.111, 'delhivery': 0.111,
      'awb': 0.111, 'nykaa': 0.111, 'ramesh': 0.111, 'your_statement': 0.111,
      'statement_for': 0.111, 'for_indusind': 0.111, 'indusind_bank': 0.111, 'bank_account': 0.111,
      'account_xx9011': 0.111, 'xx9011_for': 0.111, 'for_october': 0.111, 'october_has': 0.111,
      'been_sent': 0.111, 'sent_to': 0.111, 'your_email': 0.111, 'doorstep': 0.111,
      'dear_customer': 0.111, 'sent_rs': 0.11, 'rs_from': 0.11, 'from_hdfc': 0.11,
      'bank_to': 0.11, 'to_zomato': 0.11, 'zomato_via': 0.11, 'via_upi': 0.11,
      'upi_ref': 0.11, 'ref_avl': 0.11, 'your_login': -0.11, 'review': 0.11,
      'on': -0.109, 'end': -0.109, 'your_monthly': 0.108, 'monthly_mutual': 0.108,
      'mutual_fund': 0.108, 'fund_sip': 0.108, 'sip_of': 0.108, 'of_₹10': 0.108,
      '₹10_in': 0.108, 'in_parag': 0.108, 'parag_parikh': 0.108, 'parikh_flexi': 0.108,
      'flexi_cap': 0.108, 'cap_has': 0.108, 'been_proces': 0.108, 'sav': -0.108,
      'daily': -0.108, 'your_one': -0.107, 'one_time': -0.107, 'return_pick': 0.107,
      'up_refund': 0.107, 'refund_initiat': 0.107, 'use_verification': -0.107, 'to_authorize': -0.107,
      'authorize_your': -0.107, 'your_credit': -0.107, 'card_payment': -0.107, 'agent': 0.107,
      'your_zepto': 0.107, 'zepto_package': 0.107, 'package_was': 0.107, 'was_deliver': 0.107,
      'deliver_rate': 0.107, 'rate_your': 0.107, 'your_delivery': 0.107, 'is_live': -0.106,
      'apply': -0.106, 'no': 0.105, 'to_view': -0.104, '__concept_urgent': -0.104,
      'assign': 0.104, 'status': 0.104, 'shade': 0.104, 'polish': 0.104,
      'shop_now': -0.104, 'airtel': 0.103, 'start': -0.103, 'will_arrive': 0.103,
      'your_account': -0.103, '__ch_message': 0.102, 'sent': 0.102, '50%': -0.101,
      'account_access': -0.101, 'access_block': -0.101, '__sender_brand': 0.1, 'uidai': -0.1,
      'video': -0.099, 'live': -0.099, 'suresh': 0.099, 'silver': 0.099,
      'hyundai': 0.099, 'aura': 0.099, 'ka': 0.099, 'mn': 0.099,
      'pickup': 0.099, 'timer': -0.098, 'order_is': 0.098, 'is_being': 0.098,
      'being_prepar': 0.098, '10%': -0.098, 'km': -0.098, 'get_free': -0.097,
      'credit_card': -0.096, 'for_aadhaar': -0.096, 'aadhaar_xx4412': -0.096, 'xx4412_authentication': -0.096,
      'authentication_is': -0.096, 'for_minute': -0.096, 'instamart': 0.096, 'total': 0.096,
      '₹542': 0.096, 'special_offer': -0.095, '__acat_sys': -0.095, 'airport': 0.095,
      'terminal': 0.095, 'withdrawn': 0.094, 'atm': 0.094, 'kotak': 0.094,
      'xx7712': 0.094, 'declin': -0.093, 'return': 0.093, 'due_today': -0.093,
      'morn': -0.092, 'your_comment': -0.091, 'in_your': -0.09, 'verify_your': -0.09,
    },
    NotificationCategory.social: {
      '__pkg_social': 2.271, '__acat_social': 0.733, 'instagram': 0.619, '__sender_brand': 0.578,
      '__pkg_chat': -0.568, '__sender_human_person': -0.552, 'lik_your': 0.458, 'post': 0.398,
      'comment': 0.398, 'for': -0.396, 'your_post': 0.394, 'follow_you': 0.39,
      'flutterdev': 0.386, '__sender_dlt': -0.383, 'lik': 0.372, 'your': 0.369,
      '__pkg_urgent': -0.341, 'friend': 0.326, 'their': 0.317, 'follow': 0.313,
      '__pkg_commerce': -0.307, 'people': 0.295, 'to_their': 0.293, 'friend_request': 0.281,
      'story': 0.274, 'birthday': 0.27, 'your_comment': 0.27, 'their_story': 0.255,
      '__acat_msg': -0.255, '__pkg_other': -0.248, '__pkg_dev_update': -0.246, '__concept_social': 0.245,
      'trend': 0.234, 'androiddev': 0.234, 'you': 0.233, 'free': -0.23,
      'at': -0.228, 'unixporn': 0.224, 'start_follow': 0.221, 'view': 0.212,
      'order': -0.204, 'video': 0.196, 'upload': 0.194, 'view_your': 0.192,
      'your_profile': 0.192, 'repli_to': 0.189, 'up': -0.187, 'birthday_today': 0.182,
      'account': -0.179, '__pkg_finance': -0.177, 'off': -0.171, 'flutterdev_follow': 0.17,
      'you_back': 0.17, 'back_on': 0.17, 'live': 0.168, 'new': 0.164,
      'screenshot': -0.163, 'profile': 0.161, 'comment_on': 0.161, 'see': 0.161,
      'it': 0.16, 'new_connection': 0.16, 'connection_invitation': 0.16, 'fireship_is': 0.16,
      'live_now': 0.16, 'now_in': 0.16, 'in_space': 0.16, 'space_the': 0.16,
      'the_future': 0.16, 'future_of': 0.16, 'of_local': 0.16, 'local_ai': 0.16,
      'request': 0.159, 'snapchat': 0.159, 'ui': 0.155, '__acat_status': -0.154,
      'security': -0.154, 'trend_on': 0.153, 'on_androiddev': 0.153, 'karan_ad': 0.153,
      'story_tap': 0.153, 'view_snap': 0.153, 'repli': 0.151, 'today_is': 0.151,
      'is_aditi': 0.151, 'aditi_rao': 0.151, 'rao_birthday': 0.151, 'birthday_write': 0.151,
      'write_on': 0.151, 'on_her': 0.151, 'her_timeline': 0.151, 'pinterest': 0.147,
      'or': -0.146, 'code': -0.144, 'with': -0.144, 'aarav_design': 0.144,
      'design_start': 0.144, 'the': 0.144, 'on': 0.142, 'people_sav': 0.141,
      'sav_your': 0.141, 'your_pin': 0.141, 'pin_to': 0.141, 'their_minimalist': 0.141,
      'minimalist_ui': 0.141, 'ui_board': 0.141, 'connection': 0.139, 'invitation': 0.139,
      'login': -0.137, 'the_primeagen': 0.136, 'primeagen_upload': 0.136, 'upload_new': 0.136,
      'new_video': 0.136, 'linux_enthusiast': 0.136, 'enthusiast_repli': 0.136, 'comment_in': 0.136,
      'in_flutterdev': 0.136, 'neha_gupta': 0.134, 'gupta_staff': 0.134, 'staff_product': 0.134,
      'product_designer': 0.134, 'designer_want': 0.134, 'to_connect': 0.134, 'connect_on': 0.134,
      'on_linkedin': 0.134, 'are': -0.133, 'delivery': -0.128, 'fireship': 0.128,
      'space': 0.128, 'future': 0.128, 'rakesh_nair': 0.128, 'nair_sent': 0.128,
      'you_friend': 0.128, 'request_mutual': 0.128, 'mutual_friend': 0.128, 'trend_in': 0.127,
      'in_androiddev': 0.127, 'androiddev_how': 0.127, 'how_we': 0.127, 'we_reduc': 0.127,
      'reduc_apk': 0.127, 'apk_size': 0.127, 'size_by': 0.127, 'by_45%': 0.127,
      'sale': -0.125, 'verify': -0.123, 'want_to': 0.122, '__ch_follower': 0.122,
      'karan': 0.122, 'snap': 0.122, 'post_reach': 0.122, 'reach_upvote': 0.122,
      'upvote_in': 0.122, 'in_unixporn': 0.122, 'unixporn_see': 0.122, 'see_the': 0.122,
      'the_comment': 0.122, 'aditi': 0.121, 'write': 0.121, 'her': 0.121,
      'timeline': 0.121, 'has': -0.121, 'call': -0.121, 'premium': -0.121,
      '__acat_email': -0.119, 'card': -0.119, 'primeagen': 0.118, 'alert': -0.117,
      'google': -0.116, 'aarav': 0.115, 'people_lik': 0.115, 'meet': -0.113,
      'why_switch': 0.113, 'switch_to': 0.113, 'to_nushell': 0.113, 'nushell_new': 0.113,
      'new_upload': 0.113, 'upload_from': 0.113, 'your_subscription': 0.113, 'minimalist': 0.113,
      'this': -0.113, 'post_is': 0.112, 'is_get': 0.112, 'get_traction': 0.112,
      'from': -0.112, 'local': 0.111, 'start': 0.11, 'credit': -0.11,
      'ad_to': 0.109, 'mkbhd_start': 0.109, 'start_live': 0.109, 'live_video': 0.109,
      'video_watch': 0.109, 'watch_it': 0.109, 'it_before': 0.109, 'before_it': 0.109,
      'it_end': 0.109, 'linux': 0.109, 'enthusiast': 0.109, 'design': 0.109,
      'time': -0.109, 'and_other': 0.108, 'gupta': 0.107, 'staff': 0.107,
      'product': 0.107, 'designer': 0.107, 'linkedin': 0.107, 'from_your': 0.107,
      'rao': 0.106, 'password': -0.106, 'screenshot_sav': -0.106, 'in_min': -0.106,
      'people_view': 0.105, 'up_to': -0.104, 'has_been': -0.104, 'run': -0.103,
      'share': -0.103, 'rakesh': 0.102, 'nair': 0.102, 'nikhil_mention': 0.102,
      'mention_you': 0.102, 'you_in': 0.102, 'in_their': 0.102, 'how': 0.102,
      'reduc': 0.102, 'size': 0.102, '45%': 0.102, 'ai': 0.102,
      'neha': 0.101, 'is_live': 0.101, 'back': 0.1, 'offer': -0.1,
      'dev_sharma': 0.1, 'sharma_comment': 0.1, 'your_photo': 0.1, 'photo_clean': 0.1,
      'clean_setup': 0.1, 'setup_what': 0.1, 'what_monitor': 0.1, 'monitor_is': 0.1,
      'is_that': 0.1, 'tomorrow': -0.099, 'rs': -0.099, 'want': 0.098,
      'thread': 0.098, 'min': -0.098, 'traction': 0.098, 'upvote': 0.098,
      'pin': 0.096, 'apk': 0.096, '__ch_message': -0.096, 'your_account': -0.096,
      'out': -0.096, 'youtube': -0.096, 'of': -0.094, 'impression_and': 0.094,
      'and_reaction': 0.094, 'reaction_on': 0.094, 'your_recent': 0.094, 'recent_post': 0.094,
      'bank': -0.092, 'block': -0.091, 'invoice': -0.091, 'why': 0.091,
      'switch': 0.091, 'nushell': 0.091, 'subscription': 0.091,
    },
    NotificationCategory.promotions: {
      'off': 0.891, 'free': 0.834, 'on': 0.681, 'offer': 0.643,
      'now': 0.581, '__sender_human_person': -0.511, '__sender_brand': 0.501, 'sale': 0.495,
      '__pkg_commerce': 0.463, '__pkg_social': -0.449, 'of': 0.446, 'get': 0.435,
      'deal': 0.423, 'flat': 0.384, 'is': -0.36, 'unsubscribe': 0.359,
      'off_on': 0.344, '__pkg_urgent': -0.33, 'special_offer': 0.323, 'save': 0.32,
      'shop_now': 0.317, 'tech': 0.308, 'premium': 0.293, 'to_unsubscribe': 0.292,
      'spotify': 0.287, 'use': 0.286, '__acat_promo': 0.278, 'exclusive': 0.26,
      'special': 0.259, 'apply': 0.257, 'shop': 0.254, '__concept_promo': 0.253,
      'get_free': 0.252, 'in_your': 0.24, '__pkg_other': -0.236, 'your': -0.235,
      'from': -0.232, 'cp_icicib': 0.23, 'this_week': 0.229, 'discount': 0.228,
      'use_promo': 0.226, 'promo_code': 0.226, '50%': 0.225, 'next': 0.222,
      'try': 0.22, 'month': 0.22, 'steam': 0.215, 'lenskart': 0.21,
      '80%_off': 0.209, 'domino': 0.209, 'buy_get': 0.202, 'free_on': 0.202,
      'tldr_tech': 0.2, 'tech_newsletter': 0.2, '__ch_promo': 0.2, 'off_your': 0.198,
      'zero': 0.198, 'sale_is': 0.196, 'book_now': 0.195, 'week': 0.194,
      'upgrade_to': 0.192, 'to_icici': 0.192, 'icici_sapphiro': 0.192, 'sapphiro_credit': 0.192,
      'card_with': 0.192, 'with_lifetime': 0.192, 'lifetime_free': 0.192, 'free_offer': 0.192,
      'offer_complimentary': 0.192, 'complimentary_lounge': 0.192, 'lounge_access': 0.192, 'on_your': 0.191,
      'extra': 0.19, 'season': 0.188, 'your_next': 0.188, 'stock': 0.183,
      'code': 0.183, 'promo': 0.182, '__acat_status': -0.181, 'weekend': 0.181,
      '40%_off': 0.176, 'limit_time': 0.176, 'fee': 0.175, 'tldr': 0.174,
      'newsletter': 0.174, '80%': 0.173, 'flash_sale': 0.173, 'end': 0.171,
      'youtube': 0.169, 'buy': 0.168, 'save_50%': 0.167, '50%_on': 0.167,
      'on_in': 0.167, 'in_app': 0.167, 'app_purchase': 0.167, 'purchase_this': 0.167,
      'today_daily': 0.167, 'daily_digest': 0.167, 'digest_of': 0.167, 'of_tech': 0.167,
      'tech_new': 0.167, 'new_sponsor': 0.167, 'sponsor_by': 0.167, 'by_linear': 0.167,
      'linear_click': 0.167, 'click_here': 0.167, 'here_to': 0.167, 'at': 0.162,
      '__acat_social': -0.159, '__pkg_finance': -0.159, 'free_trial': 0.158, 'book': 0.156,
      'try_month': 0.156, 'month_of': 0.156, 'of_spotify': 0.156, 'spotify_premium': 0.156,
      'premium_for': 0.156, 'for_₹59': 0.156, '₹59_special': 0.156, 'offer_end': 0.156,
      'end_tomorrow': 0.156, 'tomorrow_unsubscribe': 0.156, 'in': -0.155, 'upgrade': 0.154,
      'icici': 0.154, 'sapphiro': 0.154, 'lifetime': 0.154, 'complimentary': 0.154,
      'lounge': 0.154, 'congrat_you': 0.152, 'you_are': 0.152, 'are_eligible': 0.152,
      'eligible_for': 0.152, 'for_pre': 0.152, 'pre_approv': 0.152, 'approv_loan': 0.152,
      'loan_of': 0.152, 'rs_lakh': 0.152, 'lakh_at': 0.152, 'at_zero': 0.152,
      'zero_proces': 0.152, 'proces_fee': 0.152, 'fee_apply': 0.152, 'apply_now': 0.152,
      'instagram': -0.152, '40%': 0.149, 'big_billion': 0.148, 'billion_day': 0.148,
      'day_extra': 0.148, 'extra_10%': 0.148, '10%_instant': 0.148, 'instant_discount': 0.148,
      '₹100': 0.147, 'is_live': 0.147, 'expire': 0.147, 'purchase': 0.145,
      'voucher': 0.144, 'super_saver': 0.14, 'saver_weekend': 0.14, 'weekend_save': 0.14,
      'save_₹200': 0.14, 'exclusive_play': 0.14, 'play_point': 0.14, 'point_reward': 0.14,
      'reward_deal': 0.14, 'deal_available': 0.14, 'available_in': 0.14, 'your_offer': 0.14,
      'offer_tab': 0.14, 'on_order': 0.139, 'order_above': 0.139, 'flash': 0.139,
      '__sender_dlt': 0.138, 'vm_domino': 0.136, 'cp': 0.135, 'digest': 0.134,
      'sponsor': 0.134, 'linear': 0.134, 'click': 0.134, 'here': 0.134,
      'inr': -0.134, 'bank': -0.134, 'up_to': 0.132, 'battery': -0.132,
      'confirm': -0.131, 'login': -0.13, 'big': 0.128, 'billion': 0.128,
      'day': 0.128, 'instant': 0.128, 'pm': -0.128, 'trial': 0.127,
      '₹59': 0.125, 'hey_your': 0.125, 'your_₹500': 0.125, '₹500_discount': 0.125,
      'discount_voucher': 0.125, 'voucher_expire': 0.125, 'expire_at': 0.125, 'at_midnight': 0.125,
      'midnight_use': 0.125, 'code_eye500': 0.125, 'eye500_to': 0.125, 'to_shop': 0.125,
      'now_reply': 0.125, 'reply_stop': 0.125, 'stop_to': 0.125, 'biggest_price': 0.123,
      'price_drop': 0.123, 'drop_of': 0.123, 'of_the': 0.123, 'the_season': 0.123,
      'season_on': 0.123, 'on_smartphone': 0.123, 'smartphone_laptop': 0.123, 'laptop_don': 0.123,
      'don_miss': 0.123, 'miss_out': 0.123, 'congrat': 0.122, 'eligible': 0.122,
      'pre': 0.122, 'approv': 0.122, 'loan': 0.122, 'lakh': 0.122,
      'vm_icicib': -0.122, 'flat_60%': 0.122, '60%_off': 0.122, 'off_free': 0.122,
      'free_delivery': 0.122, '₹200': 0.122, 'next_uber': 0.121, 'uber_premier': 0.121,
      'premier_trip': 0.121, 'jd_lenskt': 0.12, '__ch_offer': 0.119, 'stock_up': 0.117,
      'on_grocery': 0.117, 'grocery_get': 0.117, 'get_₹100': 0.117, '₹100_cashback': 0.117,
      'cashback_with': 0.117, 'with_paytm': 0.117, 'paytm_upi': 0.117, 'upi_shop': 0.117,
      'steam_autumn': 0.117, 'autumn_sale': 0.117, 'live_game': 0.117, 'game_on': 0.117,
      'your_wishlist': 0.117, 'wishlist_are': 0.117, 'are_on': 0.117, 'on_sale': 0.117,
      'sale_up': 0.117, 'to_80%': 0.117, 'to_your': -0.117, 'access': 0.116,
      'super': 0.116, 'myntra': 0.116, 'above': 0.116, 'of_rs': 0.115,
      'and': -0.115, 'google': -0.114, 'on_medium': 0.113, 'medium_pizza': 0.113,
      'pizza_use': 0.113, 'use_code': 0.113, 'code_bogo': 0.113, 'bogo_at': 0.113,
      'at_domino': 0.113, 'domino_today': 0.113, 'today_apply': 0.113, 'follow_you': -0.112,
      'reward': 0.112, 'tab': 0.112, 'insider_exclusive': 0.111, 'exclusive_deal': 0.111,
      'deal_end': 0.111, 'end_of': 0.111, 'of_season': 0.111, 'season_sale': 0.111,
      'sale_start': 0.111, 'start_now': 0.111, 'now_grab': 0.111, 'grab_70%': 0.111,
      '70%_off': 0.111, 'off_before': 0.111, 'before_stock': 0.111, 'stock_run': 0.111,
      'before': 0.11, 'call': -0.11, 'try_youtube': 0.11, 'youtube_premium': 0.11,
      'premium_free': 0.11, 'for_month': 0.11, 'has': -0.109, 'proces': 0.106,
      '60%': 0.106, 'has_been': -0.105, 'or': -0.105, 'uber': 0.105,
      'premier': 0.105, 'swiggy': -0.104, 'play': 0.104, 'lenskt': 0.104,
      'you': -0.104, 'up_on': 0.103, 'treat_yourself': 0.102, 'yourself_tonight': 0.102,
      'tonight_use': 0.102, 'code_cravings60': 0.102, 'cravings60_on': 0.102, 'on_top': 0.102,
      'top_restaurant': 0.102, 'restaurant_near': 0.102, 'near_you': 0.102, 'we': -0.101,
      'offer_unlock': 0.101, 'unlock_in': 0.101, 'account_book': 0.101, 'now_this': 0.101,
      'invoice': -0.101, 'minute': -0.101, 'flat_50%': 0.1, '50%_off': 0.1,
      'on_eyeglasse': 0.1, 'eyeglasse_free': 0.1, 'free_eye': 0.1, 'eye_test': 0.1,
      'test_at': 0.1, 'at_lenskart': 0.1, 'lenskart_limit': 0.1, 'time_deal': 0.1,
      'deal_visit': 0.1, 'visit_store': 0.1, 'store_today': 0.1, '₹500': 0.1,
      'midnight': 0.1, 'eye500': 0.1, 'stop': 0.1, 'biggest': 0.099,
      'price': 0.099, 'drop': 0.099, 'smartphone': 0.099, 'laptop': 0.099,
      'don': 0.099, 'miss': 0.099, 'min': -0.099, 'security': -0.099,
      'ad_hdfcbk': 0.099, 'free_for': 0.099, 'point': 0.098, 'makemytrip': 0.098,
      'meet': -0.098, 'up': 0.096, 'request': -0.095, 'get_₹150': 0.095,
      '₹150_off': 0.095, 'your_dinner': 0.095, 'dinner_order': 0.095, 'payment': -0.095,
      'out_for': -0.095, 'for_delivery': -0.095, 'holiday_flash': 0.094, 'sale_flat': 0.094,
      'flat_25%': 0.094, '25%_off': 0.094, 'on_goa': 0.094, 'goa_bali': 0.094,
      'bali_hotel': 0.094, 'hotel_zero': 0.094, 'zero_convenience': 0.094, 'convenience_fee': 0.094,
      'fee_book': 0.094, 'password': -0.094, 'cashback': 0.094, 'paytm': 0.094,
      'autumn': 0.094, 'game': 0.094, 'wishlist': 0.094, 'complet': -0.093,
      'reply': 0.093, 'icicib': 0.093, 'alert': -0.093, 'flat_80%': 0.092,
      'off_clearance': 0.092, 'clearance_sale': 0.092, 'watch_ad': 0.091, 'ad_free': 0.091,
      'free_video': 0.091, 'video_offline': 0.091, 'offline_and': 0.091, 'and_get': 0.091,
      'get_youtube': 0.091, 'youtube_music': 0.091, 'music_premium': 0.091, 'premium_start': 0.091,
      'start_free': 0.091, 'limit': 0.091, 'medium': 0.091, 'pizza': 0.091,
      'bogo': 0.091, 'lightn_deal': 0.09, 'deal_up': 0.09, 'to_65%': 0.09,
      '65%_off': 0.09, 'off_electronic': 0.09, 'back': -0.09,
    },
    NotificationCategory.other: {
      '__pkg_other': 1.4, 'screenshot': 0.64, '__sender_brand': -0.587, 'vpn': 0.49,
      'screenshot_sav': 0.417, 'on': -0.389, '__sender_human_person': -0.389, 'tap': 0.374,
      'km': 0.364, '__pkg_chat': -0.354, '__pkg_social': -0.352, 'and': 0.349,
      'view_or': 0.347, 'or_share': 0.347, 'share_your': 0.347, 'your_screenshot': 0.347,
      'sav': 0.345, 'device': 0.34, '__pkg_urgent': -0.327, 'usb': 0.325,
      'to_view': 0.321, 'vpn_is': 0.319, 'is_active': 0.319, 'tap_to': 0.29,
      'active': 0.277, 'step': 0.273, 'morn_run': 0.272, 'run_record': 0.272,
      'screen_time': 0.27, 'network_traffic': 0.266, 'traffic_is': 0.266, 'is_connect': 0.266,
      'connect_through': 0.266, 'through_wireguard': 0.266, 'wireguard_vpn': 0.266, '__acat_sys': 0.257,
      'share': 0.256, 'tomorrow': 0.25, '__pkg_commerce': -0.237, 'record': 0.236,
      'daily': 0.233, '__pkg_dev_update': -0.231, 'or': 0.228, 'km_in': 0.227,
      'in_pace': 0.227, 'pace_km': 0.227, 'screen': 0.226, '__acat_status': 0.221,
      'view': 0.22, '__concept_other': 0.215, 'is': 0.214, 'network': 0.213,
      'traffic': 0.213, 'through': 0.213, 'wireguard': 0.213, 'to': -0.212,
      'charg_this': 0.212, 'this_device': 0.212, 'device_via': 0.212, 'via_usb': 0.212,
      'morn': 0.211, 'your': -0.208, '__sender_dlt': -0.204, 'partly_cloudy': 0.195,
      'cloudy_in': 0.195, 'in_bengaluru': 0.195, 'this': 0.194, 'time': 0.192,
      'device_optimization': 0.192, 'optimization_complete': 0.192, 'charg': 0.184, 'tomorrow_weather': 0.182,
      'weather_outlook': 0.182, 'pace': 0.182, 'via': 0.18, 'daily_step': 0.178,
      'step_goal': 0.178, 'goal_reach': 0.178, 'run': 0.177, 'tap_for': 0.177,
      'for_more': 0.177, 'more_usb': 0.177, 'usb_debug': 0.177, 'debug_and': 0.177,
      'and_file': 0.177, 'file_transfer': 0.177, 'transfer_option': 0.177, 'connect': 0.176,
      'partly': 0.169, 'cloudy': 0.169, 'bengaluru': 0.169, 'optimization': 0.166,
      'the': -0.165, 'at': -0.163, 'today_forecast': 0.162, 'forecast_high': 0.162,
      'high_low': 0.162, 'low_10%': 0.162, '10%_chance': 0.162, 'chance_of': 0.162,
      'of_rain': 0.162, '__acat_msg': -0.161, 'fre_up': 0.16, 'up_mb': 0.16,
      'mb_of': 0.16, 'of_memory': 0.16, 'memory_and': 0.16, 'and_clos': 0.16,
      'clos_background': 0.16, 'background_app': 0.16, 'from': -0.158, 'outlook': 0.158,
      'goal': 0.154, '__pkg_finance': -0.153, 'mostly_sunny': 0.152, 'sunny_tomorrow': 0.152,
      'tomorrow_with': 0.152, 'with_light': 0.152, 'light_breeze': 0.152, 'breeze_and': 0.152,
      'and_aqi': 0.152, 'now': -0.149, 'you_walk': 0.148, 'walk_step': 0.148,
      'step_and': 0.148, 'and_burn': 0.148, 'burn_kcal': 0.148, 'kcal_today': 0.148,
      'weekly_screen': 0.147, 'time_summary': 0.147, 'more': 0.142, 'debug': 0.142,
      'file': 0.142, 'transfer': 0.142, 'option': 0.142, 'weather': 0.142,
      'order': -0.131, 'forecast': 0.13, 'chance': 0.13, 'rain': 0.13,
      'fre': 0.128, 'memory': 0.128, 'clos': 0.128, 'background': 0.128,
      'weekly': 0.128, 'summary': 0.128, '__ch_screenshot': 0.127, 'new': -0.125,
      'reach': 0.124, 'your_daily': 0.123, 'daily_screen': 0.123, 'time_report': 0.123,
      'report_averag': 0.123, 'averag_3h': 0.123, '3h_48m': 0.123, '48m_this': 0.123,
      'start': -0.123, 'of': 0.123, 'mostly': 0.122, 'sunny': 0.122,
      'breeze': 0.122, 'aqi': 0.122, 'walk': 0.119, 'burn': 0.119,
      'kcal': 0.119, 'light': 0.118, 'high': 0.112, 'call': -0.107,
      '__acat_social': -0.105, 'battery': -0.104, 'for': -0.103, 'low': 0.101,
      'delivery': -0.1, 'report': 0.099, 'averag': 0.099, '3h': 0.099,
      '48m': 0.099, 'request': -0.092, '__ch_workout': 0.092, 'account': -0.09,
    },
  };
}
