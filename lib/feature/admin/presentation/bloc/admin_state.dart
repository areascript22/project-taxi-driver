part of 'admin_bloc.dart';

const int _pageSize = 10;

// Los 4 valores no-'all' son mutuamente excluyentes y cubren el 100% de los
// casos reales: un conductor bloqueado SIEMPRE está approved (el server
// exige aprobación antes de poder bloquear), así que nunca existe un
// pending/rejected bloqueado -- por eso estos son pills de selección única,
// no checkboxes combinables entre sí.
enum AdminStatusFilter { all, pending, rejected, active, blocked }

@immutable
class AdminState {
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final AdminStatusFilter statusFilter;
  final int currentPage;
  // uid del driver sobre el que hay una acción (cambiar rol) en curso.
  final String? actionUid;

  // Modo navegación (sin filtros): conductores acumulados página por
  // página desde el server, en el orden en que se fueron pidiendo. Avanzar
  // más allá de lo ya cargado dispara un fetch nuevo (ver AdminBloc);
  // retroceder es gratis, ya está en memoria.
  final List<AdminDriverEntity> loadedDrivers;
  final String? nextCursor;
  final bool hasMore;

  // Modo filtrado (búsqueda por texto y/o pill de estado activa): fetch
  // completo (una sola vez, cacheado) + filtro + paginación local -- hace
  // falta ver a TODOS los conductores para que el buscador y los filtros de
  // estado sirvan de algo. null = todavía no se ha cargado.
  final List<AdminDriverEntity>? searchResults;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter = AdminStatusFilter.all,
    this.currentPage = 0,
    this.actionUid,
    this.loadedDrivers = const [],
    this.nextCursor,
    this.hasMore = false,
    this.searchResults,
  });

  // true si hay texto en el buscador y/o una pill de estado activa -- en
  // cualquiera de los dos casos hace falta el fetch completo en vez de la
  // paginación liviana por cursor.
  bool get isFiltering =>
      searchQuery.trim().isNotEmpty || statusFilter != AdminStatusFilter.all;

  List<AdminDriverEntity> get _sourceDrivers =>
      isFiltering ? (searchResults ?? const []) : loadedDrivers;

  bool _matchesStatusFilter(AdminDriverEntity driver) {
    return switch (statusFilter) {
      AdminStatusFilter.all => true,
      AdminStatusFilter.pending => driver.approvalStatus == 'pending',
      AdminStatusFilter.rejected => driver.approvalStatus == 'rejected',
      AdminStatusFilter.active =>
        driver.approvalStatus == 'approved' && !driver.isBlocked,
      AdminStatusFilter.blocked => driver.isBlocked,
    };
  }

  List<AdminDriverEntity> get filteredDrivers {
    if (!isFiltering) return _sourceDrivers;
    final query = searchQuery.trim().toLowerCase();
    return _sourceDrivers.where((driver) {
      final matchesQuery =
          query.isEmpty ||
          driver.fullName.toLowerCase().contains(query) ||
          driver.email.toLowerCase().contains(query) ||
          driver.phoneNumber.toLowerCase().contains(query);
      return matchesQuery && _matchesStatusFilter(driver);
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
    // En modo filtrado ya está todo cargado -- si no hay página cacheada
    // siguiente, no hay más. En modo navegación puede haber más en el
    // server aunque no esté cacheado todavía.
    return !isFiltering && hasMore;
  }

  // null = el total no se conoce con certeza todavía (modo navegación, con
  // posibles páginas sin cargar en el server). No-null = total conocido
  // (modo filtrado, donde ya se cargó todo de una).
  int? get totalPages {
    if (!isFiltering && hasMore) return null;
    final total = (filteredDrivers.length / _pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    AdminStatusFilter? statusFilter,
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
      statusFilter: statusFilter ?? this.statusFilter,
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
