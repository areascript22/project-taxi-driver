part of 'admin_bloc.dart';

const int _pageSize = 10;

@immutable
class AdminState {
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final int currentPage;
  // uid del driver sobre el que hay una acción (cambiar rol) en curso.
  final String? actionUid;

  // Modo navegación (sin búsqueda): conductores acumulados página por
  // página desde el server, en el orden en que se fueron pidiendo. Avanzar
  // más allá de lo ya cargado dispara un fetch nuevo (ver AdminBloc);
  // retroceder es gratis, ya está en memoria.
  final List<AdminDriverEntity> loadedDrivers;
  final String? nextCursor;
  final bool hasMore;

  // Modo búsqueda: fetch completo (una sola vez, cacheado) + filtro +
  // paginación local -- hace falta ver a TODOS los conductores para que el
  // buscador sirva de algo. null = todavía no se ha cargado.
  final List<AdminDriverEntity>? searchResults;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.currentPage = 0,
    this.actionUid,
    this.loadedDrivers = const [],
    this.nextCursor,
    this.hasMore = false,
    this.searchResults,
  });

  bool get isSearching => searchQuery.trim().isNotEmpty;

  List<AdminDriverEntity> get _sourceDrivers =>
      isSearching ? (searchResults ?? const []) : loadedDrivers;

  List<AdminDriverEntity> get filteredDrivers {
    if (!isSearching) return _sourceDrivers;
    final query = searchQuery.trim().toLowerCase();
    return _sourceDrivers.where((driver) {
      return driver.fullName.toLowerCase().contains(query) ||
          driver.email.toLowerCase().contains(query) ||
          driver.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  List<AdminDriverEntity> get pageDrivers {
    final filtered = filteredDrivers;
    final start = currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  bool get canGoPrevious => currentPage > 0;

  bool get canGoNext {
    final hasCachedNextPage =
        (currentPage + 1) * _pageSize < filteredDrivers.length;
    if (hasCachedNextPage) return true;
    // En modo búsqueda ya está todo cargado -- si no hay página cacheada
    // siguiente, no hay más. En modo navegación puede haber más en el
    // server aunque no esté cacheado todavía.
    return !isSearching && hasMore;
  }

  // null = el total no se conoce con certeza todavía (modo navegación, con
  // posibles páginas sin cargar en el server). No-null = total conocido
  // (modo búsqueda, donde ya se cargó todo de una).
  int? get totalPages {
    if (!isSearching && hasMore) return null;
    final total = (filteredDrivers.length / _pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    int? currentPage,
    String? actionUid,
    List<AdminDriverEntity>? loadedDrivers,
    String? nextCursor,
    bool? hasMore,
    List<AdminDriverEntity>? searchResults,
    bool clearError = false,
    bool clearActionUid = false,
    bool clearNextCursor = false,
    bool clearSearchResults = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      actionUid: clearActionUid ? null : (actionUid ?? this.actionUid),
      loadedDrivers: loadedDrivers ?? this.loadedDrivers,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      searchResults:
          clearSearchResults ? null : (searchResults ?? this.searchResults),
    );
  }
}
