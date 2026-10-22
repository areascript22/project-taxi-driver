import 'admin_driver_entity.dart';

class DriverPageEntity {
  final List<AdminDriverEntity> drivers;
  final String? nextCursor;
  final bool hasMore;

  DriverPageEntity({
    required this.drivers,
    this.nextCursor,
    this.hasMore = false,
  });
}
