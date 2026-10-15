import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/assigned_address_card.dart';
import 'assigned_address_detail_screen.dart';

class AssignedAddressesScreen extends StatelessWidget {
  const AssignedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final db = DatabaseService();

    return Scaffold(
      appBar: const AppTopBar(title: 'Assigned Addresses', showBack: true),
      body: SafeArea(
        child: uid == null
            ? const _EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Sign in required',
                subtitle: 'Log in to see assigned addresses',
              )
            : StreamBuilder<List<AssignedAddress>>(
                stream: db.watchAssignedAddresses(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    if (!SyncService.instance.online.value) {
                      return const _EmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'You are offline',
                        subtitle: 'Reconnect to load assigned addresses',
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load addresses',
                      subtitle: 'Check your connection and try again',
                    );
                  }

                  final items =
                      (snapshot.data ?? []).where((e) => e.isOpen).toList();
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No addresses assigned',
                      subtitle: 'New cases from admin will appear here',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AssignedAddressCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignedAddressDetailScreen(
                                assignedAddress: item,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
