/// Kalvin AI — Context Discovery Engine
///
/// Gradually infers learner familiarity with real-world domains
/// from natural conversation. Never asks directly —
/// discovers through conversational signals.

import 'learner_profile.dart';

/// Discovers learner context and updates familiarity map.
class ContextDiscoveryEngine {
  /// Domain keyword maps — if user mentions these, familiarity increases.
  static const Map<String, List<String>> _domainKeywords = {
    'farming': [
      'farm', 'crop', 'harvest', 'soil', 'seeds', 'tractor',
      'irrigation', 'paddy', 'wheat', 'rice', 'agriculture',
      'fertilizer', 'planting', 'field', 'cattle', 'dairy',
    ],
    'sports': [
      'cricket', 'football', 'soccer', 'basketball', 'play',
      'game', 'match', 'team', 'score', 'goal', 'bat', 'ball',
      'running', 'swimming', 'kabaddi', 'hockey', 'athlete',
    ],
    'machines': [
      'engine', 'machine', 'motor', 'robot', 'computer',
      'electricity', 'circuit', 'battery', 'gear', 'mechanical',
      'electronic', 'phone', 'laptop', 'device', 'technology',
    ],
    'nature': [
      'tree', 'forest', 'river', 'mountain', 'lake', 'flower',
      'bird', 'animal', 'rain', 'wind', 'cloud', 'garden',
      'jungle', 'ocean', 'sea', 'beach', 'hill', 'valley',
    ],
    'city_life': [
      'city', 'mall', 'metro', 'bus', 'train', 'traffic',
      'apartment', 'building', 'office', 'school', 'college',
      'restaurant', 'movie', 'park', 'hospital', 'market',
    ],
    'village_life': [
      'village', 'well', 'pond', 'temple', 'festival',
      'grandfather', 'grandmother', 'native', 'hometown',
      'mangoes', 'cow', 'buffalo', 'bullock cart',
    ],
    'science_exposure': [
      'experiment', 'laboratory', 'microscope', 'atom',
      'molecule', 'reaction', 'formula', 'equation', 'theory',
      'hypothesis', 'research', 'scientist', 'discovery',
    ],
    'vehicles': [
      'car', 'bike', 'bicycle', 'scooter', 'truck', 'bus',
      'train', 'airplane', 'helicopter', 'rocket', 'ship',
      'auto', 'rickshaw', 'wheel', 'engine', 'fuel',
    ],
    'space': [
      'planet', 'star', 'sun', 'moon', 'rocket', 'astronaut',
      'galaxy', 'universe', 'nasa', 'isro', 'satellite',
      'orbit', 'constellation', 'telescope', 'space station',
    ],
    'cooking': [
      'cook', 'recipe', 'food', 'kitchen', 'fry', 'boil',
      'bake', 'spice', 'ingredient', 'meal', 'breakfast',
      'lunch', 'dinner', 'snack', 'taste', 'flavor',
    ],
    'animals': [
      'dog', 'cat', 'elephant', 'lion', 'tiger', 'monkey',
      'horse', 'fish', 'snake', 'parrot', 'peacock',
      'butterfly', 'insect', 'pet', 'zoo', 'wildlife',
    ],
    'water': [
      'water', 'rain', 'river', 'ocean', 'sea', 'lake',
      'drink', 'well', 'tap', 'pipe', 'flood', 'dam',
      'wave', 'current', 'stream', 'waterfall',
    ],
    'weather': [
      'weather', 'hot', 'cold', 'rain', 'sunny', 'cloudy',
      'storm', 'thunder', 'lightning', 'winter', 'summer',
      'monsoon', 'humidity', 'temperature', 'forecast',
    ],
  };

  /// Analyze a user message and update familiarity map.
  void analyzeUserContext(String message, LearnerProfile profile) {
    final lower = message.toLowerCase();

    _domainKeywords.forEach((domain, keywords) {
      int matches = 0;
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          matches++;
        }
      }

      if (matches > 0) {
        // Each match increases familiarity slightly
        final delta = (matches * 0.05).clamp(0.0, 0.15);
        final current = profile.familiarityMap[domain] ?? 0.5;
        profile.updateFamiliarity(domain, current + delta);
      }
    });
  }

  /// Extract interests from a message.
  List<String> extractInterests(String message) {
    final lower = message.toLowerCase();
    final interests = <String>[];

    _domainKeywords.forEach((domain, keywords) {
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          interests.add(domain);
          break; // one match per domain is enough
        }
      }
    });

    return interests;
  }

  /// Update familiarity map based on detected interests.
  void updateFamiliarityMap(
      List<String> detectedDomains, LearnerProfile profile) {
    for (final domain in detectedDomains) {
      final current = profile.familiarityMap[domain] ?? 0.5;
      profile.updateFamiliarity(domain, current + 0.1);
    }
  }

  /// Get familiarity context string for prompt injection.
  String toPromptContext(LearnerProfile profile) {
    final buffer = StringBuffer();
    buffer.writeln('Learner familiarity levels:');

    // Sort by familiarity score
    final sorted = profile.familiarityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      final label = _familiarityLabel(entry.value);
      buffer.writeln(
          '  ${entry.key.replaceAll("_", " ")}: $label (${(entry.value * 100).toInt()}%)');
    }

    buffer.writeln(
        '\nUse analogies from domains the learner is most familiar with.');
    buffer.writeln(
        'Strongest context: ${profile.getStrongestContext()}');

    return buffer.toString();
  }

  String _familiarityLabel(double score) {
    if (score >= 0.8) return 'very familiar';
    if (score >= 0.6) return 'familiar';
    if (score >= 0.4) return 'somewhat familiar';
    if (score >= 0.2) return 'slightly familiar';
    return 'unfamiliar';
  }
}
