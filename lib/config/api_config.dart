import 'package:flutter/foundation.dart';

/// Configuration de l'API - Mobile-First
/// 
/// Mobile (Android/iOS): Appelle directement https://jirig.be/api
/// Web: Utilise le proxy local http://localhost:3001/api pour éviter CORS
class ApiConfig {
  /// URL de base de l'API selon la plateforme
  /// Mobile-First: Priorité à l'expérience mobile native
  static String get baseUrl {
    if (kIsWeb) {
      // Web: Utiliser le proxy local pour contourner CORS
      return 'http://localhost:3001/api';
    } else {
      // Mobile (Android/iOS): Appeler directement l'API de production
      return 'https://jirig.be/api';
    }
  }
  
  /// Indique si on doit utiliser la gestion des cookies
  /// Mobile: true (Dio + dio_cookie_manager + PersistCookieJar)
  /// Web: false (le navigateur gère les cookies automatiquement)
  static bool get useCookieManager => !kIsWeb;
  
  // Timeout pour les requêtes
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Obtenir l'URL d'une image avec proxy si nécessaire (mobile-first)
  /// 
  /// Mobile (Android/iOS): Retourne l'URL directement (pas de CORS)
  /// Web: Passe par le proxy pour contourner CORS
  static String getProxiedImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    
    if (kIsWeb) {
      // Web: Utiliser le proxy pour contourner CORS
      return 'http://localhost:3001/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
    } else {
      // Mobile: Charger l'image directement (pas de CORS)
      return imageUrl;
    }
  }
  
  /// Vérifier si l'URL de base est configurée
  static bool get isConfigured => baseUrl.isNotEmpty;
  
  /// Afficher la configuration actuelle (pour debug)
  static void printConfig() {
    print('🔧 Configuration API (Mobile-First):');
    print('   Plateforme: ${kIsWeb ? "Web" : "Mobile"}');
    print('   Base URL: $baseUrl');
    print('   Cookie Manager: ${useCookieManager ? "Activé" : "Désactivé (navigateur)"}');
    print('   Connect Timeout: ${connectTimeout.inSeconds}s');
  }
}
