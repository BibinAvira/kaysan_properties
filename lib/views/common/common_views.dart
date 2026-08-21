import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_provider.dart';
import '../../widgets/common_widgets.dart';

/// Full-screen "No Internet" state — used as a router redirect target, as
/// opposed to the small in-shell banner which is used once already inside
/// the app. Retries by re-checking [networkStatusProvider].
class NoInternetView extends ConsumerWidget {
  const NoInternetView({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: EmptyStateView(
        icon: Icons.wifi_off,
        title: 'No Internet Connection',
        message: 'Please check your network settings and try again.',
        actionLabel: 'Retry',
        onActionTap: () {
          ref.invalidate(initialNetworkStatusProvider);
          onRetry?.call();
        },
      ),
    );
  }
}

/// Generic full-screen error state for unrecoverable navigation errors
/// (e.g. an unknown deep link route).
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyStateView(
        icon: Icons.error_outline,
        title: 'Something Went Wrong',
        message: message ?? 'An unexpected error occurred. Please try again.',
        actionLabel: onRetry != null ? 'Retry' : null,
        onActionTap: onRetry,
      ),
    );
  }
}
