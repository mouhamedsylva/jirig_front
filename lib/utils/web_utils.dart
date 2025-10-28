// Import conditionnel pour web_utils
// Utilise web_utils_web.dart sur web et web_utils_mobile.dart sur mobile

export 'web_utils_web.dart' if (dart.library.io) 'web_utils_mobile.dart';
