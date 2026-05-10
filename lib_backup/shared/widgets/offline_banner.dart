// frontend/lib/shared/widgets/offline_banner.dart

import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Banner widget to show when the app is offline
class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      child: Material(
        elevation: 4,
        child: Container(
          width: double.infinity,
          color: AppColors.warningOrange,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                     Icons.wifi_off,
                      color:Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mode hors ligne - Données locales uniquement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent offline banner with retry and sync buttons
class PersistentOfflineBanner extends StatefulWidget {
  final bool isOnline;
  final int pendingSyncCount;
  final VoidCallback? onRetry;
  final VoidCallback? onSync;

  const PersistentOfflineBanner({
    super.key,
    required this.isOnline,
    this.pendingSyncCount = 0,
    this.onRetry,
    this.onSync,
  });

  @override
  State<PersistentOfflineBanner> createState() => _PersistentOfflineBannerState();
}

class _PersistentOfflineBannerState extends State<PersistentOfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (!widget.isOnline) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PersistentOfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOnline && oldWidget.isOnline) {
      _controller.forward();
    } else if (widget.isOnline && !oldWidget.isOnline) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnline && widget.pendingSyncCount == 0) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 8,
        child: Container(
          width: double.infinity,
          color: widget.isOnline ? AppColors.stableGreen : AppColors.warningOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                widget.isOnline ? Icons.cloud_sync : Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isOnline
                          ? 'Synchronisation en cours...'
                          : 'Vous êtes hors ligne',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!widget.isOnline && widget.pendingSyncCount > 0)
                      Text(
                        '${widget.pendingSyncCount} opération(s) en attente de synchronisation',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.isOnline && widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Réessayer'),
                ),
              if (widget.isOnline && widget.pendingSyncCount > 0 && widget.onSync != null)
                TextButton(
                  onPressed: widget.onSync,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: Text('${widget.pendingSyncCount} en attente'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small offline indicator badge
class OfflineIndicator extends StatelessWidget {
  final bool isOnline;

  const OfflineIndicator({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_off, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'Hors ligne',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog for sync operations
class OfflineSyncDialog extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onConfirm;

  const OfflineSyncDialog({
    super.key,
    required this.pendingCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Synchronisation en attente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload,
            size: 48,
            color: AppColors.warningOrange,
          ),
          const SizedBox(height: 16),
          Text(
            '$pendingCount opération(s) en attente de synchronisation',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Voulez-vous les synchroniser maintenant ?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.medicalBlue,
          ),
          child: const Text('Synchroniser'),
        ),
      ],
    );
  }
}