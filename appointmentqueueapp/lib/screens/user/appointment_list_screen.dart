import 'package:flutter/material.dart';
import 'package:my_ap/models/appointment.dart';
import 'package:my_ap/services/appointment_manager.dart';
import 'package:my_ap/utils/app_utils.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final AppointmentManager _appointmentManager = AppointmentManager();
  final TextEditingController _searchController = TextEditingController();
  AppointmentStatus? _selectedStatus;
  String? _selectedServiceType;
  DateTime? _selectedDate;
  List<Appointment> _filteredAppointments = [];
  String _sortBy = 'date'; // date, status

  @override
  void initState() {
    super.initState();
    _applyFilters();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final searchQuery = _searchController.text;

    List<Appointment> result = _appointmentManager.getAppointments();

    // Apply search
    if (searchQuery.isNotEmpty) {
      result = _appointmentManager.searchAppointments(searchQuery);
    }

    // Apply filters
    result = result.where((apt) {
      if (_selectedStatus != null && apt.status != _selectedStatus) {
        return false;
      }
      if (_selectedServiceType != null && apt.serviceType != _selectedServiceType) {
        return false;
      }
      if (_selectedDate != null) {
        final startOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        final endOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          23,
          59,
          59,
        );
        if (!apt.dateTime.isAfter(startOfDay) || !apt.dateTime.isBefore(endOfDay)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Apply sorting
    if (_sortBy == 'date') {
      result.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else if (_sortBy == 'status') {
      result.sort((a, b) => a.status.index.compareTo(b.status.index));
    }

    setState(() {
      _filteredAppointments = result;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID:', appointment.id),
              const SizedBox(height: 12),
              _buildDetailRow('Name:', appointment.name),
              const SizedBox(height: 12),
              _buildDetailRow('Service:', appointment.serviceType),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Date & Time:',
                appointment.getFormattedDateTime(),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Queue Position:', '#${appointment.queuePosition}'),
              const SizedBox(height: 12),
              _buildDetailRow('Status:', appointment.getStatusDisplayName()),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Waiting Time:',
                '${appointment.getEstimatedWaitingTime()} min',
              ),
            ],
          ),
        ),
        actions: [
          if (appointment.status == AppointmentStatus.scheduled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRescheduleDialog(appointment);
              },
              child: const Text('Reschedule'),
            ),
          if (appointment.status == AppointmentStatus.scheduled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelAppointment(appointment.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('Select new date and time for the appointment'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _selectNewDateTime(appointment);
            },
            child: const Text('Select Date & Time'),
          ),
        ],
      ),
    );
  }

  void _selectNewDateTime(Appointment appointment) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: appointment.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (newDate == null) return;

    if (mounted) {
      final newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
      );

      if (newTime == null) return;

      final newDateTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newTime.hour,
        newTime.minute,
      );

      try {
        _appointmentManager.rescheduleAppointment(
          appointment.id,
          newDateTime,
        );
        if (mounted) {
          UIUtils.showSnackBar(context, 'Appointment rescheduled successfully');
          _applyFilters();
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showErrorSnackBar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }

  void _cancelAppointment(String appointmentId) async {
    final confirmed = await UIUtils.showConfirmDialog(
      context,
      title: 'Cancel Appointment',
      message: 'Are you sure you want to cancel this appointment?',
      confirmText: 'Yes, Cancel',
      cancelText: 'No, Keep',
    );

    if (confirmed == true) {
      try {
        _appointmentManager.cancelAppointment(appointmentId);
        if (mounted) {
          UIUtils.showSnackBar(context, 'Appointment cancelled successfully');
          _applyFilters();
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showErrorSnackBar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status Filter
                  FilterChip(
                    label: Text(_selectedStatus == null
                        ? 'Status'
                        : _selectedStatus!.name),
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Text(
                                'Filter by Status',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ListTile(
                              title: const Text('All'),
                              onTap: () {
                                setState(() => _selectedStatus = null);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                            ),
                            ...AppointmentStatus.values.map((status) {
                              return ListTile(
                                title: Text(status.name),
                                onTap: () {
                                  setState(() => _selectedStatus = status);
                                  Navigator.pop(context);
                                  _applyFilters();
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    selected: _selectedStatus != null,
                  ),
                  const SizedBox(width: 10),

                  // Service Type Filter
                  FilterChip(
                    label: Text(_selectedServiceType ?? 'Service'),
                    onSelected: (selected) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Text(
                                'Filter by Service',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            ListTile(
                              title: const Text('All'),
                              onTap: () {
                                setState(() => _selectedServiceType = null);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                            ),
                            ..._appointmentManager.getServiceTypes().map((service) {
                              return ListTile(
                                title: Text(service.name),
                                onTap: () {
                                  setState(() => _selectedServiceType = service.id);
                                  Navigator.pop(context);
                                  _applyFilters();
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    selected: _selectedServiceType != null,
                  ),
                  const SizedBox(width: 10),

                  // Date Filter
                  FilterChip(
                    label: Text(
                      _selectedDate == null
                          ? 'Date'
                          : DateTimeUtils.formatDate(_selectedDate!),
                    ),
                    onSelected: (selected) {
                      _selectDate(context);
                    },
                    selected: _selectedDate != null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Appointments List
          Expanded(
            child: _filteredAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'No appointments found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final apt = _filteredAppointments[index];
                      return GestureDetector(
                        onTap: () => _showAppointmentDetails(apt),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: Color(
                                    int.parse(apt.getStatusColor()
                                        .replaceFirst('#', '0xff')),
                                  ),
                                  width: 5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${apt.queuePosition}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              title: Text(
                                apt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    apt.getFormattedDateTime(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    apt.serviceType,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(apt.getStatusColor()
                                        .replaceFirst('#', '0xff')),
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  apt.getStatusDisplayName(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(
                                      int.parse(apt.getStatusColor()
                                          .replaceFirst('#', '0xff')),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
