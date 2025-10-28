import '../models/country.dart';
import 'api_service.dart';

/// Service pour gérer les données des pays
/// Utilise l'API réelle SNAL-Project
class CountryService {
  static final CountryService _instance = CountryService._internal();
  factory CountryService() => _instance;
  CountryService._internal();

  // Utiliser le singleton ApiService (déjà initialisé dans app.dart)
  ApiService get _apiService => ApiService();

  /// Liste des pays en cache local
  List<Country> _cachedCountries = [];
  List<Map<String, dynamic>> _cachedFlags = [];
  bool _isInitialized = false;

  /// Initialiser le service avec les données de l'API
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 COUNTRY SERVICE: Début de l\'initialisation...');
      
      // L'API service est déjà initialisé dans app.dart
      // Pas besoin de réappeler initialize()
      
      // Récupérer les informations complètes depuis l'API SNAL-Project
      // Cet endpoint retourne: { LANGUE: [], PAYS: [], PaysLangue: [] }
      print('📞 COUNTRY SERVICE: Appel de getInfosStatus()...');
      final infosStatus = await _apiService.getInfosStatus();
      
      if (infosStatus['success'] != false && infosStatus['PaysLangue'] != null) {
        print('✅ COUNTRY SERVICE: Données reçues avec succès');
        print('📊 COUNTRY SERVICE: ${infosStatus['PaysLangue']?.length ?? 0} pays trouvés dans PaysLangue');
        // Convertir les données PaysLangue en objets Country
        _cachedCountries = _convertPaysLangueToCountries(infosStatus['PaysLangue']);
        
        // Charger les drapeaux depuis /api/flags
        try {
          print('🚩 COUNTRY SERVICE: Chargement des drapeaux depuis /api/flags...');
          _cachedFlags = await _apiService.getCountryFlags();
          print('✅ COUNTRY SERVICE: ${_cachedFlags.length} drapeaux chargés depuis /api/flags');
          // Fusionner les drapeaux avec les pays
          _mergeCountriesWithFlags();
          print('✅ COUNTRY SERVICE: Fusion des drapeaux terminée');
        } catch (e) {
          print('⚠️ COUNTRY SERVICE: Erreur lors du chargement des drapeaux: $e');
          print('⚠️ COUNTRY SERVICE: Utilisation des chemins par défaut');
        }
        
        _isInitialized = true;
        print('✅ COUNTRY SERVICE: Initialisé avec ${_cachedCountries.length} pays depuis /api/get-infos-status');
      } else {
        // FALLBACK COMMENTÉ - Test avec endpoint principal uniquement
        print('❌ COUNTRY SERVICE: Aucune donnée PaysLangue trouvée');
        // print('Fallback vers /api/get-all-country et /api/flags');
        // _cachedCountries = await _apiService.getAllCountries();
        // _cachedFlags = await _apiService.getCountryFlags();
        // _mergeCountriesWithFlags();
        _isInitialized = true;
        print('⚠️ COUNTRY SERVICE: Aucun pays chargé - fallback désactivé');
      }
    } catch (e) {
      print('❌ COUNTRY SERVICE: Erreur lors de l\'initialisation: $e');
      // FALLBACK DÉSACTIVÉ - Test avec endpoint principal uniquement
      // _loadFallbackData();
      _isInitialized = true;
      print('⚠️ COUNTRY SERVICE: Aucun pays chargé - fallback désactivé');
    }
  }

  /// Convertir les données PaysLangue en objets Country
  List<Country> _convertPaysLangueToCountries(List<dynamic> paysLangueData) {
    return paysLangueData.map((data) {
      return Country(
        sPays: data['sPaysLangue']?.split('/')[0] ?? '',
        sDescr: data['sDescr'] ?? '',
        sExternalRef: data['sPaysLangue']?.split('/')[0] ?? '',
        iPays: _extractCountryIdFromData(data),
        sPaysLangue: data['sPaysLangue'] ?? '',
        // Ne pas utiliser sColor - on utilisera /api/flags à la place
        image: null,
        name: data['sDescr'] ?? '',
        code: data['sPaysLangue']?.split('/')[0] ?? '',
      );
    }).toList();
  }

  /// Extraire l'ID du pays depuis les données
  int _extractCountryIdFromData(Map<String, dynamic> data) {
    // Si l'ID est directement disponible
    if (data['iPays'] != null) return data['iPays'];
    if (data['id'] != null) return data['id'];
    
    // Sinon, essayer d'extraire depuis sPaysLangue
    final sPaysLangue = data['sPaysLangue']?.toString() ?? '';
    if (sPaysLangue.contains('/')) {
      final countryCode = sPaysLangue.split('/')[0];
      // Mapping basique des codes pays vers IDs
      switch (countryCode.toUpperCase()) {
        case 'FR': return 13;
        case 'BE': return 10;
        case 'DE': return 12;
        case 'NL': return 11;
        case 'ES': return 15;
        case 'IT': return 16;
        case 'PT': return 17;
        case 'LU': return 14;
        case 'EN': return 18;
        default: return 0;
      }
    }
    return 0;
  }

  /// Fusionner les données des pays avec les informations des drapeaux depuis /api/flags
  void _mergeCountriesWithFlags() {
    print('🔄 COUNTRY SERVICE: Début de la fusion des drapeaux...');
    
    for (int i = 0; i < _cachedCountries.length; i++) {
      final country = _cachedCountries[i];
      
      // Chercher le drapeau correspondant par code pays
      final flagInfo = _cachedFlags.firstWhere(
        (flag) {
          final flagCode = flag['code']?.toString().toUpperCase() ?? '';
          final countryCode = country.sPays.toUpperCase();
          return flagCode == countryCode;
        },
        orElse: () => <String, dynamic>{},
      );
      
      if (flagInfo.isNotEmpty) {
        print('✅ COUNTRY SERVICE: Drapeau trouvé pour ${country.sPays}: ${flagInfo['image']}');
        _cachedCountries[i] = Country(
          sPays: country.sPays,
          sDescr: country.sDescr,
          sExternalRef: country.sExternalRef,
          iPays: country.iPays,
          sPaysLangue: country.sPaysLangue,
          // Utiliser l'image depuis /api/flags
          image: flagInfo['image'] ?? flagInfo['flag'] ?? country.image,
          name: country.name,
          code: country.code,
        );
      } else {
        print('⚠️ COUNTRY SERVICE: Aucun drapeau trouvé pour ${country.sPays}, utilisation du chemin par défaut');
        // Utiliser un chemin par défaut si aucun drapeau n'est trouvé
        _cachedCountries[i] = Country(
          sPays: country.sPays,
          sDescr: country.sDescr,
          sExternalRef: country.sExternalRef,
          iPays: country.iPays,
          sPaysLangue: country.sPaysLangue,
          image: '/img/flags/${country.sPays.toUpperCase()}.PNG',
          name: country.name,
          code: country.code,
        );
      }
    }
    
    print('✅ COUNTRY SERVICE: Fusion des drapeaux terminée pour ${_cachedCountries.length} pays');
  }

  /// Charger des données de fallback en cas d'erreur API
  void _loadFallbackData() {
    _cachedCountries = [
      Country(
        sPays: 'FR',
        sDescr: 'France',
        sExternalRef: 'FR',
        iPays: 13,
        sPaysLangue: 'fr/fr',
        image: '/img/flags/FR.PNG',
        name: 'France',
        code: 'FR',
      ),
      Country(
        sPays: 'BE',
        sDescr: 'Belgique',
        sExternalRef: 'BE',
        iPays: 10,
        sPaysLangue: 'be/fr',
        image: '/img/flags/BE.PNG',
        name: 'Belgique',
        code: 'BE',
      ),
      Country(
        sPays: 'DE',
        sDescr: 'Allemagne',
        sExternalRef: 'DE',
        iPays: 12,
        sPaysLangue: 'de/en',
        image: '/img/flags/DE.PNG',
        name: 'Allemagne',
        code: 'DE',
      ),
      Country(
        sPays: 'NL',
        sDescr: 'Pays-Bas',
        sExternalRef: 'NL',
        iPays: 11,
        sPaysLangue: 'nl/fr',
        image: '/img/flags/NL.PNG',
        name: 'Pays-Bas',
        code: 'NL',
      ),
      Country(
        sPays: 'ES',
        sDescr: 'Espagne',
        sExternalRef: 'ES',
        iPays: 15,
        sPaysLangue: 'es/fr',
        image: '/img/flags/ES.PNG',
        name: 'Espagne',
        code: 'ES',
      ),
      Country(
        sPays: 'IT',
        sDescr: 'Italie',
        sExternalRef: 'IT',
        iPays: 16,
        sPaysLangue: 'it/it',
        image: '/img/flags/IT.PNG',
        name: 'Italie',
        code: 'IT',
      ),
      Country(
        sPays: 'PT',
        sDescr: 'Portugal',
        sExternalRef: 'PT',
        iPays: 17,
        sPaysLangue: 'pt/pt',
        image: '/img/flags/PT.PNG',
        name: 'Portugal',
        code: 'PT',
      ),
      Country(
        sPays: 'LU',
        sDescr: 'Luxembourg',
        sExternalRef: 'LU',
        iPays: 14,
        sPaysLangue: 'lu/nl',
        image: '/img/flags/LU.PNG',
        name: 'Luxembourg',
        code: 'LU',
      ),
      Country(
        sPays: 'EN',
        sDescr: 'Royaume-Uni',
        sExternalRef: 'EN',
        iPays: 18,
        sPaysLangue: 'en/en',
        image: '/img/flags/england.png',
        name: 'Royaume-Uni',
        code: 'EN',
      ),
    ];
    _isInitialized = true;
  }

  /// Récupérer tous les pays
  List<Country> getAllCountries() {
    return List.from(_cachedCountries);
  }

  /// Rechercher des pays par nom
  List<Country> searchCountries(String query) {
    if (query.isEmpty) return getAllCountries();
    
    final lowercaseQuery = query.toLowerCase();
    return getAllCountries().where((country) =>
      country.sDescr.toLowerCase().contains(lowercaseQuery) ||
      (country.name?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  /// Trouver un pays par son code
  Country? getCountryByCode(String countryCode) {
    try {
      return getAllCountries().firstWhere(
        (country) => country.sPays == countryCode || country.code == countryCode
      );
    } catch (e) {
      return null;
    }
  }

  /// Trouver un pays par son ID
  Country? getCountryById(int countryId) {
    try {
      return getAllCountries().firstWhere(
        (country) => country.iPays == countryId
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les pays par langue
  List<Country> getCountriesByLanguage(String languageCode) {
    return getAllCountries().where((country) =>
      country.languageCode == languageCode.toLowerCase()
    ).toList();
  }

  /// Récupérer les pays depuis l'API (mise à jour)
  Future<List<Country>> fetchCountriesFromAPI() async {
    await initialize();
    return getAllCountries();
  }

  /// Récupérer les informations détaillées d'un pays
  Future<Map<String, dynamic>> getCountryInfo(int iPaysSelected) async {
    return await _apiService.getCountryInfo(iPaysSelected);
  }

  /// Tester la connexion à l'API
  Future<bool> testConnection() async {
    return await _apiService.testConnection();
  }
}
