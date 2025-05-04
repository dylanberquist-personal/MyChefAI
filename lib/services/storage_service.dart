import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create reference with the user's ID as part of the path
      final ref = _storage.ref('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Set metadata to allow caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );

      // Upload the file
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Show progress if needed
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        print('Upload progress: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100}%');
      });

      // Wait for upload to complete
      final taskSnapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      throw 'Failed to upload image: ${e.message}';
    } catch (e) {
      print('General Error: $e');
      throw 'Failed to upload image: $e';
    }
  }
}