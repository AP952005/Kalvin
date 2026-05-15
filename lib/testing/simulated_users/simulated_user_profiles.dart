/// Kalvin AI — Simulated User Profiles for Testing
///
/// Defines test personas representing different learner types:
/// village children, curious kids, frustrated students, etc.
/// Used by the validation runner to test AI response quality.

class SimulatedUser {
  final String name;
  final String type;
  final int age;
  final String knowledgeLevel; // beginner, intermediate, advanced
  final String background; // village, city, suburban
  final String emotionalState; // curious, frustrated, confused, excited, tired, shy
  final List<String> testPrompts;
  final List<String> expectedBehaviors;

  const SimulatedUser({
    required this.name,
    required this.type,
    required this.age,
    required this.knowledgeLevel,
    required this.background,
    required this.emotionalState,
    required this.testPrompts,
    required this.expectedBehaviors,
  });

  /// All test personas.
  static const List<SimulatedUser> allUsers = [
    villageChild,
    curiousKid,
    frustratedStudent,
    advancedLearner,
    tiredStudent,
    shyStudent,
    fastLearner,
  ];

  static const villageChild = SimulatedUser(
    name: 'Ravi',
    type: 'village_child',
    age: 10,
    knowledgeLevel: 'beginner',
    background: 'village',
    emotionalState: 'curious',
    testPrompts: [
      'What is the sun?',
      'Why does rain happen?',
      'What is inside a volcano?',
      'I dont understand',
      'Tell me more simply',
      'What is an atom?',
      'Why is the sky blue?',
    ],
    expectedBehaviors: [
      'Uses farming/nature analogies',
      'Simple language (age 10)',
      'No markdown or labels',
      'Warm conversational tone',
      'No repeated greetings',
    ],
  );

  static const curiousKid = SimulatedUser(
    name: 'Aisha',
    type: 'curious_kid',
    age: 12,
    knowledgeLevel: 'intermediate',
    background: 'city',
    emotionalState: 'excited',
    testPrompts: [
      'How do rockets work?',
      'What is DNA?',
      'Why do we dream?',
      'Tell me about black holes!',
      'How does WiFi work?',
      'What happens inside a computer?',
    ],
    expectedBehaviors: [
      'Matches excitement level',
      'Uses city/tech analogies',
      'Progressively detailed answers',
      'Encourages deeper questions',
    ],
  );

  static const frustratedStudent = SimulatedUser(
    name: 'Arjun',
    type: 'frustrated_student',
    age: 14,
    knowledgeLevel: 'beginner',
    background: 'suburban',
    emotionalState: 'frustrated',
    testPrompts: [
      'I hate math',
      'This is too hard',
      'I dont get it',
      'Why do I need to learn this?',
      'I give up',
      'Nothing makes sense',
    ],
    expectedBehaviors: [
      'Empathetic and supportive',
      'Simplifies immediately',
      'Never dismissive',
      'Offers encouragement',
      'Suggests easier approach',
    ],
  );

  static const advancedLearner = SimulatedUser(
    name: 'Priya',
    type: 'advanced_learner',
    age: 16,
    knowledgeLevel: 'advanced',
    background: 'city',
    emotionalState: 'curious',
    testPrompts: [
      'Explain quantum entanglement',
      'How does CRISPR gene editing work?',
      'What is dark matter?',
      'Explain the theory of relativity',
      'How do neural networks learn?',
      'What is the Higgs boson?',
    ],
    expectedBehaviors: [
      'More technical depth',
      'Does not oversimplify',
      'Uses scientific terminology appropriately',
      'Provides nuanced explanations',
    ],
  );

  static const tiredStudent = SimulatedUser(
    name: 'Kiran',
    type: 'tired_student',
    age: 11,
    knowledgeLevel: 'beginner',
    background: 'village',
    emotionalState: 'tired',
    testPrompts: [
      'Tell me something interesting',
      'Im sleepy',
      'Can we do something easy?',
      'I dont want to study',
      'Just tell me a fun fact',
    ],
    expectedBehaviors: [
      'Gentle and calm tone',
      'Short responses',
      'May suggest sleep if late',
      'Makes learning feel effortless',
      'No pressure',
    ],
  );

  static const shyStudent = SimulatedUser(
    name: 'Meera',
    type: 'shy_student',
    age: 9,
    knowledgeLevel: 'beginner',
    background: 'suburban',
    emotionalState: 'shy',
    testPrompts: [
      'hi',
      'ok',
      'yes',
      'hmm',
      'what is that?',
      'I dont know',
    ],
    expectedBehaviors: [
      'Warm and inviting',
      'Asks gentle questions',
      'Does not overwhelm',
      'Very short messages initially',
      'Gradually builds engagement',
    ],
  );

  static const fastLearner = SimulatedUser(
    name: 'Dev',
    type: 'fast_learner',
    age: 13,
    knowledgeLevel: 'intermediate',
    background: 'city',
    emotionalState: 'excited',
    testPrompts: [
      'What is photosynthesis?',
      'Ok I get it, what about cellular respiration?',
      'How are they connected?',
      'What about ATP?',
      'Show me the cycle visually',
      'Quiz me on this!',
    ],
    expectedBehaviors: [
      'Escalates complexity quickly',
      'Recognizes fast learning',
      'Connects related concepts',
      'Offers quizzes/challenges',
      'Triggers visuals when asked',
    ],
  );
}
