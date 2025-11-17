class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] ?? 0,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}

class PaginatedResponse<T> {
  final List<T> items;
  final Pagination pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });
}

class Pagination {
  final int total;
  final int totalPages;
  final int currentPage;
  final int perPage;

  Pagination({
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.perPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
    );
  }

  bool get hasMore => currentPage < totalPages;
  int get nextPage => currentPage + 1;
}
