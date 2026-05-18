class Vehicle {
  final String id;
  final String name;
  final String licensePlate;
  final bool isDefault;

  const Vehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'licensePlate': licensePlate,
      'isDefault': isDefault,
    };
  }

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      name: map['name'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}
