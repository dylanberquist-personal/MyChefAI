import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a Recipe to Firestore
  Future<void> saveRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  // Fetch a Recipe by ID
Future<Recipe?> getRecipeById(String id) async {
  DocumentSnapshot doc = await _firestore.collection('recipes').doc(id).get();
  if (doc.exists) {
    return Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
  return null;
}

// Search Recipes by Title
Future<List<Recipe>> searchRecipesByTitle(String title) async {
  QuerySnapshot snapshot = await _firestore
      .collection('recipes')
      .where('title', isGreaterThanOrEqualTo: title)
      .where('title', isLessThan: title + 'z')
      .get();

  return snapshot.docs
      .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}

// Search Recipes by Category Tags
Future<List<Recipe>> searchRecipesByCategoryTags(List<String> tags) async {
  QuerySnapshot snapshot = await _firestore
      .collection('recipes')
      .where('categoryTags', arrayContainsAny: tags)
      .get();

  return snapshot.docs
      .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}

// Search Recipes by Creator
Future<List<Recipe>> searchRecipesByCreator(String creatorId) async {
  QuerySnapshot snapshot = await _firestore
      .collection('recipes')
      .where('creator.id', isEqualTo: creatorId)
      .get();

  return snapshot.docs
      .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}

// Search Recipes by Rating
Future<List<Recipe>> searchRecipesByRating(double minRating) async {
  QuerySnapshot snapshot = await _firestore
      .collection('recipes')
      .where('averageRating', isGreaterThanOrEqualTo: minRating)
      .get();

  return snapshot.docs
      .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .toList();
}

// Update a Recipe
Future<void> updateRecipe(Recipe recipe) async {
  await _firestore.collection('recipes').doc(recipe.id).update(recipe.toMap());
}

// Get recent recipes with a limit
Future<List<Recipe>> getRecentRecipes(int limit) async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  } catch (e) {
    print('Error fetching recent recipes: $e');
    return [];
  }
}

// Delete a Recipe
Future<void> deleteRecipe(String id) async {
  await _firestore.collection('recipes').doc(id).delete();
}

Future<Recipe?> getRandomRecipe() async {
  try {
    QuerySnapshot snapshot = await _firestore.collection('recipes').get();
    if (snapshot.docs.isNotEmpty) {
      var randomDoc = snapshot.docs[Random().nextInt(snapshot.docs.length)];
      print('Fetched recipe data: ${randomDoc.data()}'); // Log the fetched data
      return Recipe.fromMap(randomDoc.data() as Map<String, dynamic>, randomDoc.id);
    } else {
      print('No recipes found in Firestore.'); // Log if no recipes exist
      return null;
    }
  } catch (e) {
    print('Error fetching random recipe: $e'); // Log any errors
    return null;
  }
}
}