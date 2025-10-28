import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service pour gérer le stockage local des informations de profil
/// Remplace les cookies par localStorage pour une approche mobile-first
class LocalStorageService {
  static const String _profileKey = 'user_profile';
  static const String _basketKey = 'user_basket';
  static const String _paysLangueKey = 'user_pays_langue';
  static const String _paysFavKey = 'user_pays_fav';
  static const String _currentRouteKey = 'current_route';
  static const String _selectedCountriesKey = 'selected_countries';
  
  /// Sauvegarder le profil utilisateur
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Sauvegarder les champs obligatoires
    if (profile['iProfile'] != null) {
      await prefs.setString(_profileKey, profile['iProfile']);
    }
    if (profile['iBasket'] != null) {
      await prefs.setString(_basketKey, profile['iBasket']);
    }
    if (profile['sPaysLangue'] != null) {
      await prefs.setString(_paysLangueKey, profile['sPaysLangue']);
    }
    if (profile['sPaysFav'] != null) {
      await prefs.setString(_paysFavKey, profile['sPaysFav']);
    }
    
    // Sauvegarder les champs optionnels (pour la session utilisateur)
    if (profile['sEmail'] != null) {
      await prefs.setString('user_email', profile['sEmail']);
    }
    if (profile['sNom'] != null) {
      await prefs.setString('user_nom', profile['sNom']);
    }
    if (profile['sPrenom'] != null) {
      await prefs.setString('user_prenom', profile['sPrenom']);
    }
    if (profile['sPhoto'] != null) {
      await prefs.setString('user_photo', profile['sPhoto']);
    }
  }
  
  /// Récupérer le profil utilisateur
  static Future<Map<String, String>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final iProfile = prefs.getString(_profileKey);
    final iBasket = prefs.getString(_basketKey);
    final sPaysLangue = prefs.getString(_paysLangueKey);
    final sPaysFav = prefs.getString(_paysFavKey);
    
    if (iProfile != null && iBasket != null && sPaysLangue != null) {
      return {
        'iProfile': iProfile,
        'iBasket': iBasket,
        'sPaysLangue': sPaysLangue,
        'sPaysFav': sPaysFav ?? '', // ✅ Retourner sPaysFav
      };
    }
    
    return null;
  }
  
  /// Créer un profil invité par défaut (comme SNAL)
  static Future<Map<String, String>> createGuestProfile() async {
    try {
      // ✅ Initialiser via l'API SNAL pour générer les vrais identifiants
      final apiService = ApiService();
      await apiService.initialize();
      
      final response = await apiService.initializeUserProfile(
        sPaysLangue: 'FR/FR', // Valeur par défautI
        sPaysFav: ['FR'], // Valeur par défaut
        bGeneralConditionAgree: true,
      );
      
      if (response != null && response is Map<String, dynamic>) {
        final iProfile = response['iProfile']?.toString() ?? '0';
        final iBasket = response['iBasket']?.toString() ?? '0';
        final sPaysLangue = response['sPaysLangue']?.toString() ?? 'FR/FR';
        final sPaysFav = response['sPaysFav']?.toString() ?? 'FR';
        
        final guestProfile = {
          'iProfile': iProfile,
          'iBasket': iBasket,
          'sPaysLangue': sPaysLangue,
          'sPaysFav': sPaysFav,
        };
        
        await saveProfile(guestProfile);
        print('✅ Profil invité initialisé via API SNAL: iProfile=$iProfile, iBasket=$iBasket');
        
        return guestProfile;
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation via API, fallback vers profil par défaut: $e');
    }
    
    // Fallback: créer un profil par défaut avec des identifiants vides
    final guestProfile = {
      'iProfile': '', // Utiliser des identifiants vides pour que SNAL les crée
      'iBasket': '',  // Utiliser des identifiants vides pour que SNAL les crée
      'sPaysLangue': 'FR/FR', // Valeur par défaut
      'sPaysFav': 'FR',       // Valeur par défaut
    };
    
    await saveProfile(guestProfile);
    
    return guestProfile;
  }
  
  /// Vérifier si un profil existe
  static Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }
  
  /// Supprimer le profil (logout)
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_basketKey);
    await prefs.remove(_paysLangueKey);
    await prefs.remove(_paysFavKey);
    await prefs.remove('user_email');
    await prefs.remove('user_nom');
    await prefs.remove('user_prenom');
    await prefs.remove('user_photo');
  }

  /// Vérifier si l'utilisateur est connecté (a un email sauvegardé)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    print('🔍 isLoggedIn() - Email: $email');
    return email != null && email.isNotEmpty;
  }

  /// Récupérer les informations complètes de l'utilisateur
  static Future<Map<String, String>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    final email = prefs.getString('user_email');
    final nom = prefs.getString('user_nom');
    final prenom = prefs.getString('user_prenom');
    final photo = prefs.getString('user_photo');
    
    print('🔍 getUserInfo() - Email: $email');
    print('🔍 getUserInfo() - Nom: $nom');
    print('🔍 getUserInfo() - Prénom: $prenom');
    print('🔍 getUserInfo() - Photo: $photo');
    
    if (email == null) {
      print('❌ getUserInfo() - Aucun email trouvé, utilisateur non connecté');
      return null;
    }
    
    final userInfo = {
      'email': email,
      'nom': nom ?? '',
      'prenom': prenom ?? '',
      'photo': photo ?? '',
    };
    
    print('✅ getUserInfo() - Informations utilisateur: $userInfo');
    return userInfo;
  }
  
  /// Initialiser le profil (créer un invité si nécessaire)
  static Future<Map<String, String>> initializeProfile() async {
    final existingProfile = await getProfile();
    
    if (existingProfile != null) {
      return existingProfile;
    }
    
    return await createGuestProfile();
  }

  /// ✅ Sauvegarder la route actuelle
  static Future<void> saveCurrentRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentRouteKey, route);
    print('💾 Route sauvegardée: $route');
  }

  /// ✅ Récupérer la route actuelle
  static Future<String?> getCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_currentRouteKey);
    print('📖 Route récupérée: $route');
    return route;
  }

  /// ✅ Effacer la route actuelle
  static Future<void> clearCurrentRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentRouteKey);
    print('🗑️ Route effacée');
  }

  /// ✅ Gérer le callBackUrl comme SNAL
  static Future<void> saveCallBackUrl(String callBackUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('callback_url', callBackUrl);
    print('💾 CallBackUrl sauvegardé: $callBackUrl');
  }

  /// ✅ Récupérer le callBackUrl comme SNAL
  static Future<String?> getCallBackUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final callBackUrl = prefs.getString('callback_url');
    print('📖 CallBackUrl récupéré: $callBackUrl');
    return callBackUrl;
  }

  /// ✅ Effacer le callBackUrl
  static Future<void> clearCallBackUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('callback_url');
    print('🗑️ CallBackUrl effacé');
  }

  /// ✅ Sauvegarder les pays sélectionnés dans le modal de gestion
  static Future<void> saveSelectedCountries(List<String> countries) async {
    final prefs = await SharedPreferences.getInstance();
    final countriesString = countries.join(',');
    await prefs.setString(_selectedCountriesKey, countriesString);
    print('💾 Pays sélectionnés sauvegardés: $countriesString');
  }

  /// ✅ Récupérer les pays sélectionnés depuis le modal de gestion
  static Future<List<String>> getSelectedCountries() async {
    final prefs = await SharedPreferences.getInstance();
    final countriesString = prefs.getString(_selectedCountriesKey);
    if (countriesString != null && countriesString.isNotEmpty) {
      final countries = countriesString.split(',').where((c) => c.isNotEmpty).toList();
      print('📖 Pays sélectionnés récupérés: $countries');
      return countries;
    }
    print('📖 Aucun pays sélectionné trouvé');
    return [];
  }

  /// ✅ Effacer les pays sélectionnés
  static Future<void> clearSelectedCountries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedCountriesKey);
    print('🗑️ Pays sélectionnés effacés');
  }
}
