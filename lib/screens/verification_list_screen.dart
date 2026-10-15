import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/verification_list_tile.dart';

class VerificationListScreen extends StatelessWidget {
  final String title;
  final bool favoritesOnly;
  final bool embedded;

  const VerificationListScreen({
    super.key,
    required this.title,
    this.favoritesOnly = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: ValueListenableBuilder<List<VerificationCase>>(
        valueListenable: VerificationStore.instance.cases,
        builder: (context, all, child) {
          final theme = Theme.of(context);
          final items =
              favoritesOnly ? all.where((e) => e.isFavorite).toList() : all;

          if (items.isEmpty) {
            return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      favoritesOnly
                          ? Icons.star_border_rounded
                          : Icons.fact_check_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      favoritesOnly
                          ? 'No favorites yet'
                          : 'No verifications yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      favoritesOnly
                          ? 'Star a completed case to see it here'
                          : 'Start a verification from Home',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return VerificationListTile(item: item);
              },
            );
          },
        ),
      );

    if (embedded) return content;
    return Scaffold(
      appBar: AppTopBar(title: title, showBack: true),
      body: content,
    );
  }
}
