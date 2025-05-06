import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';
import '../models/recipe.dart';
import 'recipe_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileService() : _firestore = FirebaseFirestore.instance;

  // Get the current user's ID
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  // Save a Profile to Firestore
  Future<void> saveProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.id).set(profile.toMap());
  }

  // Fetch a Profile by UID
  Future<Profile?> getProfileById(String uid) async {
    try {
      print('Fetching profile for UID: $uid'); // Debug log
      final querySnapshot = await _firestore
          .collection('profiles')
          .where('uid', isEqualTo: uid) // Query by the uid field
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        print('Fetched profile data: ${doc.data()}'); // Debug log
        return Profile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        print('Profile not found for UID: $uid'); // Debug log
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e'); // Debug log
      return null;
    }
  }

  // Search Profiles by Username
  Future<List<Profile>> searchProfilesByUsername(String username) async {
    QuerySnapshot snapshot = await _firestore
        .collection('profiles')
        .where('username', isGreaterThanOrEqualTo: username)
        .where('username', isLessThan: username + 'z')
        .get();

    return snapshot.docs
        .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Update a Profile
  Future<void> updateProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.id).update(profile.toMap());
  }

  // Delete a Profile
  Future<void> deleteProfile(String id) async {
    await _firestore.collection('profiles').doc(id).delete();
  }

  // Follow a User
Future<void> followUser(String followerId, String followingId) async {
  try {
    // Begin a batch operation for atomic updates
    WriteBatch batch = _firestore.batch();
    
    // Get references to both profiles
    DocumentReference followerRef = _firestore.collection('profiles').doc(followerId);
    DocumentReference followingRef = _firestore.collection('profiles').doc(followingId);
    
    // Update follower's "following" list
    batch.update(followerRef, {
      'following': FieldValue.arrayUnion([followingId]),
    });
    
    // Update following user's followers list and increment count
    batch.update(followingRef, {
      'followers': FieldValue.arrayUnion([followerId]),
      'followerCount': FieldValue.increment(1), // Use increment operation
    });
    
    // Commit the batch
    await batch.commit();
    
    print('Successfully followed user: $followingId');
  } catch (e) {
    print('Error following user: $e');
    throw e;
  }
}

// Unfollow a User
Future<void> unfollowUser(String followerId, String followingId) async {
  try {
    // Begin a batch operation for atomic updates
    WriteBatch batch = _firestore.batch();
    
    // Get references to both profiles
    DocumentReference followerRef = _firestore.collection('profiles').doc(followerId);
    DocumentReference followingRef = _firestore.collection('profiles').doc(followingId);
    
    // Update follower's "following" list
    batch.update(followerRef, {
      'following': FieldValue.arrayRemove([followingId]),
    });
    
    // Update following user's followers list and decrement count
    batch.update(followingRef, {
      'followers': FieldValue.arrayRemove([followerId]),
      'followerCount': FieldValue.increment(-1), // Use increment operation
    });
    
    // Commit the batch
    await batch.commit();
    
    print('Successfully unfollowed user: $followingId');
  } catch (e) {
    print('Error unfollowing user: $e');
    throw e;
  }
}

  // Check if current user follows a specific user
  Future<bool> checkIfFollowing(String targetUserId) async {
    String? currentUserId = await getCurrentUserId();
    if (currentUserId == null) return false;
    
    DocumentSnapshot doc = await _firestore.collection('profiles').doc(currentUserId).get();
    if (!doc.exists) return false;
    
    List<dynamic> following = (doc.data() as Map<String, dynamic>)['following'] ?? [];
    return following.contains(targetUserId);
  }

  // Fetch Followers
  Future<List<Profile>> getFollowers(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('profiles').doc(userId).get();
    List<String> followerIds = List<String>.from(doc['followers'] ?? []);
    List<Profile> followers = [];

    for (String id in followerIds) {
      Profile? profile = await getProfileById(id);
      if (profile != null) {
        followers.add(profile);
      }
    }

    return followers;
  }

  // Fetch Following
  Future<List<Profile>> getFollowing(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('profiles').doc(userId).get();
    List<String> followingIds = List<String>.from(doc['following'] ?? []);
    List<Profile> following = [];

    for (String id in followingIds) {
      Profile? profile = await getProfileById(id);
      if (profile != null) {
        following.add(profile);
      }
    }

    return following;
  }

  // Fetch User Recipes
  Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('creator.id', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching user recipes: $e');
      return [];
    }
  }

  // Fetch User Favorites
  Future<List<Recipe>> getUserFavorites(String userId, RecipeService recipeService) async {
    DocumentSnapshot doc = await _firestore.collection('profiles').doc(userId).get();
    List<String> favoriteIds = List<String>.from(doc['myFavorites'] ?? []);
    List<Recipe> favorites = [];

    for (String id in favoriteIds) {
      Recipe? recipe = await recipeService.getRecipeById(id);
      if (recipe != null) {
        favorites.add(recipe);
      }
    }

    return favorites;
  }

  // Fetch All Profiles
  Future<List<Profile>> getAllProfiles() async {
    QuerySnapshot snapshot = await _firestore.collection('profiles').get();
    return snapshot.docs
        .map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}