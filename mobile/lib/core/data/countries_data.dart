import 'package:teyago/core/models/country.dart';

class CountriesData {
  static const List<Country> countries = [
    // Afrique (ordre alphabétique avec Angola en premier)
    Country(name: 'Angola', code: 'AO', dialCode: '+244', flag: '🇦🇴'),
    Country(name: 'Bénin', code: 'BJ', dialCode: '+229', flag: '🇧🇯'),
    Country(name: 'Burkina Faso', code: 'BF', dialCode: '+226', flag: '🇧🇫'),
    Country(name: 'Cameroun', code: 'CM', dialCode: '+237', flag: '🇨🇲'),
    Country(name: 'Cap-Vert', code: 'CV', dialCode: '+238', flag: '🇨🇻'),
    Country(name: 'République Centrafricaine', code: 'CF', dialCode: '+236', flag: '🇨🇫'),
    Country(name: 'Tchad', code: 'TD', dialCode: '+235', flag: '🇹🇩'),
    Country(name: 'République du Congo', code: 'CG', dialCode: '+242', flag: '🇨🇬'),
    Country(name: 'République Démocratique du Congo', code: 'CD', dialCode: '+243', flag: '🇨🇩'),
    Country(name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225', flag: '🇨🇮'),
    Country(name: 'Gabon', code: 'GA', dialCode: '+241', flag: '🇬🇦'),
    Country(name: 'Gambie', code: 'GM', dialCode: '+220', flag: '🇬🇲'),
    Country(name: 'Ghana', code: 'GH', dialCode: '+233', flag: '🇬🇭'),
    Country(name: 'Guinée', code: 'GN', dialCode: '+224', flag: '🇬🇳'),
    Country(name: 'Guinée-Bissau', code: 'GW', dialCode: '+245', flag: '🇬🇼'),
    Country(name: 'Guinée équatoriale', code: 'GQ', dialCode: '+240', flag: '🇬🇶'),
    Country(name: 'Liberia', code: 'LR', dialCode: '+231', flag: '🇱🇷'),
    Country(name: 'Mali', code: 'ML', dialCode: '+223', flag: '🇲🇱'),
    Country(name: 'Mauritanie', code: 'MR', dialCode: '+222', flag: '🇲🇷'),
    Country(name: 'Mozambique', code: 'MZ', dialCode: '+258', flag: '🇲🇿'),
    Country(name: 'Niger', code: 'NE', dialCode: '+227', flag: '🇳🇪'),
    Country(name: 'Nigéria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    Country(name: 'Sao Tomé-et-Principe', code: 'ST', dialCode: '+239', flag: '🇸🇹'),
    Country(name: 'Sénégal', code: 'SN', dialCode: '+221', flag: '🇸🇳'),
    Country(name: 'Sierra Leone', code: 'SL', dialCode: '+232', flag: '🇸🇱'),
    Country(name: 'Togo', code: 'TG', dialCode: '+228', flag: '🇹🇬'),
    
    // Europe
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    Country(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
    Country(name: 'Espagne', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    Country(name: 'Italie', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    Country(name: 'Allemagne', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    Country(name: 'Royaume-Uni', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    Country(name: 'Suisse', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    Country(name: 'Belgique', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    
    // Amériques
    Country(name: 'États-Unis', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    Country(name: 'Brésil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    Country(name: 'Argentine', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    
    // Asie
    Country(name: 'Chine', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    Country(name: 'Inde', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    Country(name: 'Japon', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    
    // Moyen-Orient
    Country(name: 'Maroc', code: 'MA', dialCode: '+212', flag: '🇲🇦'),
    Country(name: 'Tunisie', code: 'TN', dialCode: '+216', flag: '🇹🇳'),
    Country(name: 'Algérie', code: 'DZ', dialCode: '+213', flag: '🇩🇿'),
    Country(name: 'Égypte', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  ];

  /// Obtenir l'Angola par défaut
  static Country get defaultCountry => countries.first; // Angola est en premier

  /// Rechercher un pays par code
  static Country? findByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Rechercher un pays par indicatif
  static Country? findByDialCode(String dialCode) {
    try {
      return countries.firstWhere((country) => country.dialCode == dialCode);
    } catch (e) {
      return null;
    }
  }

  /// Filtrer les pays par recherche
  static List<Country> search(String query) {
    if (query.isEmpty) return countries;
    
    final lowercaseQuery = query.toLowerCase();
    return countries.where((country) =>
        country.name.toLowerCase().contains(lowercaseQuery) ||
        country.dialCode.contains(query) ||
        country.code.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Obtenir les pays populaires (Afrique + Europe + quelques autres)
  static List<Country> get popularCountries {
    final popularCodes = [
      'AO', 'BJ', 'BF', 'CM', 'CI', 'GA', 'GH', 'GN', 'ML', 'NE', 'NG', 'SN', 'TG', // Afrique
      'FR', 'PT', 'ES', 'IT', 'DE', 'GB', 'BE', 'CH', // Europe
      'US', 'CA', 'BR', 'MA', 'TN', 'DZ' // Autres populaires
    ];
    
    return countries.where((country) => 
        popularCodes.contains(country.code)
    ).toList();
  }
}