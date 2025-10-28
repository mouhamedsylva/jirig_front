import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'qr_scanner_modal.dart';
import '../services/auth_notifier.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  
  const CustomBottomNavigationBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {

  @override
  Widget build(BuildContext context) {
    // Écouter l'état de connexion
    final authNotifier = Provider.of<AuthNotifier>(context);
    final isLoggedIn = authNotifier.isLoggedIn;
    
    // Récupérer le padding système en bas (pour la barre de navigation du téléphone)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      height: 80 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          _buildNavItem(
            context: context,
            icon: Icons.home,
            isSelected: widget.currentIndex == 0,
            onTap: () => _navigateTo('/home', 0),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.search,
            isSelected: widget.currentIndex == 1,
            onTap: () => _navigateTo('/product-search', 1),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.qr_code_scanner,
            isSelected: widget.currentIndex == 2,
            onTap: () => _openScanner(context),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.favorite_border,
            isSelected: widget.currentIndex == 3,
            onTap: () => _navigateTo('/wishlist', 3),
          ),
          // Afficher l'icône utilisateur seulement si connecté
          if (isLoggedIn)
            _buildNavItem(
              context: context,
              icon: Icons.person,
              isSelected: widget.currentIndex == 4,
              onTap: () => _navigateTo('/profile', 4),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String route, int index) {
    if (widget.currentIndex != index) {
      try {
        context.go(route);
      } catch (e) {
        print('Erreur de navigation: $e');
      }
    }
  }

  void _openScanner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QrScannerModal(),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}
