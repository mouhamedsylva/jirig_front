import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'api_service.dart';

/// Service de gestion des profils utilisateur
/// Conforme au système SNAL-Project
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Clés pour le stockage
  static const String _guestProfileKey = 'guest_profile';
  
  Map<String, dynamic>? _guestProfile;
  
  /// Initialiser le service
  Future<void> initialize() async {
    await _loadGuestProfile();
    
    // Si pas de profil, initialiser un profil invité via l'API
    if (!hasProfile) {
      await _initializeGuestProfileWithAPI();
    }
  }
  
  /// Charger le profil invité
  Future<void> _loadGuestProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_guestProfileKey);
      
      if (profileJson != null) {
        _guestProfile = Map<String, dynamic>.from(jsonDecode(profileJson));
        print('👤 PROFIL SERVICE: Profil invité chargé: $_guestProfile');
      } else {
        // Essayer de récupérer depuis les cookies du LocalStorageService
        await _loadFromLocalStorageCookies();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil invité: $e');
      await _loadFromLocalStorageCookies();
    }
  }
  
  /// Charger depuis les cookies du LocalStorageService
  Future<void> _loadFromLocalStorageCookies() async {
    try {
      // Récupérer les données depuis LocalStorageService (cookies)
      final profile = await LocalStorageService.getProfile();
      
      if (profile != null) {
        _guestProfile = {
          'iProfile': profile['iProfile'] ?? '',
          'iBasket': profile['iBasket'] ?? '',
          'sPaysLangue': profile['sPaysLangue'] ?? '',
          'sPaysFav': profile['sPaysFav'] ?? '',
        };
        await _saveGuestProfile();
        print('👤 PROFIL SERVICE: Profil chargé depuis les cookies LocalStorage');
        print('   sPaysLangue: ${_guestProfile?['sPaysLangue']}');
        print('   sPaysFav: ${_guestProfile?['sPaysFav']}');
      } else {
        // Créer un profil invité par défaut
        await _createDefaultGuestProfile();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement depuis les cookies: $e');
      await _createDefaultGuestProfile();
    }
  }
  
  /// Créer un profil invité par défaut (comme SNAL)
  Future<void> _createDefaultGuestProfile() async {
    // ✅ Utiliser des identifiants par défaut pour éviter l'erreur de conversion
    _guestProfile = {
      'iProfile': '0', // Utiliser '0' au lieu de '' pour éviter l'erreur de conversion
      'iBasket': '0',  // Utiliser '0' au lieu de '' pour éviter l'erreur de conversion
      'sPaysLangue': '',
      'sPaysFav': '',
    };
    
    await _saveGuestProfile();
    print('👤 PROFIL SERVICE: Profil invité par défaut créé (identifiants vides pour SNAL)');
  }
  
  /// Sauvegarder le profil invité
  Future<void> _saveGuestProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_guestProfile != null) {
        await prefs.setString(_guestProfileKey, jsonEncode(_guestProfile));
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du profil invité: $e');
    }
  }
  
  /// Obtenir l'iProfile actuel
  String? get iProfile => _guestProfile?['iProfile']?.toString();
  
  /// Obtenir l'iBasket actuel
  String? get iBasket => _guestProfile?['iBasket']?.toString();
  
  /// Obtenir le pays/langue actuel
  String? get sPaysLangue => _guestProfile?['sPaysLangue']?.toString();
  
  /// Obtenir les pays favoris
  String? get sPaysFav => _guestProfile?['sPaysFav']?.toString();
  
  /// Obtenir le profil complet
  Map<String, dynamic>? get guestProfile => _guestProfile;
  
  /// Mettre à jour le profil invité
  Future<void> updateGuestProfile(Map<String, dynamic> profile) async {
    _guestProfile = {...?_guestProfile, ...profile};
    await _saveGuestProfile();
    print('👤 PROFIL SERVICE: Profil invité mis à jour');
  }
  
  /// Synchroniser avec les cookies LocalStorageService
  Future<void> syncWithCookies() async {
    try {
      final profile = await LocalStorageService.getProfile();
      
      if (profile != null) {
        // Mettre à jour seulement sPaysLangue et sPaysFav depuis les cookies
        if (profile['sPaysLangue'] != null) {
          _guestProfile?['sPaysLangue'] = profile['sPaysLangue'];
        }
        if (profile['sPaysFav'] != null) {
          _guestProfile?['sPaysFav'] = profile['sPaysFav'];
        }
        
        await _saveGuestProfile();
        print('👤 PROFIL SERVICE: Synchronisé avec les cookies');
        print('   sPaysLangue: ${_guestProfile?['sPaysLangue']}');
        print('   sPaysFav: ${_guestProfile?['sPaysFav']}');
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation avec les cookies: $e');
    }
  }
  
  /// Construire l'XML pour les requêtes API
  String buildSearchXML(String search, int limit) {
    return '''
<root>
  <iProfile>${iProfile ?? ""}</iProfile>
  <sPaysLangue>${sPaysLangue ?? ""}</sPaysLangue>
  <sSearch>${search}</sSearch>
  <iBasket>${iBasket ?? ""}</iBasket>
  <iPays></iPays>
  <sLangue></sLangue>
  <top>$limit</top>
</root>''';
  }
  
  /// Vérifier si un profil existe
  bool get hasProfile => _guestProfile != null && iProfile != null;
  
  /// Initialiser un profil invité via l'API SNAL-Project
  Future<void> _initializeGuestProfileWithAPI() async {
    try {
      // ✅ Appeler l'API d'initialisation pour générer les vrais identifiants
      final apiService = ApiService();
      await apiService.initialize();
      
      // Appeler l'API d'initialisation avec des valeurs par défaut
      final response = await apiService.initializeUserProfile(
        sPaysLangue: 'FR/FR', // Valeur par défaut
        sPaysFav: ['FR'], // Valeur par défaut
        bGeneralConditionAgree: true,
      );
      
      print('👤 PROFIL SERVICE: Profil invité initialisé via API SNAL');
      print('📦 Réponse API: $response');
      
      // Recharger le profil depuis le localStorage (maintenant avec les vrais identifiants)
      await _loadFromLocalStorageCookies();
      
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du profil via API: $e');
      // Fallback: créer un profil par défaut
      await _createDefaultGuestProfile();
    }
  }
}
