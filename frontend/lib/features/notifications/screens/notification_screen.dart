import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../shared/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'transfer', 'alert'

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifications = notificationsState.notifications;

    // Apply filter
    final filteredNotifications = _applyFilter(notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        actions: [
          if (notificationsState.unreadCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
              icon: const Icon(Icons.done_all),
              label: const Text('Tout lire'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Toutes')),
              const PopupMenuItem(value: 'unread', child: Text('Non lues')),
              const PopupMenuItem(value: 'transfer', child: Text('Transferts')),
              const PopupMenuItem(value: 'alert', child: Text('Alertes')),
            ],
          ),
        ],
      ),
      body: notificationsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredNotifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> notifications) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'transfer':
        return notifications.where((n) => n.isTransferNotification).toList();
      case 'alert':
        return notifications.where((n) => n.isEmergencyAlert).toList();
      default:
        return notifications;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Les notifications apparaîtront ici',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isRead = notification.isRead;
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Card(
      elevation: isRead ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      // ✅ Correction: withOpacity → withValues
      color: isRead ? null : color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: !isRead
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // ✅ Correction: withOpacity → withValues
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        if (notification.type == 'transfer_request')
                          _buildActionButton(
                            label: 'Voir',
                            onPressed: () => _handleTransferRequest(notification),
                          ),
                        if (notification.type == 'emergency_alert')
                          _buildActionButton(
                            label: 'Urgence',
                            color: AppColors.emergencyRed,
                            onPressed: () => _handleEmergencyAlert(notification),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, Color color = AppColors.medicalBlue, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        // ✅ Correction: withOpacity → withValues
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on type
    final data = notification.data;
    if (data != null) {
      if (notification.type == 'transfer_request' || notification.type == 'transfer_approved') {
        final dossierId = data['dossierId'];
        if (dossierId != null) {
          // ✅ Correction: utiliser GoRouter.of(context)
          GoRouter.of(context).pushNamed('/dossiers/$dossierId');
        }
      } else if (notification.type == 'emergency_alert') {
        final dossierId = data['dossierId'];
        if (dossierId != null) {
          GoRouter.of(context).pushNamed('/dossiers/$dossierId');
        } else {
          GoRouter.of(context).pushNamed('/alerts');
        }
      }
    }
  }

  void _handleTransferRequest(NotificationModel notification) {
    // ✅ Correction: utiliser GoRouter.of(context)
    GoRouter.of(context).pushNamed('/transfers');
  }

  void _handleEmergencyAlert(NotificationModel notification) {
    // ✅ Correction: utiliser GoRouter.of(context)
    GoRouter.of(context).pushNamed('/alerts');
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'transfer_request':
        return Colors.orange;
      case 'transfer_approved':
        return AppColors.stableGreen;
      case 'transfer_rejected':
        return AppColors.emergencyRed;
      case 'emergency_alert':
        return AppColors.emergencyRed;
      default:
        return AppColors.medicalBlue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'transfer_request':
        return Icons.swap_horiz;
      case 'transfer_approved':
        return Icons.check_circle;
      case 'transfer_rejected':
        return Icons.cancel;
      case 'emergency_alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    }
  }
}