// Fichier spécifique Mobile
// Ce fichier sera utilisé uniquement sur Mobile

class WebUtils {
  /// Télécharge un fichier sur mobile (non supporté)
  static void downloadFile(List<int> bytes, String filename) {
    // Sur mobile, on ne peut pas télécharger directement
    // Cette fonctionnalité n'est pas disponible sur mobile
    print('⚠️ Téléchargement de fichier non supporté sur mobile');
  }
  
  /// Retour arrière dans l'historique (non supporté sur mobile)
  static void navigateBack() {
    // Sur mobile, on ne peut pas naviguer dans l'historique du navigateur
    // Cette fonctionnalité n'est pas disponible sur mobile
    print('⚠️ Navigation arrière non supportée sur mobile');
  }
  
  /// Récupère les cookies (non supporté sur mobile)
  static String getCookies() {
    // Sur mobile, on ne peut pas accéder aux cookies du navigateur
    // Cette fonctionnalité n'est pas disponible sur mobile
    print('⚠️ Récupération de cookies non supportée sur mobile');
    return '';
  }
}
