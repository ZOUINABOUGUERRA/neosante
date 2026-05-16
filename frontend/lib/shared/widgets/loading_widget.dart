// frontend/lib/shared/widgets/loading_widget.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/colors.dart';

/// Custom loading widget with different styles
class LoadingWidget extends StatelessWidget {
  final String? message;
  final LoadingStyle style;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.style = LoadingStyle.circular,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoader(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoader() {
    switch (style) {
      case LoadingStyle.circular:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.medicalBlue,
          ),
        );
      case LoadingStyle.linear:
        return LinearProgressIndicator(
          color: AppColors.medicalBlue,
          backgroundColor: Colors.grey[200],
        );
      case LoadingStyle.lottie:
        return SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            'assets/animations/loading.json',
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator(
                color: AppColors.medicalBlue,
              );
            },
          ),
        );
      case LoadingStyle.skeleton:
        return _buildSkeletonLoader();
    }
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Container(width: double.infinity, height: 100, color: Colors.grey[200]),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 20, color: Colors.grey[200]),
        const SizedBox(height: 8),
        Container(width: double.infinity, height: 20, color: Colors.grey[200]),
      ],
    );
  }
}

/// Loading overlay that covers the entire screen
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.medicalBlue,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!, style: const TextStyle(fontSize: 16)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton loading for cards
class SkeletonCard extends StatelessWidget {
  final bool isRectangular;

  const SkeletonCard({super.key, this.isRectangular = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 120, height: 16),
          const SizedBox(height: 12),
          if (isRectangular)
            Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[200],
            ),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: 200, height: 12),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Shimmer effect loading for lists
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const SizedBox(
              width: double.infinity,
              child: LoadingWidget(style: LoadingStyle.skeleton),
            )
          : child,
    );
  }
}

/// Loading button state
class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.medicalBlue,
        foregroundColor: foregroundColor ?? Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

/// Enum for loading styles
enum LoadingStyle { circular, linear, lottie, skeleton }
