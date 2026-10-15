import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/sync_service.dart';
import '../services/verification_store.dart';

class VerificationListTile extends StatelessWidget {
  final VerificationCase item;
  final VoidCallback? onTap;

  const VerificationListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.finalStatus,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (SyncService.instance.isPending(item.localKey))
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 18,
                    color: Colors.orange,
                  ),
                ),
              IconButton(
                tooltip: item.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  item.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: item.isFavorite
                      ? Colors.amber
                      : theme.colorScheme.outline,
                ),
                onPressed: () =>
                    VerificationStore.instance.toggleFavorite(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month - 1]} ${value.year}, $h:$m';
  }
}
