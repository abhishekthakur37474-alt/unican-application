import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'permission_service.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissions = PermissionService();

  Future<XFile?> capturePhoto() async {
    if (!Platform.isAndroid) return null;
    if (!await _permissions.requestCamera()) return null;
    return _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
      requestFullMetadata: false,
    );
  }

  /// Persists a rasterised (geo-tagged) photo to app storage and returns its
  /// absolute path, or null when the bytes could not be written.
  Future<String?> saveImageBytes(
    Uint8List bytes, {
    String prefix = 'geotag',
  }) async {
    if (bytes.isEmpty) return null;
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${baseDir.path}/geo_tagged_photos');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
