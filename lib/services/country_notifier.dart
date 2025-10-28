import 'package:flutter/foundation.dart';
import '../models/country.dart';
import 'settings_service.dart';

/// Service pour notifier les changements de pays sélectionné
class CountryNotifier extends ChangeNotifier {
  Country? _selectedCountry;
  bool _isInitialized = false;
  
  CountryNotifier() {
    // ✅ Charger automatiquement le pays sélectionné au démarrage
    _initializeSelectedCountry();
  }
  
  /// Initialiser le pays sélectionné depuis le localStorage
  Future<void> _initializeSelectedCountry() async {
    if (_isInitialized) return;
    
    try {
      final settingsService = SettingsService();
      final country = await settingsService.getSelectedCountry();
      
      if (country != null) {
        _selectedCountry = country;
        _isInitialized = true;
        notifyListeners();
        print('✅ CountryNotifier initialisé avec ${country.sDescr} (${country.sPays})');
      } else {
        print('⚠️ Aucun pays sélectionné trouvé dans le localStorage');
        _isInitialized = true;
      }
    } catch (e) {
      print('❌ Erreur initialisation CountryNotifier: $e');
      _isInitialized = true;
    }
  }
  
  Country? get selectedCountry => _selectedCountry;
  
  /// Mettre à jour le pays sélectionné et notifier les changements
  void updateSelectedCountry(Country country) {
    _selectedCountry = country;
    notifyListeners();
    print('Pays sélectionné mis à jour: ${country.sDescr} (${country.sPays})');
  }
  
  /// Définir le pays sélectionné sans notifier (pour l'initialisation)
  void setSelectedCountry(Country? country) {
    _selectedCountry = country;
  }
}
