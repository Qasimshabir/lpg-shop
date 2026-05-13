import 'package:flutter/material.dart';
import '../../lpg_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({Key? key}) : super(key: key);

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _incidents = [];
  List<dynamic> _checklists = [];
  Map<String, dynamic> _complianceReport = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load data with individual error handling
      List<dynamic> incidents = [];
      List<dynamic> checklists = [];
      Map<String, dynamic> complianceReport = {};
      
      try {
        final incidentsResult = await ApiService.get('/safety/incidents');
        incidents = incidentsResult['data'] ?? [];
      } catch (e) {
        print('Failed to load incidents: $e');
      }
      
      try {
        final checklistsResult = await ApiService.get('/safety/checklists');
        checklists = checklistsResult['data'] ?? [];
      } catch (e) {
        print('Failed to load checklists: $e');
      }
      
      try {
        final complianceResult = await ApiService.get('/safety/compliance-report');
        complianceReport = complianceResult['data'] ?? {};
      } catch (e) {
        print('Failed to load compliance report: $e');
      }
      
      setState(() {
        _incidents = incidents;
        _checklists = checklists;
        _complianceReport = complianceReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load safety data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safety & Compliance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Incidents', icon: Icon(Icons.warning)),
            Tab(text: 'Checklists', icon: Icon(Icons.checklist)),
            Tab(text: 'Compliance', icon: Icon(Icons.verified_user)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/safety'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIncidentsTab(),
                _buildChecklistsTab(),
                _buildComplianceTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIncidentDialog,
        icon: Icon(Icons.report),
        label: Text('Report Incident'),
        backgroundColor: LPGColors.error,
      ),
    );
  }

  Widget _buildIncidentsTab() {
    if (_incidents.isEmpty) {
      return _buildEmptyState('No incidents reported', Icons.check_circle);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _incidents.length,
        itemBuilder: (context, index) {
          final incident = _incidents[index];
          return _buildIncidentCard(incident);
        },
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final incidentDate = incident['incident_date'] ?? incident['incidentDate'];
    final date = incidentDate != null 
        ? DateTime.parse(incidentDate) 
        : DateTime.now();
    final severity = incident['severity'] ?? 'low';
    final status = incident['status'] ?? 'reported';
    final description = incident['description'] ?? 'No description';

    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'critical':
        severityColor = LPGColors.error;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = LPGColors.warning;
        break;
      default:
        severityColor = LPGColors.info;
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = LPGColors.success;
        break;
      case 'investigating':
        statusColor = LPGColors.info;
        break;
      default:
        statusColor = LPGColors.warning;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: LPGTextStyles.caption.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: LPGTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(description, style: LPGTextStyles.body1),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: LPGColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: LPGTextStyles.caption,
                ),
                if (incident['location'] != null) ...[
                  SizedBox(width: 16),
                  Icon(Icons.location_on, size: 14, color: LPGColors.textSecondary),
                  SizedBox(width: 4),
                  Text(incident['location'], style: LPGTextStyles.caption),
                ],
              ],
            ),
            if (status.toLowerCase() != 'resolved') ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _updateIncidentStatus(incident['id'], 'resolved'),
                icon: Icon(Icons.check),
                label: Text('Mark as Resolved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LPGColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistsTab() {
    if (_checklists.isEmpty) {
      return _buildEmptyState('No safety checklists', Icons.checklist);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _checklists.length,
        itemBuilder: (context, index) {
          final checklist = _checklists[index];
          return _buildChecklistCard(checklist);
        },
      ),
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    final checkDate = checklist['check_date'] ?? checklist['checkDate'];
    final date = checkDate != null 
        ? DateTime.parse(checkDate) 
        : DateTime.now();
    final passed = checklist['passed'] ?? false;
    final items = checklist['items'] ?? [];
    final notes = checklist['notes'];

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: LPGTextStyles.subtitle1,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: passed 
                        ? LPGColors.success.withOpacity(0.1)
                        : LPGColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: passed ? LPGColors.success : LPGColors.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        passed ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: passed ? LPGColors.success : LPGColors.error,
                      ),
                      SizedBox(width: 4),
                      Text(
                        passed ? 'PASSED' : 'FAILED',
                        style: LPGTextStyles.caption.copyWith(
                          color: passed ? LPGColors.success : LPGColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              SizedBox(height: 12),
              Text('Checklist Items:', style: LPGTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...items.take(3).map<Widget>((item) {
                final itemChecked = item['checked'] ?? false;
                final itemName = item['item'] ?? item['name'] ?? 'Checklist item';
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        itemChecked ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: itemChecked ? LPGColors.success : LPGColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemName,
                          style: LPGTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (items.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${items.length - 3} more items',
                    style: LPGTextStyles.caption.copyWith(
                      color: LPGColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Notes:', style: LPGTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              Text(notes, style: LPGTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceTab() {
    final totalChecklists = _complianceReport['totalChecklists'] ?? 
                           _complianceReport['total_checklists'] ?? 0;
    final passedChecklists = _complianceReport['passedChecklists'] ?? 
                            _complianceReport['passed_checklists'] ?? 0;
    final failedChecklists = _complianceReport['failedChecklists'] ?? 
                            _complianceReport['failed_checklists'] ?? 0;
    final complianceRate = totalChecklists > 0 
        ? (passedChecklists / totalChecklists * 100).toStringAsFixed(1)
        : '0.0';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compliance Overview', style: LPGTextStyles.heading3),
                  SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: LPGColors.success,
                          width: 10,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$complianceRate%',
                              style: LPGTextStyles.heading1.copyWith(
                                color: LPGColors.success,
                                fontSize: 36,
                              ),
                            ),
                            Text('Compliance', style: LPGTextStyles.caption),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox('Total', totalChecklists, LPGColors.primary),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox('Passed', passedChecklists, LPGColors.success),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox('Failed', failedChecklists, LPGColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safety Guidelines', style: LPGTextStyles.subtitle1),
                  SizedBox(height: 12),
                  _buildGuidelineItem('Always check cylinder condition before delivery'),
                  _buildGuidelineItem('Verify customer premises safety'),
                  _buildGuidelineItem('Ensure proper ventilation in storage areas'),
                  _buildGuidelineItem('Regular inspection of delivery vehicles'),
                  _buildGuidelineItem('Maintain safety equipment inventory'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: LPGTextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: LPGTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: LPGColors.success),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: LPGTextStyles.body2)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: LPGColors.success),
          SizedBox(height: 16),
          Text(message, style: LPGTextStyles.heading3),
          SizedBox(height: 8),
          Text('Great job maintaining safety!', style: LPGTextStyles.body2),
        ],
      ),
    );
  }

  void _showReportIncidentDialog() {
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    String severity = 'low';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Report Safety Incident'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: InputDecoration(labelText: 'Severity'),
                  items: ['low', 'medium', 'high', 'critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => severity = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.post('/safety/incidents', {
                    'description': descriptionController.text,
                    'location': locationController.text,
                    'severity': severity,
                    'incident_date': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                  _showSuccess('Incident reported successfully');
                  _loadData();
                } catch (e) {
                  _showError('Failed to report incident: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: LPGColors.error),
              child: Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateIncidentStatus(String incidentId, String status) async {
    try {
      await ApiService.put('/safety/incidents/$incidentId/status', {
        'status': status,
      });
      _showSuccess('Incident status updated');
      _loadData();
    } catch (e) {
      _showError('Failed to update status: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LPGColors.success),
    );
  }
}
