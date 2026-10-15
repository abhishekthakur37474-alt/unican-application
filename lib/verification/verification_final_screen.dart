import 'dart:io';
import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_done_screen.dart';

class VerificationFinalScreen extends StatefulWidget {
  final VerificationCase verificationCase;
  final bool isReview;

  const VerificationFinalScreen({
    super.key,
    required this.verificationCase,
    this.isReview = false,
  });

  @override
  State<VerificationFinalScreen> createState() => _VerificationFinalScreenState();
}

class _VerificationFinalScreenState extends State<VerificationFinalScreen> {
  bool _submitting = false;

  Future<void> _onDone() async {
    if (_submitting) return;
    final c = widget.verificationCase;

    if (widget.isReview) {
      Navigator.pop(context);
      return;
    }

    setState(() => _submitting = true);
    try {
      await VerificationStore.instance.save(c);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => VerificationDoneScreen(verificationCase: c),
        ),
        (route) => route.settings.name == '/home' || route.isFirst,
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.verificationCase;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Complete')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            c.finalStatus,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Geo Tag',
                      value: c.geoTagText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Photos',
                      value: '${c.photoPaths.length}',
                    ),
                  ),
                ],
              ),
              if (c.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: c.photoPaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(c.photoPaths[i]),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Generated Remarks',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: c.remarksEntries.isEmpty
                    ? const Text('No remarks available')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0;
                              i < c.remarksEntries.length;
                              i++) ...[
                            if (i > 0)
                              Divider(
                                height: 18,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            Text.rich(
                              TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: c.remarksEntries[i].$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' - '),
                                  TextSpan(text: c.remarksEntries[i].$2),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _onDone,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}