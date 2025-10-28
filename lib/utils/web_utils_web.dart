// Fichier spécifique Web
// Ce fichier sera utilisé uniquement sur Web
import 'dart:html' as html;

class WebUtils {
  /// Télécharge un fichier sur le navigateur Web
  static void downloadFile(List<int> bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  
  /// Retour arrière dans l'historique du navigateur
  static void navigateBack() {
    html.window.history.back();
  }
  
  /// Récupère les cookies du navigateur
  static String getCookies() {
    return html.document.cookie ?? '';
  }
}

