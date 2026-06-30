import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AvatarStorageService {
  static const int _maxAvatarBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedContentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAvatar({
    required String userId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final contentType = image.mimeType ?? _contentTypeFromName(image.name);

    _validateAvatarFile(bytes.length, contentType);

    final extension = _extensionForContentType(contentType);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final reference = _storage.ref('avatars/$userId/$timestamp.$extension');

    await reference.putData(bytes, SettableMetadata(contentType: contentType));

    return reference.getDownloadURL();
  }

  void _validateAvatarFile(int byteLength, String contentType) {
    if (byteLength == 0) {
      throw const FormatException('File ảnh không hợp lệ.');
    }
    if (byteLength > _maxAvatarBytes) {
      throw const FormatException('Avatar không được vượt quá 5MB.');
    }
    if (!_allowedContentTypes.contains(contentType)) {
      throw const FormatException('Avatar chỉ hỗ trợ JPG, PNG, WEBP hoặc GIF.');
    }
  }

  String _contentTypeFromName(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  String _extensionForContentType(String contentType) {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }
}
