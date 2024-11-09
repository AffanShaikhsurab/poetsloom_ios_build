import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // Base theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  
  // Primary accent colors
  static const accentColor = Color(0xFF6C63FF);
  static const accentLight = Color(0xFF8B85FF);
  static const accentDark = Color(0xFF4E46CC);

  // Gradient combinations
  static const gradientColors = [
    Color(0xFF6C63FF),
    Color(0xFF4E46CC),
  ];

  // Card gradients
  static List<Color> cardGradient = [
    cardColor,
    Color(0xFF252525),
  ];

  // Status colors
  static const successColor = Color(0xFF4CAF50);
  static const errorColor = Color(0xFFE57373);
  static const warningColor = Color(0xFFFFB74D);

  // Text colors
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB3B3B3);
  static const textHint = Color(0xFF666666);

  // Border colors
  static Color borderColor = Colors.white.withOpacity(0.1);
  static Color focusBorder = accentColor.withOpacity(0.5);

  // Card styling
  static BoxDecoration getCardDecoration({bool isGradient = true}) {
    return BoxDecoration(
      color: isGradient ? null : cardColor,
      gradient: isGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardGradient,
            )
          : null,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Accent card styling
  static BoxDecoration getAccentCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.15),
          cardColor,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: accentColor.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Button styling
  static ButtonStyle getAccentButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    );
  }

  // Input decoration
  static InputDecoration getInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        color: accentColor.withOpacity(0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: focusBorder,
        ),
      ),
      filled: true,
      fillColor: cardColor,
    );
  }
}

// Usage example in a widget:
Widget buildCard() {
  return Container(
    decoration: AppColors.getCardDecoration(),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Card Title',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: AppColors.getInputDecoration(
              label: 'Input Field',
              icon: Icons.edit,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: AppColors.getAccentButtonStyle(),
            onPressed: () {},
            child: const Text('Action Button'),
          ),
        ],
      ),
    ),
  );
}

// Example for accent card
Widget buildAccentCard() {
  return Container(
    decoration: AppColors.getAccentCardDecoration(),
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                color: AppColors.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Featured Content',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // ... rest of your content
      ],
    ),
  );
}