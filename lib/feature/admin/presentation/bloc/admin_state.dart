part of 'admin_bloc.dart';

const int _pageSize = 10;

@immutable
class AdminState {
  final bool isLoading;
  final String? errorMessage;
  final List<AdminDriverEntity> drivers;
  final String searchQuery;
  final int currentPage;
  // uid del driver sobre el que hay una acción (borrar/cambiar rol) en curso.
  final String? actionUid;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.drivers = const [],
    this.searchQuery = '',
    this.currentPage = 0,
    this.actionUid,
  });

  List<AdminDriverEntity> get filteredDrivers {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return drivers;
    return drivers.where((driver) {
      return driver.fullName.toLowerCase().contains(query) ||
          driver.email.toLowerCase().contains(query) ||
          driver.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  int get totalPages {
    final total = (filteredDrivers.length / _pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  List<AdminDriverEntity> get pageDrivers {
    final filtered = filteredDrivers;
    final start = currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AdminDriverEntity>? drivers,
    String? searchQuery,
    int? currentPage,
    String? actionUid,
    bool clearError = false,
    bool clearActionUid = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      drivers: drivers ?? this.drivers,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      actionUid: clearActionUid ? null : (actionUid ?? this.actionUid),
    );
  }
}
