class PaginatedRoutes {
  final List<Map<String, dynamic>> routes;
  final bool hasMore;
  final int currentPage;
  final int totalItems;
  static const int itemsPerPage = 10;

  PaginatedRoutes({
    required this.routes,
    required this.hasMore,
    required this.currentPage,
    required this.totalItems,
  });

  factory PaginatedRoutes.initial() {
    return PaginatedRoutes(
      routes: [],
      hasMore: false,
      currentPage: 0,
      totalItems: 0,
    );
  }

  PaginatedRoutes copyWith({
    List<Map<String, dynamic>>? routes,
    bool? hasMore,
    int? currentPage,
    int? totalItems,
  }) {
    return PaginatedRoutes(
      routes: routes ?? this.routes,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  List<Map<String, dynamic>> getPageItems(int page) {
    final startIndex = page * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    if (startIndex >= routes.length) return [];
    return routes.sublist(startIndex, endIndex.clamp(0, routes.length));
  }

  bool hasNextPage() {
    return (currentPage + 1) * itemsPerPage < totalItems;
  }

  bool hasPreviousPage() {
    return currentPage > 0;
  }
}
