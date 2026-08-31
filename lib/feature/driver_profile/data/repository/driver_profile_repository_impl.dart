import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/driver_entity.dart';
import '../../domain/entity/vehicle_entity.dart';
import '../../domain/repository/driver_profile_repository.dart';
import '../model/driver_model.dart';
import '../model/vehicle_model.dart';

class DriverProfileRepositoryImpl implements DriverProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _driversCollection = 'drivers';
  static const String _vehiclesCollection = 'vehicles';

  @override
  Future<Either<Failure, DriverEntity?>> getDriver({
    required String driverId,
  }) async {
    try {
      final snapshot =
          await _firestore.collection(_driversCollection).doc(driverId).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return const Right(null);
      }

      final driver = DriverModel.fromJson(snapshot.data()!, id: snapshot.id);
      return Right(driver.toEntity());
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en getDriver: $e');
      return Left(
        Failure(message: 'No se pudo verificar tu información de conductor'),
      );
    }
  }

  @override
  Future<Either<Failure, VehicleEntity?>> getVehicle({
    required String vehicleId,
  }) async {
    try {
      final snapshot =
          await _firestore.collection(_vehiclesCollection).doc(vehicleId).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return const Right(null);
      }

      final vehicle = VehicleModel.fromJson(
        snapshot.data()!,
        vehicleId: snapshot.id,
      );
      return Right(vehicle.toEntity());
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en getVehicle: $e');
      return Left(
        Failure(message: 'No se pudo obtener la información del vehículo'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> registerDriver({
    required DriverEntity driver,
    required VehicleEntity vehicle,
    File? profileImage,
  }) async {
    try {
      String? photoUrl = driver.photoUrl;

      if (profileImage != null) {
        final storageRef = _storage.ref(
          'driver_profile_photos/${driver.id}.jpg',
        );
        await storageRef.putFile(profileImage);
        photoUrl = await storageRef.getDownloadURL();
      }

      final driverRef = _firestore.collection(_driversCollection).doc(
        driver.id,
      );
      final vehicleRef =
          _firestore.collection(_vehiclesCollection).doc();

      final driverToSave = driver.copyWith(
        photoUrl: photoUrl,
        vehicleId: vehicleRef.id,
      );
      final vehicleToSave = vehicle.copyWith(
        vehicleId: vehicleRef.id,
        driverId: driver.id,
      );

      final batch = _firestore.batch();
      batch.set(driverRef, {
        ...DriverModel.fromEntity(driverToSave).toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(vehicleRef, {
        ...VehicleModel.fromEntity(vehicleToSave).toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return const Right(unit);
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en registerDriver: $e');
      return Left(
        Failure(
          message: 'No se pudo guardar tu información. Intenta nuevamente.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFcmToken({
    required String driverId,
    required String token,
  }) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).update({
        'fcmToken': token,
      });
      return const Right(unit);
    } catch (e) {
      debugPrint('DriverProfileDebug | Error en updateFcmToken: $e');
      return Left(
        Failure(message: 'No se pudo registrar el token de notificaciones'),
      );
    }
  }
}
