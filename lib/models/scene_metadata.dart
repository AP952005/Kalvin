/// Centralized scientific metadata for all 3D scene objects.
/// All values are scientifically accurate.
class SceneMetadata {
  static const Map<String, Map<String, List<ObjectFact>>> sceneObjects = {
    'solar_system': {
      'sun': [
        ObjectFact(label: 'Type', value: 'G2V Main-sequence star'),
        ObjectFact(label: 'Diameter', value: '1.39 million km'),
        ObjectFact(label: 'Surface temp', value: '5,500 °C'),
        ObjectFact(label: 'Core temp', value: '15 million °C'),
        ObjectFact(label: 'Mass', value: '1.989 × 10³⁰ kg'),
        ObjectFact(label: 'Composition', value: '73% Hydrogen, 25% Helium'),
        ObjectFact(label: 'Age', value: '4.6 billion years'),
      ],
      'earth': [
        ObjectFact(label: 'Type', value: 'Terrestrial planet'),
        ObjectFact(label: 'Diameter', value: '12,742 km'),
        ObjectFact(label: 'Distance from Sun', value: '149.6 million km (1 AU)'),
        ObjectFact(label: 'Surface gravity', value: '9.807 m/s²'),
        ObjectFact(label: 'Atmosphere', value: '78% N₂, 21% O₂, 1% Ar'),
        ObjectFact(label: 'Orbital period', value: '365.25 days'),
        ObjectFact(label: 'Axial tilt', value: '23.44°'),
      ],
    },
    'volcano': {
      'mountain': [
        ObjectFact(label: 'Type', value: 'Stratovolcano (composite)'),
        ObjectFact(label: 'Formation', value: 'Convergent plate boundary'),
        ObjectFact(label: 'Slope angle', value: '30–35°'),
        ObjectFact(label: 'Composition', value: 'Alternating lava and tephra layers'),
      ],
      'crater': [
        ObjectFact(label: 'Type', value: 'Volcanic crater'),
        ObjectFact(label: 'Magma temp', value: '700–1,300 °C'),
        ObjectFact(label: 'Gases emitted', value: 'H₂O, CO₂, SO₂, HCl'),
        ObjectFact(label: 'Eruption speed', value: 'Up to 700 km/h (pyroclastic)'),
      ],
      'lava': [
        ObjectFact(label: 'Type', value: 'Basaltic lava flow'),
        ObjectFact(label: 'Temperature', value: '1,000–1,200 °C'),
        ObjectFact(label: 'Speed', value: '10–300 m/hour'),
        ObjectFact(label: 'Viscosity', value: 'Low (fluid)'),
      ],
    },
    'water_cycle': {
      'sun': [
        ObjectFact(label: 'Role', value: 'Primary energy source'),
        ObjectFact(label: 'Energy output', value: '3.8 × 10²⁶ Watts'),
        ObjectFact(label: 'Effect', value: 'Heats surface water → evaporation'),
      ],
      'ocean': [
        ObjectFact(label: 'Coverage', value: '71% of Earth\'s surface'),
        ObjectFact(label: 'Volume', value: '1.335 billion km³'),
        ObjectFact(label: 'Avg depth', value: '3,688 m'),
        ObjectFact(label: 'Evaporation rate', value: '~500,000 km³/year'),
      ],
      'cloud': [
        ObjectFact(label: 'Formation', value: 'Condensation of water vapour'),
        ObjectFact(label: 'Altitude', value: '2,000–18,000 m'),
        ObjectFact(label: 'Composition', value: 'Water droplets and ice crystals'),
        ObjectFact(label: 'Precipitation', value: 'Rain, snow, sleet, hail'),
      ],
    },
  };

  /// Get facts for a specific object in a scene
  static List<ObjectFact> getFacts(String scene, String object) {
    return sceneObjects[scene]?[object] ?? [];
  }

  /// Get all object names for a scene
  static List<String> getObjects(String scene) {
    return sceneObjects[scene]?.keys.toList() ?? [];
  }
}

class ObjectFact {
  final String label;
  final String value;

  const ObjectFact({required this.label, required this.value});
}
