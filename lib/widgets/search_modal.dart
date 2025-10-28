import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/country_service.dart';
import '../services/translation_service.dart';
import '../services/local_storage_service.dart';
import '../models/country.dart';
import '../config/api_config.dart';
import 'qr_scanner_modal.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({Key? key}) : super(key: key);

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedCountries = ['BE']; // Par défaut Belgique
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _errorMessage = '';
  bool _hasSearched = false;
  
  // Gestion du profil utilisateur et du token
  String? _userToken;
  String? _userBasket;
  
  // Liste des pays disponibles (chargée dynamiquement)
  List<Country> _availableCountries = [];
  bool _isLoadingCountries = true;
  
  // Map des drapeaux emoji
  final Map<String, String> _countryFlags = {
    'BE': '🇧🇪',
    'DE': '🇩🇪',
    'ES': '🇪🇸',
    'FR': '🇫🇷',
    'IT': '🇮🇹',
    'NL': '🇳🇱',
    'PT': '🇵🇹',
    'LU': '🇱🇺',
    'EN': '🇬🇧',
  };

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
    
    // Initialiser les services et charger les données
    _initializeServices();
  }

  /// Initialiser les services API et charger les pays
  Future<void> _initializeServices() async {
    try {
      // 1. Initialiser l'API service
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.initialize();
      
      // 2. Initialiser le profil utilisateur pour obtenir un token
      await _initializeProfile();
      
      // 3. Charger les pays disponibles
      await _loadCountries();
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des services: $e');
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  /// Récupérer le token utilisateur depuis LocalStorage (déjà initialisé dans app.dart)
  Future<void> _initializeProfile() async {
    try {
      // ✅ Récupérer le profil depuis LocalStorage (déjà initialisé dans app.dart)
      final profileData = await LocalStorageService.getProfile();
      setState(() {
        _userToken = profileData?['iProfile']?.toString();
        _userBasket = profileData?['iBasket']?.toString();
      });
      print('✅ Token récupéré depuis LocalStorage: ${_userToken != null ? "✅" : "❌"}');
    } catch (e) {
      print('❌ Erreur lors de la récupération du profil: $e');
    }
  }

  /// Charger les pays disponibles depuis l'API
  Future<void> _loadCountries() async {
    try {
      final countryService = CountryService();
      await countryService.initialize();
      
      final countries = countryService.getAllCountries();
      
      setState(() {
        _availableCountries = countries;
        _isLoadingCountries = false;
      });
      
      print('✅ ${countries.length} pays chargés depuis l\'API');
    } catch (e) {
      print('❌ Erreur lors du chargement des pays: $e');
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      // Arrêter les animations avant de les disposer
      if (_slideController.isAnimating) {
        _slideController.stop();
      }
      if (_fadeController.isAnimating) {
        _fadeController.stop();
      }
      _slideController.dispose();
      _fadeController.dispose();
      _searchController.dispose();
    } catch (e) {
      print('Erreur lors du dispose de SearchModal: $e');
    }
    super.dispose();
  }

  Future<void> _closeModal() async {
    try {
      if (mounted && _slideController.isAnimating == false) {
        await _slideController.reverse();
      }
      if (mounted && _fadeController.isAnimating == false) {
        await _fadeController.reverse();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Erreur lors de la fermeture du modal: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _toggleCountry(String country) {
    setState(() {
      if (_selectedCountries.contains(country)) {
        _selectedCountries.remove(country);
      } else {
        _selectedCountries.add(country);
      }
    });
  }

  void _onInputCode(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }

    String formatted = '';
    if (digitsOnly.length > 6) {
      formatted = '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3, 6)}.${digitsOnly.substring(6)}';
    } else if (digitsOnly.length > 3) {
      formatted = '${digitsOnly.substring(0, 3)}.${digitsOnly.substring(3)}';
    } else {
      formatted = digitsOnly;
    }

    if (_searchController.text != formatted) {
      _searchController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.fromPosition(
          TextPosition(offset: formatted.length),
        ),
      );
    }

    if (digitsOnly.length >= 3) {
      _searchProduct(digitsOnly);
    } else {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isSearching = false;
        _hasSearched = false;
      });
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _searchResults = [];
      _hasSearched = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.initialize();
      
      // Utiliser le token si disponible (comme dans product_search_screen)
      final results = await apiService.searchArticle(
        query.trim(),
        token: _userToken ?? '',
        limit: 10,
      );
      
      setState(() {
        _searchResults = results.cast<Map<String, dynamic>>();
        _isSearching = false;
        if (results.length == 0) {
          _errorMessage = 'Aucun produit trouvé pour "$query"';
        }
        
        // Debug: Afficher les champs disponibles dans les résultats
        if (results.isNotEmpty) {
          print('🔍 DEBUG - Premier résultat de recherche:');
          final firstResult = results.first as Map<String, dynamic>;
          print('📋 Champs disponibles: ${firstResult.keys.toList()}');
          print('📝 sDescr: "${firstResult['sDescr']}"');
          print('📝 sName: "${firstResult['sName']}"');
          print('📝 sCodeArticle: "${firstResult['sCodeArticle']}"');
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Erreur de recherche: $e';
      });
    }
  }

  void _selectProduct(Map<String, dynamic> product) async {
    final codeArticle = product['sCodeArticle'] ?? '';
    final codeArticleCrypt = product['sCodeArticleCrypt'] ?? '';
    
    // Fermer le modal d'abord
    await _closeModal();
    
    // Attendre que le modal soit complètement fermé
    if (!mounted) return;
    
    // Utiliser replace pour remplacer la route actuelle et forcer le rechargement
    // Cela va déclencher initState dans PodiumScreen avec les nouvelles données
    context.replace('/podium/$codeArticle?crypt=$codeArticleCrypt');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallMobile = screenWidth < 361;   // Galaxy Fold fermé, Galaxy S8+ (≤360px)
    final isSmallMobile = screenWidth < 431;       // iPhone XR/14 Pro Max, Pixel 7, Galaxy S20/A51 (361-430px)
    final isMobile = screenWidth < 768;            // Tous les mobiles standards (431-767px)
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
            child: GestureDetector(
              onTap: _closeModal,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: GestureDetector(
                          onTap: () {}, // Empêche la fermeture au tap sur le contenu
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight: screenHeight * 0.92,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: _buildModalContent(isVerySmallMobile, isSmallMobile, isMobile),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalContent(bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          margin: EdgeInsets.only(
            top: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12),
            bottom: isVerySmallMobile ? 6 : (isSmallMobile ? 7 : 8),
          ),
          width: isVerySmallMobile ? 35 : 40,
          height: isVerySmallMobile ? 3 : 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // En-tête avec fermeture
        Padding(
          padding: EdgeInsets.fromLTRB(
            isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20),
            isVerySmallMobile ? 6 : (isSmallMobile ? 7 : 8),
            isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20),
            isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16),
          ),
          child: Consumer<TranslationService>(
            builder: (context, translationService, child) {
              return Row(
                children: [
                  Text(
                    translationService.translate('FRONTPAGE_Msg05'),
                    style: TextStyle(
                      fontSize: isVerySmallMobile ? 18 : (isSmallMobile ? 20 : 22),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _closeModal,
                    child: Container(
                      width: isVerySmallMobile ? 32 : (isSmallMobile ? 34 : 36),
                      height: isVerySmallMobile ? 32 : (isSmallMobile ? 34 : 36),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Color(0xFF666666),
                        size: isVerySmallMobile ? 18 : (isSmallMobile ? 19 : 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20),
                0,
                isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20),
                isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bouton Scanner
                  _buildScanButton(isVerySmallMobile, isSmallMobile, isMobile),
                  
                  SizedBox(height: isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20)),
                  
                  // Divider avec texte
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16)),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isVerySmallMobile ? 12 : (isSmallMobile ? 13 : 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  
                  SizedBox(height: isVerySmallMobile ? 16 : (isSmallMobile ? 18 : 20)),
                  
                  // Champ de recherche moderne
                  _buildSearchField(isVerySmallMobile, isSmallMobile, isMobile),
                  
                  SizedBox(height: isVerySmallMobile ? 20 : (isSmallMobile ? 22 : 24)),
                  
                  // Section des pays
                  _buildCountrySection(isVerySmallMobile, isSmallMobile, isMobile),
                  
                  SizedBox(height: isVerySmallMobile ? 20 : (isSmallMobile ? 22 : 24)),
                  
                  // Résultats ou états vides avec fond blanc pendant la recherche
                  Container(
                    color: _isSearching ? Colors.white : Colors.transparent,
                    child: _isSearching
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  LoadingAnimationWidget.progressiveDots(
                                    color: Colors.blue,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Recherche en cours...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildSearchResults(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    final translationService = Provider.of<TranslationService>(context, listen: false);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Fermer ce modal puis ouvrir le modal scanner avec animation Fade+Scale
            await _closeModal();
            if (!mounted) return;
            showModal(
              context: context,
              configuration: const FadeScaleTransitionConfiguration(
                transitionDuration: Duration(milliseconds: 280),
                reverseTransitionDuration: Duration(milliseconds: 220),
                barrierDismissible: true,
              ),
              builder: (context) => const QrScannerModal(),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isVerySmallMobile ? 14 : (isSmallMobile ? 16 : 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: isVerySmallMobile ? 20 : (isSmallMobile ? 22 : 24),
                ),
                SizedBox(width: isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12)),
                Text(
                  translationService.translate('FRONTPAGE_Msg08'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchController.text.isNotEmpty 
              ? const Color(0xFF2563EB) 
              : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onInputCode,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: 'Ex: 123.456.789',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _searchController.text.isNotEmpty 
                ? const Color(0xFF2563EB) 
                : Colors.grey[400],
            size: isVerySmallMobile ? 20 : (isSmallMobile ? 21 : 22),
          ),
          suffixIcon: _isSearching
              ? Padding(
                  padding: EdgeInsets.all(isVerySmallMobile ? 12 : (isSmallMobile ? 13 : 14)),
                  child: SizedBox(
                    width: isVerySmallMobile ? 18 : 20,
                    height: isVerySmallMobile ? 18 : 20,
                    child: LoadingAnimationWidget.progressiveDots(
                      color: Colors.blue,
                      size: isVerySmallMobile ? 18 : 20,
                    ),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: isVerySmallMobile ? 18 : (isSmallMobile ? 19 : 20),
                      ),
                      padding: EdgeInsets.all(isVerySmallMobile ? 8 : (isSmallMobile ? 10 : 12)),
                      constraints: BoxConstraints(
                        minWidth: isVerySmallMobile ? 36 : (isSmallMobile ? 38 : 40),
                        minHeight: isVerySmallMobile ? 36 : (isSmallMobile ? 38 : 40),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _errorMessage = '';
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: isVerySmallMobile ? 16 : (isSmallMobile ? 17 : 18),
            horizontal: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySection(bool isVerySmallMobile, bool isSmallMobile, bool isMobile) {
    final translationService = Provider.of<TranslationService>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translationService.translate('FRONTPAGE_Msg04'),
          style: TextStyle(
            fontSize: isVerySmallMobile ? 13 : (isSmallMobile ? 14 : 15),
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isVerySmallMobile ? 10 : (isSmallMobile ? 11 : 12)),
        _isLoadingCountries
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: LoadingAnimationWidget.progressiveDots(
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            )
          : _buildCountryChips(),
      ],
    );
  }

  Widget _buildCountryChips() {
    // Si pas de pays chargés, utiliser une liste par défaut
    // Vérification robuste pour éviter les erreurs en Web
    if (_availableCountries.length == 0) {
      return Wrap(
        spacing: 8,
        runSpacing: 10,
        children: ['BE', 'DE', 'ES', 'FR', 'IT', 'NL', 'PT'].map((code) {
          final isSelected = _selectedCountries.contains(code);
          
          return GestureDetector(
            onTap: () => _toggleCountry(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _countryFlags[code] ?? '🏳️',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // Utiliser les pays chargés depuis l'API
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _availableCountries.map((country) {
        final countryCode = country.sPays.toUpperCase();
        final isSelected = _selectedCountries.contains(countryCode);
        
        return GestureDetector(
          onTap: () => _toggleCountry(countryCode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _countryFlags[countryCode] ?? '🏳️',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched && _searchResults.length == 0 && _errorMessage.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_searchResults.length > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ..._searchResults.map((product) => _buildProductCard(product)).toList(),
        ],
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Consumer<TranslationService>(
      builder: (context, translationService, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  size: 36,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translationService.translate('FRONTPAGE_Msg05'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scannez un code-barres ou\nsaisissez un code article',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(
            'Aucun résultat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Vérifier si le produit est disponible
    final isAvailable = product['bAvailable'] == true || 
                       product['bAvailable'] == 1 || 
                       product['bAvailable'] == '1' ||
                       product['bAvailable'] == null; // Par défaut disponible si non spécifié
    
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5, // Griser si indisponible
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAvailable ? Colors.grey[200]! : Colors.grey[300]!),
          boxShadow: isAvailable ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable ? () => _selectProduct(product) : null, // Désactiver le clic si indisponible
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image du produit
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: _getProductImage(product),
                      ),
                      // Badge "Indisponible" si nécessaire
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Indisponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 14),
                  
                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['sDescr'] ?? product['sName'] ?? product['sTitle'] ?? product['sProductName'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Color(0xFF1A1A1A) : Colors.grey[600],
                            letterSpacing: -0.2,
                            decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['sCodeArticle'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                        if (product['iPrice'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${product['iPrice']} ${product['sCurrency'] ?? '€'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable ? Color(0xFF1A1A1A) : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  if (isAvailable)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getProductImage(Map<String, dynamic> product) {
    final imageUrl = _getFirstImageUrl(product);
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: 72,
          height: 72,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Erreur de chargement image: $error');
            return _buildDefaultImage();
          },
        ),
      );
    }
    
    return _buildDefaultImage();
  }

  /// Extraire l'URL de la première image valide (comme dans product_search_screen)
  String? _getFirstImageUrl(Map<String, dynamic> product) {
    if (product['aImageLink'] == null) {
      return null;
    }

    // Si c'est une chaîne XML, essayer d'extraire l'URL
    if (product['aImageLink'] is String) {
      final xmlString = product['aImageLink'] as String;
      final regex = RegExp(r'<sHyperlink>(.*?)<\/sHyperlink>', caseSensitive: false);
      final match = regex.firstMatch(xmlString);
      if (match != null) {
        final url = match.group(1) ?? '';
        if (url.isNotEmpty && !url.toLowerCase().contains('no_image')) {
          // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
          return ApiConfig.getProxiedImageUrl(url);
        }
      }
      return null;
    }

    // Si c'est une liste, chercher la première image valide
    if (product['aImageLink'] is List) {
      final imageLinks = product['aImageLink'] as List;
      if (imageLinks.length == 0) return null;
      
      for (var link in imageLinks) {
        if (link is Map && link['sHyperlink'] != null) {
          final hyperlink = link['sHyperlink'] as String;
          if (hyperlink.isNotEmpty && 
              !hyperlink.toLowerCase().contains('no_image') &&
              (hyperlink.toLowerCase().contains('.jpg') ||
               hyperlink.toLowerCase().contains('.jpeg') ||
               hyperlink.toLowerCase().contains('.png') ||
               hyperlink.toLowerCase().contains('.webp'))) {
            // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
            return ApiConfig.getProxiedImageUrl(hyperlink);
          }
        } else if (link is String && link.isNotEmpty) {
          if (!link.toLowerCase().contains('no_image')) {
            // Mobile-First: Utilise automatiquement le proxy en Web, URL directe en mobile
            return ApiConfig.getProxiedImageUrl(link);
          }
        }
      }
    }

    return null;
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }
}