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

// Get more recent recipes with pagination
Future<List<Recipe>> getMoreRecentRecipes(int limit, DateTime? lastTimestamp) async {
  try {
    Query query = _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    
    // If we have a lastTimestamp, start after it
    if (lastTimestamp != null) {
      query = query.startAfter([Timestamp.fromDate(lastTimestamp)]);
    }
    
    QuerySnapshot snapshot = await query.get();

    return snapshot.docs
        .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  } catch (e) {
    print('Error fetching more recent recipes: $e');
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

// Toggle favorite status for a recipe
Future<void> toggleFavorite(String recipeId, String userId) async {
  try {
    // Get the recipe
    DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
    
    // Get the user profile
    DocumentSnapshot profileDoc = await _firestore.collection('profiles').doc(userId).get();
    
    if (!recipeDoc.exists || !profileDoc.exists) {
      throw 'Recipe or profile not found';
    }
    
    // Check if recipe is already favorited
    List<String> favorites = List<String>.from(profileDoc['myFavorites'] ?? []);
    bool isFavorited = favorites.contains(recipeId);
    
    // Use a batch to update both documents atomically
    WriteBatch batch = _firestore.batch();
    
    // Update profile favorites
    if (isFavorited) {
      // Remove from favorites
      batch.update(
        _firestore.collection('profiles').doc(userId),
        {'myFavorites': FieldValue.arrayRemove([recipeId])}
      );
      
      // Decrement favorite count
      batch.update(
        _firestore.collection('recipes').doc(recipeId),
        {'numberOfFavorites': FieldValue.increment(-1)}
      );
    } else {
      // Add to favorites
      batch.update(
        _firestore.collection('profiles').doc(userId),
        {'myFavorites': FieldValue.arrayUnion([recipeId])}
      );
      
      // Increment favorite count
      batch.update(
        _firestore.collection('recipes').doc(recipeId),
        {'numberOfFavorites': FieldValue.increment(1)}
      );
    }
    
    // Commit the batch
    await batch.commit();
    
  } catch (e) {
    print('Error toggling favorite: $e');
    throw e;
  }
}

// Check if a recipe is favorited by the current user
Future<bool> isRecipeFavorited(String recipeId, String userId) async {
  try {
    DocumentSnapshot profileDoc = await _firestore.collection('profiles').doc(userId).get();
    
    if (!profileDoc.exists) {
      return false;
    }
    
    List<String> favorites = List<String>.from(profileDoc['myFavorites'] ?? []);
    return favorites.contains(recipeId);
  } catch (e) {
    print('Error checking favorite status: $e');
    return false;
  }
}

// Get updated recipe with latest favorite count
Future<Recipe?> getUpdatedRecipe(String recipeId) async {
  try {
    final doc = await _firestore.collection('recipes').doc(recipeId).get();
    if (doc.exists) {
      return Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  } catch (e) {
    print('Error fetching updated recipe: $e');
    return null;
  }
}

// Get recipes from followed profiles
Future<List<Recipe>> getRecipesFromFollowing(List<String> followingIds, int limit) async {
  try {
    // Handling Firestore's limitation of whereIn with max 10 values
    if (followingIds.length > 10) {
      // For simplicity, just use first 10
      followingIds = followingIds.sublist(0, 10);
    }
    
    // Check if the list is empty
    if (followingIds.isEmpty) {
      print('Following IDs list is empty, returning empty recipe list');
      return [];
    }
    
    print('Fetching recipes for followingIds: $followingIds');
    
    try {
      // First attempt with compound query (requires index)
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('creator.uid', whereIn: followingIds)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      print('Found ${snapshot.docs.length} recipes from followed profiles');
      
      List<Recipe> recipes = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('Recipe data: ${data['title']} by creator: ${data['creator']['uid']}');
          recipes.add(Recipe.fromMap(data, doc.id));
        } catch (e) {
          print('Error parsing recipe document: $e');
        }
      }
      
      return recipes;
    } catch (e) {
      // If index doesn't exist, fall back to a simpler query without ordering
      print('Index-based query failed, falling back to simpler query: $e');
      
      // Try with just the whereIn clause (doesn't require index)
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('creator.uid', whereIn: followingIds)
          .limit(limit)
          .get();
      
      print('Found ${snapshot.docs.length} recipes in fallback query');
      
      List<Recipe> recipes = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('Recipe data (fallback): ${data['title']} by creator: ${data['creator']['uid']}');
          recipes.add(Recipe.fromMap(data, doc.id));
        } catch (e) {
          print('Error parsing recipe document: $e');
        }
      }
      
      // Sort the results locally since we couldn't use orderBy in the query
      recipes.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!); // Descending order
      });
      
      return recipes;
    }
  } catch (e) {
    print('Error fetching recipes from following: $e');
    return [];
  }
}

// Get more recipes from followed profiles with pagination
Future<List<Recipe>> getMoreRecipesFromFollowing(List<String> followingIds, int limit, DateTime? lastTimestamp) async {
  try {
    // Handling Firestore's limitation of whereIn with max 10 values
    if (followingIds.length > 10) {
      // For simplicity, just use first 10 - in a real app you'd implement chunking
      followingIds = followingIds.sublist(0, 10);
    }
    
    // Check if the list is empty
    if (followingIds.isEmpty) {
      return [];
    }
    
    Query query = _firestore
        .collection('recipes')
        .where('creator.uid', whereIn: followingIds)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    
    // If we have a lastTimestamp, start after it
    if (lastTimestamp != null) {
      query = query.startAfter([Timestamp.fromDate(lastTimestamp)]);
    }
    
    QuerySnapshot snapshot = await query.get();
    
    List<Recipe> recipes = [];
    for (var doc in snapshot.docs) {
      try {
        recipes.add(Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id));
      } catch (e) {
        print('Error parsing recipe document: $e');
      }
    }
    
    return recipes;
  } catch (e) {
    print('Error fetching more recipes from following: $e');
    return [];
  }
}
}