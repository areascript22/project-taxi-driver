import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/driver_entity.dart';
import '../entity/vehicle_entity.dart';

abstract class DriverProfileRepository {
  // Devuelve null (dentro de Right) si el conductor autenticado todavía no
  // tiene datos guardados en Firestore -- señal de que es un usuario nuevo
  // y debe pasar por el flujo de registro.
  Future<Either<Failure, DriverEntity?>> getDriver({required String driverId});

  // Devuelve null (dentro de Right) si el vehículo no existe.
  Future<Either<Failure, VehicleEntity?>> getVehicle({
    required String vehicleId,
  });

  // Sube (si corresponde) la foto de perfil a Storage y guarda, en una sola
  // escritura atómica, el documento del conductor y el de su vehículo.
  Future<Either<Failure, Unit>> registerDriver({
    required DriverEntity driver,
    required VehicleEntity vehicle,
    File? profileImage,
  });
}
