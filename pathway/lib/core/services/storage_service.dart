import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> pickAndUploadImage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final ImagePicker picker = ImagePicker();
    
    // the image
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return null;

    try {
      // bytes
      final Uint8List bytes = await image.readAsBytes();
      final String mimeType = image.mimeType ?? 'image/jpeg';
      final String extension = mimeType.split('/').last;
      final String fileName = "venue_${DateTime.now().millisecondsSinceEpoch}.$extension";
      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType, 
              upsert: true,
            ),
          );

      return fileName;
    } catch (e) {
      debugPrint('Supabase Storage Error: $e');
      return null;
    }
  }
}