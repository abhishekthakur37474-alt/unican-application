import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/assigned_address.dart';
import '../models/staff_notification.dart';
import '../services/app_settings.dart';
import '../services/database_service.dart';
import '../verification/verification_address_screen.dart';
import '../widgets/app_top_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseService _db = DatabaseService();

  String _timeLabel(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Future<void> _openNotification(StaffNotification item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !item.read) {
      _db.markNotificationRead(uid, item.id);
    }

    AssignedAddress? assigned;
    try {
      assigned = await _db.getAssignedAddressByCaseId(item.caseId);
    } catch (_) {}

    if (assigned != null && assigned.isClosed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This case is closed')),
      );
      return;
    }

    assigned ??= AssignedAddress(
      id: '',
      addressLine: item.address,
      applicantName: item.applicantName,
      assignedToStaffEmail: '',
      assignedToStaffId: uid ?? '',
      assignedToStaffName: '',
      caseId: item.caseId,
      city: '',
      clientName: item.clientName,
      landmark: '',
      phone: item.phone,
      pincode: '',
      priority: item.priority,
      state: '',
      status: 'Assigned',
      verificationType: item.verificationType,
    );

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationAddressScreen(assignedAddress: assigned!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: const AppTopBar(title: 'Notifications', showBack: true),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
        valueListenable: AppSettings.instance.verificationAlerts,
        builder: (context, alertsEnabled, child) {
          if (!alertsEnabled) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verification alerts are off',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (uid == null) {
            return Center(
              child: Text(
                'Sign in to see alerts',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return StreamBuilder<List<StaffNotification>>(
            stream: _db.watchStaffNotifications(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load notifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: item.read
                        ? theme.colorScheme.surfaceContainerHigh
                        : theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openNotification(item),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.message.isEmpty
                                        ? 'New verification assigned'
                                        : item.message,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: item.read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.address,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _timeLabel(item.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.outline,
                            ),
                          ],
                        ),
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
