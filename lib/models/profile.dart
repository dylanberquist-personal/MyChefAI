import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  String id; // Unique ID for Firebase (non-nullable)
  String uid; // Firebase Auth user ID (non-nullable)
  String username;
  String? profilePicture; // URL or file path
  String email;
  String description;
  String? topRecipeId; // Store recipe ID instead of full Recipe object
  String? region;
  double chefScore;
  int? numberOfReviews;
  String dietaryRestrictions;
  List<String> myRecipes; // Store recipe IDs as strings
  List<String> myFavorites; // Store recipe IDs as strings
  bool isFollowing;
  int followers;
  List<String> following; // Store user IDs that this user follows
  int followerCount;

  Profile({
    required this.id,
    required this.uid,
    required this.username,
    this.profilePicture,
    required this.email,
    this.description = '',
    this.topRecipeId,
    this.region,
    this.chefScore = 0.0,
    this.numberOfReviews = 0,
    this.dietaryRestrictions = '',
    this.myRecipes = const [],
    this.myFavorites = const [],
    this.isFollowing = false,
    this.followers = 0,
    this.following = const [],
    this.followerCount = 0,
  });

  // Convert Profile to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'profilePicture': profilePicture,
      'email': email,
      'description': description,
      'topRecipeId': topRecipeId,
      'region': region,
      'chefScore': chefScore,
      'numberOfReviews': numberOfReviews,
      'dietaryRestrictions': dietaryRestrictions,
      'myRecipes': myRecipes,
      'myFavorites': myFavorites,
      'isFollowing': isFollowing,
      'followers': followers,
      'following': following,
      'followerCount': followerCount,
    };
  }

  // Create Profile from a Firebase document
  factory Profile.fromMap(Map<String, dynamic> data, String id) {
    // Safe conversion for integer fields
    int? safeIntFromField(dynamic field) {
      if (field == null) return null;
      if (field is int) return field;
      if (field is double) return field.toInt();
      if (field is String) return int.tryParse(field);
      if (field is List) return field.length; // Convert lists to their length as a fallback
      return null;
    }

    // Handle myRecipes list
    List<String> recipesList = [];
    if (data['myRecipes'] != null) {
      if (data['myRecipes'] is List) {
        recipesList = List<String>.from(
          (data['myRecipes'] as List).map((item) => 
            item is String ? item : (item is Map ? item['id'] ?? '' : ''))
        );
      }
    }
    
    // Handle myFavorites list
    List<String> favoritesList = [];
    if (data['myFavorites'] != null) {
      if (data['myFavorites'] is List) {
        favoritesList = List<String>.from(
          (data['myFavorites'] as List).map((item) => 
            item is String ? item : (item is Map ? item['id'] ?? '' : ''))
        );
      }
    }
    
    // Handle following list
    List<String> followingList = [];
    if (data['following'] != null) {
      if (data['following'] is List) {
        followingList = List<String>.from(data['following']);
      }
    }

    return Profile(
      id: id,
      uid: data['uid'] ?? id, 
      username: data['username'] ?? 'Unknown User',
      profilePicture: data['profilePicture'],
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      topRecipeId: data['topRecipeId'],
      region: data['region'],
      chefScore: (data['chefScore'] is num) ? (data['chefScore'] as num).toDouble() : 0.0,
      numberOfReviews: safeIntFromField(data['numberOfReviews']),
      dietaryRestrictions: data['dietaryRestrictions'] ?? '',
      myRecipes: recipesList,
      myFavorites: favoritesList,
      isFollowing: data['isFollowing'] ?? false,
      followers: safeIntFromField(data['followers']) ?? 0,
      following: followingList,
      followerCount: safeIntFromField(data['followerCount']) ?? 0,
    );
  }
}