import 'package:flutter/material.dart';

import '../../domain/models/song.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

/// A dismissible card representing a song in the list.
///
/// Swipe-to-delete is supported via [Dismissible]. Tapping the card invokes
/// [onTap].
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Future<bool> Function(DismissDirection)? confirmDismiss;
  final void Function(DismissDirection)? onDismissed;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.confirmDismiss,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(song.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: confirmDismiss,
      onDismissed: (direction) {
        onDismissed?.call(direction);
        onDelete?.call();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: kSpaceSm),
        decoration: const BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.all(Radius.circular(kBorderRadiusMd)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: kSpaceMd),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: kSpaceSm),
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusMd),
        ),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kBorderRadiusMd),
          splashColor: AppTheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(kSpaceMd),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: kSpaceXs),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                  color: AppTheme.surface,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.onSurface, size: 20),
                          SizedBox(width: kSpaceSm),
                          Text('Редактировать'),
                        ],
                      ),
                      onTap: () => onEdit?.call(),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.error, size: 20),
                          SizedBox(width: kSpaceSm),
                          Text('Удалить', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                      onTap: () => onDelete?.call(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
