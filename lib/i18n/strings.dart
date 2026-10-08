enum AppLang { en, ta, hi }

extension AppLangName on AppLang {
  String get label => switch (this) { AppLang.en => 'English', AppLang.ta => 'தமிழ்', AppLang.hi => 'हिन्दी' };
}

/// Key labels in English, Tamil and Hindi. Long explanatory text stays in English.
const Map<String, List<String>> _strings = {
  //            English                                   Tamil                                                   Hindi
  'tagline': ['Career guidance that brings the whole family to the table', 'முழு குடும்பத்தையும் உள்ளடக்கிய தொழில் வழிகாட்டல்', 'पूरे परिवार को साथ लेकर करियर मार्गदर्शन'],
  'startStudent': ['Start as student', 'மாணவராகத் தொடங்கு', 'छात्र के रूप में शुरू करें'],
  'joinParent': ['Join as parent', 'பெற்றோராக இணையுங்கள்', 'अभिभावक के रूप में जुड़ें'],
  'tryDemo': ['Try a demo family', 'மாதிரி குடும்பத்தை முயற்சிக்கவும்', 'डेमो परिवार आज़माएँ'],
  'topMatch': ['Top match', 'சிறந்த பொருத்தம்', 'सबसे अच्छा मेल'],
  'prismScore': ['PRISM score', 'PRISM மதிப்பெண்', 'PRISM स्कोर'],
  'rankings': ['Your top careers', 'உங்கள் சிறந்த தொழில்கள்', 'आपके शीर्ष करियर'],
  'whatIf': ['Try different weights', 'எடைகளை மாற்றிப் பாருங்கள்', 'वेटेज बदलकर देखें'],
  'conflict': ['Family alignment', 'குடும்ப ஒத்திசைவு', 'पारिवारिक सहमति'],
  'bridge': ['Bridge careers', 'இணைப்புத் தொழில்கள்', 'बीच के करियर'],
  'afford': ['Can we afford it?', 'நம்மால் செலவை ஏற்க முடியுமா?', 'क्या हम खर्च उठा सकते हैं?'],
  'demand': ['Where the jobs are', 'வேலைகள் எங்கே உள்ளன', 'नौकरियाँ कहाँ हैं'],
  'swot': ['Your SWOT', 'உங்கள் SWOT', 'आपका SWOT'],
  'roadmap': ['Your roadmap', 'உங்கள் வழித்திட்டம்', 'आपका रोडमैप'],
  'hyperLocal': ['Innovate where you live', 'நீங்கள் வாழும் இடத்தில் புதுமை செய்யுங்கள்', 'जहाँ रहते हैं, वहीं नवाचार करें'],
  'parentView': ['Parent summary', 'பெற்றோருக்கான சுருக்கம்', 'अभिभावक सारांश'],
  'counselor': ['Ask the counselor', 'ஆலோசகரிடம் கேளுங்கள்', 'काउंसलर से पूछें'],
  'pdf': ['Download report', 'அறிக்கையைப் பதிவிறக்கு', 'रिपोर्ट डाउनलोड करें'],
  'how': ['How was this calculated?', 'இது எப்படிக் கணக்கிடப்பட்டது?', 'यह कैसे गणना हुई?'],
  'methodology': ['How it works', 'இது எப்படி வேலை செய்கிறது', 'यह कैसे काम करता है'],
  'sources': ['Data sources', 'தரவு மூலங்கள்', 'डेटा स्रोत'],
  'school': ['School dashboard', 'பள்ளி டாஷ்போர்டு', 'स्कूल डैशबोर्ड'],
  'strengths': ['Strengths', 'பலங்கள்', 'ताकत'],
  'weaknesses': ['Weaknesses', 'பலவீனங்கள்', 'कमज़ोरियाँ'],
  'opportunities': ['Opportunities', 'வாய்ப்புகள்', 'अवसर'],
  'threats': ['Threats', 'அச்சுறுத்தல்கள்', 'खतरे'],
  'next': ['Next', 'அடுத்து', 'आगे'],
  'back': ['Back', 'பின்செல்', 'पीछे'],
  'seeResults': ['See results', 'முடிவுகளைப் பார்', 'परिणाम देखें'],
  'familyCode': ['Family code', 'குடும்பக் குறியீடு', 'परिवार कोड'],
  'liveFeed': ['Live job market (simulated)', 'நேரடி வேலைச் சந்தை (மாதிரி)', 'लाइव जॉब मार्केट (सिम्युलेटेड)'],
  'fit': ['Fit', 'பொருத்தம்', 'मेल'],
  'market': ['Market', 'சந்தை', 'बाज़ार'],
  'feasibility': ['Affordability', 'செலவுத் தகுதி', 'खर्च क्षमता'],
  'roi': ['Return', 'வருவாய்', 'रिटर्न'],
  'penalty': ['Family gap', 'குடும்ப இடைவெளி', 'पारिवारिक अंतर'],
  'skills': ['Your profile vs. this career', 'உங்கள் திறன் vs இந்தத் தொழில்', 'आपकी प्रोफ़ाइल बनाम यह करियर'],
};

String tr(AppLang lang, String key) {
  final row = _strings[key];
  if (row == null) return key;
  return row[lang.index];
}
