import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _blueRingController;
  late AnimationController _yellowRingController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation controller pour l'anneau bleu (rotation normale)
    _blueRingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    // Animation controller pour l'anneau jaune (rotation inverse)
    _yellowRingController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();
    
    // Animation controller pour la barre de progression
    _progressController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Animation controller pour le fade in (séparé, ne se répète pas)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de fade in (ne se répète pas)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // Animation de progression
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer le fade in et la progression
    _fadeController.forward();
    _progressController.forward();
    
    // Naviguer quand la progression est terminée
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Arrêter toutes les animations avant de naviguer
        _blueRingController.stop();
        _yellowRingController.stop();
        _progressController.stop();
        // ✅ Utiliser replace au lieu de go pour ne pas garder splash dans l'historique
        context.replace('/country-selection');
      }
    });
  }

  @override
  void dispose() {
    try {
      // Arrêter les animations avant de les disposer
      if (_blueRingController.isAnimating) {
        _blueRingController.stop();
      }
      if (_yellowRingController.isAnimating) {
        _yellowRingController.stop();
      }
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      if (_fadeController.isAnimating) {
        _fadeController.stop();
      }
      
      _blueRingController.dispose();
      _yellowRingController.dispose();
      _progressController.dispose();
      _fadeController.dispose();
    } catch (e) {
      print('Erreur lors du dispose du SplashScreen: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les insets de sécurité (notch, bottom bar, etc.)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: const Color(0xFF21252F),
      body: Stack(
        children: [
          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Jirig avec anneaux animés
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle de fond gris foncé
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3E5C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Chemin du cercle extérieur (pour anneau jaune)
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: CirclePathPainter(
                            color: const Color(0xFF3D4D6C),
                            strokeWidth: 5,
                            radiusOffset: 10,
                          ),
                        ),
                        // Chemin du cercle intérieur (pour anneau bleu)
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: CirclePathPainter(
                            color: const Color(0xFF3D4D6C),
                            strokeWidth: 5,
                            radiusOffset: 22,
                          ),
                        ),
                        // Anneau jaune sur cercle extérieur
                        AnimatedBuilder(
                          animation: _yellowRingController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(140, 140),
                              painter: MovingArcPainter(
                                color: const Color(0xFFFDD835),
                                progress: _yellowRingController.value,
                                arcLength: 3.14159 * 0.5, // 90 degrés
                                strokeWidth: 5,
                                clockwise: false,
                                radiusOffset: 10,
                              ),
                            );
                          },
                        ),
                        // Anneau bleu sur cercle intérieur
                        AnimatedBuilder(
                          animation: _blueRingController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(140, 140),
                              painter: MovingArcPainter(
                                color: const Color(0xFF0066FF),
                                progress: _blueRingController.value,
                                arcLength: 3.14159 * 1.5, // 270 degrés
                                strokeWidth: 5,
                                clockwise: true,
                                radiusOffset: 22,
                              ),
                            );
                          },
                        ),
                        // Cercle intérieur blanc avec logo JIRIG
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'JIRIG',
                              style: TextStyle(
                                color: const Color(0xFF0066FF),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Texte "Chargement en cours"
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Chargement en cours',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Barre de progression en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding > 0 ? bottomPadding : 0,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 6,
                  color: const Color(0xFF1A2842),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour dessiner les chemins circulaires (rails)
class CirclePathPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radiusOffset;

  CirclePathPainter({
    required this.color,
    required this.strokeWidth,
    required this.radiusOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - strokeWidth / 2 - radiusOffset;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Painter pour dessiner un arc animé qui se déplace sur son chemin
class MovingArcPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double arcLength;
  final double strokeWidth;
  final bool clockwise;
  final double radiusOffset;

  MovingArcPainter({
    required this.color,
    required this.progress,
    required this.arcLength,
    required this.strokeWidth,
    required this.clockwise,
    required this.radiusOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - strokeWidth / 2 - radiusOffset;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Calcul de l'angle de départ basé sur la progression
    final double rotationAngle = clockwise 
        ? progress * 2 * 3.14159 
        : -progress * 2 * 3.14159;
    
    // Position de départ de l'arc
    final double startAngle = -3.14159 / 2 + rotationAngle;

    canvas.drawArc(rect, startAngle, arcLength, false, paint);
  }

  @override
  bool shouldRepaint(covariant MovingArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}