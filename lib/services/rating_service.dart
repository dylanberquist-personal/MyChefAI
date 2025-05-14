// lib/services/rating_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/profile.dart';
import '../services/notification_service.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rate a recipe and update chef score
  Future<void> rateRecipe(String recipeId, String userId, int rating) async {
    try {
      // Get the recipe
      DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
      if (!recipeDoc.exists) {
        throw 'Recipe not found';
      }

      // Get user's existing rating (if any)
      DocumentSnapshot userRatingDoc = await _firestore
          .collection('ratings')
          .doc('${userId}_${recipeId}')
          .get();

      bool isUpdating = userRatingDoc.exists;
      int? previousRating;
      
      if (isUpdating) {
        previousRating = (userRatingDoc.data() as Map<String, dynamic>)['rating'];
        
        // If user is selecting the same rating again, delete the rating
        if (previousRating == rating) {
          return await _removeRating(recipeId, userId, previousRating!);
        }
      }

      // Start a batch operation for atomic updates
      WriteBatch batch = _firestore.batch();

      // Get recipe data
      Recipe recipe = Recipe.fromMap(recipeDoc.data() as Map<String, dynamic>, recipeId);
      String creatorId = recipe.creator.uid;
      
      // Get creator profile
      DocumentSnapshot creatorDoc = await _firestore.collection('profiles').doc(creatorId).get();
      Profile creator = Profile.fromMap(creatorDoc.data() as Map<String, dynamic>, creatorId);

      // Calculate new values
      // Handle cases where averageRating might be NaN, Infinity, or null
      double safeAverageRating = 0.0;
      if (recipe.averageRating.isFinite && !recipe.averageRating.isNaN) {
        safeAverageRating = recipe.averageRating;
      }
      
      // Calculate current total rating points (avg * count)
      double currentTotalRating = safeAverageRating * recipe.numberOfRatings;
      int newNumberOfRatings = recipe.numberOfRatings;
      double newTotalRating;

      if (isUpdating) {
        // Updating an existing rating
        newTotalRating = currentTotalRating - previousRating! + rating;
      } else {
        // Adding a new rating
        newNumberOfRatings++;
        newTotalRating = currentTotalRating + rating;
      }

      // Calculate new average - ensure we don't divide by zero
      double newAverageRating = 0.0;
      if (newNumberOfRatings > 0) {
        newAverageRating = newTotalRating / newNumberOfRatings;
      }

      // Update recipe in database
      batch.update(_firestore.collection('recipes').doc(recipeId), {
        'averageRating': newAverageRating,
        'numberOfRatings': newNumberOfRatings,
      });

      // Store or update user rating
      batch.set(_firestore.collection('ratings').doc('${userId}_${recipeId}'), {
        'userId': userId,
        'recipeId': recipeId,
        'rating': rating,
        'createdAt': isUpdating ? userRatingDoc.get('createdAt') : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update chef score
      // Get all recipe ratings for this chef
      QuerySnapshot chefRecipesQuery = await _firestore
          .collection('recipes')
          .where('creator.id', isEqualTo: creatorId)
          .get();

      // Calculate new chef score (average of all recipe ratings)
      double totalChefScore = 0.0;
      int totalChefRatings = 0;

      // Process all the chef's recipes, including the current one with its new rating
      for (var doc in chefRecipesQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If this is the recipe we're updating, use the calculated new values
        if (doc.id == recipeId) {
          if (newNumberOfRatings > 0) {
            totalChefScore += newTotalRating;  // Add the total rating points, not the average
            totalChefRatings += newNumberOfRatings;
          }
        } else {
          // For other recipes, get their current values
          double recipeAvg = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          int recipeRatings = (data['numberOfRatings'] as int?) ?? 0;
          
          // Skip recipes with invalid ratings
          if (recipeAvg.isNaN || recipeAvg.isInfinite) {
            recipeAvg = 0.0;
          }
          
          // Only include recipes with ratings
          if (recipeRatings > 0) {
            totalChefScore += (recipeAvg * recipeRatings);
            totalChefRatings += recipeRatings;
          }
        }
      }

      // Calculate new chef score average
      double newChefScore = 0.0;
      if (totalChefRatings > 0) {
        newChefScore = totalChefScore / totalChefRatings;
      }

      // Update profile's chef score
      batch.update(_firestore.collection('profiles').doc(creatorId), {
        'chefScore': newChefScore,
        'numberOfReviews': totalChefRatings,
      });

      // Commit the batch
      await batch.commit();
      
      // Create notification only if this is a new rating, not an update
      if (!isUpdating) {
        // Only notify if creator is not the same as the user who rated
        if (creatorId != userId) {
          final notificationService = NotificationService();
          await notificationService.createRatingNotification(
            creatorId, 
            recipeId, 
            recipe.title
          );
        }
      }
    } catch (e) {
      print('Error rating recipe: $e');
      throw e;
    }
  }

  // Remove a rating from a recipe
  Future<void> _removeRating(String recipeId, String userId, int oldRating) async {
    try {
      // Start a batch operation
      WriteBatch batch = _firestore.batch();

      // Get the recipe
      DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
      Recipe recipe = Recipe.fromMap(recipeDoc.data() as Map<String, dynamic>, recipeId);
      String creatorId = recipe.creator.uid;

      // Calculate new values for recipe
      // Handle cases where averageRating might be NaN, Infinity, or null
      double safeAverageRating = 0.0;
      if (recipe.averageRating.isFinite && !recipe.averageRating.isNaN) {
        safeAverageRating = recipe.averageRating;
      }
      
      double currentTotalRating = safeAverageRating * recipe.numberOfRatings;
      int newNumberOfRatings = recipe.numberOfRatings - 1;
      double newAverageRating = 0.0;

      if (newNumberOfRatings > 0) {
        newAverageRating = (currentTotalRating - oldRating) / newNumberOfRatings;
      }

      // Update recipe
      batch.update(_firestore.collection('recipes').doc(recipeId), {
        'averageRating': newAverageRating,
        'numberOfRatings': newNumberOfRatings,
      });

      // Delete user rating
      batch.delete(_firestore.collection('ratings').doc('${userId}_${recipeId}'));

      // Update chef score
      // Get all recipe ratings for this chef
      QuerySnapshot chefRecipesQuery = await _firestore
          .collection('recipes')
          .where('creator.id', isEqualTo: creatorId)
          .get();

      double totalChefScore = 0.0;
      int totalChefRatings = 0;

      // Calculate new chef score including all recipes 
      for (var doc in chefRecipesQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If this is the recipe we're updating, use the new values
        if (doc.id == recipeId) {
          if (newNumberOfRatings > 0) {
            double newTotalRating = (currentTotalRating - oldRating);
            totalChefScore += newTotalRating;  // Add the total rating points, not the average
            totalChefRatings += newNumberOfRatings;
          }
        } else {
          double recipeAvg = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          int recipeRatings = (data['numberOfRatings'] as int?) ?? 0;
          
          // Skip recipes with invalid ratings
          if (recipeAvg.isNaN || recipeAvg.isInfinite) {
            recipeAvg = 0.0;
          }
          
          if (recipeRatings > 0) {
            totalChefScore += (recipeAvg * recipeRatings);
            totalChefRatings += recipeRatings;
          }
        }
      }

      // Calculate new chef score average
      double newChefScore = 0.0;
      if (totalChefRatings > 0) {
        newChefScore = totalChefScore / totalChefRatings;
      }

      // Update profile's chef score
      batch.update(_firestore.collection('profiles').doc(creatorId), {
        'chefScore': newChefScore,
        'numberOfReviews': totalChefRatings,
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error removing rating: $e');
      throw e;
    }
  }

  // Get user's rating for a recipe
  Future<int?> getUserRating(String recipeId, String userId) async {
    try {
      DocumentSnapshot ratingDoc = await _firestore
          .collection('ratings')
          .doc('${userId}_${recipeId}')
          .get();

      if (ratingDoc.exists) {
        return (ratingDoc.data() as Map<String, dynamic>)['rating'] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }
}