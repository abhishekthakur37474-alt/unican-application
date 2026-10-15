import 'package:firebase_database/firebase_database.dart';
import '../models/assigned_address.dart';
import '../models/staff_notification.dart';
import '../models/verification_case.dart';

/// RTDB node structure (Firebase project: unican-33d3b)
///
/// root
///  ├── staff/{uid}
///  │     ├── name, role, deviceId
///  │     ├── oneSignalId, oneSignalIdUpdatedAt
///  │     └── fcmToken, fcmTokenUpdatedAt            // admin push targets
///  ├── staff_notifications/{uid}/{notificationId}  // admin -> app alerts
///  │     └── id, caseId, addressId, applicantName, phone, address,
///  │         clientName, verificationType, priority, timestamp,
///  │         read, type, message
///  ├── verification_addresses/{addressId}           // admin assigns work
///  │     ├── addressLine, applicantName, caseId, clientName, city,
///  │     ├── landmark, phone, pincode, priority, state, status,
///  │     └── assignedToStaffId, assignedToStaffName, assignedAt, createdAt
///  └── staff_verifications/{uid}/{caseId}           // app writes results
///        └── full VerificationCase map (VerificationCase.toMap)
///
/// Completed verifications are written locally first (Hive) and only then
/// mirrored here by SyncService; see that class for the offline queue.
class DatabaseService {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  /// Returns staff record for uid, or null if not a staff member.
  Future<Map<String, dynamic>?> getStaff(String uid) async {
    final snap = await _root.child('staff').child(uid).get();
    if (!snap.exists || snap.value is! Map) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<void> setStaffDeviceId(String uid, String deviceId) async {
    await _root.child('staff').child(uid).update({'deviceId': deviceId});
  }

  Future<void> updateStaffName(String uid, String name) async {
    await _root.child('staff').child(uid).update({'name': name});
  }

  Future<void> setStaffOneSignalId(String uid, String id) async {
    await _root.child('staff').child(uid).update({
      'oneSignalId': id,
      'oneSignalIdUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearStaffOneSignalId(String uid) async {
    await _root.child('staff').child(uid).update({'oneSignalId': null});
  }

  Future<void> setStaffFcmToken(String uid, String token) async {
    await _root.child('staff').child(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearStaffFcmToken(String uid) async {
    await _root.child('staff').child(uid).update({'fcmToken': null});
  }

  Future<List<AssignedAddress>> getAssignedAddresses(String staffId) async {
    final snap = await _root.child('verification_addresses').get();
    if (!snap.exists || snap.value is! Map) return [];

    final items = <AssignedAddress>[];
    for (final child in snap.children) {
      if (child.value is! Map) continue;
      final map = Map<String, dynamic>.from(child.value as Map);
      final item = AssignedAddress.fromMap(child.key ?? '', map);
      if (item.assignedToStaffId == staffId && item.isOpen) {
        items.add(item);
      }
    }

    items.sort((a, b) {
      final aTime = a.assignedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.assignedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return items;
  }

  Future<List<StaffNotification>> getStaffNotifications(String staffId) async {
    final snap = await _root.child('staff_notifications').child(staffId).get();
    if (!snap.exists || snap.value is! Map) return [];

    final items = <StaffNotification>[];
    for (final child in snap.children) {
      if (child.value is! Map) continue;
      items.add(
        StaffNotification.fromMap(
          child.key ?? '',
          Map<String, dynamic>.from(child.value as Map),
        ),
      );
    }

    items.sort((a, b) {
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return items;
  }

  Future<AssignedAddress?> getAssignedAddressById(String addressId) async {
    if (addressId.isEmpty) return null;
    final snap = await _root.child('verification_addresses').child(addressId).get();
    if (!snap.exists || snap.value is! Map) return null;
    return AssignedAddress.fromMap(
      addressId,
      Map<String, dynamic>.from(snap.value as Map),
    );
  }

  Future<AssignedAddress?> getAssignedAddressByCaseId(String caseId) async {
    if (caseId.isEmpty) return null;
    final snap = await _root.child('verification_addresses').get();
    if (!snap.exists || snap.value is! Map) return null;

    for (final child in snap.children) {
      if (child.value is! Map) continue;
      final map = Map<String, dynamic>.from(child.value as Map);
      final item = AssignedAddress.fromMap(child.key ?? '', map);
      if (item.caseId == caseId) return item;
    }
    return null;
  }

  Future<void> markNotificationRead(String staffId, String notificationId) async {
    await _root
        .child('staff_notifications')
        .child(staffId)
        .child(notificationId)
        .update({'read': true});
  }

  Future<void> updateAddressStatus(String addressId, String status) async {
    if (addressId.isEmpty) return;
    await _root.child('verification_addresses').child(addressId).update({
      'status': status,
    });
  }

  Stream<List<StaffNotification>> watchStaffNotifications(String staffId) {
    return _root.child('staff_notifications').child(staffId).onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value is! Map) return <StaffNotification>[];

      final items = <StaffNotification>[];
      for (final child in snap.children) {
        if (child.value is! Map) continue;
        items.add(
          StaffNotification.fromMap(
            child.key ?? '',
            Map<String, dynamic>.from(child.value as Map),
          ),
        );
      }
      items.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return items;
    });
  }

  Stream<List<AssignedAddress>> watchAssignedAddresses(String staffId) {
    return _root.child('verification_addresses').onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value is! Map) return <AssignedAddress>[];

      final items = <AssignedAddress>[];
      for (final child in snap.children) {
        if (child.value is! Map) continue;
        final item = AssignedAddress.fromMap(
          child.key ?? '',
          Map<String, dynamic>.from(child.value as Map),
        );
        if (item.assignedToStaffId == staffId) {
          items.add(item);
        }
      }
      items.sort((a, b) {
        final aTime =
            a.assignedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.assignedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return items;
    });
  }

  Stream<List<VerificationCase>> watchCompletedCases(String staffId) {
    return _root.child('staff_verifications').child(staffId).onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value is! Map) return <VerificationCase>[];

      final items = <VerificationCase>[];
      for (final child in snap.children) {
        if (child.value is! Map) continue;
        items.add(
          VerificationCase.fromMap(
            child.key ?? '',
            Map<String, dynamic>.from(child.value as Map),
          ),
        );
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> saveCompletedCase(String staffId, VerificationCase value) async {
    await _root
        .child('staff_verifications')
        .child(staffId)
        .child(value.id)
        .set(value.toMap());
  }

  Future<void> updateCaseFavorite(
    String staffId,
    String caseId,
    bool isFavorite,
  ) async {
    await _root
        .child('staff_verifications')
        .child(staffId)
        .child(caseId)
        .update({'isFavorite': isFavorite});
  }
}