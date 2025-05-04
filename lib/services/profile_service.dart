import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../models/recipe.dart';
import 'recipe_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService() : _firestore = FirebaseFirestore.instance;

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
    await _firestore.collection('profiles').doc(followerId).update({
      'following': FieldValue.arrayUnion([followingId]),
    });
    await _firestore.collection('profiles').doc(followingId).update({
      'followers': FieldValue.arrayUnion([followerId]),
    });
  }

  // Unfollow a User
  Future<void> unfollowUser(String followerId, String followingId) async {
    await _firestore.collection('profiles').doc(followerId).update({
      'following': FieldValue.arrayRemove([followingId]),
    });
    await _firestore.collection('profiles').doc(followingId).update({
      'followers': FieldValue.arrayRemove([followerId]),
    });
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