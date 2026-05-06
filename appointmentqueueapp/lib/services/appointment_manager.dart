import 'package:my_ap/models/appointment.dart';
import 'package:my_ap/models/service_type.dart';
import 'package:uuid/uuid.dart';

class AppointmentManager {
  static final AppointmentManager _instance = AppointmentManager._internal();

  factory AppointmentManager() {
    return _instance;
  }

  AppointmentManager._internal();

  final List<Appointment> _appointments = [];
  final List<ServiceType> _serviceTypes = defaultServiceTypes;
  int _currentTokenServing = 0;

  // Get all appointments
  List<Appointment> getAppointments() => _appointments;

  // Get all service types
  List<ServiceType> getServiceTypes() => _serviceTypes;

  // Get current token being served
  int getCurrentTokenServing() => _currentTokenServing;

  // Get appointments for a specific date
  List<Appointment> getAppointmentsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _appointments
        .where((apt) =>
            apt.dateTime.isAfter(startOfDay) && apt.dateTime.isBefore(endOfDay))
        .toList();
  }

  // Get appointments by service type
  List<Appointment> getAppointmentsByServiceType(String serviceType) {
    return _appointments.where((apt) => apt.serviceType == serviceType).toList();
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return _appointments.where((apt) => apt.status == status).toList();
  }

  // Search appointments by name or ID
  List<Appointment> searchAppointments(String query) {
    final lowerQuery = query.toLowerCase();
    return _appointments
        .where((apt) =>
            apt.name.toLowerCase().contains(lowerQuery) ||
            apt.id.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Filter appointments
  List<Appointment> filterAppointments({
    DateTime? date,
    AppointmentStatus? status,
    String? serviceType,
  }) {
    var filtered = List<Appointment>.from(_appointments);

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      filtered = filtered
          .where((apt) =>
              apt.dateTime.isAfter(startOfDay) && apt.dateTime.isBefore(endOfDay))
          .toList();
    }

    if (status != null) {
      filtered = filtered.where((apt) => apt.status == status).toList();
    }

    if (serviceType != null) {
      filtered = filtered.where((apt) => apt.serviceType == serviceType).toList();
    }

    return filtered;
  }

  // Get active appointments (scheduled and in progress)
  List<Appointment> getActiveAppointments() {
    return _appointments
        .where((apt) =>
            apt.status == AppointmentStatus.scheduled ||
            apt.status == AppointmentStatus.inProgress)
        .toList();
  }

  // Check if time slot is available
  bool isTimeSlotAvailable(String serviceType, DateTime dateTime) {
    final service = _serviceTypes.firstWhere((s) => s.id == serviceType);
    final slotStartTime = DateTime(dateTime.year, dateTime.month, dateTime.day,
        dateTime.hour, dateTime.minute, 0);
    final slotEndTime =
        slotStartTime.add(Duration(minutes: service.durationMinutes));

    // Count existing appointments in this time slot
    final conflictingAppointments = _appointments.where((apt) {
      if (apt.status == AppointmentStatus.cancelled) return false;

      final aptStartTime = DateTime(apt.dateTime.year, apt.dateTime.month,
          apt.dateTime.day, apt.dateTime.hour, apt.dateTime.minute, 0);
      final aptEndTime =
          aptStartTime.add(Duration(minutes: service.durationMinutes));

      // Check for overlap
      return !(aptEndTime.isBefore(slotStartTime) ||
          aptStartTime.isAfter(slotEndTime));
    }).toList();

    return conflictingAppointments.length < service.maxSlotsPerDay;
  }

  // Get available time slots for a date
  List<DateTime> getAvailableTimeSlots(String serviceType, DateTime date) {
    final service = _serviceTypes.firstWhere((s) => s.id == serviceType);
    final slots = <DateTime>[];

    // Generate time slots from 9 AM to 5 PM, 30 minutes apart
    for (int hour = 9; hour < 17; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slotDateTime = DateTime(date.year, date.month, date.day, hour, minute);

        // Check if slot is in the future
        if (slotDateTime.isAfter(DateTime.now())) {
          if (isTimeSlotAvailable(serviceType, slotDateTime)) {
            slots.add(slotDateTime);
          }
        }
      }
    }

    return slots;
  }

  // Book an appointment
  Appointment bookAppointment({
    required String name,
    required String serviceType,
    required DateTime dateTime,
  }) {
    // Validate input
    if (name.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    if (dateTime.isBefore(DateTime.now())) {
      throw Exception('Cannot book appointment for past date/time');
    }

    if (!isTimeSlotAvailable(serviceType, dateTime)) {
      throw Exception('Selected time slot is not available');
    }

    // Generate unique ID
    const uuid = Uuid();
    final appointmentId = 'APT-${uuid.v4().substring(0, 8).toUpperCase()}';

    // Calculate queue position
    final queuePosition = _getNextQueuePosition();

    final appointment = Appointment(
      id: appointmentId,
      name: name,
      serviceType: serviceType,
      dateTime: dateTime,
      queuePosition: queuePosition,
      createdAt: DateTime.now(),
    );

    _appointments.add(appointment);

    // Sort by queue position
    _sortAppointmentsByQueuePosition();

    return appointment;
  }

  // Cancel appointment
  void cancelAppointment(String appointmentId) {
    final appointment = _appointments.firstWhere(
      (apt) => apt.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );

    appointment.status = AppointmentStatus.cancelled;
    _recalculateQueuePositions();
  }

  // Reschedule appointment
  void rescheduleAppointment(String appointmentId, DateTime newDateTime) {
    if (newDateTime.isBefore(DateTime.now())) {
      throw Exception('Cannot reschedule to past date/time');
    }

    final appointment = _appointments.firstWhere(
      (apt) => apt.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );

    if (!isTimeSlotAvailable(appointment.serviceType, newDateTime)) {
      throw Exception('Selected time slot is not available');
    }

    appointment.dateTime = newDateTime;
    _recalculateQueuePositions();
  }

  // Mark appointment as in progress
  void markAsInProgress(String appointmentId) {
    final appointment = _appointments.firstWhere(
      (apt) => apt.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );

    appointment.status = AppointmentStatus.inProgress;
  }

  // Mark appointment as completed
  void completeAppointment(String appointmentId) {
    final appointment = _appointments.firstWhere(
      (apt) => apt.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );

    appointment.status = AppointmentStatus.completed;
    _currentTokenServing++;
  }

  // Move queue forward (complete current and start next)
  void moveQueueForward() {
    final inProgressAppointments = _appointments
        .where((apt) => apt.status == AppointmentStatus.inProgress)
        .toList();

    if (inProgressAppointments.isNotEmpty) {
      completeAppointment(inProgressAppointments.first.id);

      // Start next appointment
      final nextAppointment = _appointments.firstWhere(
        (apt) => apt.status == AppointmentStatus.scheduled,
        orElse: () => throw Exception('No scheduled appointments'),
      );

      markAsInProgress(nextAppointment.id);
    } else {
      // Start first scheduled appointment
      final nextAppointment = _appointments.firstWhere(
        (apt) => apt.status == AppointmentStatus.scheduled,
        orElse: () => throw Exception('No scheduled appointments'),
      );

      markAsInProgress(nextAppointment.id);
      _currentTokenServing++;
    }
  }

  // Get appointment by ID
  Appointment? getAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((apt) => apt.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  // Get next queue position
  int _getNextQueuePosition() {
    if (_appointments.isEmpty) return 1;
    return _appointments.map((apt) => apt.queuePosition).reduce((a, b) => a > b ? a : b) +
        1;
  }

  // Recalculate queue positions based on appointment order
  void _recalculateQueuePositions() {
    final active = getActiveAppointments();
    active.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (int i = 0; i < active.length; i++) {
      active[i].queuePosition = i + 1;
    }
  }

  // Sort appointments by queue position
  void _sortAppointmentsByQueuePosition() {
    _appointments.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
  }

  // Get dashboard statistics
  Map<String, int> getDashboardStats() {
    return {
      'total': _appointments.length,
      'scheduled': getAppointmentsByStatus(AppointmentStatus.scheduled).length,
      'inProgress':
          getAppointmentsByStatus(AppointmentStatus.inProgress).length,
      'completed': getAppointmentsByStatus(AppointmentStatus.completed).length,
      'cancelled': getAppointmentsByStatus(AppointmentStatus.cancelled).length,
    };
  }

  // Clear all data (for testing)
  void clearAllData() {
    _appointments.clear();
    _currentTokenServing = 0;
  }
}
