import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

/// Handles uploads to Supabase Storage. Web-safe: uses bytes (uploadBinary),
/// never dart:io File.
class StorageService {
  final _sb = SupabaseService.instance;
  final _uuid = const Uuid();

  Future<String> uploadPropertyMedia({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
    final path = '${_sb.uid}/${_uuid.v4()}.$ext';
    await _sb.client.storage.from(Buckets.propertyMedia).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return _sb.client.storage.from(Buckets.propertyMedia).getPublicUrl(path);
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '${_sb.uid}/avatar.png';
    await _sb.client.storage.from(Buckets.avatars).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    final base =
        _sb.client.storage.from(Buckets.avatars).getPublicUrl(path);
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
