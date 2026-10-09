import 'dart:io';

import 'package:flutter/material.dart';

import '../models/verification_case.dart';
import '../services/sync_service.dart';

class VerificationDetailScreen extends StatelessWidget {
  final VerificationCase verificationCase;

  const VerificationDetailScreen({super.key, required this.verificationCase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = verificationCase;
    final pending = SyncService.instance.isPending(c.localKey);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Not synced yet. Details will upload automatically '
                        'when you are online.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            _StatusCard(verificationCase: c),
            const SizedBox(height: 14),
            _Section(
              title: 'Applicant & Case',
              icon: Icons.badge_outlined,
              entries: [
                ('Applicant Name', c.applicantName),
                ('Case ID', c.caseId),
                ('Client Name', c.clientName),
                ('Phone', c.phone),
                ('Address', c.address),
                ('Address Key', c.firebaseKey),
                ('Created At', _formatDateTime(c.createdAt)),
              ],
            ),
            _Section(
              title: 'Result',
              icon: Icons.fact_check_outlined,
              entries: [
                ('Final Status', c.finalStatus),
                ('Traced', _yesNo(c.traced)),
                (
                  'Applicant Residing There',
                  c.applicantResidingThere == null
                      ? ''
                      : _yesNo(c.applicantResidingThere),
                ),
                ('Favorite', c.isFavorite ? 'Yes' : 'No'),
              ],
            ),
            _Section(
              title: 'Geo Tag & Photos',
              icon: Icons.location_on_outlined,
              entries: [
                ('Geo Tag', c.geoTagText),
                ('Photos Captured', '${c.photoPaths.length}'),
                ('Photos Uploaded', '${c.photoUrls.length}'),
              ],
            ),
            if (c.photoPaths.isNotEmpty) _PhotoStrip(paths: c.photoPaths),
            if (c.untracedComments.isNotEmpty ||
                c.reasonOfUntraced.isNotEmpty ||
                c.lastLocation.isNotEmpty)
              _Section(
                title: 'Untraced Details',
                icon: Icons.report_gmailerrorred_outlined,
                entries: [
                  ('Reason of Untraced', c.reasonOfUntraced),
                  ('Require to Trace', c.requireToTrace),
                  ('Calling Response', c.callingResponse),
                  ('Last Location', c.lastLocation),
                  ('Comments', c.untracedComments),
                ],
              ),
            if (c.neighbor1.isNotEmpty ||
                c.neighbor2.isNotEmpty ||
                c.neighborConfirmed != null)
              _Section(
                title: 'Neighbour Check',
                icon: Icons.people_alt_outlined,
                entries: [
                  ('1st Neighbour', c.neighbor1),
                  ('2nd Neighbour', c.neighbor2),
                  ('Neighbours Confirmed', _yesNo(c.neighborConfirmed)),
                ],
              ),
            if (c.metPersonName.isNotEmpty ||
                c.relationWithApplicant.isNotEmpty ||
                c.residenceConfirmation.isNotEmpty ||
                c.whoIsThat.isNotEmpty ||
                c.residenceConfirmationB2.isNotEmpty)
              _Section(
                title: 'Residence Details',
                icon: Icons.home_work_outlined,
                entries: [
                  ('Met Person Name', c.metPersonName),
                  ('Relation with Applicant', c.relationWithApplicant),
                  ('Who Is That', c.whoIsThat),
                  ('Residence Confirmation', c.residenceConfirmation),
                  ('Residence Confirmation (B)', c.residenceConfirmationB2),
                  ('Tenure of Residence', c.tenureOfResidence),
                  ('Ownership of Residence', c.ownershipOfResidence),
                  ('Rent Amount', c.rentAmount),
                  ('Landlord Name', c.landlordName),
                  ('Building Description', c.buildingDescription),
                  ('Total Floors', c.totalFloors),
                  ('Total Floors (B)', c.totalFloorsB2),
                  ('Applicant Floor', c.applicantFloor),
                  ('Address Floor (B)', c.addressFloorB2),
                  ('Land Area', c.landArea),
                  ('Land Area (B)', c.landAreaB2),
                  ('Locality of Address', c.localityOfAddress),
                  ('Locality (B)', c.localityB2),
                  ('Document Shown', c.documentShown),
                  ('Total Family Members', c.totalFamilyMembers),
                  ('Number of Earners', c.numberOfEarners),
                  ('Verifier Comments', c.verifierComments),
                  ('Comments (B)', c.commentsB2),
                ],
              ),
            if (c.generatedRemarks.isNotEmpty)
              _Section(
                title: 'Generated Remarks',
                icon: Icons.notes_outlined,
                entries: [('', c.generatedRemarks)],
              ),
            if (c.photoUrls.isNotEmpty)
              _Section(
                title: 'Hosted Photo URLs',
                icon: Icons.cloud_done_outlined,
                entries: [
                  for (var i = 0; i < c.photoUrls.length; i++)
                    ('Photo ${i + 1}', c.photoUrls[i]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final VerificationCase verificationCase;

  const _StatusCard({required this.verificationCase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = verificationCase;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: theme.colorScheme.primary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.applicantName.isEmpty ? 'Verification' : c.applicantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.finalStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> entries;

  const _Section({
    required this.title,
    required this.icon,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = entries
        .where((e) => e.$1.isEmpty || e.$2.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in visible) ...[
            if (entry.$1.isEmpty)
              Text(entry.$2, style: theme.textTheme.bodyMedium)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<String> paths;

  const _PhotoStrip({required this.paths});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: paths.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(paths[i]),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 96,
                height: 96,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _yesNo(bool? value) {
  if (value == null) return '';
  return value ? 'Yes' : 'No';
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year}, $h:$m';
}
