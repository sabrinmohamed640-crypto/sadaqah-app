import 'package:flutter_test/flutter_test.dart';
import 'package:zakat_sadaqah_app/services/paginated_query_service.dart';

void main() {
  group('PaginationState Tests', () {
    test('PaginationState creation with all parameters', () {
      final items = [
        {'id': '1', 'name': 'Item 1'},
        {'id': '2', 'name': 'Item 2'},
      ];

      final state = PaginationState<Map<String, dynamic>>(
        items: items,
        hasMore: true,
        isLoading: false,
        error: null,
        totalCount: 50,
        pageSize: 10,
        currentPage: 1,
      );

      expect(state.items, items);
      expect(state.hasMore, true);
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.totalCount, 50);
      expect(state.pageSize, 10);
      expect(state.currentPage, 1);
      expect(state.isEmpty, false);
      expect(state.isNotEmpty, true);
    });

    test('PaginationState isEmpty property', () {
      final emptyState = PaginationState<Map<String, dynamic>>(
        items: [],
        hasMore: false,
        isLoading: false,
        totalCount: 0,
        pageSize: 10,
        currentPage: 1,
      );

      expect(emptyState.isEmpty, true);
      expect(emptyState.isNotEmpty, false);
    });

    test('PaginationState copyWith method', () {
      final state1 = PaginationState<Map<String, dynamic>>(
        items: [{'id': '1'}],
        hasMore: true,
        isLoading: false,
        totalCount: 100,
        pageSize: 10,
        currentPage: 1,
      );

      final state2 = state1.copyWith(
        currentPage: 2,
        isLoading: true,
      );

      expect(state2.currentPage, 2);
      expect(state2.isLoading, true);
      expect(state2.items, state1.items); // Unchanged
      expect(state2.hasMore, state1.hasMore); // Unchanged
    });
  });

  group('QueryFilter Tests', () {
    test('QueryFilter with isEqualTo condition', () {
      final filter = QueryFilter(
        fieldPath: 'status',
        isEqualTo: 'Verified',
      );

      expect(filter.fieldPath, 'status');
      expect(filter.isEqualTo, 'Verified');
      expect(filter.isLessThan, null);
    });

    test('QueryFilter with range conditions', () {
      final filter = QueryFilter(
        fieldPath: 'amount',
        isGreaterThan: 100,
        isLessThan: 1000,
      );

      expect(filter.fieldPath, 'amount');
      expect(filter.isGreaterThan, 100);
      expect(filter.isLessThan, 1000);
    });

    test('QueryFilter with whereIn condition', () {
      final filter = QueryFilter(
        fieldPath: 'category',
        whereIn: ['Fakir', 'Miskin', 'Amil'],
      );

      expect(filter.fieldPath, 'category');
      expect(filter.whereIn, ['Fakir', 'Miskin', 'Amil']);
    });
  });

  group('QuerySort Tests', () {
    test('QuerySort ascending order', () {
      final sort = QuerySort(fieldPath: 'name', descending: false);

      expect(sort.fieldPath, 'name');
      expect(sort.descending, false);
    });

    test('QuerySort descending order', () {
      final sort = QuerySort(fieldPath: 'amount', descending: true);

      expect(sort.fieldPath, 'amount');
      expect(sort.descending, true);
    });
  });

  group('Pagination Math Tests', () {
    test('Calculate start index for page 1', () {
      final pageSize = 10;
      final page = 1;
      final startIndex = (page - 1) * pageSize;

      expect(startIndex, 0);
    });

    test('Calculate start index for page 2', () {
      final pageSize = 10;
      final page = 2;
      final startIndex = (page - 1) * pageSize;

      expect(startIndex, 10);
    });

    test('Calculate start index for page 5 with custom page size', () {
      final pageSize = 25;
      final page = 5;
      final startIndex = (page - 1) * pageSize;

      expect(startIndex, 100);
    });

    test('Determine hasMore based on fetched items', () {
      final pageSize = 10;
      final fetchedCount = 11; // Fetched pageSize + 1

      final hasMore = fetchedCount > pageSize;
      expect(hasMore, true);
    });

    test('No more items when fetched count equals page size', () {
      final pageSize = 10;
      final fetchedCount = 10;

      final hasMore = fetchedCount > pageSize;
      expect(hasMore, false);
    });
  });

  group('Pagination Text Search Tests', () {
    test('Text search case-insensitive matching', () {
      final searchText = 'john';
      final fieldValue = 'John Doe';
      final searchLower = searchText.toLowerCase();
      final fieldLower = fieldValue.toLowerCase();

      final matches = fieldLower.contains(searchLower);
      expect(matches, true);
    });

    test('Text search with partial matching', () {
      final searchText = 'doe';
      final fieldValue = 'John Doe';
      final matches =
          fieldValue.toLowerCase().contains(searchText.toLowerCase());

      expect(matches, true);
    });

    test('Text search no match', () {
      final searchText = 'xyz';
      final fieldValue = 'John Doe';
      final matches =
          fieldValue.toLowerCase().contains(searchText.toLowerCase());

      expect(matches, false);
    });
  });
}
