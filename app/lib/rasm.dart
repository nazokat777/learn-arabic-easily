/// Konkret otlar uchun rasm — o'zbekcha ma'nodan tasvir (emoji) topadi.
///
/// Nega emoji: rasm fayllari yo'q, brauzer va telefon esa rangli
/// emoji shriftini o'zi beradi (Flutter web Noto Color Emoji'ni
/// kerak bo'lganda o'zi yuklaydi). Bu «rasm» birinchi qadam: keyin
/// xohlasa haqiqiy rasmlar shu kalitlar bo'yicha almashtiriladi.
///
/// Faqat KONKRET narsalar: hayvon, tana a'zosi, buyum, joy, tabiat,
/// taom. Fe'l va mavhum so'zga rasm berilmaydi — noto'g'ri rasm
/// rasm yo'qligidan yomon (o'quvchi ma'noni rasmdan «o'qiydi»).
class Rasm {
  Rasm._();

  static const Map<String, String> _lugat = {
    // Hayvonlar
    'mushuk': '🐈', 'it': '🐕', 'ot': '🐴', 'buqa': '🐂', 'sigir': '🐄',
    "qo'y": '🐑', 'echki': '🐐', 'tuya': '🐫', 'eshak': '🫏', 'fil': '🐘',
    'sher': '🦁', 'arslon': '🦁', 'qoplon': '🐆', 'yo\'lbars': '🐅',
    'ayiq': '🐻', "bo'ri": '🐺', 'tulki': '🦊', 'quyon': '🐇', 'ohu': '🦌',
    'kiyik': '🦌', 'maymun': '🐒', 'sichqon': '🐭', 'kalamush': '🐀',
    'tovuq': '🐔', "xo'roz": '🐓', "jo'ja": '🐤', "o'rdak": '🦆', "g'oz": '🪿',
    'kaptar': '🕊️', "to'ti": '🦜', 'qush': '🐦', 'qushcha': '🐦',
    "qarg'a": '🐦‍⬛', 'burgut': '🦅', 'boyo\'g\'li': '🦉', 'tovus': '🦚',
    'baliq': '🐟', 'ilon': '🐍', 'toshbaqa': '🐢', 'qurbaqa': '🐸',
    'chumoli': '🐜', 'asalari': '🐝', 'kapalak': '🦋', 'chivin': '🦟',
    'pashsha': '🪰', 'hasharot': '🐛', 'qurt': '🐛', "o'rgimchak": '🕷️',
    'chayon': '🦂', 'timsoh': '🐊', 'kit': '🐋', 'delfin': '🐬',
    'uya': '🪹', 'tuxum': '🥚', 'qanot': '🪽', 'pat': '🪶',
    // Odamlar
    'ota': '👨', 'ona': '👩', 'bola': '🧒', 'qiz': '👧', "o'g'il": '👦',
    'chol': '👴', 'kampir': '👵', 'erkak': '👨', 'ayol': '👩',
    'chaqaloq': '👶', "o'qituvchi": '🧑‍🏫', "o'quvchi": '🧑‍🎓',
    'shifokor': '🧑‍⚕️',
    'tabib': '🧑‍⚕️',
    'dehqon': '🧑‍🌾',
    'podshoh': '👑',
    'shoh': '👑',
    'askar': '💂',
    'oshpaz': '🧑‍🍳',
    'baliqchi': '🎣', // Tana
    "qo'l": '✋', 'kaft': '✋', 'barmoq': '☝️', "ko'z": '👁️',
    'quloq': '👂', 'burun': '👃', "og'iz": '👄', 'lab': '👄',
    'tish': '🦷', 'oyoq': '🦶', 'yurak': '❤️',
    'yuz': '🙂', "ko'z yoshi": '😢', 'miya': '🧠', 'suyak': '🦴', 'qon': '🩸',
    // Buyumlar
    'kitob': '📖', 'daftar': '📓', 'qalam': '✏️', 'ruchka': '🖊️',
    "chizg'ich": '📏', "qog'oz": '📄', 'hujjat': '📄', 'maktub': '✉️',
    'xat': '✉️', 'sumka': '🎒', 'xalta': '👝', 'savatcha': '🧺', 'savat': '🧺',
    'stol': '🪑',
    'kursi': '🪑',
    'karavot': '🛏️',
    'deraza': '🪟',
    'eshik': '🚪',
    'kalit': '🔑',
    'qulf': '🔒',
    'chiroq': '💡',
    'sham': '🕯️', "ko'zgu": '🪞', 'soat': '⌚', 'telefon': '📱', 'pul': '💰',
    'tiyin': '🪙', 'tanga': '🪙', 'pichoq': '🔪', 'qaychi': '✂️', 'igna': '🪡',
    'ip': '🧵', 'gazlama': '🧵', 'mato': '🧵', 'kiyim': '👕', "ko'ylak": '👕',
    'oyoq kiyimi': '👞', 'etik': '👢', 'shim': '👖', 'shlyapa': '👒',
    'taroq': '🪮', 'misvok': '🪥', 'sovun': '🧼', 'latta': '🧽',
    'choynak': '🫖', 'piyola': '🍵', 'stakan': '🥛', 'qoshiq': '🥄',
    'likopcha': '🍽️', 'qozon': '🍲', 'chelak': '🪣', 'bochka': '🛢️',
    'shisha idish': '🍾', 'idish': '🏺', "ko'za": '🏺', 'bolta': '🪓',
    'arqon': '🪢', 'yoy': '🏹', 'kamon': '🏹', "o'q": '🏹',
    'qilich': '⚔️', 'nayza': '🗡️', 'qalqon': '🛡️', 'bayroq': '🚩',
    'toj': '👑', 'marjan': '📿', 'marjon': '📿', 'uzuk': '💍', "to'p": '⚽',
    "sovg'a": '🎁', 'chodir': '⛺', 'qayiq': '🛶', 'kema': '🚢',
    'mashina': '🚗', 'poyezd': '🚆', 'samolyot': '✈️', 'velosiped': '🚲',
    'arava': '🛒', "g'ildirak": '🛞', 'ilgich': '🪝', 'teshik': '🕳️',
    'olov': '🔥', "o'choq": '🔥', 'muz': '🧊', 'tosh': '🪨', // Joylar
    'uy': '🏠', 'maktab': '🏫', 'masjid': '🕌', "do'kon": '🏪', 'bozor': '🏪',
    'kasalxona': '🏥', 'shahar': '🏙️', 'qishloq': '🏘️', "ko'cha": '🛣️',
    "yo'l": '🛣️', "ko'prik": '🌉', 'devor': '🧱', "bog'": '🌳',
    'chashma': '⛲', 'daryo': '🏞️', 'soy': '🏞️',
    "ko'lmak": '💧', 'dengiz': '🌊', "ko'l": '🏞️', "tog'": '⛰️',
    'tepalik': '⛰️', "cho'l": '🏜️', 'sahro': '🏜️', "o'rmon": '🌲',
    'chakalakzor': '🌲', 'mamlakat': '🗺️', 'afrika': '🌍',
    'yer': '🌍', 'dunyo': '🌍',
    // Tabiat
    'quyosh': '☀️', 'oy': '🌙', 'yulduz': '⭐', 'osmon': '🌌', 'bulut': '☁️',
    "yomg'ir": '🌧️', 'qor': '❄️', 'shamol': '💨', 'momaqaldiroq': '⛈️',
    'suv': '💧', 'daraxt': '🌳', 'gul': '🌸', 'barg': '🍃',
    "o't-o'lan": '🌿', 'pichan': '🌾',
    "bug'doy": '🌾',
    'don': '🌾',
    'urug\'': '🌱',
    'qish': '❄️',
    'bahor': '🌸',
    'kuz': '🍂',
    'tun': '🌙',
    'tong': '🌅', // Taom
    'ovqat': '🍲', 'non': '🍞', 'sut': '🥛', "saryog'": '🧈', 'asal': '🍯',
    "go'sht": '🥩', 'guruch': '🍚', 'tuz': '🧂', 'choy': '🍵', 'olma': '🍎',
    'uzum': '🍇', 'banan': '🍌', 'tarvuz': '🍉', 'qovun': '🍈',
    'zaytun': '🫒', 'sabzi': '🥕', 'piyoz': '🧅',
    'kartoshka': '🥔', 'pomidor': '🍅', 'meva': '🍎', 'sabzavot': '🥕',
    // Kengaytma (2-bosqich)
    "qo'zichoq": '🐑',
    "ko'chqor": '🐏',
    'olmaxon': '🐿️',
    'tipratikon': '🦔',
    'kurka': '🦃',
    'kuchukcha': '🐶',
    "bug'u": '🦌',
    'chigirtka': '🦗',
    'kabutar': '🕊️',
    'oqqush': '🦢',
    'qisqichbaqa': '🦀',
    'tyulen': '🦭',
    'orangutan': '🦧',
    'gorilla': '🦍',
    "ayg'ir": '🐎',
    "chig'anoq": '🐚',
    'inson': '🧑',
    'kuyov': '🤵',
    'kelin': '👰',
    "do'xtir": '🧑‍⚕️',
    'sartarosh': '💈',
    'duradgor': '🪚',
    "bog'bon": '🧑‍🌾',
    "go'dak": '👶',
    'buvi': '👵',
    'buva': '👴',
    'aka-uka': '👬',
    'opa-singil': '👭',
    'soqol': '🧔',
    'tizza': '🦵',
    'libos': '👗',
    'ishton': '👖',
    'kurtka': '🧥',
    'shapka': '🧢',
    'salla': '👳',
    "bo'yinbog'": '👔',
    'jun': '🧶',
    "qo'lqop": '🧤',
    'botinka': '🥾',
    'poyabzal': '👞',
    "tog'ora": '🥣',
    "ko'ng'iroq": '🔔',
    'tarozu': '⚖️',
    'dori': '💊',
    'olmos': '💎',
    'nina': '🪡',
    "o'yinchoq": '🧸',
    'shamsiya': '☂️',
    'narvon': '🪜',
    'sandiq': '📦',
    'supurgi': '🧹',
    'arra': '🪚',
    "bolg'acha": '🔨',
    'tovoq': '🍽️',
    'stul': '🪑',
    'varaq': '📄',
    'taqvim': '📅',
    'xarita': '🗺️',
    'ustara': '🪒',
    'tuzdon': '🧂',
    'sanchqi': '🍴',
    "yog'och": '🪵',
    'tomchi': '💧',
    'bekat': '🚏',
    'kutubxona': '📚',
    'shifoxona': '🏥',
    'hovli': '🏡',
    'sohil': '🏖️',
    "qal'a": '🏰',
    'saroy': '🏰',
    'oshxona': '🍳',
    "o'simlik": '🌱',
    'arpa': '🌾',
    'tuman': '🌫️',
    'quyin': '🌪️',
    'yashin': '⚡',
    "yong'in": '🔥',
    'qizil': '🔴',
    'sariq': '🟡',
    'yashil': '🟢',
    "ko'k": '🔵',
    'qora': '⚫',
    'oq': '⚪',
    'mandarin': '🍊',
    'apelsin': '🍊',
    'limon': '🍋',
    'bodring': '🥒',
    'karam': '🥬',
    'baqlajon': '🍆',
    'qalampir': '🌶️',
    'salat': '🥗',
    'kofe': '☕',
    "sho'rva": '🍲',
  };

  /// Ma'no matnidan rasm topadi: birinchi bo'lak (vergul, qavs yoki
  /// «/» gacha) lug'atda aynan bo'lsa. Aynan mos kelmasa `null` —
  /// «shunga o'xshash» rasm berilmaydi.
  static String? topish(String uz) {
    final k = _kalit(uz);
    if (k.isEmpty) return null;
    return _lugat[k];
  }

  static String _kalit(String uz) {
    var s = uz
        .toLowerCase()
        .replaceAll('ʼ', "'")
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('`', "'");
    s = s.split(RegExp('[,;(/]')).first.trim();
    // «bir …», «bitta …» kabi sanoq so'zlar olib tashlanadi.
    s = s.replaceFirst(RegExp(r'^(bir|bitta)\s+'), '');
    return s;
  }
}
