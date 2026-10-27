import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Pagination state for list queries
class PaginationState<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final int pageSize;
  final int currentPage;

  PaginationState({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    this.error,
    required this.totalCount,
    required this.pageSize,
    required this.currentPage,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  PaginationState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoading,
    String? error,
    int? totalCount,
    int? pageSize,
    int? currentPage,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Filter configuration for Firestore queries
class QueryFilter {
  final String? fieldPath;
  final dynamic isEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final List<dynamic>? whereIn;

  QueryFilter({
    this.fieldPath,
    this.isEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.whereIn,
  });
}

/// Sort configuration for Firestore queries
class QuerySort {
  final String fieldPath;
  final bool descending;

  QuerySort({required this.fieldPath, this.descending = false});
}

/// Service for efficient pagination of Firestore collections
/// Compatible with Cloud Firestore 6.5.0+
class PaginatedQueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Build a query with filters and sorting applied
  Query<Map<String, dynamic>> _buildQuery(
    String collectionPath, {
    List<QueryFilter>? filters,
    QuerySort? sortBy,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    // Apply filters
    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        if (filter.fieldPath == null) continue;

        if (filter.isEqualTo != null) {
          query = query.where(filter.fieldPath!, isEqualTo: filter.isEqualTo);
        } else if (filter.isLessThan != null) {
          query = query.where(filter.fieldPath!, isLessThan: filter.isLessThan);
        } else if (filter.isLessThanOrEqualTo != null) {
          query = query.where(filter.fieldPath!,
              isLessThanOrEqualTo: filter.isLessThanOrEqualTo);
        } else if (filter.isGreaterThan != null) {
          query =
              query.where(filter.fieldPath!, isGreaterThan: filter.isGreaterThan);
        } else if (filter.isGreaterThanOrEqualTo != null) {
          query = query.where(filter.fieldPath!,
              isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo);
        } else if (filter.whereIn != null) {
          query = query.where(filter.fieldPath!, whereIn: filter.whereIn);
        }
      }
    }

    // Apply sorting
    if (sortBy != null) {
      query = query.orderBy(sortBy.fieldPath, descending: sortBy.descending);
    }

    return query;
  }

  /// Get paginated collection with optional filters and sorting
  /// Note: Uses limit-based pagination (fetches all up to page, then slices)
  /// For production with large datasets, implement cursor-based pagination with startAfter()
  Future<PaginationState<Map<String, dynamic>>> getPaginatedCollection(
    String collectionPath, {
    int pageSize = 10,
    int page = 1,
    List<QueryFilter>? filters,
    QuerySort? sortBy,
  }) async {
    try {
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      // Build the query
      final query = _buildQuery(collectionPath, filters: filters, sortBy: sortBy);

      // Fetch all documents up to current page + 1 to determine if hasMore
      final snapshot =
          await query.limit(pageSize * page + 1).get();

      final totalCount = snapshot.docs.length;
      final slicedDocs = snapshot.docs
          .sublist(
            startIndex,
            (endIndex < snapshot.docs.length) ? endIndex : snapshot.docs.length,
          )
          .toList();

      final hasMore = snapshot.docs.length > endIndex;

      debugPrint(
          '📄 [Pagination] Collection: $collectionPath, Page: $page, Items: ${slicedDocs.length}, HasMore: $hasMore');

      return PaginationState<Map<String, dynamic>>(
        items: slicedDocs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList(),
        hasMore: hasMore,
        isLoading: false,
        totalCount: totalCount,
        pageSize: pageSize,
        currentPage: page,
      );
    } catch (e) {
      debugPrint('❌ [Pagination] Error fetching $collectionPath: $e');
      return PaginationState<Map<String, dynamic>>(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
        totalCount: 0,
        pageSize: pageSize,
        currentPage: page,
      );
    }
  }

  /// Stream paginated collection (for real-time updates)
  Stream<PaginationState<Map<String, dynamic>>> streamPaginatedCollection(
    String collectionPath, {
    int pageSize = 10,
    int page = 1,
    List<QueryFilter>? filters,
    QuerySort? sortBy,
  }) {
    try {
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      // Build the query
      final query = _buildQuery(collectionPath, filters: filters, sortBy: sortBy);

      // Stream with real-time updates
      return query
          .limit(pageSize * page + 1)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final totalCount = snapshot.docs.length;
        final slicedDocs = snapshot.docs
            .sublist(
              startIndex,
              (endIndex < snapshot.docs.length)
                  ? endIndex
                  : snapshot.docs.length,
            )
            .toList();

        final hasMore = snapshot.docs.length > endIndex;

        return PaginationState<Map<String, dynamic>>(
          items: slicedDocs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
          hasMore: hasMore,
          isLoading: false,
          totalCount: totalCount,
          pageSize: pageSize,
          currentPage: page,
        );
      }).handleError((error) {
        debugPrint(
            '❌ [Pagination] Stream error for $collectionPath: $error');
        return PaginationState<Map<String, dynamic>>(
          items: [],
          hasMore: false,
          isLoading: false,
          error: error.toString(),
          totalCount: 0,
          pageSize: pageSize,
          currentPage: page,
        );
      });
    } catch (e) {
      debugPrint(
          '❌ [Pagination] Error building stream for $collectionPath: $e');
      return Stream.value(PaginationState<Map<String, dynamic>>(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
        totalCount: 0,
        pageSize: pageSize,
        currentPage: page,
      ));
    }
  }

  /// Get all distinct values for a field (for filter dropdowns)
  Future<List<dynamic>> getDistinctValues(
    String collectionPath,
    String fieldPath,
  ) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).get();
      final values = <dynamic>{};

      for (final doc in snapshot.docs) {
        final value = doc.data()[fieldPath];
        if (value != null) {
          values.add(value);
        }
      }

      debugPrint(
          '📋 [Pagination] Found ${values.length} distinct values for $fieldPath in $collectionPath');

      return values.toList();
    } catch (e) {
      debugPrint(
          '❌ [Pagination] Error getting distinct values for $fieldPath: $e');
      return [];
    }
  }

  /// Search collection by text in a specific field
  Future<PaginationState<Map<String, dynamic>>> searchCollection(
    String collectionPath,
    String searchFieldPath,
    String searchTerm, {
    int pageSize = 10,
    int page = 1,
    List<QueryFilter>? additionalFilters,
    QuerySort? sortBy,
  }) async {
    try {
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      // Build base query
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

      // Apply additional filters first
      if (additionalFilters != null && additionalFilters.isNotEmpty) {
        for (final filter in additionalFilters) {
          if (filter.fieldPath == null) continue;
          if (filter.isEqualTo != null) {
            query =
                query.where(filter.fieldPath!, isEqualTo: filter.isEqualTo);
          }
        }
      }

      // Add text search (case-insensitive contains)
      // Note: Cloud Firestore doesn't support native contains queries
      // This is a simple implementation - for production, use Algolia or Meilisearch
      if (sortBy != null) {
        query =
            query.orderBy(sortBy.fieldPath, descending: sortBy.descending);
      }

      final snapshot = await query.limit(pageSize * page + 1).get();

      // Filter results locally for the search term
      final searchTermLower = searchTerm.toLowerCase();
      final filteredDocs = snapshot.docs
          .where((doc) {
            final fieldValue = doc.data()[searchFieldPath]?.toString() ?? '';
            return fieldValue.toLowerCase().contains(searchTermLower);
          })
          .toList();

      final totalCount = filteredDocs.length;
      final slicedDocs = filteredDocs
          .sublist(
            startIndex,
            (endIndex < filteredDocs.length)
                ? endIndex
                : filteredDocs.length,
          )
          .toList();

      final hasMore = filteredDocs.length > endIndex;

      debugPrint(
          '🔍 [Pagination] Search "$searchTerm" in $collectionPath.$searchFieldPath: ${slicedDocs.length} results');

      return PaginationState<Map<String, dynamic>>(
        items: slicedDocs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList(),
        hasMore: hasMore,
        isLoading: false,
        totalCount: totalCount,
        pageSize: pageSize,
        currentPage: page,
      );
    } catch (e) {
      debugPrint('❌ [Pagination] Error searching $collectionPath: $e');
      return PaginationState<Map<String, dynamic>>(
        items: [],
        hasMore: false,
        isLoading: false,
        error: e.toString(),
        totalCount: 0,
        pageSize: pageSize,
        currentPage: page,
      );
    }
  }

  /// Calculate offset for pagination
  int calculateOffset(int pageNumber, int pageSize) {
    return (pageNumber - 1) * pageSize;
  }

  /// Check if page has more items
  bool hasMoreItems(int itemCount, int pageSize) {
    return itemCount > pageSize;
  }

  /// Get total pages for a collection count
  int calculateTotalPages(int totalCount, int pageSize) {
    return (totalCount / pageSize).ceil();
  }
}
