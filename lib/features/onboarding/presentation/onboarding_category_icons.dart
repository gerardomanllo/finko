import 'package:flutter/material.dart';

/// Fixed Material icon map for category `iconKey` (web + mobile stable).
final Map<String, IconData> kOnboardingCategoryIconMap = <String, IconData>{
  'lock': Icons.lock_outline,
  'home': Icons.home_outlined,
  'work': Icons.work_outline,
  'restaurant': Icons.restaurant_outlined,
  'directions_car': Icons.directions_car_outlined,
  'shopping_cart': Icons.shopping_cart_outlined,
  'movie': Icons.movie_outlined,
  'fitness': Icons.fitness_center_outlined,
  'pets': Icons.pets_outlined,
  'school': Icons.school_outlined,
  'local_hospital': Icons.local_hospital_outlined,
  'flight': Icons.flight_outlined,
  'savings': Icons.savings_outlined,
  'category': Icons.category_outlined,
};

Iterable<String> get kOnboardingIconKeys => kOnboardingCategoryIconMap.keys;

IconData onboardingIconForKey(String key) =>
    kOnboardingCategoryIconMap[key] ?? Icons.label_outline;
