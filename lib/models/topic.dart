import 'package:flutter/material.dart';

class Topic {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String scene;       // scene identifier for the visual engine
  final String textureSet;  // texture folder name

  const Topic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.scene,
    required this.textureSet,
  });

  static const List<Topic> allTopics = [
    Topic(
      id: 'solar_system',
      title: 'Solar System',
      subtitle: 'Planets, orbits & the Sun',
      icon: Icons.public,
      gradientColors: [Color(0xFF3880FF), Color(0xFF5190FF)],
      scene: 'solar_system',
      textureSet: 'planets',
    ),
    Topic(
      id: 'volcanoes',
      title: 'Volcanoes',
      subtitle: 'Eruptions, lava & tectonic plates',
      icon: Icons.terrain,
      gradientColors: [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
      scene: 'volcano',
      textureSet: 'volcano',
    ),
    Topic(
      id: 'human_heart',
      title: 'Human Heart',
      subtitle: 'Chambers, valves & blood flow',
      icon: Icons.favorite,
      gradientColors: [Color(0xFFE91E63), Color(0xFFFF5B8D)],
      scene: 'human',
      textureSet: 'human',
    ),
    Topic(
      id: 'water_cycle',
      title: 'Water Cycle',
      subtitle: 'Evaporation, clouds & rain',
      icon: Icons.water_drop,
      gradientColors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
      scene: 'water_cycle',
      textureSet: 'water',
    ),
  ];
}
