import 'profile.dart';
import 'nutrition.dart';

class Recipe {
  String? id; // Unique ID for Firebase
  String title;
  String? image; // URL or file path
  List<String> ingredients;
  List<String> instructions;
  List<String> categoryTags; // Max 5
  Profile creator;
  double averageRating;
  int numberOfRatings;
  int numberOfFavorites;
  Nutrition nutritionInfo;
  bool isPublic;
  bool isFavorited;

  Recipe({
    this.id,
    required this.title,
    this.image,
    required this.ingredients,
    required this.instructions,
    required this.categoryTags,
    required this.creator,
    this.averageRating = 0.0,
    this.numberOfRatings = 0,
    this.numberOfFavorites = 0,
    required this.nutritionInfo,
    this.isPublic = true,
    this.isFavorited = false,
  });

  // Convert Recipe to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'ingredients': ingredients,
      'instructions': instructions,
      'categoryTags': categoryTags,
      'creator': creator.toMap(), // Convert Profile to a Map
      'averageRating': averageRating,
      'numberOfRatings': numberOfRatings,
      'numberOfFavorites': numberOfFavorites,
      'nutritionInfo': nutritionInfo.toMap(), // Convert Nutrition to a Map
      'isPublic': isPublic,
      'isFavorited': isFavorited,
    };
  }

  // Create a Recipe object from a Firestore Map
 factory Recipe.fromMap(Map<String, dynamic> data, String id) {
  return Recipe(
    id: id,
    title: data['title'] ?? 'Untitled Recipe',
    image: data['image'],
    ingredients: List<String>.from(data['ingredients'] ?? []),
    instructions: List<String>.from(data['instructions'] ?? []),
    categoryTags: List<String>.from(data['categoryTags'] ?? []),
    creator: data['creator'] != null
        ? Profile.fromMap(
            data['creator'],
            data['creator']['uid'] ?? '', // Use uid as the id
          )
        : Profile(
            id: 'default-creator-id',
            uid: 'default-uid',
            username: 'Unknown Creator',
            profilePicture: null,
            email: 'default@example.com',
            description: 'No description available',
            chefScore: 0.0,
            numberOfReviews: 0,
            dietaryRestrictions: '',
            myRecipes: [],
            myFavorites: [],
            isFollowing: false,
            followers: 0,
          ),
    averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
    numberOfRatings: (data['numberOfRatings'] as int?) ?? 0,
    numberOfFavorites: (data['numberOfFavorites'] as int?) ?? 0,
    nutritionInfo: Nutrition.fromMap(data['nutritionInfo'] ?? {}),
    isPublic: data['isPublic'] ?? true,
    isFavorited: data['isFavorited'] ?? false,
  );
}
}