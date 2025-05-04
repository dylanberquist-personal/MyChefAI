import 'recipe.dart';

class Profile {
  String id; // Unique ID for Firebase (non-nullable)
  String uid; // Firebase Auth user ID (non-nullable)
  String username;
  String? profilePicture; // URL or file path
  String email;
  String description;
  Recipe? topRecipe; // Optional
  String? region;
  double chefScore;
  int numberOfReviews;
  String dietaryRestrictions;
  List<Recipe> myRecipes;
  List<Recipe> myFavorites;
  bool isFollowing;
  int followers;

  Profile({
    required this.id, // id is now required
    required this.uid, // uid is required
    required this.username,
    this.profilePicture,
    required this.email,
    this.description = '', // Default value
    this.topRecipe,
    this.region,
    this.chefScore = 0.0, // Default value
    this.numberOfReviews = 0, // Default value
    this.dietaryRestrictions = '', // Default value
    this.myRecipes = const [], // Default value
    this.myFavorites = const [], // Default value
    this.isFollowing = false, // Default value
    this.followers = 0, // Default value
  });

  // Convert Profile to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid, // Include uid in the map
      'username': username,
      'profilePicture': profilePicture,
      'email': email,
      'description': description,
      'topRecipe': topRecipe?.toMap(), // Convert Recipe to Map if not null
      'region': region,
      'chefScore': chefScore,
      'numberOfReviews': numberOfReviews,
      'dietaryRestrictions': dietaryRestrictions,
      'myRecipes': myRecipes.map((recipe) => recipe.toMap()).toList(), // Convert List<Recipe> to List<Map>
      'myFavorites': myFavorites.map((recipe) => recipe.toMap()).toList(), // Convert List<Recipe> to List<Map>
      'isFollowing': isFollowing,
      'followers': followers,
    };
  }

  // Create Profile from a Firebase document
 factory Profile.fromMap(Map<String, dynamic> data, String id) {
  return Profile(
    id: id,
    uid: data['uid'] ?? '', 
    username: data['username'] ?? 'Unknown User',
    profilePicture: data['profilePicture'],
    email: data['email'] ?? '',
    description: data['description'] ?? '',
    topRecipe: data['topRecipe'] != null 
        ? Recipe.fromMap(data['topRecipe'], data['topRecipe']['id'] ?? '')
        : null,
    region: data['region'], // This was missing previously
    chefScore: (data['chefScore'] as num?)?.toDouble() ?? 0.0,
    numberOfReviews: (data['numberOfReviews'] as int?) ?? 0,
    dietaryRestrictions: data['dietaryRestrictions'] ?? '',
    myRecipes: List<Recipe>.from(data['myRecipes']?.map((recipe) => Recipe.fromMap(recipe, recipe['id'])) ?? []),
    myFavorites: List<Recipe>.from(data['myFavorites']?.map((recipe) => Recipe.fromMap(recipe, recipe['id'])) ?? []),
    isFollowing: data['isFollowing'] ?? false,
    followers: (data['followers'] as int?) ?? 0,
  );
}
}