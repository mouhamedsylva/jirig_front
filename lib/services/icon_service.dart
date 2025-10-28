import 'package:flutter/material.dart';

/// Service centralisé pour gérer tous les icônes de l'application
/// Permet de reproduire facilement les icônes de SNAL-Project
class IconService {
  
  // =================== MODULES PRINCIPAUX ===================
  
  /// Icônes des modules de la page d'accueil (Material Icons)
  static const Map<String, IconData> moduleIcons = {
    'scanner': Icons.search,                    // i-heroicons-magnifying-glass
    'comparison': Icons.balance,                // streamline-freehand:business-cash-scale-balance
    'pdf': Icons.description,                   // i-heroicons-document-text
    'wishlist': Icons.favorite_border,          // material-symbols-heart-check-outline-rounded
  };

  /// Icônes des modules avec Material Icons (alternative)
  static const Map<String, IconData> materialModuleIcons = {
    'scanner': Icons.search,
    'comparison': Icons.balance,
    'pdf': Icons.description,
    'wishlist': Icons.favorite_border,
  };


  // =================== RÉSEAUX SOCIAUX ===================
  
  /// Icônes des réseaux sociaux (Material Icons avec CustomPainter)
  static const Map<String, IconData> socialIcons = {
    'facebook': Icons.facebook,               // logos:facebook
    'instagram': Icons.camera_alt,            // skill-icons:instagram
    'twitter': Icons.close,                   // devicon:twitter
    'tiktok': Icons.music_note,               // logos:tiktok-icon
  };


  /// Couleurs des réseaux sociaux
  static const Map<String, Color> socialColors = {
    'facebook': Color(0xFF1877F2),
    'instagram': Color(0xFFE4405F),
    'twitter': Color(0xFF1DA1F2),
    'tiktok': Colors.black,
  };

  // =================== NAVIGATION ===================
  
  /// Icônes de navigation
  static const Map<String, IconData> navigationIcons = {
    'home': Icons.home,                       // Accueil
    'scanner': Icons.qr_code_scanner,         // Scanner
    'download': Icons.download,               // Import/PDF
    'heart': Icons.favorite_border,           // Wishlist
  };

  // =================== SERVICES ===================
  
  /// Icônes des services additionnels
  static const Map<String, IconData> serviceIcons = {
    'barcode_scan': Icons.qr_code_scanner,           // mdi-barcode-scan
    'dialpad': Icons.dialpad,                        // mdi:dialpad
    'file_pdf': Icons.picture_as_pdf,                // mdi-file-pdf
    'envelope': Icons.email,                         // heroicons-outline:envelope
  };


  // =================== INTERFACE ===================
  
  /// Icônes d'interface utilisateur
  static const Map<String, IconData> interfaceIcons = {
    'arrow_right': Icons.arrow_forward,               // i-heroicons-arrow-right
    'chevron_down': Icons.expand_more,                // i-heroicons-chevron-down
    'settings': Icons.settings,                       // i-heroicons-cog-8-tooth
    'logout': Icons.logout,                          // i-heroicons-arrow-left-on-rectangle
  };


  // =================== MÉTHODES UTILITAIRES ===================
  
  /// Récupère un icône de module par son nom
  static IconData getModuleIcon(String moduleName, {bool useMaterial = false}) {
    final icons = useMaterial ? materialModuleIcons : moduleIcons;
    return icons[moduleName] ?? Icons.help_outline;
  }

  /// Récupère un icône social par son nom
  static IconData getSocialIcon(String socialName) {
    return socialIcons[socialName] ?? Icons.help_outline;
  }

  /// Récupère la couleur d'un réseau social
  static Color getSocialColor(String socialName) {
    return socialColors[socialName] ?? Colors.grey;
  }

  /// Récupère un icône de navigation par son nom
  static IconData getNavigationIcon(String navName) {
    return navigationIcons[navName] ?? Icons.help_outline;
  }

  /// Récupère un icône de service par son nom
  static IconData getServiceIcon(String serviceName) {
    return serviceIcons[serviceName] ?? Icons.help_outline;
  }

  /// Récupère un icône d'interface par son nom
  static IconData getInterfaceIcon(String interfaceName) {
    return interfaceIcons[interfaceName] ?? Icons.help_outline;
  }

  // =================== WIDGETS UTILITAIRES ===================
  
  /// Crée un widget icône social avec style
  static Widget buildSocialIcon(String socialName, {double size = 32.0, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: getSocialColor(socialName),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getSocialIcon(socialName),
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  /// Crée un widget icône de module avec style
  static Widget buildModuleIcon(String moduleName, {double size = 32.0, Color? color, bool useMaterial = false}) {
    final iconColor = color ?? Colors.blue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        getModuleIcon(moduleName, useMaterial: useMaterial),
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }

  /// Crée un widget icône de navigation avec style
  static Widget buildNavigationIcon(String navName, {double size = 24.0, Color? color, bool isSelected = false}) {
    final iconColor = isSelected ? Colors.blue : (color ?? Colors.grey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        getNavigationIcon(navName),
        color: iconColor,
        size: size * 0.8,
      ),
    );
  }

}

/// Extension pour faciliter l'utilisation
extension IconServiceExtension on String {
  IconData get asModuleIcon => IconService.getModuleIcon(this);
  IconData get asSocialIcon => IconService.getSocialIcon(this);
  IconData get asNavigationIcon => IconService.getNavigationIcon(this);
  IconData get asServiceIcon => IconService.getServiceIcon(this);
  IconData get asInterfaceIcon => IconService.getInterfaceIcon(this);
  Color get asSocialColor => IconService.getSocialColor(this);
}
