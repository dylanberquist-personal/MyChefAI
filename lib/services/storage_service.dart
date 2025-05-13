// lib/services/storage_service.dart

import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Check if the current user matches the userId
      if (_auth.currentUser?.uid != userId) {
        throw 'Permission denied: You can only upload your own profile images';
      }
      
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
  
  // Update the recipe image upload method to check permissions
  Future<String> uploadRecipeImage(String recipeId, File imageFile) async {
    try {
      // Ensure user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'You must be logged in to upload images';
      }
      
      // Use the current user's UID in the path to avoid permission issues
      // This ensures each user uploads to their own directory
      final userId = currentUser.uid;
      final ref = _storage.ref('user_uploads/$userId/recipes/$recipeId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Set metadata to allow caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );

      // Upload the file
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Show progress if needed
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        print('Recipe image upload progress: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100}%');
      });

      // Wait for upload to complete
      final taskSnapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      throw 'Failed to upload recipe image: ${e.message}';
    } catch (e) {
      print('General Error: $e');
      throw 'Failed to upload recipe image: $e';
    }
  }
}