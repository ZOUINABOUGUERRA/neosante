import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:neosante/theme/colors.dart';
import 'package:neosante/shared/models/notification_model.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ✅ Bouton "Tout lire"
          if (notificationsState.unreadCount > 0)
            TextButton.icon(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text('📖 Tout lire (${notificationsState.unreadCount})'),
            ),
          // ✅ Menu filtre
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 18),
                    SizedBox(width: 8),
                    Text('📋 Toutes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, size: 18),
                    SizedBox(width: 8),
                    Text('📭 Non lues'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('🚑 Transferts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'alert',
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 18),
                    SizedBox(width: 8),
                    Text('⚠️ Alertes'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsState.isLoading && filteredNotifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : filteredNotifications.isEmpty
          ? _buildEmptyState(_selectedFilter)
          : isDesktop
          ? _buildDesktopGrid(filteredNotifications)
          : _buildMobileList(filteredNotifications),
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

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'unread':
        message = '📭 Aucune notification non lue';
        icon = Icons.mark_email_unread;
        break;
      case 'transfer':
        message = '🚑 Aucun transfert';
        icon = Icons.swap_horiz;
        break;
      case 'alert':
        message = '⚠️ Aucune alerte';
        icon = Icons.warning;
        break;
      default:
        message = '🔔 Aucune notification';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
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

  Widget _buildDesktopGrid(List<NotificationModel> notifications) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildMobileList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNotificationCard(notification),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isRead = notification.isRead;
    final color = _getNotificationColor(notification.type);
    //final icon = _getNotificationIcon(notification.type);
    final emoji = _getNotificationEmoji(notification.type);

    return Card(
      elevation: isRead ? 1 : 4,
      margin: EdgeInsets.zero,
      color: isRead ? Colors.white : color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: !isRead ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Icon with gradient background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                            '$emoji ${notification.title}',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (notification.type == 'transfer_request')
                          _buildActionButton(
                            label: '👁️ Voir',
                            icon: Icons.visibility,
                            onPressed: () =>
                                _handleTransferRequest(notification),
                          ),
                        if (notification.type == 'emergency_alert')
                          _buildActionButton(
                            label: '🚨 Urgence',
                            icon: Icons.warning,
                            color: AppColors.emergencyRed,
                            onPressed: () =>
                                _handleEmergencyAlert(notification),
                          ),
                        if (notification.type == 'transfer_approved')
                          _buildActionButton(
                            label: '✅ Voir',
                            icon: Icons.check_circle,
                            color: AppColors.stableGreen,
                            onPressed: () =>
                                _handleNotificationTap(notification),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // ✅ Delete button
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    ref
                        .read(notificationsProvider.notifier)
                        .deleteNotification(notification.id);
                  },
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    Color color = AppColors.medicalBlue,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
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
      if (notification.type == 'transfer_request' ||
          notification.type == 'transfer_approved') {
        final dossierId = data['dossierId'];
        if (dossierId != null) {
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
    GoRouter.of(context).pushNamed('/transfers');
  }

  void _handleEmergencyAlert(NotificationModel notification) {
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

  //IconData _getNotificationIcon(String type) {
  // switch (type) {
  //   case 'transfer_request': return Icons.swap_horiz;
  //  case 'transfer_approved': return Icons.check_circle;
  // case 'transfer_rejected': return Icons.cancel;
  //  case 'emergency_alert': return Icons.warning;
  // default: return Icons.notifications;
  // }
  //}

  String _getNotificationEmoji(String type) {
    switch (type) {
      case 'transfer_request':
        return '🚑';
      case 'transfer_approved':
        return '✅';
      case 'transfer_rejected':
        return '❌';
      case 'emergency_alert':
        return '🚨';
      default:
        return '🔔';
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
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    }
  }
}
