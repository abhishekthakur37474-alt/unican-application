import 'package:flutter/material.dart';
import '../models/assigned_address.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_media_screen.dart';
import 'verification_neighbor_screen.dart';
import 'verification_not_confirmed_screen.dart';
import 'verification_confirmed_screen.dart';
import 'verification_residing_screen.dart';
import 'verification_untraced_screen.dart';

class VerificationAddressScreen extends StatefulWidget {
  final AssignedAddress assignedAddress;

  const VerificationAddressScreen({
    super.key,
    required this.assignedAddress,
  });

  @override
  State<VerificationAddressScreen> createState() =>
      _VerificationAddressScreenState();
}

class _VerificationAddressScreenState
    extends State<VerificationAddressScreen> {
  late final VerificationCase _case;
  String? _tracedChoice;
  int _resumeStep = 1;

  @override
  void initState() {
    super.initState();
    final assigned = widget.assignedAddress;

    final draft = VerificationStore.instance.getDraft(assigned.id);
    final draftCase = draft?['case'];
    if (draft != null && draftCase is Map) {
      final map = Map<String, dynamic>.from(draftCase);
      _case = VerificationCase.fromMap(
        (map['id'] ?? assigned.caseId).toString(),
        map,
      );
      _tracedChoice = _case.traced == null
          ? null
          : (_case.traced! ? 'Traced' : 'Untraced');
      _resumeStep = (draft['step'] as num?)?.toInt() ?? 1;
    } else {
      _case = VerificationCase(
        address: assigned.fullAddress,
        applicantName: assigned.applicantName,
        caseId: assigned.caseId,
        clientName: assigned.clientName,
        phone: assigned.phone,
        firebaseKey: assigned.id,
      );
      _resumeStep = 1;
    }

    if (assigned.isClosed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This case is closed')),
        );
        Navigator.pop(context);
      });
      return;
    }

    if (_resumeStep > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
    }
  }

  void _resume() {
    if (!mounted) return;
    final Widget screen;
    switch (_resumeStep) {
      case 2:
        screen = VerificationMediaScreen(verificationCase: _case);
        break;
      case 3:
        screen = VerificationNeighborScreen(verificationCase: _case);
        break;
      case 4:
        screen = VerificationConfirmedScreen(verificationCase: _case);
        break;
      case 5:
        screen = VerificationResidingScreen(verificationCase: _case);
        break;
      case 6:
        screen = VerificationNotConfirmedScreen(verificationCase: _case);
        break;
      case 7:
        screen = VerificationUntracedScreen(verificationCase: _case);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _next() {
    if (_tracedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Traced or Untraced first')),
      );
      return;
    }

    _case.traced = _tracedChoice == 'Traced';
    VerificationStore.instance.saveDraft(_case, 2);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationMediaScreen(verificationCase: _case),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assigned = widget.assignedAddress;

    return VStepScaffold(
      title: 'Residence Verification',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ApplicantCard(assigned: assigned),
          const SizedBox(height: 16),
          _AddressCard(
            address: _case.address,
            phone: assigned.phone,
          ),
          const SizedBox(height: 20),
          VOptionGroup(
            label: 'Was the address traced?',
            options: const ['Traced', 'Untraced'],
            value: _tracedChoice,
            onChanged: (v) => setState(() => _tracedChoice = v),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final AssignedAddress assigned;

  const _ApplicantCard({required this.assigned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (assigned.applicantName.isEmpty &&
        assigned.caseId.isEmpty &&
        assigned.clientName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assigned.applicantName.isNotEmpty)
                  Text(
                    assigned.applicantName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                if (assigned.caseId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    assigned.caseId,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                if (assigned.clientName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    assigned.clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String address;
  final String phone;

  const _AddressCard({
    required this.address,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Given Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
