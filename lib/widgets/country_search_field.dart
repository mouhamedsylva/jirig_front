import 'package:flutter/material.dart';

/// Widget personnalisé pour la recherche de pays
class CountrySearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const CountrySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Rechercher...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallMobile = screenWidth < 361;   // Galaxy Fold fermé, Galaxy S8+ (≤360px)
    final isSmallMobile = screenWidth < 431;       // iPhone XR/14 Pro Max, Pixel 7, Galaxy S20/A51 (361-430px)
    final isMobile = screenWidth < 768;            // Tous les mobiles standards (431-767px)
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
            size: isVerySmallMobile ? 20 : (isSmallMobile ? 22 : 24),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: isVerySmallMobile ? 18 : (isSmallMobile ? 19 : 20),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16),
            vertical: isVerySmallMobile ? 12 : (isSmallMobile ? 14 : 16),
          ),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.grey[800],
          fontSize: isVerySmallMobile ? 14 : (isSmallMobile ? 15 : 16),
        ),
      ),
    );
  }
}
