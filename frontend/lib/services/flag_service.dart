class FlagService {
  FlagService._();

  /// Returns a flag emoji string for [country] (case-insensitive, accepts
  /// common aliases and ISO 3166-1 alpha-2 codes).
  /// Returns null if the country is unrecognised.
  static String? getFlag(String country) {
    final code = _resolveCode(country);
    if (code == null) return null;
    return _emojiFlag(code);
  }

  // ---------------------------------------------------------------------------

  /// Converts an ISO 3166-1 alpha-2 code to a Unicode flag emoji.
  /// Each letter maps to a Regional Indicator Symbol (🇦 = U+1F1E6).
  static String _emojiFlag(String isoCode) => isoCode
      .toUpperCase()
      .split('')
      .map((c) => String.fromCharCode(0x1F1E6 + c.codeUnitAt(0) - 65))
      .join();

  static String? _resolveCode(String country) =>
      _nameToCode[country.trim().toLowerCase()];

  static const _nameToCode = <String, String>{
    // United States
    'united states': 'US', 'usa': 'US', 'us': 'US', 'america': 'US',
    'united states of america': 'US',
    // United Kingdom
    'united kingdom': 'GB', 'uk': 'GB', 'gb': 'GB', 'britain': 'GB',
    'great britain': 'GB', 'england': 'GB',
    // Canada
    'canada': 'CA', 'ca': 'CA',
    // Germany
    'germany': 'DE', 'de': 'DE', 'deutschland': 'DE',
    // France
    'france': 'FR', 'fr': 'FR',
    // Japan
    'japan': 'JP', 'jp': 'JP',
    // China
    'china': 'CN', 'cn': 'CN', "people's republic of china": 'CN',
    // South Korea
    'south korea': 'KR', 'korea': 'KR', 'kr': 'KR',
    // India
    'india': 'IN', 'in': 'IN',
    // Australia
    'australia': 'AU', 'au': 'AU',
    // Brazil
    'brazil': 'BR', 'br': 'BR', 'brasil': 'BR',
    // Mexico
    'mexico': 'MX', 'mx': 'MX',
    // Switzerland
    'switzerland': 'CH', 'ch': 'CH',
    // Netherlands
    'netherlands': 'NL', 'nl': 'NL', 'holland': 'NL',
    // Sweden
    'sweden': 'SE', 'se': 'SE',
    // Norway
    'norway': 'NO', 'no': 'NO',
    // Denmark
    'denmark': 'DK', 'dk': 'DK',
    // Finland
    'finland': 'FI', 'fi': 'FI',
    // Italy
    'italy': 'IT', 'it': 'IT',
    // Spain
    'spain': 'ES', 'es': 'ES',
    // Portugal
    'portugal': 'PT', 'pt': 'PT',
    // Russia
    'russia': 'RU', 'ru': 'RU', 'russian federation': 'RU',
    // Singapore
    'singapore': 'SG', 'sg': 'SG',
    // Hong Kong
    'hong kong': 'HK', 'hk': 'HK',
    // Taiwan
    'taiwan': 'TW', 'tw': 'TW',
    // Israel
    'israel': 'IL', 'il': 'IL',
    // Saudi Arabia
    'saudi arabia': 'SA', 'sa': 'SA',
    // UAE
    'united arab emirates': 'AE', 'uae': 'AE', 'ae': 'AE',
    // South Africa
    'south africa': 'ZA', 'za': 'ZA',
    // New Zealand
    'new zealand': 'NZ', 'nz': 'NZ',
    // Ireland
    'ireland': 'IE', 'ie': 'IE',
    // Belgium
    'belgium': 'BE', 'be': 'BE',
    // Austria
    'austria': 'AT', 'at': 'AT',
    // Poland
    'poland': 'PL', 'pl': 'PL',
    // Czech Republic
    'czech republic': 'CZ', 'czechia': 'CZ', 'cz': 'CZ',
    // Hungary
    'hungary': 'HU', 'hu': 'HU',
    // Greece
    'greece': 'GR', 'gr': 'GR',
    // Turkey
    'turkey': 'TR', 'tr': 'TR', 'türkiye': 'TR',
    // Argentina
    'argentina': 'AR', 'ar': 'AR',
    // Chile
    'chile': 'CL', 'cl': 'CL',
    // Colombia
    'colombia': 'CO', 'co': 'CO',
    // Indonesia
    'indonesia': 'ID', 'id': 'ID',
    // Malaysia
    'malaysia': 'MY', 'my': 'MY',
    // Thailand
    'thailand': 'TH', 'th': 'TH',
    // Philippines
    'philippines': 'PH', 'ph': 'PH',
    // Vietnam
    'vietnam': 'VN', 'vn': 'VN', 'viet nam': 'VN',
    // Pakistan
    'pakistan': 'PK', 'pk': 'PK',
    // Bangladesh
    'bangladesh': 'BD', 'bd': 'BD',
    // Egypt
    'egypt': 'EG', 'eg': 'EG',
    // Nigeria
    'nigeria': 'NG', 'ng': 'NG',
    // Kenya
    'kenya': 'KE', 'ke': 'KE',
    // Romania
    'romania': 'RO', 'ro': 'RO',
    // Ukraine
    'ukraine': 'UA', 'ua': 'UA',
  };
}
