import 'spatial_shape.dart';

/// Pre-configured room templates with standard Indian/international dimensions.
///
/// Each template provides realistic default dimensions that users can
/// modify after selection — no hardcoded fallbacks.
class RoomTemplate {
  final String name;
  final String icon;
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final String description;
  final List<WallOpening> typicalOpenings;

  const RoomTemplate({
    required this.name,
    required this.icon,
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.description,
    this.typicalOpenings = const [],
  });

  /// Convert template to a RoomShape.
  RoomShape toRoomShape() => RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(lengthMeters, 0),
          Point3D(lengthMeters, widthMeters),
          Point3D(0, widthMeters),
        ],
        heightMeters: heightMeters,
      );

  /// All standard room templates.
  static const List<RoomTemplate> all = [
    standardBedroom,
    masterBedroom,
    bathroom,
    kitchen,
    livingRoom,
    diningRoom,
    homeOffice,
    garage,
    studioApartment,
    balcony,
    storeRoom,
    poojaRoom,
    hallCorridor,
    laundryUtility,
  ];

  // ── Standard Templates (Indian residential standards) ──

  static const standardBedroom = RoomTemplate(
    name: 'Standard Bedroom',
    icon: '🛏️',
    lengthMeters: 3.66, // 12 ft
    widthMeters: 3.05, // 10 ft
    heightMeters: 3.0, // 10 ft
    description: '12×10 ft • Standard single/double bedroom',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
      WallOpening(label: 'Window', widthMeters: 1.2, heightMeters: 1.2),
    ],
  );

  static const masterBedroom = RoomTemplate(
    name: 'Master Bedroom',
    icon: '👑',
    lengthMeters: 4.88, // 16 ft
    widthMeters: 3.66, // 12 ft
    heightMeters: 3.0,
    description: '16×12 ft • Spacious master with attached bath',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
      WallOpening(label: 'Bath Door', widthMeters: 0.76, heightMeters: 2.1),
      WallOpening(label: 'Window 1', widthMeters: 1.5, heightMeters: 1.2),
      WallOpening(label: 'Window 2', widthMeters: 1.2, heightMeters: 1.2),
    ],
  );

  static const bathroom = RoomTemplate(
    name: 'Bathroom',
    icon: '🚿',
    lengthMeters: 2.44, // 8 ft
    widthMeters: 1.83, // 6 ft
    heightMeters: 3.0,
    description: '8×6 ft • Standard Indian bathroom',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.76, heightMeters: 2.1),
      WallOpening(label: 'Ventilator', widthMeters: 0.6, heightMeters: 0.45),
    ],
  );

  static const kitchen = RoomTemplate(
    name: 'Kitchen',
    icon: '🍳',
    lengthMeters: 3.66, // 12 ft
    widthMeters: 2.74, // 9 ft
    heightMeters: 3.0,
    description: '12×9 ft • Standard modular kitchen',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
      WallOpening(label: 'Window', widthMeters: 1.2, heightMeters: 1.0),
    ],
  );

  static const livingRoom = RoomTemplate(
    name: 'Living Room',
    icon: '🛋️',
    lengthMeters: 4.88, // 16 ft
    widthMeters: 3.66, // 12 ft
    heightMeters: 3.0,
    description: '16×12 ft • Family living/drawing room',
    typicalOpenings: [
      WallOpening(label: 'Main Door', widthMeters: 1.05, heightMeters: 2.1),
      WallOpening(label: 'Window 1', widthMeters: 1.5, heightMeters: 1.5),
      WallOpening(label: 'Window 2', widthMeters: 1.5, heightMeters: 1.5),
    ],
  );

  static const diningRoom = RoomTemplate(
    name: 'Dining Room',
    icon: '🍽️',
    lengthMeters: 3.66, // 12 ft
    widthMeters: 3.05, // 10 ft
    heightMeters: 3.0,
    description: '12×10 ft • Dining area',
    typicalOpenings: [
      WallOpening(label: 'Opening', widthMeters: 1.5, heightMeters: 2.1),
    ],
  );

  static const homeOffice = RoomTemplate(
    name: 'Home Office',
    icon: '💻',
    lengthMeters: 3.05, // 10 ft
    widthMeters: 2.74, // 9 ft
    heightMeters: 3.0,
    description: '10×9 ft • Study/work-from-home room',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
      WallOpening(label: 'Window', widthMeters: 1.2, heightMeters: 1.2),
    ],
  );

  static const garage = RoomTemplate(
    name: 'Garage / Car Parking',
    icon: '🚗',
    lengthMeters: 5.49, // 18 ft
    widthMeters: 3.05, // 10 ft
    heightMeters: 3.0,
    description: '18×10 ft • Single car parking',
    typicalOpenings: [
      WallOpening(label: 'Shutter', widthMeters: 2.4, heightMeters: 2.4),
    ],
  );

  static const studioApartment = RoomTemplate(
    name: 'Studio Apartment',
    icon: '🏠',
    lengthMeters: 6.1, // 20 ft
    widthMeters: 4.57, // 15 ft
    heightMeters: 3.0,
    description: '20×15 ft • Open-plan studio',
    typicalOpenings: [
      WallOpening(label: 'Main Door', widthMeters: 0.9, heightMeters: 2.1),
      WallOpening(label: 'Window 1', widthMeters: 1.5, heightMeters: 1.5),
      WallOpening(label: 'Window 2', widthMeters: 1.5, heightMeters: 1.5),
      WallOpening(label: 'Bath Door', widthMeters: 0.76, heightMeters: 2.1),
    ],
  );

  static const balcony = RoomTemplate(
    name: 'Balcony',
    icon: '🌿',
    lengthMeters: 3.05, // 10 ft
    widthMeters: 1.22, // 4 ft
    heightMeters: 3.0,
    description: '10×4 ft • Standard balcony',
  );

  static const storeRoom = RoomTemplate(
    name: 'Store Room',
    icon: '📦',
    lengthMeters: 2.44, // 8 ft
    widthMeters: 1.83, // 6 ft
    heightMeters: 3.0,
    description: '8×6 ft • Storage area',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.76, heightMeters: 2.1),
    ],
  );

  static const poojaRoom = RoomTemplate(
    name: 'Pooja Room',
    icon: '🪔',
    lengthMeters: 1.83, // 6 ft
    widthMeters: 1.52, // 5 ft
    heightMeters: 3.0,
    description: '6×5 ft • Prayer/worship room',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.76, heightMeters: 2.1),
    ],
  );

  static const hallCorridor = RoomTemplate(
    name: 'Hall / Corridor',
    icon: '🚶',
    lengthMeters: 6.1, // 20 ft
    widthMeters: 1.22, // 4 ft
    heightMeters: 3.0,
    description: '20×4 ft • Passageway/corridor',
  );

  static const laundryUtility = RoomTemplate(
    name: 'Utility / Laundry',
    icon: '🧺',
    lengthMeters: 2.44, // 8 ft
    widthMeters: 2.13, // 7 ft
    heightMeters: 3.0,
    description: '8×7 ft • Utility/laundry area',
    typicalOpenings: [
      WallOpening(label: 'Door', widthMeters: 0.76, heightMeters: 2.1),
    ],
  );
}
