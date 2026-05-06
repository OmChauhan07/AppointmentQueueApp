import 'package:intl/intl.dart';

enum AppointmentStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class Appointment {
  final String id;
  final String name;
  final String serviceType;
  DateTime dateTime;
  AppointmentStatus status;
  int queuePosition;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.dateTime,
    this.status = AppointmentStatus.scheduled,
    required this.queuePosition,
    required this.createdAt,
  });

  // Get estimated waiting time in minutes
  int getEstimatedWaitingTime() {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    return difference.inMinutes > 0 ? difference.inMinutes : 0;
  }

  // Format date time for display
  String getFormattedDateTime() {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Format date only for display
  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  // Format time only for display
  String getFormattedTime() {
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Get status color
  String getStatusColor() {
    switch (status) {
      case AppointmentStatus.scheduled:
        return '#2196F3'; // Blue
      case AppointmentStatus.inProgress:
        return '#FF9800'; // Orange
      case AppointmentStatus.completed:
        return '#4CAF50'; // Green
      case AppointmentStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  // Get status display name
  String getStatusDisplayName() {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  String toString() =>
      'Appointment(id: $id, name: $name, serviceType: $serviceType, dateTime: $dateTime, status: $status, queuePosition: $queuePosition)';
}
