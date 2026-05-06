import 'package:flutter/material.dart';
import 'package:my_ap/models/appointment.dart';
import 'package:my_ap/services/appointment_manager.dart';
import 'package:my_ap/utils/app_utils.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final AppointmentManager _appointmentManager = AppointmentManager();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedServiceType;
  AppointmentStatus? _selectedStatus;
  DateTime? _selectedDate;
  List<Appointment> _searchResults = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    String query = _searchController.text.trim();
    List<Appointment> results = [];

    if (query.isNotEmpty) {
      results = _appointmentManager.searchAppointments(query);
    } else {
      results = _appointmentManager.filterAppointments(
        date: _selectedDate,
        status: _selectedStatus,
        serviceType: _selectedServiceType,
      );
    }

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedServiceType = null;
      _selectedStatus = null;
      _selectedDate = null;
      _searchResults = [];
      _hasSearched = false;
    });
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
              const SizedBox(height: 12),
              _buildDetailRow(
                'Booked At:',
                DateTimeUtils.formatDateTime(appointment.createdAt),
              ),
            ],
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
        title: const Text('Search & Filter'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),

            // Filter Section
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 15),

            // Service Type Filter
            Text(
              'Service Type',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Services'),
                ),
                ..._appointmentManager.getServiceTypes().map((service) {
                  return DropdownMenuItem(
                    value: service.id,
                    child: Text(service.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedServiceType = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Status Filter
            Text(
              'Status',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppointmentStatus?>(
              value: _selectedStatus,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...AppointmentStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.name.replaceFirst(
                        status.name[0],
                        status.name[0].toUpperCase(),
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Date Filter
            Text(
              'Date',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select date (optional)'
                            : DateTimeUtils.formatDate(_selectedDate!),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _selectedDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: const Icon(Icons.close, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Results
            if (_hasSearched)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${_searchResults.length} found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_searchResults.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'No appointments found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final apt = _searchResults[index];
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
                                      'ID: ${apt.id}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      apt.getFormattedDateTime(),
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
