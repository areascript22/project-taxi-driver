import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/admin/domain/entity/admin_driver_entity.dart';
import 'package:driver_app/feature/admin/domain/repository/admin_repository.dart';
import 'package:driver_app/feature/admin/presentation/bloc/driver_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

AdminDriverEntity _driver({
  String approvalStatus = 'pending',
  bool isBlocked = false,
  String? blockReason,
  String? rejectionReason,
}) {
  return AdminDriverEntity(
    uid: '1',
    firstName: 'First',
    lastName: 'Last',
    email: '1@example.com',
    phoneNumber: '555-1',
    approvalStatus: approvalStatus,
    isBlocked: isBlocked,
    blockReason: blockReason,
    rejectionReason: rejectionReason,
  );
}

void main() {
  late MockAdminRepository repository;

  setUp(() {
    repository = MockAdminRepository();
  });

  DriverDetailCubit buildCubit({AdminDriverEntity? driver}) =>
      DriverDetailCubit(adminRepository: repository, driver: driver ?? _driver());

  test('initial state carries the driver passed to the constructor', () {
    final driver = _driver();
    final cubit = buildCubit(driver: driver);
    expect(cubit.state.driver, driver);
    expect(cubit.state.isProcessing, isFalse);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.wasDeleted, isFalse);
  });

  group('approve', () {
    blocTest<DriverDetailCubit, DriverDetailState>(
      'marks the driver as approved and clears any rejection reason',
      setUp: () {
        when(
          () => repository.updateApprovalStatus(uid: '1', status: 'approved'),
        ).thenAnswer((_) async => const Right(unit));
      },
      build:
          () => buildCubit(
            driver: _driver(
              approvalStatus: 'rejected',
              rejectionReason: 'documentos vencidos',
            ),
          ),
      act: (cubit) => cubit.approve(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.driver.approvalStatus == 'approved' &&
                  s.driver.rejectionReason == null,
            ),
          ],
    );

    blocTest<DriverDetailCubit, DriverDetailState>(
      'reports the error and leaves the driver unchanged on failure',
      setUp: () {
        when(
          () => repository.updateApprovalStatus(uid: '1', status: 'approved'),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo aprobar')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.approve(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.errorMessage == 'no se pudo aprobar' &&
                  s.driver.approvalStatus == 'pending',
            ),
          ],
    );
  });

  group('reject', () {
    blocTest<DriverDetailCubit, DriverDetailState>(
      'marks the driver as rejected with the given reason',
      setUp: () {
        when(
          () => repository.updateApprovalStatus(
            uid: '1',
            status: 'rejected',
            reason: 'foto de la licencia ilegible',
          ),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildCubit,
      act: (cubit) => cubit.reject(reason: 'foto de la licencia ilegible'),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.driver.approvalStatus == 'rejected' &&
                  s.driver.rejectionReason == 'foto de la licencia ilegible',
            ),
          ],
    );

    blocTest<DriverDetailCubit, DriverDetailState>(
      'reports the error on failure',
      setUp: () {
        when(
          () => repository.updateApprovalStatus(
            uid: '1',
            status: 'rejected',
            reason: 'motivo',
          ),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo rechazar')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.reject(reason: 'motivo'),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) => !s.isProcessing && s.errorMessage == 'no se pudo rechazar',
            ),
          ],
    );
  });

  group('block', () {
    blocTest<DriverDetailCubit, DriverDetailState>(
      'marks the driver as blocked with the given reason',
      setUp: () {
        when(
          () => repository.updateBlockStatus(
            uid: '1',
            blocked: true,
            reason: 'quejas de pasajeros',
          ),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: () => buildCubit(driver: _driver(approvalStatus: 'approved')),
      act: (cubit) => cubit.block(reason: 'quejas de pasajeros'),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.driver.isBlocked &&
                  s.driver.blockReason == 'quejas de pasajeros',
            ),
          ],
    );

    blocTest<DriverDetailCubit, DriverDetailState>(
      'reports the error and leaves the driver unblocked on failure',
      setUp: () {
        when(
          () => repository.updateBlockStatus(
            uid: '1',
            blocked: true,
            reason: 'motivo',
          ),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo bloquear')),
        );
      },
      build: () => buildCubit(driver: _driver(approvalStatus: 'approved')),
      act: (cubit) => cubit.block(reason: 'motivo'),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.errorMessage == 'no se pudo bloquear' &&
                  !s.driver.isBlocked,
            ),
          ],
    );
  });

  group('unblock', () {
    blocTest<DriverDetailCubit, DriverDetailState>(
      'clears the block info on success',
      setUp: () {
        when(
          () => repository.updateBlockStatus(uid: '1', blocked: false),
        ).thenAnswer((_) async => const Right(unit));
      },
      build:
          () => buildCubit(
            driver: _driver(
              approvalStatus: 'approved',
              isBlocked: true,
              blockReason: 'motivo viejo',
            ),
          ),
      act: (cubit) => cubit.unblock(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  !s.driver.isBlocked &&
                  s.driver.blockReason == null,
            ),
          ],
    );

    blocTest<DriverDetailCubit, DriverDetailState>(
      'reports the error on failure',
      setUp: () {
        when(
          () => repository.updateBlockStatus(uid: '1', blocked: false),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo desbloquear')),
        );
      },
      build:
          () => buildCubit(
            driver: _driver(approvalStatus: 'approved', isBlocked: true),
          ),
      act: (cubit) => cubit.unblock(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) => !s.isProcessing && s.errorMessage == 'no se pudo desbloquear',
            ),
          ],
    );
  });

  group('delete', () {
    blocTest<DriverDetailCubit, DriverDetailState>(
      'marks the state as deleted on success',
      setUp: () {
        when(
          () => repository.deleteDriver(uid: '1'),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildCubit,
      act: (cubit) => cubit.delete(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>((s) => !s.isProcessing && s.wasDeleted),
          ],
    );

    blocTest<DriverDetailCubit, DriverDetailState>(
      'reports the error and does not mark as deleted on failure',
      setUp: () {
        when(() => repository.deleteDriver(uid: '1')).thenAnswer(
          (_) async => Left(Failure(message: 'no se pudo eliminar')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.delete(),
      expect:
          () => [
            predicate<DriverDetailState>((s) => s.isProcessing),
            predicate<DriverDetailState>(
              (s) =>
                  !s.isProcessing &&
                  s.errorMessage == 'no se pudo eliminar' &&
                  !s.wasDeleted,
            ),
          ],
    );
  });
}
