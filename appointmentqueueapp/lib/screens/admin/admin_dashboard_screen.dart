import 'package:flutter/material.dart';
import 'package:my_ap/models/appointment.dart';
import 'package:my_ap/services/appointment_manager.dart';
import 'package:my_ap/utils/app_utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AppointmentManager _appointmentManager = AppointmentManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              _buildStatisticsSection(),
              const SizedBox(height: 30),

              // Quick Actions
              _buildQuickActionsSection(context),
              const SizedBox(height: 30),

              // Current Appointment
              _buildCurrentAppointmentSection(context),
              const SizedBox(height: 30),

              // All Appointments
              _buildAppointmentsListSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = _appointmentManager.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              label: 'Total Appointments',
              value: stats['total'].toString(),
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
            _buildStatCard(
              label: 'Scheduled',
              value: stats['scheduled'].toString(),
              icon: Icons.schedule,
              color: Colors.orange,
            ),
            _buildStatCard(
              label: 'In Progress',
              value: stats['inProgress'].toString(),
              icon: Icons.person,
              color: Colors.green,
            ),
            _buildStatCard(
              label: 'Completed',
              value: stats['completed'].toString(),
              icon: Icons.done_all,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _moveQueueForward(),
            icon: const Icon(Icons.forward),
            label: const Text('Move Queue Forward'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAllAppointmentsDialog(context),
            icon: const Icon(Icons.list),
            label: const Text('View All Appointments'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showQueueManagementDialog(context),
            icon: const Icon(Icons.manage_search),
            label: const Text('Manage Appointments'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentAppointmentSection(BuildContext context) {
    final inProgressAppointments = _appointmentManager.getAppointmentsByStatus(
      AppointmentStatus.inProgress,
    );

    final hasAppointment = inProgressAppointments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currently Being Served',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 15),
        if (hasAppointment)
          _buildAppointmentCard(
            inProgressAppointments.first,
            context,
            isCurrentlyServing: true,
          )
        else
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                const Text(
                  'No appointments being served',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentsListSection(BuildContext context) {
    final appointments = _appointmentManager.getAppointments();
    final activeAppointments = appointments
        .where((apt) =>
            apt.status == AppointmentStatus.scheduled ||
            apt.status == AppointmentStatus.inProgress)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${activeAppointments.length} total',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (activeAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No active appointments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeAppointments.length > 5
                ? 5
                : activeAppointments.length,
            itemBuilder: (context, index) {
              final apt = activeAppointments[index];
              return _buildAppointmentCard(apt, context);
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment,
    BuildContext context, {
    bool isCurrentlyServing = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentlyServing ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyServing
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: isCurrentlyServing ? 2 : 1,
        ),
        boxShadow: isCurrentlyServing
            ? [
                BoxShadow(
                  color: Colors.orange.shade200.withOpacity(0.5),
                  blurRadius: 8,
                )
              ]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(
              int.parse(appointment.getStatusColor()
                  .replaceFirst('#', '0xff')),
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${appointment.queuePosition}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(
                int.parse(
                  appointment.getStatusColor()
                      .replaceFirst('#', '0xff'),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          appointment.name,
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
              appointment.getFormattedTime(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              appointment.serviceType,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Complete'),
              onTap: () => _completeAppointment(appointment.id),
            ),
            if (appointment.status == AppointmentStatus.scheduled)
              PopupMenuItem(
                child: const Text('Start Service'),
                onTap: () => _startService(appointment.id),
              ),
            if (appointment.status != AppointmentStatus.completed &&
                appointment.status != AppointmentStatus.cancelled)
              PopupMenuItem(
                child: const Text('Cancel'),
                onTap: () => _cancelAppointment(appointment.id),
              ),
          ],
        ),
      ),
    );
  }

  void _moveQueueForward() {
    _appointmentManager.moveQueueForward();
    setState(() {});
    UIUtils.showSnackBar(context, 'Queue moved forward');
  }

  void _completeAppointment(String appointmentId) {
    try {
      _appointmentManager.completeAppointment(appointmentId);
      setState(() {});
      UIUtils.showSnackBar(context, 'Appointment completed');
    } catch (e) {
      UIUtils.showErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _startService(String appointmentId) {
    try {
      _appointmentManager.markAsInProgress(appointmentId);
      setState(() {});
      UIUtils.showSnackBar(context, 'Service started');
    } catch (e) {
      UIUtils.showErrorSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _cancelAppointment(String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              try {
                _appointmentManager.cancelAppointment(appointmentId);
                Navigator.pop(context);
                setState(() {});
                UIUtils.showSnackBar(context, 'Appointment cancelled');
              } catch (e) {
                Navigator.pop(context);
                UIUtils.showErrorSnackBar(
                  context,
                  e.toString().replaceFirst('Exception: ', ''),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAllAppointmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Appointments'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: _appointmentManager.getAppointments().length,
            itemBuilder: (context, index) {
              final apt = _appointmentManager.getAppointments()[index];
              return ListTile(
                title: Text(apt.name),
                subtitle: Text(apt.getFormattedDateTime()),
                trailing: Text(apt.getStatusDisplayName()),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQueueManagementDialog(BuildContext context) {
    String? selectedAppointmentId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final appointments = _appointmentManager.getActiveAppointments();

          return AlertDialog(
            title: const Text('Manage Appointment'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appointments.isEmpty)
                    const Text('No active appointments')
                  else
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedAppointmentId,
                      items: appointments.map((apt) {
                        return DropdownMenuItem(
                          value: apt.id,
                          child: Text('${apt.name} - ${apt.getFormattedTime()}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedAppointmentId = value);
                      },
                      hint: const Text('Select appointment'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (selectedAppointmentId != null)
                ElevatedButton(
                  onPressed: () {
                    _startService(selectedAppointmentId!);
                    Navigator.pop(context);
                  },
                  child: const Text('Start Service'),
                ),
            ],
          );
        },
      ),
    );
  }
}
