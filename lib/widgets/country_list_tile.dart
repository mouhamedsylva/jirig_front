import 'package:flutter/material.dart';
import '../models/country.dart';
import '../config/api_config.dart';

/// Widget pour afficher un pays dans la liste
class CountryListTile extends StatelessWidget {
  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  const CountryListTile({
    super.key,
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Drapeau du pays (placeholder pour l'instant)
              _buildFlag(),
              
              const SizedBox(width: 12),
              
              // Nom du pays
              Expanded(
                child: Text(
                  country.sDescr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? theme.primaryColor : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              
              // Indicateur de sélection
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.primaryColor,
                  size: 20,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlag() {
    // Utiliser l'image du drapeau si disponible, sinon placeholder
    if (country.image != null && country.image!.isNotEmpty) {
      return Container(
        width: 32,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[400]!, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            ApiConfig.getProxiedImageUrl(country.image!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderFlag();
            },
          ),
        ),
      );
    } else {
      return _buildPlaceholderFlag();
    }
  }

  Widget _buildPlaceholderFlag() {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[400]!, width: 0.5),
      ),
      child: Center(
        child: Text(
          country.sPays,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
