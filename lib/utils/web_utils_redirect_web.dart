// Fichier spécifique Web
// Ce fichier sera utilisé uniquement sur Web
import 'dart:html' as html;

class WebRedirect {
  /// Redirige vers une URL dans le navigateur Web
  static void redirect(String url) {
    html.window.location.href = url;
  }
}

