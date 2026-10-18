import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';

abstract class StoreLauncherService {
  /// Abre la ficha de la app en la tienda (fuera de la app).
  Future<Either<Failure, Unit>> open({required String url});
}
