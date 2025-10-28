import 'country.dart';

/// Modèle pour les paramètres utilisateur
class UserSettings {
  final Country? selectedCountry;
  final List<String> favoriteCountries;
  final bool termsAccepted;
  final String? languageCode;
  final DateTime? lastUpdated;

  const UserSettings({
    this.selectedCountry,
    this.favoriteCountries = const [],
    this.termsAccepted = false,
    this.languageCode,
    this.lastUpdated,
  });

  /// Créer des paramètres par défaut
  factory UserSettings.defaultSettings() {
    return const UserSettings();
  }

  /// Créer un objet UserSettings depuis un JSON
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      selectedCountry: json['selectedCountry'] != null 
          ? Country.fromJson(json['selectedCountry']) 
          : null,
      favoriteCountries: List<String>.from(json['favoriteCountries'] ?? []),
      termsAccepted: json['termsAccepted'] ?? false,
      languageCode: json['languageCode'],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  /// Convertir un objet UserSettings en JSON
  Map<String, dynamic> toJson() {
    return {
      'selectedCountry': selectedCountry?.toJson(),
      'favoriteCountries': favoriteCountries,
      'termsAccepted': termsAccepted,
      'languageCode': languageCode,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Copier avec de nouvelles valeurs
  UserSettings copyWith({
    Country? selectedCountry,
    List<String>? favoriteCountries,
    bool? termsAccepted,
    String? languageCode,
    DateTime? lastUpdated,
  }) {
    return UserSettings(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      favoriteCountries: favoriteCountries ?? this.favoriteCountries,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      languageCode: languageCode ?? this.languageCode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Vérifier si les paramètres sont valides pour continuer
  bool get canProceed {
    return selectedCountry != null && termsAccepted;
  }

  @override
  String toString() {
    return 'UserSettings(selectedCountry: $selectedCountry, favoriteCountries: $favoriteCountries, termsAccepted: $termsAccepted)';
  }
}
