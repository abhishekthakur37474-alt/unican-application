import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../screens/notifications_screen.dart';
import '../verification/verification_address_screen.dart';
import 'database_service.dart';

/// Resolves an FCM notification tap (foreground, background or terminated)
/// into the assigned verification case and navigates to it.
///
/// If the tap arrives before the user/navigator is ready, the target is
/// stashed and retried via [flushPending].
class NotificationRouter {
  NotificationRouter._();

  static final NotificationRouter instance = NotificationRouter._();

  /// Attached to [MaterialApp] so taps can navigate without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final DatabaseService _db = DatabaseService();

  Map<String, dynamic>? _pending;
  bool _pendingAlerts = false;

  bool get hasPending => _pending != null;

  /// Opens the notifications list. Used for alert taps that are not tied to a
  /// specific case. Queued until the navigator is ready if needed.
  void openNotifications() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingAlerts = true;
      return;
    }
    _pendingAlerts = false;
    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Entry point for FCM message data payloads.
  void handleData(Map<String, dynamic> data) {
    _pending = <String, dynamic>{
      'type': data['type'],
      'caseId': data['caseId'],
      'addressId': data['addressId'],
      'notificationId': data['notificationId'],
    };
    _tryOpen();
  }

  /// Retry a tap stashed before the navigator/user was available.
  void flushPending() {
    if (_pendingAlerts) openNotifications();
    if (_pending == null) return;
    _tryOpen();
  }

  Future<void> _tryOpen() async {
    final data = _pending;
    if (data == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final caseId = (data['caseId'] ?? '').toString();
    final addressId = (data['addressId'] ?? '').toString();
    final notificationId = (data['notificationId'] ?? '').toString();

    if (caseId.isEmpty && addressId.isEmpty) {
      _pending = null;
      openNotifications();
      return;
    }

    // Consume the target now to avoid repeated navigation on rebuilds.
    _pending = null;

    AssignedAddress? assigned;
    try {
      assigned = await _db.getAssignedAddressByCaseId(caseId);
      assigned ??= await _db.getAssignedAddressById(addressId);
    } catch (_) {}

    if (notificationId.isNotEmpty) {
      try {
        await _db.markNotificationRead(uid, notificationId);
      } catch (_) {}
    }

    if (assigned != null && assigned.isClosed) return;

    assigned ??= AssignedAddress(
      id: addressId,
      addressLine: '',
      applicantName: '',
      assignedToStaffEmail: '',
      assignedToStaffId: uid,
      assignedToStaffName: '',
      caseId: caseId,
      city: '',
      clientName: '',
      landmark: '',
      phone: '',
      pincode: '',
      priority: '',
      state: '',
      status: 'Assigned',
      verificationType: '',
    );

    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => VerificationAddressScreen(assignedAddress: assigned!),
      ),
    );
  }
}
