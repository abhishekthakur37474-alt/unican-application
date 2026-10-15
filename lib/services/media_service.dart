import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
}
