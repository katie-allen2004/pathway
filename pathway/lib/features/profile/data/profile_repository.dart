import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository {
final SupabaseClient supabase;
ProfileRepository({SupabaseClient? client})
  : supabase = client ?? Supabase.instance.client;

//////////// API methods for updating profile data ///////////

// Method: Return auth UUID string
Future<String> _getAuthUUID() async {
  final authUser = supabase.auth.currentUser;
  if (authUser == null) {
    throw Exception('Not logged in');
  }
  return authUser.id;
}

// Method: Map auth UUID -> user_id
Future<int> _getInternalUserId() async {
  final authUser = supabase.auth.currentUser;
  if (authUser == null) {
    throw Exception('Not logged in');
  }

  final row = await supabase
      .schema('pathway')
      .from('users')
      .select('user_id')
      .eq('external_id', authUser.id)
      .single();
  
  return (row['user_id'] as num).toInt();
}

// Method: Update avatar (optional) and return URL
Future<String?> _updateAvatar(XFile? photo) async {
  if (photo == null) return null;

  final authUser = supabase.auth.currentUser;
  if (authUser == null) {
    throw Exception('Not logged in');
  }

  final fileBytes = await photo.readAsBytes();
  final ext = (photo.name.contains('.'))
      ? photo.name.split('.').last
      : 'jpg';
  
  final path = '${authUser.id}/avatar.$ext';

  await supabase.storage.from('avatars').uploadBinary(
    path, 
    fileBytes, 
    fileOptions: const FileOptions(upsert: true)
  );

  return supabase.storage.from('avatars').getPublicUrl(path);

}

// Method: Update display_name + avatar_url in profiles
Future<void> _updateProfileRow({
  required String authUuid,
  required String? displayName,
  required String? avatarUrl,
}) async {
  final update = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };
  if (displayName != null) update['display_name'] = displayName;
  if (avatarUrl != null) update['avatar_url'] = avatarUrl;

  await supabase
      .schema('pathway')
      .from('profiles')
      .upsert(
        {
          'user_id': authUuid,
          ...update,
        },
        onConflict: 'user_id',
      );
}

// Method: Replace user's accessibility tags
Future<void> _replaceAccessibilityTags({
  required int userId,
  required List<String> tagNames,
}) async {
  await supabase
      .schema('pathway')
      .from('user_accessibility_tags')
      .delete()
      .eq('user_id', userId);
  
  if (tagNames.isEmpty) return;

  final tagRows = await supabase
      .schema('pathway')
      .from('accessibility_tags')
      .select('tag_id, tag_name')
      .inFilter('tag_name', tagNames);
  
  final tagIds = (tagRows as List)
      .map((r) => (r['tag_id'] as num).toInt())
      .toList();

  final inserts = tagIds
      .map((tagId) => {'user_id': userId, 'tag_id': tagId})
      .toList();

  await supabase
      .schema('pathway')
      .from('user_accessibility_tags')
      .insert(inserts);
}

Future<void> _changePasswordIfNeeded({
  required String currentPassword,
  required String newPassword,
}) async {
  if (newPassword.trim().isEmpty) return;

  final authUser = supabase.auth.currentUser;
  final email = authUser?.email;
  if (email == null) {
    throw Exception('Missing email for current user');
  }

  await supabase.auth.signInWithPassword(email: email, password: currentPassword);

  await supabase.auth.updateUser(UserAttributes(password: newPassword));
}

// Method: Public method to update profile
Future<void> updateProfile({
  required String displayName,
  XFile? photo,
  required List<String> tags,
  required String currentPassword,
  required String newPassword,
}) async {
  final authUuid = await _getAuthUUID();
  final userId = await _getInternalUserId();
  final avatarUrl = await _updateAvatar(photo);

  await _updateProfileRow(
    authUuid: authUuid,
    displayName: displayName.trim(),
    avatarUrl: avatarUrl,
  );

  await _replaceAccessibilityTags(
    userId: userId, 
    tagNames: tags,
  );

  await _changePasswordIfNeeded(
    currentPassword: currentPassword.trim(), 
    newPassword: newPassword.trim(),
  );
}

/////////// Getter methods for profile data ///////////
// Method: Retrieves user's display name
Future<String?> getDisplayName() async {
  final authUuid = await _getAuthUUID();

  final profileRow = await supabase
      .schema('pathway')
      .from('profiles')
      .select('display_name')
      .eq('user_id', authUuid)
      .maybeSingle();

  return profileRow?['display_name'] as String?;
}

// Method: Retrieve user's profile picture URL
Future<String?> getProfilePictureUrl() async {
  final authUuid = await _getAuthUUID();

  final profileRow = await supabase
      .schema('pathway')
      .from('profiles')
      .select('avatar_url')
      .eq('user_id', authUuid)
      .maybeSingle();

  return profileRow?['avatar_url'] as String?;
}

// Method: Retrieve user's accessibility tags
Future<List<String>?> getUserAccessibilityTags() async {
  final userId = await _getInternalUserId();

  final rows = await supabase
      .schema('pathway')
      .from('user_accessibility_tags')
      .select('accessibility_tags(tag_name)')
      .eq('user_id', userId);
  
  return (rows as List)
      .map((r) => r['accessibility_tags']?['tag_name'] as String?)
      .whereType<String>()
      .toList();
}
}
