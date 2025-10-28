import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/local_storage_service.dart';
import '../services/route_tracker.dart';
import '../config/api_config.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_modal.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:math' as math;

class PodiumScreen extends StatefulWidget {
  final String productCode;
  final String? productCodeCrypt;
  
  const PodiumScreen({
    super.key,
    required this.productCode,
    this.productCodeCrypt,
  });

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> 
    with RouteTracker, TickerProviderStateMixin {
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentQuantity = 1;
  int _currentImageIndex = 0;
  String? _userCountryCode; // Code du pays de l'utilisateur
  bool _hasInitiallyLoaded = false; // Suivre si les données ont été chargées initialement
  
  // Controllers d'animation (style "Explosion & Reveal" - différent des autres pages)
  late AnimationController _productController;
  late AnimationController _podiumController;
  late AnimationController _otherCountriesController;
  
  late Animation<double> _productScaleAnimation;
  late Animation<double> _productRotationAnimation;
  late Animation<double> _productFadeAnimation;
  
  bool _animationsInitialized = false;
  
  ApiService get _apiService => Provider.of<ApiService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    // Ne pas charger les données ici - attendre didChangeDependencies
  }
  
  /// Initialiser les controllers d'animation (style Explosion & Reveal)
  void _initializeAnimationControllers() {
    try {
      // Produit principal : Rotation 3D + Scale + Fade
      _productController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      
      _productScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _productController,
          curve: Curves.elasticOut, // Super bounce
        ),
      );
      
      _productRotationAnimation = Tween<double>(begin: math.pi / 6, end: 0.0).animate(
        CurvedAnimation(
          parent: _productController,
          curve: Curves.easeOutBack,
        ),
      );
      
      _productFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _productController,
          curve: Curves.easeIn,
        ),
      );
      
      // Podium : Construction depuis le bas (comme si le podium se construit)
      _podiumController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );
      
      // Autres pays : Ripple effect
      _otherCountriesController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _animationsInitialized = true;
      print('✅ Animations Podium initialisées (style Explosion & Reveal)');
    } catch (e) {
      print('❌ Erreur initialisation animations podium: $e');
    }
  }
  
  /// Démarrer les animations quand les données sont chargées
  void _startPodiumAnimations() async {
    if (!_animationsInitialized || !mounted) return;
    
    try {
      // Reset avant de commencer
      _productController.reset();
      _podiumController.reset();
      _otherCountriesController.reset();
      
      // Animation du produit principal (immédiate)
      _productController.forward();
      
      // Animation du podium (après 300ms)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _podiumController.forward();
      
      // Animation des autres pays (après 600ms)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _otherCountriesController.forward();
    } catch (e) {
      print('❌ Erreur démarrage animations: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ne recharger les données que si elles ne sont pas déjà chargées
    // pour éviter le rechargement lors du changement de langue
    if (!_hasInitiallyLoaded) {
      _hasInitiallyLoaded = true;
      _loadProductData();
    }
  }

  @override
  void didUpdateWidget(PodiumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le code produit a changé, recharger les données
    if (oldWidget.productCode != widget.productCode || 
        oldWidget.productCodeCrypt != widget.productCodeCrypt) {
      print('🔄 Nouveau produit détecté : ${widget.productCode}');
      _hasInitiallyLoaded = false; // Réinitialiser le flag pour permettre le rechargement
      _loadProductData();
    }
  }
  
  @override
  void dispose() {
    try {
      _productController.dispose();
      _podiumController.dispose();
      _otherCountriesController.dispose();
    } catch (e) {
      print('⚠️ Erreur dispose controllers podium: $e');
    }
    super.dispose();
  }


  Future<void> _loadProductData() async {
    try {
      // ✅ Récupérer la quantité depuis l'URL (si venant de la wishlist)
      final uri = GoRouterState.of(context).uri;
      final iQuantiteFromUrl = uri.queryParameters['iQuantite'];
      final initialQuantity = int.tryParse(iQuantiteFromUrl ?? '1') ?? 1;
      
      print('📦 Quantité récupérée depuis URL: $iQuantiteFromUrl → $initialQuantity');
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
          // ✅ Ne réinitialiser la quantité que si elle n'a pas été définie depuis l'URL
          if (_currentQuantity == 1 && initialQuantity != 1) {
            _currentQuantity = initialQuantity;
          }
          _currentImageIndex = 0; // Réinitialiser l'index d'image
        });
      }

      
      String? sTokenUrl;
      String? sPaysLangue;
      String? iBasket;
      
      try {
        // ✅ Récupérer le profil depuis LocalStorage (déjà initialisé dans app.dart)
        final profileData = await LocalStorageService.getProfile();
        sTokenUrl = profileData?['iProfile']?.toString();
        iBasket = profileData?['iBasket']?.toString();
        sPaysLangue = profileData?['sPaysLangue']?.toString();
        
        print('🔑 Profil récupéré - iProfile: ${sTokenUrl != null ? "✅" : "❌"}');
        
        // Récupérer le pays de l'utilisateur
        final settingsService = SettingsService();
        final selectedCountry = await settingsService.getSelectedCountry();
        if (selectedCountry != null) {
          _userCountryCode = selectedCountry.sPays;
          // Utiliser sPaysLangue du profil ou du pays sélectionné
          sPaysLangue ??= selectedCountry.sPaysLangue ?? '${selectedCountry.sPays.toLowerCase()}/fr';
        }
      } catch (e) {
        print('⚠️ Erreur lors de la récupération du profil: $e');
      }

      String codeToUse = widget.productCode;
      if (widget.productCode.length > 50) {
        codeToUse = widget.productCode.replaceAll(RegExp(r'[^\d]'), '');
        if (codeToUse.length > 9) {
          codeToUse = codeToUse.substring(0, 9);
        }
      }
      
      print('🔍 Paramètres API:');
      print('  - sCodeArticle: $codeToUse');
      print('  - sCodeArticleCrypt: ${widget.productCodeCrypt}');
      print('  - iProfile: $sTokenUrl');
      print('  - iBasket: $iBasket');
      print('  - iQuantite: $_currentQuantity');
      
      final response = await _apiService.getComparaisonByCode(
        sCodeArticle: codeToUse,
        sCodeArticleCrypt: widget.productCodeCrypt,
        iProfile: sTokenUrl,
        iBasket: iBasket,
        iQuantite: _currentQuantity,
      );
      
      print('📡 Réponse API: $response');

      if (response != null) {
        if (response['error'] == true) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur API: ${response['message'] ?? 'Erreur inconnue'}';
            });
          }
        } else if (response['Ui_Result'] == 'ARTICLE_NOT_FOUND') {
          // Afficher le message d'erreur normal pour la recherche par code
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'ARTICLE_NOT_FOUND';
            });
          }
        } else if (response['Ui_Result'] == 'GIVE_EMAIL') {
          // Afficher le message d'erreur normal pour la recherche par code
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur d\'authentification - Veuillez vous connecter ou vérifier votre profil';
            });
          }
        } else if (response['Ui_Result'] == 'GET_ABONNEMENT') {
          // Afficher le message d'erreur normal pour la recherche par code
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'GET_ABONNEMENT';
            });
          }
        } else if (response['Articles'] == null || (response['Articles'] is List && (response['Articles'] as List).isEmpty)) {
          // Afficher le message d'erreur normal pour la recherche par code
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Aucun article trouvé dans la réponse';
            });
          }
        } else {
          // Debug: Afficher un article pour voir les champs disponibles
          if (response['Articles'] != null && (response['Articles'] as List).isNotEmpty) {
            print('🏳️ DEBUG Article 0: ${response['Articles'][0]}');
            print('🏳️ sPaysDrapeau: ${response['Articles'][0]['sPaysDrapeau']}');
          }
          if (mounted) {
            setState(() {
              _productData = response;
              _isLoading = false;
            });
            // Démarrer les animations après chargement réussi
            _startPodiumAnimations();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Produit non trouvé - API response null';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement: $e';
        });
      }
    }
  }

  List<String> _collectImageUrls() {
    final urls = <String>[];

    // 1) aImageLink au niveau racine
    final root = _productData?['aImageLink'];
    if (root is List && root.isNotEmpty) {
      for (final it in root) {
        if (it is Map && (it['sHyperlink'] ?? '').toString().isNotEmpty) {
          final link = it['sHyperlink'].toString();
          if (!link.toLowerCase().contains('no_image')) {
            // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
            urls.add(ApiConfig.getProxiedImageUrl(link));
          }
        } else if (it is String && it.isNotEmpty) {
          if (!it.toLowerCase().contains('no_image')) {
            // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
            urls.add(ApiConfig.getProxiedImageUrl(it));
          }
        }
      }
    } else if (root is String && root.isNotEmpty) {
      // Peut être un XML <row><sHyperlink>...</sHyperlink></row>
      final m = RegExp(r'<sHyperlink>(.*?)<\/sHyperlink>', caseSensitive: false)
          .firstMatch(root);
      final link = m?.group(1) ?? '';
      if (link.isNotEmpty && !link.toLowerCase().contains('no_image')) {
        // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
        urls.add(ApiConfig.getProxiedImageUrl(link));
      }
    }

    // 2) aImageLink dans Articles[0]
    final articles = _productData?['Articles'];
    if (articles is List && articles.isNotEmpty) {
      final a0 = articles[0];
      final articleImages = (a0 is Map) ? a0['aImageLink'] : null;
      if (articleImages is List) {
        for (final it in articleImages) {
          if (it is Map && (it['sHyperlink'] ?? '').toString().isNotEmpty) {
            final link = it['sHyperlink'].toString();
            if (!link.toLowerCase().contains('no_image')) {
              // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
              urls.add(ApiConfig.getProxiedImageUrl(link));
            }
          } else if (it is String && it.isNotEmpty) {
            if (!it.toLowerCase().contains('no_image')) {
              // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
              urls.add(ApiConfig.getProxiedImageUrl(it));
            }
          }
        }
      } else if (articleImages is String && articleImages.isNotEmpty) {
        final m = RegExp(r'<sHyperlink>(.*?)<\/sHyperlink>', caseSensitive: false)
            .firstMatch(articleImages);
        final link = m?.group(1) ?? '';
        if (link.isNotEmpty && !link.toLowerCase().contains('no_image')) {
          // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
          urls.add(ApiConfig.getProxiedImageUrl(link));
        }
      }
    }

    return urls;
  }

  String _getCurrentImageUrl() {
    final urls = _collectImageUrls();
    if (urls.isEmpty) return '';
    final idx = (_currentImageIndex % urls.length).abs();
    return urls[idx];
  }

  void _nextImage() {
    final urls = _collectImageUrls();
    if (urls.isEmpty) return;
    
    // Animation désactivée pour Flutter Web
    if (mounted) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % urls.length;
      });
    }
  }

  void _prevImage() {
    final urls = _collectImageUrls();
    if (urls.isEmpty) return;
    
    // Animation désactivée pour Flutter Web
    if (mounted) {
      setState(() {
        _currentImageIndex = (_currentImageIndex - 1 + urls.length) % urls.length;
      });
    }
  }

  void _showSearchModal() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 280),
        reverseTransitionDuration: Duration(milliseconds: 220),
        barrierDismissible: true,
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.white,
              elevation: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: media.size.height * 0.9,
                  minHeight: media.size.height * 0.5,
                  maxWidth: 700,
                ),
                child: const SearchModal(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Afficher l'image en plein écran
  void _showFullscreenImage() {
    final urls = _collectImageUrls();
    if (urls.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Zone de clic pour fermer (couvre tout l'écran)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                
                // Image centrée avec zoom et scroll
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(100),
                    child: Image.network(
                      urls[_currentImageIndex % urls.length],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                
                // Contrôles de navigation (si plusieurs images)
                if (urls.length > 1) ...[
                  // Bouton précédent
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentImageIndex = (_currentImageIndex - 1 + urls.length) % urls.length;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bouton suivant
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentImageIndex = (_currentImageIndex + 1) % urls.length;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                ],
                
                // Bouton fermer
                Positioned(
                  top: 40,
                  right: 16,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Doré clair
      case 2:
        return const Color(0xFF90A4AE); // Argent
      case 3:
        return const Color(0xFFFF6F00); // Bronze
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getPodiumGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFD700), // Doré clair (haut)
            Color(0xFFB8860B), // Doré foncé (bas)
          ],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB0BEC5), // Argent clair
            Color(0xFF90A4AE), // Argent foncé
          ],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB74D), // Bronze clair
            Color(0xFFFF6F00), // Bronze foncé
          ],
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.grey],
        );
    }
  }

  Color _getPodiumNumberColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFB8860B); // Doré foncé
      case 2:
        return const Color(0xFF424242); // Gris foncé
      case 3:
        return const Color(0xFFD32F2F); // Rouge foncé
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallMobile = screenWidth < 361;   // Galaxy Fold fermé, Galaxy S8+ (≤360px)
    final isSmallMobile = screenWidth < 431;       // iPhone XR/14 Pro Max, Pixel 7, Galaxy S20/A51 (361-430px)
    final isMobile = screenWidth < 768;            // Tous les mobiles standards (431-767px)
    final translationService = Provider.of<TranslationService>(context, listen: true);
    
    // Précharger les traductions pour éviter les appels répétés
    final loadingText = translationService.translate('SCANCODE_Processing');
    final podiumMsg01 = translationService.translate('PODIUM_Msg01');
    final podiumMsg02 = translationService.translate('PODIUM_Msg02');
    final podiumMsg03 = translationService.translate('PODIUM_Msg03');
    final productcodeMsg08 = translationService.translate('PRODUCTCODE_Msg08');
    final productcodeMsg09 = translationService.translate('PRODUCTCODE_Msg09');
    final appHeaderHome = translationService.translate('APPHEADER_HOME');
    final scancodeTitle = translationService.translate('SCANCODE_Title');
    final appHeaderWishlist = translationService.translate('APPHEADER_WISHLIST');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: CustomAppBar(),
      ),
      body: Stack(
        children: [
          // Contenu principal
          _errorMessage.isNotEmpty
              ? _buildErrorState(podiumMsg01, isVerySmallMobile, isSmallMobile, isMobile)
              : _productData == null && !_isLoading
                  ? _buildNotFoundState(productcodeMsg08, productcodeMsg09, podiumMsg01, isVerySmallMobile, isSmallMobile, isMobile)
                  : _buildPodiumView(isMobile, isSmallMobile, isVerySmallMobile, podiumMsg01, podiumMsg02, podiumMsg03),
          
          // Loader en overlay complet
          if (_isLoading)
            Positioned.fill(
              child: _buildLoadingState(loadingText, isVerySmallMobile, isSmallMobile),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildLoadingState(String loadingText, bool isVerySmallMobile, bool isSmallMobile) {
    return Container(
      color: Colors.white, // Page entièrement blanche
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de chargement hexagonDots
            LoadingAnimationWidget.hexagonDots(
              color: Colors.blue,
              size: isVerySmallMobile ? 60 : (isSmallMobile ? 70 : 80),
            ),
            SizedBox(height: isVerySmallMobile ? 16 : (isSmallMobile ? 20 : 24)),
            // Texte de chargement
            Text(
              loadingText,
              style: TextStyle(
                fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String podiumMsg01, bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmallMobile ? 16.0 : (isSmallMobile ? 20.0 : 24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isVerySmallMobile ? 48 : (isSmallMobile ? 56 : 64),
              color: Colors.red[600],
            ),
            SizedBox(height: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16)),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showSearchModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(podiumMsg01),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(String productcodeMsg08, String productcodeMsg09, String podiumMsg01, bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVerySmallMobile ? 16.0 : (isSmallMobile ? 20.0 : 24.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: isVerySmallMobile ? 48 : (isSmallMobile ? 56 : 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16)),
            Text(
              productcodeMsg08,
              style: TextStyle(
                fontSize: isVerySmallMobile ? 18 : (isSmallMobile ? 19 : 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isVerySmallMobile ? 6 : (isSmallMobile ? 7 : 8)),
            Text(
              productcodeMsg09,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isVerySmallMobile ? 12 : (isSmallMobile ? 13 : 14),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showSearchModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(podiumMsg01),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumView(bool isMobile, bool isSmallMobile, bool isVerySmallMobile, String podiumMsg01, String podiumMsg02, String podiumMsg03) {
    final articles = _productData?['Articles'] as List<dynamic>?;
    if (articles == null || articles.isEmpty) {
      // Variables temporaires pour les cas d'erreur
      final translationService = Provider.of<TranslationService>(context, listen: false);
      final productcodeMsg08 = translationService.translate('PRODUCTCODE_Msg08');
      final productcodeMsg09 = translationService.translate('PRODUCTCODE_Msg09');
      return _buildNotFoundState(productcodeMsg08, productcodeMsg09, podiumMsg01, isVerySmallMobile, isSmallMobile, isMobile);
    }

    final mainArticle = articles[0];
    // Afficher exactement les champs API (sans filtrage ni masquage)
    final productName = ((_productData?['sName'] as String?)
        ?? (mainArticle['sName'] as String?)
        ?? (mainArticle['sArticleName'] as String?)
        ?? '');
    final productDescr = ((_productData?['sDescr'] as String?)
        ?? (mainArticle['sDescr'] as String?)
        ?? (mainArticle['sArticleDescr'] as String?)
        ?? '');
    final productCode = _productData?['sCodeArticle'] ?? '';
    final productPrice = mainArticle['sPrice'];

    // Trier les articles par prix (du moins cher au plus cher)
    final sortedArticles = List<Map<String, dynamic>>.from(
      articles.map((e) => e as Map<String, dynamic>)
    );
    sortedArticles.sort((a, b) {
      final priceA = _extractPrice(a['sPrice'] ?? '');
      final priceB = _extractPrice(b['sPrice'] ?? '');
      return priceA.compareTo(priceB);
    });

    // Top 3 pour le podium (comme SNAL-Project)
    final topThree = sortedArticles.take(3).toList();
    
    // Autres pays : filtrer par iPodiumPosition > 3 (comme SNAL-Project)
    final otherCountries = articles.where((article) {
      final position = int.tryParse(article['iPodiumPosition']?.toString() ?? '0') ?? 0;
      return position > 3;
    }).map((e) => e as Map<String, dynamic>).toList();
    
    
    // Calculer le prix maximum pour la comparaison
    final maxPrice = sortedArticles.isEmpty 
        ? 0.0 
        : sortedArticles.map((a) => _extractPrice(a['sPrice'] ?? '')).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Image et infos principales avec animation Rotation 3D + Scale + Fade
          AnimatedBuilder(
            animation: _productController,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(_productRotationAnimation.value), // Rotation 3D
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: _productScaleAnimation.value,
                  child: Opacity(
                    opacity: _productFadeAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmallMobile ? 6.0 : (isSmallMobile ? 7.0 : 8.0),
                vertical: isVerySmallMobile ? 8.0 : (isSmallMobile ? 10.0 : 12.0),
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                child: Container(
                padding: EdgeInsets.all(isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                width: double.infinity,
                child: Column(
                  children: [
                    // Image taille réduite
                    SizedBox(
                      height: isVerySmallMobile ? 180 : (isSmallMobile ? 200 : 220),
                      child: _buildProductImage(),
                    ),
                    SizedBox(height: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productName,
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 16 : (isSmallMobile ? 17 : 18),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12)),
                        Text(
                          productCode,
                          style: TextStyle(
                            fontSize: isVerySmallMobile ? 11 : (isSmallMobile ? 12 : 13),
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isVerySmallMobile ? 3 : 4),
                    Text(
                      productDescr,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isVerySmallMobile ? 16 : (isSmallMobile ? 17 : 18),
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12)),
                    _buildQuantitySelector(),
                  ],
                ),
              ),
            ),
            ),
          ), // Ferme AnimatedBuilder
        
          // Podium avec top 3 - Animation construction depuis le bas  
          if (topThree.isNotEmpty) ...[
            SizedBox(height: isVerySmallMobile ? 8 : (isSmallMobile ? 12 : 16)),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5), // Depuis le bas
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _podiumController,
                  curve: Curves.easeOutBack, // Bounce effect
                ),
              ),
              child: FadeTransition(
                opacity: _podiumController,
                child: Container(
                  height: isVerySmallMobile ? 380 : (isSmallMobile ? 400 : 420),
                  padding: EdgeInsets.symmetric(horizontal: isVerySmallMobile ? 8 : (isSmallMobile ? 12 : 16)),
                  child: _buildPodium(topThree, maxPrice, isVerySmallMobile, isSmallMobile, isMobile),
                ),
              ),
            ),
          ],

          // Espace entre pieds de podium et bouton
          SizedBox(height: isVerySmallMobile ? 16 : (isSmallMobile ? 20 : 24)),
          // Bouton nouvelle recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showSearchModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  podiumMsg01,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Autres pays
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MediaQuery.of(context).size.width < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podiumMsg02,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            podiumMsg03,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: Colors.green[600]),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text(
                        podiumMsg02,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          'Comparaison des prix en Europe',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.green[600]),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (otherCountries.isNotEmpty)
            _buildOtherCountries(otherCountries),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = _getCurrentImageUrl();
    final hasMultipleImages = _productData?['aImageLink'] != null && 
        _productData!['aImageLink'] is List &&
        (_productData!['aImageLink'] as List).length > 1;

    return Stack(
      children: [
        // Image avec animation et clic pour plein écran
        GestureDetector(
          onTap: _showFullscreenImage,
          child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white, // Background blanc
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[400],
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.image,
                  size: 64,
                  color: Colors.grey[400],
                ),
        ),
        ),
        
        
        // Boutons de navigation
        if (hasMultipleImages) ...[
          Positioned(
            left: 8,
            top: 80,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _prevImage,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 80,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _nextImage,
                ),
              ),
            ),
          ),
          
        ],
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentQuantity > 1 ? () {
            if (mounted) setState(() => _currentQuantity--);
          } : null,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _currentQuantity > 1 ? const Color(0xFFBBDEFB) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, size: 20),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _currentQuantity.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            if (mounted) setState(() => _currentQuantity++);
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF81D4FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree, double maxPrice, bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    // Réorganiser pour avoir 2, 1, 3 (argent, or, bronze)
    final arranged = [
      if (topThree.length > 1) topThree[1], // 2ème place
      if (topThree.isNotEmpty) topThree[0],  // 1ère place
      if (topThree.length > 2) topThree[2],  // 3ème place
    ];

    return Container(
      height: isVerySmallMobile ? 380 : (isSmallMobile ? 400 : 420),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: arranged.asMap().entries.map((entry) {
          final visualIndex = entry.key;
          final article = entry.value;
          
          // Déterminer le rang réel (pas l'index visuel)
          int realRank;
          if (visualIndex == 0) realRank = 2; // Argent à gauche
          else if (visualIndex == 1) realRank = 1; // Or au centre
          else realRank = 3; // Bronze à droite


          return Container(
            width: isVerySmallMobile 
                ? (realRank == 1 ? 120 : 100)
                : (isSmallMobile 
                    ? (realRank == 1 ? 130 : 110)
                    : (realRank == 1 ? 140 : 120)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildPodiumCard(article, realRank, maxPrice, isVerySmallMobile, isSmallMobile, isMobile),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> article, int rank, double maxPrice, bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    final cardColor = rank == 1 
        ? const Color(0xFFFFFBE6) 
        : (rank == 2 ? const Color(0xFFF5F5F5) : const Color(0xFFFFF3E0));
    final borderColor = rank == 1 
        ? const Color(0xFFFFB300) 
        : (rank == 2 ? const Color(0xFF90A4AE) : const Color(0xFFFF6F00));
    
    // Calculer l'écart de prix
    final currentPrice = _extractPrice(article['sPrice'] ?? '');
    final priceDifference = maxPrice - currentPrice;
    final isEconomy = priceDifference > 0;
    
    // Vérifier si tous les prix sont identiques
    final allPricesSame = _checkAllPricesSame();
    
    // Vérifier si c'est le pays de l'utilisateur
    final isUserCountry = _userCountryCode != null && 
        article['sPays']?.toString().toLowerCase() == _userCountryCode!.toLowerCase();

    final podiumHeight = isVerySmallMobile 
        ? (rank == 1 ? 80.0 : (rank == 2 ? 65.0 : 50.0))
        : (isSmallMobile 
            ? (rank == 1 ? 90.0 : (rank == 2 ? 72.0 : 55.0))
            : (rank == 1 ? 100.0 : (rank == 2 ? 80.0 : 60.0)));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Carte du pays
        Container(
          margin: EdgeInsets.symmetric(horizontal: isVerySmallMobile ? 0.5 : 1),
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallMobile ? 6 : (isSmallMobile ? 8 : 10),
            vertical: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12),
          ),
          constraints: BoxConstraints(
            minHeight: isVerySmallMobile
                ? (rank == 1 ? 250 : (rank == 2 ? 180 : 200))
                : (isSmallMobile
                    ? (rank == 1 ? 270 : (rank == 2 ? 200 : 220))
                    : (rank == 1 ? 290 : (rank == 2 ? 220 : 240))),
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête (drapeau + pays + IKEA + icônes à droite)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    // Drapeau à gauche (toujours affiché)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: article['sPaysDrapeau'] != null
                            ? Image.network(
                                ApiConfig.getProxiedImageUrl('https://jirig.be${article['sPaysDrapeau']}'),
                                width: 24,
                                height: 16,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Erreur chargement drapeau: ${article['sPaysDrapeau']}');
                                  print('❌ URL complète: ${ApiConfig.getProxiedImageUrl('https://jirig.be${article['sPaysDrapeau']}')}');
                                  return Container(
                                    width: 24,
                                    height: 16,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.flag, size: 12, color: Colors.grey[400]),
                                  );
                                },
                              )
                            : Container(
                                width: 24,
                                height: 16,
                                color: Colors.grey[200],
                                child: Icon(Icons.flag, size: 12, color: Colors.grey[400]),
                              ),
                      ),
                    ),
                    // Nom du pays et IKEA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            article['sPays'] ?? 'Pays',
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 10 : (isSmallMobile ? 11 : 12),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isVerySmallMobile ? 0.5 : 1),
                          Text(
                            'IKEA',
                            style: TextStyle(
                              fontSize: isVerySmallMobile ? 8 : (isSmallMobile ? 9 : 10),
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Icône Home pour le pays de l'utilisateur
                    if (isUserCountry)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home, size: 14, color: Colors.white),
                    ),
                    // Trophée pour la 1ère place
                    if (rank == 1 && !isUserCountry)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Color(0xFFFFD54F), shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_events, size: 12, color: Color(0xFF7A5F00)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              
              // Prix centré
              Text(
                article['sPrice']?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: isVerySmallMobile ? 16 : (isSmallMobile ? 17 : 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: isVerySmallMobile ? 3 : 4),
              
              
              // Badge d'écart de prix (seulement si les prix ne sont pas tous identiques)
              if (priceDifference.abs() > 0.01 && !allPricesSame)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12),
                    vertical: isVerySmallMobile ? 6 : (isSmallMobile ? 7 : 8),
                  ),
                  decoration: BoxDecoration(
                    color: isEconomy ? const Color(0xFF86EFAC) : Colors.red[300], // Tailwind green-300
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isEconomy 
                        ? '-${priceDifference.toStringAsFixed(2)}€'
                        : '+${priceDifference.abs().toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: isVerySmallMobile ? 10 : (isSmallMobile ? 11 : 12),
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Texte noir
                    ),
                  ),
                ),
              SizedBox(
                height: isVerySmallMobile
                    ? (rank == 2 ? 20 : (rank == 1 ? 25 : (rank == 3 ? 15 : 60)))
                    : (isSmallMobile
                        ? (rank == 2 ? 25 : (rank == 1 ? 28 : (rank == 3 ? 20 : 65)))
                        : (rank == 2 ? 30 : (rank == 1 ? 30 : (rank == 3 ? 25 : 70)))),
              ),
              
              // Quantité
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: _currentQuantity > 1 
                        ? SystemMouseCursors.click 
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          if (_currentQuantity > 1) {
                            _currentQuantity--;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _currentQuantity > 1 
                            ? const Color(0xFF64B5F6)  // Bleu vif quand cliquable
                              : const Color(0xFFE3F2FD), // Bleu très clair quand à 1
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove, 
                        size: 16, 
                        color: _currentQuantity > 1 
                            ? Colors.white  // Blanc quand cliquable
                              : Colors.grey[300], // Gris clair quand à 1
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _currentQuantity.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _currentQuantity++;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF64B5F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bouton cœur
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Ajouter au panier
                    _addToCart(article);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),  // Toujours bleu actif
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,  // Toujours blanc
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isVerySmallMobile ? 4 : (isSmallMobile ? 6 : 8)),
        
        // Bloc de base du podium
        Container(
          height: podiumHeight,
          margin: EdgeInsets.symmetric(horizontal: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16)),
          decoration: BoxDecoration(
            gradient: _getPodiumGradient(rank),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: _getPodiumColor(rank).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Effet de brillance sur le bloc
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: podiumHeight * 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Numéro du rang
              Center(
                child: Container(
                  width: isVerySmallMobile ? 32 : (isSmallMobile ? 36 : 40),
                  height: isVerySmallMobile ? 32 : (isSmallMobile ? 36 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: TextStyle(
                        fontSize: isVerySmallMobile ? 18 : (isSmallMobile ? 20 : 22),
                        fontWeight: FontWeight.bold,
                        color: _getPodiumNumberColor(rank),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildOtherCountries(List<Map<String, dynamic>> countries) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        
        // Vérifier si c'est le pays de l'utilisateur
        final isUserCountry = _userCountryCode != null && 
            country['sPays']?.toString().toLowerCase() == _userCountryCode!.toLowerCase();
        
        // Animation ripple effect : chaque pays apparaît avec un délai progressif
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 80)), // Délai progressif (ripple)
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCirc, // Courbe circulaire (effet ripple)
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2), // Scale de 0.8 → 1.0
              child: Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0), // Slide depuis la gauche
                  child: child,
                ),
              ),
            );
          },
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 64, // Hauteur augmentée pour éviter l'overflow
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUserCountry ? Colors.green[400]! : Colors.grey[300]!,
              width: isUserCountry ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Centrer verticalement
            children: [
              // Drapeau
              if (country['sPaysDrapeau'] != null)
                Container(
                  width: 24,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  child: Image.network(
                    ApiConfig.getProxiedImageUrl('https://jirig.be${country['sPaysDrapeau']}'),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.flag, size: 12, color: Colors.grey[400]);
                    },
                  ),
                ),
              
              // Infos pays
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
                  children: [
                    Text(
                      country['sPays'] ?? 'Pays',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Text(
                      'IKEA',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              
              // Icône Home pour le pays de l'utilisateur
              if (isUserCountry)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home,
                    size: 16,
                    color: Colors.white,
                ),
              ),
              
              // Prix
              Text(
                country['sPrice']?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900, // ✅ Font weight augmenté
                  color: Color(0xFF2563EB), // ✅ text-blue-600 comme SNAL-Project
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Wishlist
              StatefulBuilder(
                builder: (context, setState) {
                  bool isHovered = false;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _addToWishlist(country);
                      },
                      icon: Icon(
                        isHovered ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isHovered ? Colors.red : Colors.grey[700],
                      ),
                      label: Text(
                        'Wishlist',
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.red : Colors.grey[700],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isHovered ? Colors.red : Colors.grey[700],
                        side: BorderSide(
                          color: isHovered ? Colors.red : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: isHovered ? Colors.blue[100] : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(String appHeaderHome, String scancodeTitle, String appHeaderWishlist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.home, appHeaderHome),
              _buildBottomNavItem(Icons.qr_code_scanner, scancodeTitle),
              _buildBottomNavItem(Icons.photo_library, 'Photos'),
              _buildBottomNavItem(Icons.favorite_border, appHeaderWishlist),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(height: 4),
        ],
      ),
    );
  }


  bool _checkAllPricesSame() {
    if (_productData == null || _productData!['aComparaisonUi'] == null) {
      return false;
    }
    
    final articles = _productData!['aComparaisonUi'] as List;
    if (articles.length < 2) return false;
    
    // Prendre le premier prix comme référence
    final firstPrice = _extractPrice(articles.first['sPrice'] ?? '');
    
    // Vérifier si tous les autres prix sont identiques au premier
    for (int i = 1; i < articles.length; i++) {
      final price = _extractPrice(articles[i]['sPrice'] ?? '');
      if ((price - firstPrice).abs() > 0.01) {
        return false; // Prix différent trouvé
      }
    }
    
    return true; // Tous les prix sont identiques
  }

  double _extractPrice(String priceString) {
    // ✅ Nettoyer la chaîne de prix (enlever €, espaces, etc.)
    final cleanedPrice = priceString
        .replaceAll('€', '')           // Enlever €
        .replaceAll(' ', '')           // Enlever espaces
        .replaceAll(',', '.')          // Remplacer virgule par point
        .trim();
    
    // ✅ Extraire uniquement les chiffres et le point décimal
    final match = RegExp(r'\d+\.?\d*').firstMatch(cleanedPrice);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  /// Ajouter un article au panier (basé sur SNAL-Project)
  Future<void> _addToCart(Map<String, dynamic> article) async {
    try {
      if (_productData == null) return;

      // Récupérer le profil utilisateur
      final profileData = await LocalStorageService.getProfile();
      if (profileData == null) {
        _showSnackBar('Veuillez vous connecter pour ajouter au panier');
        return;
      }

      final iProfile = profileData['iProfile'];
      final iBasket = profileData['iBasket'];
      final sPaysFav = profileData['sPaysFav'] ?? '';
      
      print('🔍 DEBUG profileData (_addToCart):');
      print('   iProfile: $iProfile');
      print('   iBasket: $iBasket');
      print('   sPaysLangue: ${profileData['sPaysLangue']}');
      print('   sPaysFav: "$sPaysFav" (length: ${sPaysFav.length})');
      print('   Toutes les clés: ${profileData.keys.toList()}');
      
      if (iProfile == null) {
        _showSnackBar('Profil utilisateur invalide');
        return;
      }

      // Récupérer les données du produit (comme SNAL-Project)
      final sCodeArticle = _productData!['sCodeArticleCrypt'] ?? '';
      final sPays = article['sLangueIso'] ?? article['sPays'] ?? ''; // ✅ Utiliser sLangueIso (code pays: DE, FR, ES...)
      final iPrice = _extractPrice(article['sPrice'] ?? '');
      
      print('📦 Données du produit (_addToCart):');
      print('   sCodeArticle: $sCodeArticle');
      print('   sPays (code): $sPays');
      print('   sPays (nom): ${article['sPays']}');
      print('   iPrice: $iPrice');
      
      if (sCodeArticle.isEmpty || sPays.isEmpty || iPrice <= 0) {
        _showSnackBar('Données du produit invalides');
        return;
      }

      // ✅ Pas de loader nécessaire - redirection immédiate

      // ✅ iBasket est une chaîne cryptée, ne PAS la parser en int
      final iBasketStr = iBasket?.toString() ?? '';
      
      print('🛒 Ajout panier - iBasket: $iBasketStr');
      print('🛒 Pays sélectionné (code): $sPays');
      
      // Ajouter l'article au panier
      final result = await _apiService.addToWishlist(
        sCodeArticle: sCodeArticle,
        sPays: sPays,
        iPrice: iPrice,
        iQuantity: _currentQuantity,
        currentIBasket: iBasketStr,
        iProfile: iProfile.toString(),
        sPaysLangue: profileData['sPaysLangue'] ?? 'FR/FR',
        sPaysFav: profileData['sPaysFav'] ?? '',
      );

      print('📥 Résultat complet de addToWishlist: $result');
      
      if (result != null && result['success'] == true) {
        // ⚠️ Vérifier s'il y a une erreur SQL même si success=true (comme dans vos logs)
        if (result['data'] != null && result['data'] is List && result['data'].isNotEmpty) {
          final firstData = result['data'][0];
          
          // Vérifier si c'est un objet avec une erreur SQL
          if (firstData is Map && firstData.containsKey('JSON_F52E2B61-18A1-11d1-B105-00805F49916B')) {
            final jsonStr = firstData['JSON_F52E2B61-18A1-11d1-B105-00805F49916B'];
            print('⚠️ Réponse contient un JSON SQL: $jsonStr');
            
            // Vérifier si c'est une erreur
            if (jsonStr != null && jsonStr.toString().contains('sError')) {
              print('❌ ERREUR SQL détectée même avec success=true !');
              _showSnackBar('Erreur SQL lors de l\'ajout au panier');
              return;
            }
          }
        }
        
        print('✅ Article ajouté/mis à jour dans le panier (pas d\'erreur SQL)');
        
        // Sauvegarder le nouveau iBasket
        if (result['data'] != null && result['data'] is List && result['data'].isNotEmpty) {
          final newIBasket = result['data'][0]['iBasket']?.toString();
          if (newIBasket != null && newIBasket.isNotEmpty) {
            await LocalStorageService.saveProfile({
              'iProfile': iProfile.toString(),
              'iBasket': newIBasket,
              'sPaysLangue': profileData['sPaysLangue'] ?? '',
            });
            print('💾 Nouveau iBasket sauvegardé: $newIBasket');
          }
        }
        
        // Afficher un message de succès
        // _showSnackBar(
        //   '✓ Article ajouté au panier (${article['sPays']}) !',
        //   isSuccess: true,
        // );
        
        // ⏱️ Attendre un peu pour s'assurer que le serveur a traité l'ajout
        print('⏱️ Attente de 300ms pour s\'assurer que le serveur a bien traité l\'ajout...');
        await Future.delayed(const Duration(milliseconds: 300));
        
        // ✅ Redirection vers wishlist avec timestamp pour forcer le rechargement
        print('🔄 Redirection vers /wishlist depuis _addToCart');
        if (mounted) {
          print('✅ Widget monté, redirection en cours...');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          context.go('/wishlist?refresh=$timestamp');
        } else {
          print('❌ Widget non monté, redirection annulée');
        }
      } else if (result != null && result['error'] != null) {
        print('❌ Erreur addToWishlist: ${result['error']}');
        _showSnackBar('Erreur: ${result['error']}');
      } else {
        print('❌ Réponse invalide de addToWishlist: $result');
        _showSnackBar('Erreur lors de l\'ajout au panier');
      }
      
    } catch (e) {
      print('Erreur _addToCart: $e');
      _showSnackBar('Erreur lors de l\'ajout au panier');
    }
  }

  /// Ajouter un article à la wishlist (basé sur SNAL-Project)
  Future<void> _addToWishlist(Map<String, dynamic> country) async {
    print('\n🚀 === DÉBUT _addToWishlist ===');
    print('🌍 Pays reçu: ${country['sPays']}');
    print('💰 Prix reçu: ${country['sPrice']}');
    
    try {
      if (_productData == null) {
        print('❌ _productData est null - RETOUR');
        return;
      }

      print('✅ _productData OK');

      // Récupérer le profil utilisateur
      final profileData = await LocalStorageService.getProfile();
      if (profileData == null) {
        print('❌ profileData est null - RETOUR');
        _showSnackBar('Veuillez vous connecter pour ajouter à la wishlist');
        return;
      }

      print('✅ profileData récupéré');

      final iProfile = profileData['iProfile'];
      final iBasket = profileData['iBasket'];
      final sPaysFav = profileData['sPaysFav'] ?? '';
      
      print('🔍 DEBUG profileData (_addToWishlist):');
      print('   iProfile: $iProfile');
      print('   iBasket: $iBasket');
      print('   sPaysLangue: ${profileData['sPaysLangue']}');
      print('   sPaysFav: "$sPaysFav" (length: ${sPaysFav.length})');
      print('   Toutes les clés: ${profileData.keys.toList()}');
      
      if (iProfile == null) {
        print('❌ iProfile est null - RETOUR');
        _showSnackBar('Profil utilisateur invalide');
        return;
      }

      print('✅ iProfile OK');

      // Récupérer les données du produit (comme SNAL-Project)
      final sCodeArticle = _productData!['sCodeArticleCrypt'] ?? '';
      final sPays = country['sLangueIso'] ?? country['sPays'] ?? ''; // ✅ Utiliser sLangueIso (code pays: DE, FR, ES...)
      final iPrice = _extractPrice(country['sPrice'] ?? '');
      
      print('📦 Données du produit:');
      print('   sCodeArticle: $sCodeArticle');
      print('   sPays (code): $sPays');
      print('   sPays (nom): ${country['sPays']}');
      print('   iPrice: $iPrice');
      
      if (sCodeArticle.isEmpty || sPays.isEmpty || iPrice <= 0) {
        print('❌ Données invalides - RETOUR');
        print('   sCodeArticle.isEmpty: ${sCodeArticle.isEmpty}');
        print('   sPays.isEmpty: ${sPays.isEmpty}');
        print('   iPrice <= 0: ${iPrice <= 0}');
        _showSnackBar('Données du produit invalides');
        return;
      }

      print('✅ Données du produit OK');

      // ✅ iBasket est une chaîne cryptée, ne PAS la parser en int
      final iBasketStr = iBasket?.toString() ?? '';
      
      print('🛒 Ajout wishlist - iBasket: $iBasketStr');
      print('🛒 Pays sélectionné: $sPays');
      print('🔄 APPEL addToWishlist...');
      
      // Ajouter l'article à la wishlist
      final result = await _apiService.addToWishlist(
        sCodeArticle: sCodeArticle,
        sPays: sPays,
        iPrice: iPrice,
        iQuantity: _currentQuantity,
        currentIBasket: iBasketStr,
        iProfile: iProfile.toString(),
        sPaysLangue: profileData['sPaysLangue'] ?? 'FR/FR',
        sPaysFav: profileData['sPaysFav'] ?? '',
      );

      print('📥 Résultat complet de addToWishlist: $result');
      
      if (result != null && result['success'] == true) {
        // ⚠️ Vérifier s'il y a une erreur SQL même si success=true (comme dans vos logs)
        if (result['data'] != null && result['data'] is List && result['data'].isNotEmpty) {
          final firstData = result['data'][0];
          
          // Vérifier si c'est un objet avec une erreur SQL
          if (firstData is Map && firstData.containsKey('JSON_F52E2B61-18A1-11d1-B105-00805F49916B')) {
            final jsonStr = firstData['JSON_F52E2B61-18A1-11d1-B105-00805F49916B'];
            print('⚠️ Réponse contient un JSON SQL: $jsonStr');
            
            // Vérifier si c'est une erreur
            if (jsonStr != null && jsonStr.toString().contains('sError')) {
              print('❌ ERREUR SQL détectée même avec success=true !');
              _showSnackBar('Erreur SQL lors de l\'ajout à la wishlist');
              return;
            }
          }
        }
        
        print('✅ Article ajouté/mis à jour dans la wishlist (pas d\'erreur SQL)');
        
        // Sauvegarder le nouveau iBasket
        if (result['data'] != null && result['data'] is List && result['data'].isNotEmpty) {
          final newIBasket = result['data'][0]['iBasket']?.toString();
          if (newIBasket != null && newIBasket.isNotEmpty) {
            await LocalStorageService.saveProfile({
              'iProfile': iProfile.toString(),
              'iBasket': newIBasket,
              'sPaysLangue': profileData['sPaysLangue'] ?? '',
            });
            print('💾 Nouveau iBasket sauvegardé: $newIBasket');
          }
        }
        
        // Afficher un message de succès
        // _showSnackBar(
        //   '✓ Article ajouté à la wishlist (${country['sPays']}) !',
        //   isSuccess: true,
        // );
        
        // ⏱️ Attendre un peu pour s'assurer que le serveur a traité l'ajout
        print('⏱️ Attente de 300ms pour s\'assurer que le serveur a bien traité l\'ajout...');
        await Future.delayed(const Duration(milliseconds: 300));
        
        // ✅ Redirection vers wishlist avec timestamp pour forcer le rechargement
        print('🔄 Redirection vers /wishlist depuis _addToWishlist');
        if (mounted) {
          print('✅ Widget monté, redirection en cours...');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          context.go('/wishlist?refresh=$timestamp');
        } else {
          print('❌ Widget non monté, redirection annulée');
        }
      } else if (result != null && result['error'] != null) {
        print('❌ Erreur addToWishlist: ${result['error']}');
        _showSnackBar('Erreur: ${result['error']}');
      } else {
        print('❌ Réponse invalide de addToWishlist: $result');
        _showSnackBar('Erreur lors de l\'ajout à la wishlist');
      }
    } catch (e) {
      print('Erreur _addToWishlist: $e');
      _showSnackBar('Erreur lors de l\'ajout à la wishlist');
    }
  }

  /// Afficher un message snackbar
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}