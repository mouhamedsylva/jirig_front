import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/qr_scanner_modal.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_navigation_bar.dart';

class ArticleNotFoundScreen extends StatelessWidget {
  const ArticleNotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(),
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Message "Désole"
                    const Text(
                      'Désole',
                      style: TextStyle(
                        color: Color(0xFF3B82F6), // Bleu
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message "Aucun résultat trouvé"
                    const Text(
                      'Aucun résultat trouvé',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Message explicatif
                    const Text(
                      'Nous n\'avons pas trouvé de produits correspondant à votre recherche.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton "Refaire un autre search"
                    ElevatedButton(
                      onPressed: () {
                        // Ouvrir directement le modal de scanner QR
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const QrScannerModal(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Refaire un autre search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Navigation Bar
          const CustomBottomNavigationBar(currentIndex: 2), // Index 2 pour le scanner
        ],
      ),
    );
  }
}
