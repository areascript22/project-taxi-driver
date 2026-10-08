import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Traduce un [FailureCode] al texto que se le muestra al usuario.
///
/// Es la contraparte de la regla de la capa de datos: los repositorios
/// devuelven codigos, y este es el unico lugar que decide el texto. Los
/// codigos que no son para mostrar (fallos de servicios internos que el
/// repositorio ya loguea, como el token de push) caen en el mensaje genarico
/// a proposito: si alguno llega a la UI por un camino nuevo, el usuario ve
/// algo razonable en vez de un detalle tecnico.
extension FailureTextX on BuildContext {
  String failureText(FailureCode code) {
    final l10n = AppLocalizations.of(this);
    return switch (code) {
      FailureCode.noPermission => l10n.failureNoPermission,
      FailureCode.driverNotFound => l10n.failureDriverNotFound,
      FailureCode.driversFetchFailed => l10n.failureDriversFetchFailed,
      FailureCode.driverUpdateFailed => l10n.failureDriverUpdateFailed,
      FailureCode.driverDeleteFailed => l10n.failureDriverDeleteFailed,
      FailureCode.blockReasonMissing => l10n.failureBlockReasonMissing,
      FailureCode.rejectReasonMissing => l10n.failureRejectReasonMissing,
      FailureCode.driverNotApproved => l10n.failureDriverNotApproved,
      FailureCode.gpsDisabled => l10n.failureGpsDisabled,
      FailureCode.locationUpdateFailed => l10n.failureLocationUpdateFailed,
      FailureCode.rideTaken => l10n.failureRideTaken,
      FailureCode.rideUnavailable => l10n.failureRideUnavailable,
      FailureCode.rideAcceptFailed => l10n.failureRideAcceptFailed,
      FailureCode.rideCancelNotAllowed => l10n.failureRideCancelNotAllowed,
      FailureCode.rideCancelUnavailable => l10n.failureRideCancelUnavailable,
      FailureCode.rideCancelFailed => l10n.failureRideCancelFailed,
      FailureCode.tripFinishNotAllowed => l10n.failureTripFinishNotAllowed,
      FailureCode.tripFinishUnavailable => l10n.failureTripFinishUnavailable,
      FailureCode.tripFinishFailed => l10n.failureTripFinishFailed,
      FailureCode.arrivalNotifyFailed => l10n.failureArrivalNotifyFailed,
      FailureCode.activeTripCheckFailed => l10n.failureActiveTripCheckFailed,
      FailureCode.chatWriteNotAllowed => l10n.failureChatWriteNotAllowed,
      FailureCode.chatRideFinished => l10n.failureChatRideFinished,
      FailureCode.chatSendFailed => l10n.failureChatSendFailed,
      FailureCode.accountHasActiveRide => l10n.failureAccountHasActiveRide,
      FailureCode.accountDeleteFailed => l10n.failureAccountDeleteFailed,
      FailureCode.driverProfileCheckFailed => l10n.failureDriverProfileCheckFailed,
      FailureCode.vehicleFetchFailed => l10n.failureVehicleFetchFailed,
      FailureCode.profileSaveFailed => l10n.failureProfileSaveFailed,
      FailureCode.imagePickFailed => l10n.failureImagePickFailed,
      FailureCode.sessionVerifyFailed => l10n.failureSessionVerifyFailed,
      FailureCode.signInFailed => l10n.failureSignInFailed,
      FailureCode.signOutFailed => l10n.failureSignOutFailed,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.notSignedIn => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.batteryStatusFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.batteryRequestFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.appSettingsFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushInitFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushTokenFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.fcmTokenSaveFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushLanguageSaveFailed => l10n.failureUnexpected,
      FailureCode.chatMessagesLoadFailed => l10n.failureChatMessagesLoadFailed,
      FailureCode.profileLoadFailed => l10n.failureProfileLoadFailed,
      FailureCode.unexpected => l10n.failureUnexpected,
    };
  }
}
