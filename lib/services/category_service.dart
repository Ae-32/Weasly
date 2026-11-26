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
  /// Automatically deduplicates categories by ID and normalized (name, type),
  /// preferring canonical default category IDs over duplicate documents.
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    final defaultIds = DefaultCategories.defaultList.map((c) => c.id).toSet();

    return _categoriesRef(userId).snapshots().map((snapshot) {
      final allCats = snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();

      // Prefer canonical default IDs, then isDefault entries, then custom documents
      allCats.sort((a, b) {
        final aPriority = defaultIds.contains(a.id) ? 0 : (a.isDefault ? 1 : 2);
        final bPriority = defaultIds.contains(b.id) ? 0 : (b.isDefault ? 1 : 2);
        return aPriority.compareTo(bPriority);
      });

      final list = <CategoryModel>[];
      final seenIds = <String>{};
      final seenKeys = <String>{};

      for (final cat in allCats) {
        final key = '${DefaultCategories.normalizeCategoryName(cat.name)}_${cat.type.name}';
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
        // Check existing categories and clean up duplicate documents in Firestore
        final existingIds = snapshot.docs.map((d) => d.id).toSet();
        final defaultIds = DefaultCategories.defaultList.map((c) => c.id).toSet();
        final seenKeys = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        final docsToDelete = <DocumentSnapshot<Map<String, dynamic>>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = DefaultCategories.normalizeCategoryName(data['name'] as String? ?? '');
          final typeStr = (data['type'] as String? ?? 'expense').trim().toLowerCase();
          final key = '${name}_$typeStr';

          if (seenKeys.containsKey(key)) {
            // Keep the canonical document with fixed ID (or isDefault) if available, otherwise delete duplicate
            final existingDoc = seenKeys[key]!;
            final docIsCanonical = defaultIds.contains(doc.id);
            final existingIsCanonical = defaultIds.contains(existingDoc.id);
            final docIsDefault = data['isDefault'] as bool? ?? false;
            final existingIsDefault = existingDoc.data()?['isDefault'] as bool? ?? false;

            if ((docIsCanonical && !existingIsCanonical) ||
                (!docIsCanonical && !existingIsCanonical && docIsDefault && !existingIsDefault)) {
              docsToDelete.add(existingDoc);
              seenKeys[key] = doc;
            } else {
              docsToDelete.add(doc);
            }
          } else {
            seenKeys[key] = doc;
          }
        }

        // Identify any missing default categories (e.g., new income categories) for existing users
        final missingDefaultCategories = <CategoryModel>[];
        for (final defaultCat in DefaultCategories.defaultList) {
          final key = '${DefaultCategories.normalizeCategoryName(defaultCat.name)}_${defaultCat.type.name}';
          final hasId = existingIds.contains(defaultCat.id);
          final hasKey = seenKeys.containsKey(key);
          if (!hasId && !hasKey) {
            missingDefaultCategories.add(defaultCat);
          }
        }

        if (docsToDelete.isNotEmpty || missingDefaultCategories.isNotEmpty) {
          debugPrint(
            "Category sync for user $userId: adding ${missingDefaultCategories.length} missing default categories, deleting ${docsToDelete.length} duplicates.",
          );
          final batch = _firestore.batch();
          for (final d in docsToDelete) {
            batch.delete(d.reference);
          }
          for (final missing in missingDefaultCategories) {
            final docRef = _categoriesRef(userId).doc(missing.id);
            batch.set(docRef, missing.toMap());
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
      final existingSnap = await _categoriesRef(userId).get();
      final hasDuplicate = existingSnap.docs.any((doc) {
        final existingCat = CategoryModel.fromFirestore(doc);
        if (!DefaultCategories.isSameCategoryName(existingCat.name, name)) {
          return false;
        }
        return existingCat.type == type ||
            existingCat.type == CategoryType.both ||
            type == CategoryType.both;
      });
      if (hasDuplicate) {
        throw CategoryException('Category "${name.trim()}" already exists.');
      }

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
