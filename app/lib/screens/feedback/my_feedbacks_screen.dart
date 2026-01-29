import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/feedback.dart' as fb;
import '../../services/api_service.dart';

class MyFeedbacksScreen extends StatefulWidget {
  const MyFeedbacksScreen({super.key});

  @override
  State<MyFeedbacksScreen> createState() => _MyFeedbacksScreenState();
}

class _MyFeedbacksScreenState extends State<MyFeedbacksScreen> {
  List<fb.Feedback> _feedbacks = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final feedbacks = await ApiService.getMyFeedbacks(
        status: _selectedStatus,
      );
      setState(() => _feedbacks = feedbacks);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feedbacks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFeedback(fb.Feedback feedback) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteFeedback(feedback.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted successfully')),
        );
        _loadFeedbacks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting feedback: $e')),
        );
      }
    }
  }

  void _showFeedbackDetails(fb.Feedback feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        feedback.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Status and Category badges
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(feedback.statusDisplayText),
                      backgroundColor: _getStatusColor(feedback.status),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    Chip(
                      label: Text(feedback.categoryDisplayText),
                      backgroundColor: Colors.grey[300],
                    ),
                    Chip(
                      label: Text(feedback.priorityDisplayText),
                      backgroundColor: _getPriorityColor(feedback.priority),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(feedback.message),
                        const SizedBox(height: 16),
                        
                        if (feedback.hasResponse) ...[
                          Text(
                            'Admin Response:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(feedback.adminResponse!),
                                if (feedback.responseDate != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Responded on: ${DateFormat('dd/MM/yyyy HH:mm').format(feedback.responseDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Metadata
                        Text(
                          'Submitted: ${DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feedbacks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('In Progress'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Resolved'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
            onSelected: (status) {
              setState(() => _selectedStatus = status);
              _loadFeedbacks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedbacks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _feedbacks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _feedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = _feedbacks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(feedback.status),
                            child: Icon(
                              _getStatusIcon(feedback.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            feedback.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feedback.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    feedback.statusDisplayText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(feedback.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(feedback.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Text('View Details'),
                              ),
                              if (feedback.isPending)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showFeedbackDetails(feedback);
                              } else if (value == 'delete') {
                                _deleteFeedback(feedback);
                              }
                            },
                          ),
                          onTap: () => _showFeedbackDetails(feedback),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == null 
                ? 'No feedbacks submitted yet'
                : 'No feedbacks with status: ${_selectedStatus!}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your thoughts to help us improve!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.hourglass_bottom;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
