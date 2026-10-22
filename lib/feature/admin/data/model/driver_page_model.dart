import '../../domain/entity/driver_page_entity.dart';
import 'admin_driver_model.dart';

class DriverPageModel {
  final List<AdminDriverModel> drivers;
  final String? nextCursor;
  final bool hasMore;

  DriverPageModel({
    required this.drivers,
    this.nextCursor,
    this.hasMore = false,
  });

  factory DriverPageModel.fromJson(Map<String, dynamic> json) {
    return DriverPageModel(
      drivers:
          (json['drivers'] as List<dynamic>? ?? [])
              .map(
                (item) => AdminDriverModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  DriverPageEntity toEntity() {
    return DriverPageEntity(
      drivers: drivers.map((model) => model.toEntity()).toList(),
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }
}
