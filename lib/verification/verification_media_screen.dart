import 'dart:io';
import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_neighbor_screen.dart';
import 'verification_untraced_screen.dart';

class VerificationMediaScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationMediaScreen({super.key, required this.verificationCase});

  @override
  State<VerificationMediaScreen> createState() =>
      _VerificationMediaScreenState();
}

class _VerificationMediaScreenState extends State<VerificationMediaScreen> {
  final LocationService _locationService = LocationService();
  final MediaService _mediaService = MediaService();

  bool _attaching = false;
  int? _activeGroupIndex;
  String? _locationError;

  VerificationCase get _case => widget.verificationCase;

  bool get _hasAnyPhoto =>
      _case.geoGroups.any((g) => g.photoPaths.isNotEmpty) ||
      _case.photoPaths.isNotEmpty;

  bool get _hasAnyGeoTag =>
      _case.geoGroups.any((g) => g.hasGeoTag) ||
      (_case.latitude != null && _case.longitude != null);

  @override
  void initState() {
    super.initState();
    _case.syncGeoFields();
  }

  GeoPhotoGroup? get _activeGroup {
    if (_activeGroupIndex == null) return null;
    if (_activeGroupIndex! < 0 || _activeGroupIndex! >= _case.geoGroups.length) {
      return null;
    }
    return _case.geoGroups[_activeGroupIndex!];
  }

  bool _sameLocation(double lat, double lng, GeoPhotoGroup group) {
    if (!group.hasGeoTag) return false;
    return (lat - group.latitude!).abs() < 0.00015 &&
        (lng - group.longitude!).abs() < 0.00015;
  }

  Future<void> _addPhoto({int? groupIndex}) async {
    if (_attaching) return;
    setState(() {
      _attaching = true;
      _locationError = null;
    });
    try {
      final file = await _mediaService.capturePhoto();
      if (file == null || !mounted) return;

      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        if (groupIndex != null &&
            groupIndex >= 0 &&
            groupIndex < _case.geoGroups.length) {
          _case.geoGroups[groupIndex].photoPaths.add(file.path);
          if (!_case.geoGroups[groupIndex].hasGeoTag && position != null) {
            _case.geoGroups[groupIndex].latitude = position.latitude;
            _case.geoGroups[groupIndex].longitude = position.longitude;
          }
          _activeGroupIndex = groupIndex;
        } else if (position != null) {
          final matchIndex = _case.geoGroups.indexWhere(
            (g) => _sameLocation(position.latitude, position.longitude, g),
          );
          if (matchIndex >= 0) {
            _case.geoGroups[matchIndex].photoPaths.add(file.path);
            _activeGroupIndex = matchIndex;
          } else {
            _case.geoGroups.add(
              GeoPhotoGroup(
                latitude: position.latitude,
                longitude: position.longitude,
                photoPaths: [file.path],
              ),
            );
            _activeGroupIndex = _case.geoGroups.length - 1;
          }
        } else {
          _case.geoGroups.add(
            GeoPhotoGroup(photoPaths: [file.path]),
          );
          _activeGroupIndex = _case.geoGroups.length - 1;
          _locationError =
              'Location unavailable. Enable GPS and grant location permission.';
        }
        _case.syncGeoFields();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Failed to get location.');
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  Future<void> _retryGroupLocation(int index) async {
    if (_attaching) return;
    setState(() {
      _attaching = true;
      _locationError = null;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        if (position != null) {
          final matchIndex = _case.geoGroups.indexWhere(
            (g) => _sameLocation(position.latitude, position.longitude, g),
          );
          if (matchIndex >= 0 && matchIndex != index) {
            _case.geoGroups[matchIndex].photoPaths
                .addAll(_case.geoGroups[index].photoPaths);
            _case.geoGroups.removeAt(index);
            _activeGroupIndex = matchIndex > index ? matchIndex - 1 : matchIndex;
          } else {
            _case.geoGroups[index].latitude = position.latitude;
            _case.geoGroups[index].longitude = position.longitude;
            _activeGroupIndex = index;
          }
          _case.syncGeoFields();
        } else {
          _locationError =
              'Location unavailable. Enable GPS and grant location permission.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Failed to get location.');
      }
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  void _removePhoto(int groupIndex, int photoIndex) {
    setState(() {
      final group = _case.geoGroups[groupIndex];
      group.photoPaths.removeAt(photoIndex);
      if (group.photoPaths.isEmpty) {
        _case.geoGroups.removeAt(groupIndex);
        if (_activeGroupIndex == groupIndex) {
          _activeGroupIndex = null;
        } else if (_activeGroupIndex != null &&
            _activeGroupIndex! > groupIndex) {
          _activeGroupIndex = _activeGroupIndex! - 1;
        }
      }
      _case.syncGeoFields();
    });
  }

  void _openFullView(List<String> paths, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoFullView(
          paths: paths,
          initialIndex: index,
        ),
      ),
    );
  }

  void _next() {
    _case.syncGeoFields();
    if (!_hasAnyPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach at least one photo')),
      );
      return;
    }
    if (!_hasAnyGeoTag) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _locationError ??
                'Location could not be attached. Enable GPS and try again.',
          ),
        ),
      );
      return;
    }

    VerificationStore.instance.saveDraft(_case, _case.traced! ? 3 : 7);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _case.traced!
            ? VerificationNeighborScreen(verificationCase: _case)
            : VerificationUntracedScreen(verificationCase: _case),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VStepScaffold(
      title: 'Photos',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_case.address.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _case.address,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                Text(
                  'Attach Photos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activeGroup == null
                      ? 'A new geo tag is created when location changes.'
                      : 'Photos will be added to the selected geo tag.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                _ActionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: _attaching ? null : () => _addPhoto(),
                ),
                if (_attaching) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (_locationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _locationError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_case.geoGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'No photos attached yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < _case.geoGroups.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _GeoGroupCard(
                index: i,
                group: _case.geoGroups[i],
                selected: _activeGroupIndex == i,
                attaching: _attaching && _activeGroupIndex == i,
                onSelect: () => setState(() => _activeGroupIndex = i),
                onAddPhoto: () => _addPhoto(groupIndex: i),
                onRetry: () => _retryGroupLocation(i),
                onRemovePhoto: (photoIndex) => _removePhoto(i, photoIndex),
                onOpenPhoto: (photoIndex) => _openFullView(
                  _case.geoGroups[i].photoPaths,
                  photoIndex,
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _GeoGroupCard extends StatelessWidget {
  final int index;
  final GeoPhotoGroup group;
  final bool selected;
  final bool attaching;
  final VoidCallback onSelect;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetry;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onOpenPhoto;

  const _GeoGroupCard({
    required this.index,
    required this.group,
    required this.selected,
    required this.attaching,
    required this.onSelect,
    required this.onAddPhoto,
    required this.onRetry,
    required this.onRemovePhoto,
    required this.onOpenPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    group.hasGeoTag
                        ? Icons.location_on_rounded
                        : Icons.location_off_outlined,
                    color: group.hasGeoTag
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geo Tag ${index + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          attaching && !group.hasGeoTag
                              ? 'Capturing location...'
                              : group.geoTagText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: group.hasGeoTag
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attaching && !group.hasGeoTag)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (!group.hasGeoTag)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    )
                  else
                    TextButton(
                      onPressed: onAddPhoto,
                      child: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < group.photoPaths.length; i++)
                    _PhotoThumb(
                      path: group.photoPaths[i],
                      onTap: () => onOpenPhoto(i),
                      onRemove: () => onRemovePhoto(i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoThumb({
    required this.path,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoFullView extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _PhotoFullView({
    required this.paths,
    required this.initialIndex,
  });

  @override
  State<_PhotoFullView> createState() => _PhotoFullViewState();
}

class _PhotoFullViewState extends State<_PhotoFullView> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.paths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(widget.paths[i]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
