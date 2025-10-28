import 'package:flutter/material.dart';

class PageLoader extends StatefulWidget {
  final bool show;
  final String? message;
  final Duration duration;
  final VoidCallback? onComplete;

  const PageLoader({
    super.key,
    this.show = true,
    this.message,
    this.duration = const Duration(seconds: 2),
    this.onComplete,
  });

  @override
  State<PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<PageLoader>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _dotsController;

  late Animation<double> _gradientAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Contrôleur pour l'animation du gradient
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Contrôleur pour l'animation des anneaux du logo
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Contrôleur pour l'animation du texte
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Contrôleur pour l'animation de la barre de progression
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Contrôleur pour l'animation des points
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Animations
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.linear,
    ));

    _textAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    _dotsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeInOut,
    ));

    // Démarrer l'animation de la barre de progression
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // Masquer le loader après la durée spécifiée
    Future.delayed(widget.duration, () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    try {
      // Arrêter toutes les animations avant de les disposer
      if (_gradientController.isAnimating) {
        _gradientController.stop();
      }
      if (_logoController.isAnimating) {
        _logoController.stop();
      }
      if (_textController.isAnimating) {
        _textController.stop();
      }
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      if (_dotsController.isAnimating) {
        _dotsController.stop();
      }
      
      _gradientController.dispose();
      _logoController.dispose();
      _textController.dispose();
      _progressController.dispose();
      _dotsController.dispose();
    } catch (e) {
      print('Erreur lors du dispose du PageLoader: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF667EEA),
              Color(0xFFE3D50D),
            ],
            stops: [
              0.0 + (_gradientAnimation.value * 0.5),
              1.0 - (_gradientAnimation.value * 0.5),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Effet de bulles flottantes
            _buildFloatingOrbs(),
            
            // Contenu principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo avec anneaux animés
                  _buildLogoContainer(isMobile),
                  
                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // Texte de chargement avec points
                  _buildLoadingText(isMobile),
                ],
              ),
            ),
            
            // Barre de progression en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildProgressBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Stack(
          children: [
            // Bulle 1
            Positioned(
              top: 100 + (50 * _gradientAnimation.value),
              left: 50 + (30 * _gradientAnimation.value),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Bulle 2
            Positioned(
              top: 200 + (40 * _gradientAnimation.value),
              right: 80 + (25 * _gradientAnimation.value),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Bulle 3
            Positioned(
              bottom: 150 + (35 * _gradientAnimation.value),
              left: 120 + (20 * _gradientAnimation.value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoContainer(bool isMobile) {
    final size = isMobile ? 100.0 : 120.0;
    
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anneau extérieur
              Transform.rotate(
                angle: _logoAnimation.value * 2 * 3.14159,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 5,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEDD446),
                        width: 5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Anneau intérieur (rotation inverse)
              Transform.rotate(
                angle: -_logoAnimation.value * 2 * 3.14159 * 1.5,
                child: Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 4,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0058CC),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Centre avec logo
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'JIRIG',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF667EEA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingText(bool isMobile) {
    return AnimatedBuilder(
      animation: _textAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: _textAnimation.value,
              child: Text(
                widget.message ?? 'Chargement en cours',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildLoadingDots(),
          ],
        );
      },
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final opacity = (_dotsAnimation.value - delay).clamp(0.0, 1.0);
            final dotOpacity = opacity > 0.5 ? (1.0 - opacity) * 2 : opacity * 2;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: dotOpacity,
                child: Text(
                  '.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: 4,
          width: double.infinity,
          color: Colors.white.withOpacity(0.1),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEDD446),
                    Color(0xFF0058CC),
                    Color(0xFFEDD446),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
