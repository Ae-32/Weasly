import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../utils/default_categories.dart';

/// Exception thrown for invalid category operations.
class CategoryException implements Exception {
  final String message;
  const CategoryException(this.message);

  @override
  String toString() => message;
}

/// Service class managing Firestore CRUD operations for financial categories.
/// Collection path: users/{userId}/categories/
class CategoryService {
  final FirebaseFirestore _firestore;

  static final Set<String> _seedingUserIds = {};

  CategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  /// Streams real-time category updates for a specific user.
  /// Automatically deduplicates categories by ID and (name, type).
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _categoriesRef(userId).snapshots().map((snapshot) {
      final list = <CategoryModel>[];
      final seenIds = <String>{};
      final seenKeys = <String>{};

      for (final doc in snapshot.docs) {
        final cat = CategoryModel.fromFirestore(doc);
        final key = '${cat.name.trim().toLowerCase()}_${cat.type.name}';
        if (seenIds.add(cat.id) && seenKeys.add(key)) {
          list.add(cat);
        }
      }
      return list;
    });
  }

  /// Automatically seeds default categories if the collection is empty for a user,
  /// and cleans up duplicate default categories if any exist.
  Future<void> seedDefaultCategoriesIfEmpty(String userId) async {
    if (userId.isEmpty || _seedingUserIds.contains(userId)) return;
    _seedingUserIds.add(userId);

    try {
      final snapshot = await _categoriesRef(userId).get();
      if (snapshot.docs.isEmpty) {
        debugPrint("Seeding default categories for user: $userId");
        final batch = _firestore.batch();
        for (final category in DefaultCategories.defaultList) {
          final docRef = _categoriesRef(userId).doc(category.id);
          batch.set(docRef, category.toMap());
        }
        await batch.commit();
      } else {
        // Check for and clean up duplicate category documents in Firestore
        final seenKeys = <String, DocumentSnapshot>{};
        final docsToDelete = <DocumentSnapshot>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').trim().toLowerCase();
          final type = (data['type'] as String? ?? 'expense').trim().toLowerCase();
          final key = '${name}_$type';

          if (seenKeys.containsKey(key)) {
            // Keep the canonical document with fixed ID if available, otherwise delete duplicate
            final existingDoc = seenKeys[key]!;
            final defaultIds = DefaultCategories.defaultList.map((c) => c.id).toSet();
            if (defaultIds.contains(doc.id) && !defaultIds.contains(existingDoc.id)) {
              docsToDelete.add(existingDoc);
              seenKeys[key] = doc;
            } else {
              docsToDelete.add(doc);
            }
          } else {
            seenKeys[key] = doc;
          }
        }

        if (docsToDelete.isNotEmpty) {
          debugPrint("Cleaning up ${docsToDelete.length} duplicate category documents for user: $userId");
          final batch = _firestore.batch();
          for (final d in docsToDelete) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint("Error seeding/cleaning default categories: $e");
    } finally {
      _seedingUserIds.remove(userId);
    }
  }

  /// Creates a new user-defined custom category.
  Future<CategoryModel> addCategory({
    required String userId,
    required String name,
    required String iconName,
    required String colorHex,
    required CategoryType type,
  }) async {
    if (userId.isEmpty) {
      throw const CategoryException("User is not signed in.");
    }
    if (name.trim().isEmpty) {
      throw const CategoryException("Category name cannot be empty.");
    }

    try {
      final docRef = _categoriesRef(userId).doc();
      final category = CategoryModel(
        id: docRef.id,
        name: name.trim(),
        iconName: iconName,
        colorHex: colorHex,
        type: type,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(category.toMap());
      return category;
    } catch (e) {
      throw CategoryException("Failed to create category: ${e.toString()}");
    }
  }

  /// Updates an existing category (applies to both default and custom categories).
  Future<void> updateCategory({
    required String userId,
    required CategoryModel category,
  }) async {
    if (userId.isEmpty) {
      throw const CategoryException("User is not signed in.");
    }
    if (category.name.trim().isEmpty) {
      throw const CategoryException("Category name cannot be empty.");
    }

    try {
      await _categoriesRef(userId).doc(category.id).update({
        'name': category.name.trim(),
        'iconName': category.iconName,
        'colorHex': category.colorHex,
        'type': category.type.toMap(),
      });
    } catch (e) {
      throw CategoryException("Failed to update category: ${e.toString()}");
    }
  }

  /// Deletes a custom category.
  /// Rule: Default categories (isDefault == true) CANNOT be deleted.
  Future<void> deleteCategory({
    required String userId,
    required CategoryModel category,
  }) async {
    if (userId.isEmpty) {
      throw const CategoryException("User is not signed in.");
    }

    if (category.isDefault) {
      throw const CategoryException(
        "Default categories cannot be deleted to protect existing transactions and budgets.",
      );
    }

    try {
      await _categoriesRef(userId).doc(category.id).delete();
    } catch (e) {
      throw CategoryException("Failed to delete category: ${e.toString()}");
    }
  }
}
