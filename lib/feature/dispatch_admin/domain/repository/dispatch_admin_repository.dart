import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/dispatch_change_entity.dart';
import '../entity/dispatch_config_entity.dart';
import '../entity/dispatch_ring_entity.dart';

abstract class DispatchAdminRepository {
  Future<Either<Failure, DispatchConfigEntity>> getConfig();

  /// Reemplaza la configuración completa. [expectedVersion] es la que se vio al
  /// cargar: si ya cambió, falla con `FailureCode.dispatchConfigConflict`.
  /// Devuelve la configuración tal como quedó guardada.
  Future<Either<Failure, DispatchConfigEntity>> saveConfig({
    required List<DispatchRingEntity> rings,
    required int locationMaxAgeSeconds,
    required int expectedVersion,
  });

  /// Solo el superuser. Devuelve la configuración con el interruptor ya movido.
  Future<Either<Failure, DispatchConfigEntity>> setAdminEditing({
    required bool enabled,
  });

  /// Del cambio más nuevo al más viejo. [beforeId] pide los anteriores a ese.
  Future<Either<Failure, DispatchHistoryPageEntity>> getHistory({
    required int limit,
    int? beforeId,
  });
}
