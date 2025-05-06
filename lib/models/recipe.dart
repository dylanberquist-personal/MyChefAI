// lib/models/recipe.dart
import 'profile.dart';
import 'nutrition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  DateTime? createdAt;

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
    this.createdAt,
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create a Recipe object from a Firestore Map
  factory Recipe.fromMap(Map<String, dynamic> data, String id) {
    // Create a proper timestamp
    DateTime? timestamp;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        timestamp = (data['createdAt'] as Timestamp).toDate();
      }
    }
    
    // Handle creator profile data
    Profile creatorProfile;
    if (data['creator'] != null) {
      if (data['creator'] is Map) {
        creatorProfile = Profile.fromMap(
          data['creator'] as Map<String, dynamic>,
          data['creator']['id'] ?? '',
        );
      } else if (data['creator'] is String) {
        // If creator is a String (which might be just an ID), create a minimal profile
        creatorProfile = Profile(
          id: data['creator'],
          uid: data['creator'],
          username: 'Unknown Creator',
          email: 'unknown@example.com',
          description: '',
        );
      } else {
        // Default profile if creator data is invalid
        creatorProfile = Profile(
          id: 'default-creator-id',
          uid: 'default-uid',
          username: 'Unknown Creator',
          email: 'default@example.com',
          description: 'No description available',
          chefScore: 0.0,
          numberOfReviews: 0,
          dietaryRestrictions: '',
        );
      }
    } else {
      // Default profile if no creator data
      creatorProfile = Profile(
        id: 'default-creator-id',
        uid: 'default-uid',
        username: 'Unknown Creator',
        email: 'default@example.com',
        description: 'No description available',
        chefScore: 0.0,
        numberOfReviews: 0,
        dietaryRestrictions: '',
      );
    }

    return Recipe(
      id: id,
      title: data['title'] ?? 'Untitled Recipe',
      image: data['image'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      categoryTags: List<String>.from(data['categoryTags'] ?? []),
      creator: creatorProfile,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (data['numberOfRatings'] as int?) ?? 0,
      numberOfFavorites: (data['numberOfFavorites'] as int?) ?? 0,
      nutritionInfo: data['nutritionInfo'] != null 
          ? Nutrition.fromMap(data['nutritionInfo']) 
          : Nutrition(
              numberOfServings: 1,
              caloriesPerServing: 0,
              carbs: 0,
              protein: 0,
              fat: 0,
              saturatedFat: 0,
              polyunsaturatedFat: 0,
              monounsaturatedFat: 0,
              transFat: 0,
              cholesterol: 0,
              sodium: 0,
              potassium: 0,
              fiber: 0,
              sugar: 0,
              vitaminA: 0,
              vitaminC: 0,
              calcium: 0,
              iron: 0,
              unit: 'g',
            ),
      isPublic: data['isPublic'] ?? true,
      isFavorited: data['isFavorited'] ?? false,
      createdAt: timestamp,
    );
  }
}