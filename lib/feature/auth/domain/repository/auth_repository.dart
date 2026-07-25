import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_entity.dart';

abstract class AuthRepository{
  Future<Either<Failure, UserEntity >> signInWithGoogle();
}