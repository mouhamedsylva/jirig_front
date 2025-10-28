import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../models/country.dart';
import 'api_service.dart';
import 'search_service.dart';
import 'local_storage_service.dart';

/// Service pour gérer les paramètres utilisateur
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() {
    // ✅ Initialiser automatiquement au premier appel
    if (!_instance._isInitialized) {
      _instance._initializeSelectedCountry();
    }
    return _instance;
  }
  SettingsService._internal();

  // Utiliser le singleton ApiService (déjà initialisé dans app.dart)
  ApiService get _apiService => ApiService();

  static const String _settingsKey = 'user_settings';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  
  bool _isInitialized = false;
  
  /// Initialiser le pays sélectionné au premier appel
  Future<void> _initializeSelectedCountry() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      _selectedCountry = await getSelectedCountry();
      if (_selectedCountry != null) {
        print('✅ SettingsService initialisé avec ${_selectedCountry!.sDescr} (${_selectedCountry!.sPays})');
      } else {
        print('⚠️ SettingsService: aucun pays sélectionné trouvé');
      }
    } catch (e) {
      print('❌ Erreur initialisation SettingsService: $e');
    }
  }

  /// Charger les paramètres utilisateur
  Future<UserSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        return UserSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
    
    return UserSettings.defaultSettings();
  }

  /// Sauvegarder les paramètres utilisateur
  Future<bool> saveSettings(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      
      final success = await prefs.setString(_settingsKey, settingsJson);
      
      if (success) {
        print('Paramètres sauvegardés avec succès');
      }
      
      return success;
    } catch (e) {
      print('Erreur lors de la sauvegarde des paramètres: $e');
      return false;
    }
  }

  /// Sauvegarder la sélection de pays et les conditions d'utilisation
  Future<bool> saveCountrySelection({
    required Country selectedCountry,
    required bool termsAccepted,
  }) async {
    try {
      // 1. Sauvegarder localement
      final currentSettings = await loadSettings();
      
      final updatedSettings = currentSettings.copyWith(
        selectedCountry: selectedCountry,
        termsAccepted: termsAccepted,
        languageCode: selectedCountry.languageCode,
        lastUpdated: DateTime.now(),
      );

      final localSuccess = await saveSettings(updatedSettings);
      
      if (!localSuccess) {
        print('Erreur lors de la sauvegarde locale');
        return false;
      }

      // Mettre à jour le getter synchrone
      _selectedCountry = selectedCountry;

      // 2. Envoyer à l'API SNAL-Project
      try {
        print('🌍 Pays sélectionné: ${selectedCountry.sPays}');
        print('🌍 sPaysLangue: ${selectedCountry.sPaysLangue}');
        
        // ✅ Vérifier si un profil existant possède déjà sPaysFav
        final existingProfile = await LocalStorageService.getProfile();
        final existingSPaysFav = existingProfile?['sPaysFav']?.toString() ?? '';
        
        List<String> sPaysFavList;
        String sPaysFavFormatted;
        
        if (existingSPaysFav.isNotEmpty) {
          // Utiliser les pays favoris existants
          sPaysFavList = existingSPaysFav.split(',').where((s) => s.isNotEmpty).toList();
          sPaysFavFormatted = existingSPaysFav;
          print('✅ Utilisation des pays favoris existants: $existingSPaysFav');
        } else {
          // Utiliser les principaux pays IKEA comme sPaysFav par défaut (pour nouveau profil)
          sPaysFavList = ['FR', 'BE', 'NL', 'PT', 'DE', 'ES', 'IT', 'AT', 'CH'];
          sPaysFavFormatted = sPaysFavList.join(',');
          print('⚠️ Aucun pays favori existant, utilisation des pays par défaut');
        }
        
        print('📤 Données préparées:');
        print('   sPaysFavList (array pour API): $sPaysFavList');
        print('   sPaysFavFormatted (string pour LocalStorage): "$sPaysFavFormatted"');
        
        final apiResponse = await _apiService.initializeUserProfile(
          sPaysLangue: selectedCountry.sPaysLangue ?? '${selectedCountry.sPays.toLowerCase()}/fr',
          sPaysFav: sPaysFavList, // ✅ Array envoyé à l'API
          bGeneralConditionAgree: termsAccepted,
        );

        if (apiResponse['success'] == true) {
          print('✅ Profil initialisé avec succès sur l\'API');
          print('📦 Réponse API: $apiResponse');
          
          final sPaysLangueToSave = selectedCountry.sPaysLangue ?? '${selectedCountry.sPays.toLowerCase()}/fr';
          
          print('💾 Valeurs à sauvegarder dans LocalStorage:');
          print('   iProfile: ${apiResponse['iProfile']?.toString() ?? ''}');
          print('   iBasket: ${apiResponse['iBasket']?.toString() ?? ''}');
          print('   sPaysLangue: $sPaysLangueToSave');
          print('   sPaysFav: "$sPaysFavFormatted" (longueur: ${sPaysFavFormatted.length})');
          
          await LocalStorageService.saveProfile({
            'iProfile': apiResponse['iProfile']?.toString() ?? '',
            'iBasket': apiResponse['iBasket']?.toString() ?? '',
            'sPaysLangue': sPaysLangueToSave,
            'sPaysFav': sPaysFavFormatted, // ✅ Format: ',FR,BE,NL'
          });
          print('✅ Profil sauvegardé dans LocalStorage');
          
          // Définir le profil dans SearchService pour mobile-first
          final searchService = SearchService();
          searchService.setUserProfile(
            apiResponse['iProfile']?.toString(),
            apiResponse['iBasket']?.toString(),
          );
          
          // Marquer que l'onboarding est terminé
          await setOnboardingCompleted(true);
          return true;
        } else {
          print('Erreur API lors de l\'initialisation: ${apiResponse['message']}');
          return false;
        }
      } catch (apiError) {
        print('Erreur de connexion API: $apiError');
        // Même en cas d'erreur API, on garde les données locales
        await setOnboardingCompleted(true);
        return true;
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de la sélection: $e');
      return false;
    }
  }

  /// Ajouter un pays aux favoris
  Future<bool> addFavoriteCountry(String countryCode) async {
    try {
      final currentSettings = await loadSettings();
      
      if (!currentSettings.favoriteCountries.contains(countryCode)) {
        final updatedFavorites = [...currentSettings.favoriteCountries, countryCode];
        
        final updatedSettings = currentSettings.copyWith(
          favoriteCountries: updatedFavorites,
          lastUpdated: DateTime.now(),
        );
        
        return await saveSettings(updatedSettings);
      }
      
      return true; // Déjà dans les favoris
    } catch (e) {
      print('Erreur lors de l\'ajout du pays favori: $e');
      return false;
    }
  }

  /// Retirer un pays des favoris
  Future<bool> removeFavoriteCountry(String countryCode) async {
    try {
      final currentSettings = await loadSettings();
      
      final updatedFavorites = currentSettings.favoriteCountries
          .where((code) => code != countryCode)
          .toList();
      
      final updatedSettings = currentSettings.copyWith(
        favoriteCountries: updatedFavorites,
        lastUpdated: DateTime.now(),
      );
      
      return await saveSettings(updatedSettings);
    } catch (e) {
      print('Erreur lors de la suppression du pays favori: $e');
      return false;
    }
  }

  /// Vérifier si l'onboarding est terminé
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    } catch (e) {
      print('Erreur lors de la vérification de l\'onboarding: $e');
      return false;
    }
  }

  /// Marquer l'onboarding comme terminé
  Future<bool> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_hasCompletedOnboardingKey, completed);
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'onboarding: $e');
      return false;
    }
  }

  /// Effacer tous les paramètres (pour les tests ou reset)
  Future<bool> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await prefs.remove(_hasCompletedOnboardingKey);
      return true;
    } catch (e) {
      print('Erreur lors de l\'effacement des paramètres: $e');
      return false;
    }
  }

  /// Obtenir la langue actuelle
  Future<String> getCurrentLanguage() async {
    final settings = await loadSettings();
    return settings.languageCode ?? 'fr';
  }

  /// Obtenir le pays sélectionné
  Future<Country?> getSelectedCountry() async {
    final settings = await loadSettings();
    return settings.selectedCountry;
  }

  /// Getter synchrone pour le pays sélectionné
  Country? _selectedCountry;
  
  Country? get selectedCountry => _selectedCountry;
  
  /// Mettre à jour le pays sélectionné
  void updateSelectedCountry(Country country) {
    _selectedCountry = country;
    print('Pays sélectionné mis à jour: ${country.sDescr} (${country.sPays})');
  }
}
