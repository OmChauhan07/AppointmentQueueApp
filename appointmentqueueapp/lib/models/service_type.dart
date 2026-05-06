class ServiceType {
  final String id;
  final String name;
  final int maxSlotsPerDay;
  final int durationMinutes;

  ServiceType({
    required this.id,
    required this.name,
    required this.maxSlotsPerDay,
    required this.durationMinutes,
  });

  @override
  String toString() => 'ServiceType(id: $id, name: $name)';
}

// Predefined service types
final List<ServiceType> defaultServiceTypes = [
  ServiceType(
    id: 'consultation',
    name: 'General Consultation',
    maxSlotsPerDay: 10,
    durationMinutes: 30,
  ),
  ServiceType(
    id: 'checkup',
    name: 'Medical Checkup',
    maxSlotsPerDay: 8,
    durationMinutes: 45,
  ),
  ServiceType(
    id: 'haircut',
    name: 'Haircut',
    maxSlotsPerDay: 12,
    durationMinutes: 25,
  ),
  ServiceType(
    id: 'repair',
    name: 'Device Repair',
    maxSlotsPerDay: 6,
    durationMinutes: 60,
  ),
  ServiceType(
    id: 'registration',
    name: 'Registration',
    maxSlotsPerDay: 15,
    durationMinutes: 20,
  ),
];
