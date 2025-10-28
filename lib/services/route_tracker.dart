import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_persistence_service.dart';

/// Mixin pour tracker automatiquement les routes et les sauvegarder
/// Mobile-first : utilise SharedPreferences (fonctionne sur mobile ET web)
mixin RouteTracker<T extends StatefulWidget> on State<T> {
  String? _currentRoute;
  
  /// ✅ Sauvegarder la route actuelle
  void saveCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      RoutePersistenceService.saveCurrentRoute(route);
      print('💾 Route sauvegardée: $route');
    }
  }


  @override
  void initState() {
    super.initState();
    // ✅ Sauvegarder la route actuelle lors de l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _saveCurrentRouteFromContext();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Sauvegarder la route à chaque changement de dépendances
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _saveCurrentRouteFromContext();
      }
    });
  }

  void _saveCurrentRouteFromContext() {
    try {
      final currentRoute = GoRouterState.of(context).uri.path;
      
      // ✅ Valider la route avant de la sauvegarder
      if (RoutePersistenceService.isValidRoute(currentRoute)) {
        saveCurrentRoute(currentRoute);
      } else {
        print('⚠️ Route non valide ignorée: $currentRoute');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la sauvegarde de la route: $e');
    }
  }

  /// ✅ Navigation sécurisée avec validation de route
  void goWithRouteTracking(String route, {Object? extra}) {
    if (RoutePersistenceService.isValidRoute(route)) {
      saveCurrentRoute(route);
      if (mounted) {
        context.go(route, extra: extra);
      }
    } else {
      print('⚠️ Navigation ignorée - route non valide: $route');
    }
  }

  /// ✅ Push sécurisé avec validation de route
  void pushWithRouteTracking(String route, {Object? extra}) {
    if (RoutePersistenceService.isValidRoute(route)) {
      saveCurrentRoute(route);
      if (mounted) {
        context.push(route, extra: extra);
      }
    } else {
      print('⚠️ Push ignoré - route non valide: $route');
    }
  }

  /// ✅ Replace sécurisé avec validation de route
  void replaceWithRouteTracking(String route, {Object? extra}) {
    if (RoutePersistenceService.isValidRoute(route)) {
      saveCurrentRoute(route);
      if (mounted) {
        context.replace(route, extra: extra);
      }
    } else {
      print('⚠️ Replace ignoré - route non valide: $route');
    }
  }
}
