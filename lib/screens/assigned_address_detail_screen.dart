import 'package:flutter/material.dart';

import '../models/assigned_address.dart';
import '../verification/verification_address_screen.dart';

class AssignedAddressDetailScreen extends StatelessWidget {
  final AssignedAddress assignedAddress;

  const AssignedAddressDetailScreen({
    super.key,
    required this.assignedAddress,
  });

  void _start(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationAddressScreen(
          assignedAddress: assignedAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = assignedAddress;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Verification Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 560.0 : double.infinity;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SummaryCard(item: item),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Applicant',
                    icon: Icons.badge_outlined,
                    rows: [
                      ('Name', item.applicantName),
                      ('Phone', item.phone),
                      ('Case ID', item.caseId),
                      ('Client', item.clientName),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Address',
                    icon: Icons.location_on_outlined,
                    rows: [
                      ('Address', item.addressLine),
                      ('Landmark', item.landmark),
                      ('City', item.city),
                      ('State', item.state),
                      ('Pincode', item.pincode),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Assignment',
                    icon: Icons.assignment_outlined,
                    rows: [
                      ('Type', item.verificationType),
                      ('Priority', item.priority),
                      ('Assigned At', _formatDateTime(item.assignedAt)),
                    ],
                    status: item.status,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: item.isClosed
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _start(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    'Start Verification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AssignedAddress item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        item.applicantName.isEmpty ? item.caseId : item.applicantName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Icons.home_work_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (item.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.fullAddress,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                ],
                if (item.caseId.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.caseId,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.2,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  final String? status;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = rows
        .where((e) => e.$1.isNotEmpty && e.$2.trim().isNotEmpty)
        .toList();
    final showStatus = status != null && status!.trim().isNotEmpty;
    if (visible.isEmpty && !showStatus) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < visible.length; i++) ...[
            _InfoRow(label: visible[i].$1, value: visible[i].$2),
            if (i != visible.length - 1 || showStatus) const _RowDivider(),
          ],
          if (showStatus) _StatusRow(status: status!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;

  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              'Status',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Spacer(),
          _StatusBadge(label: status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: green,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.45),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year}, $h:$m';
}
