/// Modèle de données pour représenter un pays
/// Basé sur la structure réelle de l'API SNAL-Project
class Country {
  final String sPays;           // Code du pays (ex: "FR", "BE") - de la DB
  final String sDescr;          // Description/nom du pays
  final String? sExternalRef;   // Référence externe du pays
  final int iPays;              // ID numérique du pays (iStatus dans la DB)
  final String? sPaysLangue;    // Code pays/langue (ex: "FR/FR", "BE/NL") - pour les flags
  final String? image;          // Chemin vers l'image du drapeau
  final String? name;           // Nom alternatif du pays
  final String? code;           // Code alternatif du pays

  const Country({
    required this.sPays,
    required this.sDescr,
    this.sExternalRef,
    required this.iPays,
    this.sPaysLangue,
    this.image,
    this.name,
    this.code,
  });

  /// Créer un objet Country depuis un JSON
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      sPays: json['sPays'] ?? json['sExternalRef'] ?? '',
      sDescr: json['sDescr'] ?? json['name'] ?? '',
      sExternalRef: json['sExternalRef'],
      iPays: json['iPays'] ?? json['iStatus'] ?? 0,
      sPaysLangue: json['sPaysLangue'],
      image: json['image'] ?? json['sColor'],
      name: json['name'],
      code: json['code'],
    );
  }

  /// Convertir un objet Country en JSON
  Map<String, dynamic> toJson() {
    return {
      'sPays': sPays,
      'sDescr': sDescr,
      'sExternalRef': sExternalRef,
      'iPays': iPays,
      'sPaysLangue': sPaysLangue,
      'image': image,
      'name': name,
      'code': code,
    };
  }

  /// Obtenir le code de langue depuis sPaysLangue
  String get languageCode {
    if (sPaysLangue != null && sPaysLangue!.contains('/')) {
      return sPaysLangue!.split('/')[1].toLowerCase();
    }
    return 'fr'; // Par défaut
  }

  /// Obtenir le code pays depuis sPaysLangue
  String get countryCode {
    if (sPaysLangue != null && sPaysLangue!.contains('/')) {
      return sPaysLangue!.split('/')[0];
    }
    return sPays;
  }

  /// Obtenir le chemin vers l'image du drapeau
  String get flagImagePath {
    if (image != null && image!.isNotEmpty) {
      return image!;
    }
    return '/img/flags/${sPays.toUpperCase()}.PNG';
  }

  /// Obtenir les pays limitrophes
  List<String> get neighboringCountries {
    // Dans SNAL-Project, PaysLimitrophes est une chaîne séparée par des virgules
    // Cette propriété sera ajoutée quand on aura les données complètes
    return [];
  }

  @override
  String toString() {
    return 'Country(sPays: $sPays, sDescr: $sDescr, iPays: $iPays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.sPays == sPays;
  }

  @override
  int get hashCode => sPays.hashCode;
}
