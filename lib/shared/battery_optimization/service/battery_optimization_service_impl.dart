import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../core/error/errors.dart';
import 'battery_optimization_service.dart';

class BatteryOptimizationServiceImpl implements BatteryOptimizationService {
  @override
  Future<Either<Failure, bool>> isIgnoringBatteryOptimizations() async {
    try {
      final status = await ph.Permission.ignoreBatteryOptimizations.status;
      debugPrint(
        'BatteryOptimizationDebug | isIgnoringBatteryOptimizations -> $status',
      );
      return Right(status.isGranted);
    } catch (e) {
      debugPrint(
        'BatteryOptimizationDebug | Error en isIgnoringBatteryOptimizations: $e',
      );
      return Left(
        Failure(
          message: 'No se pudo consultar el estado de optimización de batería',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> requestIgnoreBatteryOptimizations() async {
    try {
      final status = await ph.Permission.ignoreBatteryOptimizations.request();
      debugPrint(
        'BatteryOptimizationDebug | requestIgnoreBatteryOptimizations -> $status',
      );
      return Right(status.isGranted);
    } catch (e) {
      debugPrint(
        'BatteryOptimizationDebug | Error en requestIgnoreBatteryOptimizations: $e',
      );
      return Left(
        Failure(
          message: 'No se pudo solicitar el permiso de optimización de batería',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> openAppSettings() async {
    try {
      final opened = await ph.openAppSettings();
      debugPrint('BatteryOptimizationDebug | openAppSettings -> $opened');
      return const Right(null);
    } catch (e) {
      debugPrint('BatteryOptimizationDebug | Error en openAppSettings: $e');
      return Left(
        Failure(message: 'No se pudo abrir la configuración de la app'),
      );
    }
  }
}
