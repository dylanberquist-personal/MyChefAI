// lib/services/recipe_service.dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../services/notification_service.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a Recipe to Firestore
  Future<void> saveRecipe(Recipe recipe) async {
    // Ensure all text fields are properly encoded
    final recipeMap = recipe.toMap();
    await _firestore.collection('recipes').doc(recipe.id).set(recipeMap);
  }

  // Create a new recipe and return its ID
  Future<String> createRecipe(Recipe recipe) async {
    try {
      // Create a new document reference
      final docRef = _firestore.collection('recipes').doc();
      
      // Create a copy of the recipe with the new ID
      final recipeWithId = Recipe(
        id: docRef.id,
        title: recipe.title,
        image: recipe.image,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        categoryTags: recipe.categoryTags,
        creator: recipe.creator,
        averageRating: recipe.averageRating,
        numberOfRatings: recipe.numberOfRatings,
        numberOfFavorites: recipe.numberOfFavorites,
        nutritionInfo: recipe.nutritionInfo,
        isPublic: recipe.isPublic,
        isFavorited: recipe.isFavorited,
        createdAt: recipe.createdAt ?? DateTime.now(),
      );
      
      // Save the recipe using its toMap method which handles encoding
      await docRef.set(recipeWithId.toMap());
      
      // Update the user's myRecipes array
      await _firestore.collection('profiles').doc(recipe.creator.id).update({
        'myRecipes': FieldValue.arrayUnion([docRef.id]),
      });
      
      print('Recipe created with ID: ${docRef.id} by user: ${recipe.creator.uid}');
      
      // Get followers to notify
      try {
        // Be more careful about the profile ID we use
        String creatorProfileId = recipe.creator.uid.isNotEmpty ? recipe.creator.uid : recipe.creator.id;
        print('Fetching creator profile with ID: $creatorProfileId');
        
        DocumentSnapshot creatorDoc = await _firestore.collection('profiles').doc(creatorProfileId).get();
        if (creatorDoc.exists) {
          print('Creator profile found');
          final creatorData = creatorDoc.data() as Map<String, dynamic>;
          
          // Check for 'followers' field
          if (creatorData.containsKey('followers')) {
            List<dynamic> rawFollowers = creatorData['followers'] ?? [];
            print('Raw followers data: $rawFollowers');
            
            // Convert to list of strings
            List<String> followers = rawFollowers.map((f) => f.toString()).toList();
            print('Found ${followers.length} followers to notify about new recipe');
            
            if (followers.isNotEmpty) {
              print('Creating notifications for followers...');
              // Create the notifications
              final notificationService = NotificationService();
              await notificationService.createNewRecipeNotification(recipeWithId, followers);
              print('Notifications created successfully');
            } else {
              print('No followers to notify');
            }
          } else {
            print('Creator profile does not have a followers field');
          }
        } else {
          print('Creator profile not found');
        }
      } catch (e) {
        // Just log the error and continue - don't let notification issues affect recipe creation
        print('Error creating follower notifications: $e');
      }
      
      return docRef.id;
    } catch (e) {
      print('Error creating recipe: $e');
      throw e;
    }
  }

  // Fetch a Recipe by ID - updated to respect privacy
  Future<Recipe?> getRecipeById(String id, {String? currentUserId}) async {
    DocumentSnapshot doc = await _firestore.collection('recipes').doc(id).get();
    if (doc.exists) {
      try {
        Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Check if recipe is public or belongs to current user
        if (recipe.isPublic || (currentUserId != null && recipe.creator.uid == currentUserId)) {
          return recipe;
        } else {
          print('Recipe is private and does not belong to current user');
          return null;
        }
      } catch (e) {
        print('Error parsing recipe data: $e');
        return null;
      }
    }
    return null;
  }

  // Search Recipes by Title - updated to respect privacy
  Future<List<Recipe>> searchRecipesByTitle(String title, {String? currentUserId}) async {
    QuerySnapshot snapshot = await _firestore
        .collection('recipes')
        .where('title', isGreaterThanOrEqualTo: title)
        .where('title', isLessThan: title + 'z')
        .get();

    // Filter for privacy after getting results
    return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
  }

  // Search Recipes by Category Tags - updated to respect privacy
  Future<List<Recipe>> searchRecipesByCategoryTags(List<String> tags, {String? currentUserId}) async {
    QuerySnapshot snapshot = await _firestore
        .collection('recipes')
        .where('categoryTags', arrayContainsAny: tags)
        .get();

    return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
  }

  // Search Recipes by Creator - updated to respect privacy
  Future<List<Recipe>> searchRecipesByCreator(String creatorId, {String? currentUserId}) async {
    QuerySnapshot snapshot = await _firestore
        .collection('recipes')
        .where('creator.id', isEqualTo: creatorId)
        .get();

    return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
  }

  // Search Recipes by Rating - updated to respect privacy
  Future<List<Recipe>> searchRecipesByRating(double minRating, {String? currentUserId}) async {
    QuerySnapshot snapshot = await _firestore
        .collection('recipes')
        .where('averageRating', isGreaterThanOrEqualTo: minRating)
        .get();

    return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
  }

  // Helper method to parse recipe snapshots with error handling and respect privacy
  List<Recipe> _parseRecipeSnapshot(QuerySnapshot snapshot, {String? currentUserId}) {
    List<Recipe> recipes = [];
    for (var doc in snapshot.docs) {
      try {
        Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Only include recipe if it's public or belongs to current user
        if (recipe.isPublic || (currentUserId != null && recipe.creator.uid == currentUserId)) {
          recipes.add(recipe);
        }
      } catch (e) {
        print('Error parsing recipe document ${doc.id}: $e');
        // Skip this document and continue with others
      }
    }
    return recipes;
  }

  // Update a Recipe
  Future<void> updateRecipe(Recipe recipe) async {
    // Ensure all text fields are properly encoded
    final recipeMap = recipe.toMap();
    await _firestore.collection('recipes').doc(recipe.id).update(recipeMap);
  }

  // Get recent recipes with a limit - updated to respect privacy
  Future<List<Recipe>> getRecentRecipes(int limit, {String? currentUserId}) async {
    try {
      // First try using the compound query with isPublic filter
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        List<Recipe> publicRecipes = _parseRecipeSnapshot(snapshot);
        
        // If currentUserId is provided, also get their private recipes
        if (currentUserId != null) {
          QuerySnapshot privateSnapshot = await _firestore
              .collection('recipes')
              .where('creator.uid', isEqualTo: currentUserId)
              .where('isPublic', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();
          
          List<Recipe> privateRecipes = _parseRecipeSnapshot(privateSnapshot);
          
          // Combine and sort the two lists
          publicRecipes.addAll(privateRecipes);
          publicRecipes.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) {
              return 0;
            }
            return b.createdAt!.compareTo(a.createdAt!); // Descending order
          });
          
          // Return only the first 'limit' recipes
          if (publicRecipes.length > limit) {
            return publicRecipes.sublist(0, limit);
          }
          return publicRecipes;
        }
        
        return publicRecipes;
      } catch (e) {
        // If the compound query fails (likely because index doesn't exist), fall back to the old approach
        print('Compound query failed, falling back to simpler approach: $e');
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .orderBy('createdAt', descending: true)
            .limit(limit * 2) // Fetch more to account for filtering
            .get();

        return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
      }
    } catch (e) {
      print('Error fetching recent recipes: $e');
      return [];
    }
  }

  // Get more recent recipes with pagination - updated to respect privacy
  Future<List<Recipe>> getMoreRecentRecipes(int limit, DateTime? lastTimestamp, {String? currentUserId}) async {
    try {
      // Try compound query first
      try {
        Query query = _firestore
            .collection('recipes')
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit);
        
        // If we have a lastTimestamp, start after it
        if (lastTimestamp != null) {
          query = query.startAfter([Timestamp.fromDate(lastTimestamp)]);
        }
        
        QuerySnapshot snapshot = await query.get();
        List<Recipe> publicRecipes = _parseRecipeSnapshot(snapshot);
        
        // If currentUserId is provided, also get their private recipes
        if (currentUserId != null) {
          Query privateQuery = _firestore
              .collection('recipes')
              .where('creator.uid', isEqualTo: currentUserId)
              .where('isPublic', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(limit);
          
          if (lastTimestamp != null) {
            privateQuery = privateQuery.startAfter([Timestamp.fromDate(lastTimestamp)]);
          }
          
          QuerySnapshot privateSnapshot = await privateQuery.get();
          List<Recipe> privateRecipes = _parseRecipeSnapshot(privateSnapshot);
          
          // Combine and sort the two lists
          publicRecipes.addAll(privateRecipes);
          publicRecipes.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) {
              return 0;
            }
            return b.createdAt!.compareTo(a.createdAt!); // Descending order
          });
          
          // Return only the first 'limit' recipes
          if (publicRecipes.length > limit) {
            return publicRecipes.sublist(0, limit);
          }
          return publicRecipes;
        }
        
        return publicRecipes;
      } catch (e) {
        // Fall back to simpler approach
        print('Compound query failed, falling back to simpler approach: $e');
        Query query = _firestore
            .collection('recipes')
            .orderBy('createdAt', descending: true)
            .limit(limit * 2); // Fetch more to account for filtering
        
        // If we have a lastTimestamp, start after it
        if (lastTimestamp != null) {
          query = query.startAfter([Timestamp.fromDate(lastTimestamp)]);
        }
        
        QuerySnapshot snapshot = await query.get();
        return _parseRecipeSnapshot(snapshot, currentUserId: currentUserId);
      }
    } catch (e) {
      print('Error fetching more recent recipes: $e');
      return [];
    }
  }

  // Delete a Recipe with full cleanup
  Future<void> deleteRecipe(String recipeId, String creatorId) async {
    try {
      // Use a batch to ensure atomic operations
      WriteBatch batch = _firestore.batch();
      
      // Reference to the recipe document
      DocumentReference recipeRef = _firestore.collection('recipes').doc(recipeId);
      
      // Reference to the creator's profile document
      DocumentReference creatorRef = _firestore.collection('profiles').doc(creatorId);
      
      // Delete the recipe document
      batch.delete(recipeRef);
      
      // Remove recipe ID from creator's myRecipes array
      batch.update(creatorRef, {
        'myRecipes': FieldValue.arrayRemove([recipeId])
      });
      
      // Execute all operations atomically
      await batch.commit();
      
      print('Recipe $recipeId successfully deleted and removed from creator profile');
    } catch (e) {
      print('Error deleting recipe: $e');
      throw e;
    }
  }

  // Get a random recipe - updated to respect privacy
  Future<Recipe?> getRandomRecipe({String? currentUserId}) async {
    try {
      // Only fetch public recipes for randomization
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('isPublic', isEqualTo: true)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        var randomDoc = snapshot.docs[Random().nextInt(snapshot.docs.length)];
        print('Fetched recipe data: ${randomDoc.data()}'); // Log the fetched data
        try {
          return Recipe.fromMap(randomDoc.data() as Map<String, dynamic>, randomDoc.id);
        } catch (e) {
          print('Error parsing random recipe: $e');
          return null;
        }
      } else {
        print('No recipes found in Firestore.'); // Log if no recipes exist
        return null;
      }
    } catch (e) {
      print('Error fetching random recipe: $e');
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
      
      // Create notification if adding to favorites
      if (!isFavorited) {
        // Get recipe creator ID
        final recipeData = recipeDoc.data() as Map<String, dynamic>;
        final creatorId = recipeData['creator']['uid'];
        
        // Only notify if creator is not the same as the user who favorited
        if (creatorId != userId) {
          final notificationService = NotificationService();
          await notificationService.createFavoriteNotification(
            creatorId, 
            recipeId, 
            recipeData['title'] ?? 'Unknown Recipe'
          );
        }
      }
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

  // Get updated recipe with latest favorite count - updated to respect privacy
  Future<Recipe?> getUpdatedRecipe(String recipeId, {String? currentUserId}) async {
    try {
      final doc = await _firestore.collection('recipes').doc(recipeId).get();
      if (doc.exists) {
        try {
          Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          // Check if recipe is public or belongs to current user
          if (recipe.isPublic || (currentUserId != null && recipe.creator.uid == currentUserId)) {
            return recipe;
          } else {
            print('Recipe is private and does not belong to current user');
            return null;
          }
        } catch (e) {
          print('Error parsing updated recipe: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching updated recipe: $e');
      return null;
    }
  }

  // Get recipes from followed profiles - updated to respect privacy
  Future<List<Recipe>> getRecipesFromFollowing(List<String> followingIds, int limit, {String? currentUserId}) async {
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
        // First attempt with compound query (requires index) - adding isPublic filter
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .where('creator.uid', whereIn: followingIds)
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        
        print('Found ${snapshot.docs.length} recipes from followed profiles');
        
        return _parseRecipeSnapshot(snapshot);
      } catch (e) {
        // If index doesn't exist, fall back to a simpler query without ordering
        print('Index-based query failed, falling back to simpler query: $e');
        
        // Try with just the whereIn clause (doesn't require index)
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .where('creator.uid', whereIn: followingIds)
            .get();
        
        print('Found ${snapshot.docs.length} recipes in fallback query');
        
        // Filter for public recipes manually
        List<Recipe> recipes = [];
        for (var doc in snapshot.docs) {
          try {
            Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (recipe.isPublic) {
              recipes.add(recipe);
            }
          } catch (e) {
            print('Error parsing recipe in fallback query: $e');
          }
        }
        
        // Sort the results locally since we couldn't use orderBy in the query
        recipes.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!); // Descending order
        });
        
        // Limit the results
        if (recipes.length > limit) {
          return recipes.sublist(0, limit);
        }
        
        return recipes;
      }
    } catch (e) {
      print('Error fetching recipes from following: $e');
      return [];
    }
  }

  // Get more recipes from followed profiles with pagination - updated to respect privacy
  Future<List<Recipe>> getMoreRecipesFromFollowing(List<String> followingIds, int limit, DateTime? lastTimestamp, {String? currentUserId}) async {
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
      
      try {
        Query query = _firestore
            .collection('recipes')
            .where('creator.uid', whereIn: followingIds)
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit);
        
        // If we have a lastTimestamp, start after it
        if (lastTimestamp != null) {
          query = query.startAfter([Timestamp.fromDate(lastTimestamp)]);
        }
        
        QuerySnapshot snapshot = await query.get();
        
        return _parseRecipeSnapshot(snapshot);
      } catch (e) {
        // If index doesn't exist, fall back to a simpler query
        print('Index-based query failed, falling back to simpler query: $e');
        
        // Try with just the whereIn clause (doesn't require index)
        QuerySnapshot snapshot = await _firestore
            .collection('recipes')
            .where('creator.uid', whereIn: followingIds)
            .get();
        
        // Filter for public recipes manually
        List<Recipe> recipes = [];
        for (var doc in snapshot.docs) {
          try {
            Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (recipe.isPublic) {
              recipes.add(recipe);
            }
          } catch (e) {
            print('Error parsing recipe in fallback query: $e');
          }
        }
        
        // Sort the results locally
        recipes.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!); // Descending order
        });
        
        // Filter by timestamp if provided
        if (lastTimestamp != null) {
          recipes = recipes.where((recipe) => 
            recipe.createdAt != null && recipe.createdAt!.isBefore(lastTimestamp)
          ).toList();
        }
        
        // Limit the results
        if (recipes.length > limit) {
          return recipes.sublist(0, limit);
        }
        
        return recipes;
      }
    } catch (e) {
      print('Error fetching more recipes from following: $e');
      return [];
    }
  }
}