import 'package:flutter/material.dart';

import '../models/verification_case.dart';
import '../services/sync_service.dart';
import '../services/verification_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

/// Report screen: how many addresses this staff member has verified, a
/// breakdown by result, and the full list of completed verifications.
class VerifiedAddressesScreen extends StatelessWidget {
  final bool embedded;

  const VerifiedAddressesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: ValueListenableBuilder<List<VerificationCase>>(
          valueListenable: VerificationStore.instance.cases,
          builder: (context, all, child) {
            if (all.isEmpty) {
              return const _EmptyState();
            }
            final confirmed = <VerificationCase>[];
            final notConfirmed = <VerificationCase>[];
            final untraced = <VerificationCase>[];
            for (final c in all) {
              final status = c.finalStatus.toLowerCase();
              if (status.contains('untraced')) {
                untraced.add(c);
              } else if (status.contains('not confirmed')) {
                notConfirmed.add(c);
              } else if (status.contains('confirmed')) {
                confirmed.add(c);
              } else {
                confirmed.add(c);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TotalCard(
                  total: all.length,
                  pending: SyncService.instance.pendingCount.value,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.verified_rounded,
                        label: 'Confirmed',
                        count: confirmed.length,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.report_problem_outlined,
                        label: 'Not Confirmed',
                        count: notConfirmed.length,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.location_off_outlined,
                        label: 'Untraced',
                        count: untraced.length,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'All Verifications (${all.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _VerificationCard(item: all[index]),
                ),
              ],
            );
          },
        ),
      );

    if (embedded) return content;
    return Scaffold(
      appBar: const AppTopBar(title: 'Verified Addresses', showBack: true),
      body: content,
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int total;
  final int pending;

  const _TotalCard({required this.total, required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Addresses Verified',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$pending pending sync',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.assignment_turned_in_rounded,
            color: theme.colorScheme.onPrimary,
            size: 52,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final VerificationCase item;

  const _VerificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = SyncService.instance.isPending(item.localKey);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.isFavorite
                          ? Icons.star_rounded
                          : Icons.fact_check_outlined,
                      color: item.isFavorite
                          ? Colors.amber
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.applicantName.isEmpty
                              ? item.address
                              : item.applicantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(label: item.finalStatus),
                  if (item.caseId.isNotEmpty) _Chip(label: item.caseId),
                  if (item.clientName.isNotEmpty)
                    _Chip(label: item.clientName),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No verifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Completed verifications will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
