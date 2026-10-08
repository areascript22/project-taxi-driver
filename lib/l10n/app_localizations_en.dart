// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taxi project - Driver';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsVoiceTitle => 'Voice';

  @override
  String get settingsVoiceSubtitle => 'Spoken announcements';

  @override
  String get settingsVibrationTitle => 'Vibration';

  @override
  String get settingsVibrationSubtitle => 'Vibrate on important events';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'This action cannot be undone';

  @override
  String get deleteAccountDialogBody => 'This action is irreversible. Your profile, your photo, your registered vehicle and your chats will be deleted. You will not be able to recover this information.\n\nAre you sure you want to delete your account?';

  @override
  String get deleteAccountSuccess => 'Account deleted successfully';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonNotProvided => 'Not provided';

  @override
  String get navRides => 'Rides';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navProfile => 'Profile';

  @override
  String appVersionLabel(String version) {
    return 'Version: $version';
  }

  @override
  String get appVersionLoading => 'Loading...';

  @override
  String get appVersionUnavailable => 'Version unavailable';

  @override
  String get appVersionError => 'Could not get the version';

  @override
  String get brandRoleLabel => 'Driver';

  @override
  String get signInTagline => 'Sign in to start driving';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get splashVersionLabel => 'Version 1.0.0';

  @override
  String get logoutDialogBody => 'Are you sure you want to sign out?';

  @override
  String get profileDriverNotFound => 'Driver information not found';

  @override
  String get profileFallbackName => 'Driver';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileVehicleFallback => 'Vehicle';

  @override
  String get roleSuperuser => 'Superuser';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleDriver => 'Driver';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonActivate => 'Turn on';

  @override
  String get commonUnderstood => 'Got it';

  @override
  String get commonPickupPoint => 'Pickup point';

  @override
  String get batteryBannerTitle => 'You can\'t receive rides yet';

  @override
  String get batteryBannerBody => 'You need to exclude TaxiGo Conductor from battery optimization so your location is not lost during a ride.';

  @override
  String get batteryOpenSettings => 'Open settings';

  @override
  String get batteryDialogTitle => 'We need one more permission';

  @override
  String get batteryDialogBody => 'So we do not lose your location during a ride -- even if the app closes by accident -- we need you to exclude TaxiGo Conductor from the system battery optimization.';

  @override
  String get locationDeniedTitle => 'We need your location';

  @override
  String get locationDeniedBlockedBody => 'Location access is blocked. Turn it on from your device settings to see and accept rides.';

  @override
  String get locationDeniedBody => 'We need access to your location to show and accept passenger rides.';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationGrantPermission => 'Grant location permission';

  @override
  String get locationRequiredToAccept => 'Location access is required to accept rides.';

  @override
  String get offlineTitle => 'You are offline';

  @override
  String get offlineBody => 'Turn on the switch at the top to start receiving ride requests.';

  @override
  String get offlineConnect => 'Go online';

  @override
  String get requestsTitle => 'Incoming requests';

  @override
  String get requestsEmpty => 'No passengers are looking for\na taxi right now.';

  @override
  String requestWaitingSeconds(int seconds) {
    return 'Waiting for a driver · ${seconds}s';
  }

  @override
  String get requestAccept => 'Accept ride';

  @override
  String get requestAcceptFailed => 'The ride could not be accepted.';

  @override
  String get welcomeAnnouncement => 'Welcome to TaxiGo Driver';

  @override
  String get chatTitle => 'Chat with the passenger';

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatInputHint => 'Write a message...';

  @override
  String get tripInProgressTitle => 'Ride in progress';

  @override
  String get tripCancel => 'Cancel ride';

  @override
  String get tripPassengerLabel => 'Passenger';

  @override
  String get tripOpenInMaps => 'Open in Google Maps';

  @override
  String get tripNavigateToPickup => 'Navigate to the pickup point';

  @override
  String get tripOpenMapsFailed => 'Google Maps could not be opened. Is it installed?';

  @override
  String get tripPassengerOnTheWay => 'The passenger is on the way to the car';

  @override
  String get tripPassengerCancelledAnnouncement => 'The passenger cancelled the ride';

  @override
  String get cancelTripDialogTitle => 'Cancel the ride?';

  @override
  String get cancelTripDialogBody => 'You already accepted this ride and the passenger is waiting for you. Cancelling now could affect your reputation as a driver.';

  @override
  String get cancelTripContinue => 'Keep the ride';

  @override
  String get passengerCancelledTitle => 'Ride cancelled';

  @override
  String get passengerCancelledBody => 'The passenger cancelled this ride. You can go back to the incoming requests list.';

  @override
  String get tripArrivedSending => 'Sending...';

  @override
  String get tripArrived => 'I have arrived';

  @override
  String get tripFinishing => 'Finishing...';

  @override
  String get tripFinish => 'Finish ride';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonNoName => 'No name';

  @override
  String get commonReason => 'Reason';

  @override
  String commonReasonWithValue(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get commonVerifyAgain => 'Check again';

  @override
  String get commonMoreOptions => 'More options';

  @override
  String get sessionCheckFailed => 'We could not verify your session. Check your connection and try again.';

  @override
  String get sessionBlockedTitle => 'Your account is blocked';

  @override
  String get sessionBlockedBody => 'An administrator temporarily blocked your account and you cannot receive rides in the meantime.';

  @override
  String get sessionRejectedTitle => 'Your application was rejected';

  @override
  String get sessionPendingTitle => 'Your account is under review';

  @override
  String get sessionRejectedBody => 'An administrator reviewed your registration and it was not approved.';

  @override
  String get sessionPendingBody => 'An administrator is reviewing your registration. We will let you know as soon as you can start receiving rides.';

  @override
  String onboardingStepOf(int step, int totalSteps) {
    return 'Step $step of $totalSteps';
  }

  @override
  String get onboardingPersonalTitle => 'Your details';

  @override
  String get onboardingPersonalSubtitle => 'Tell us who you are so we can verify you.';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldMobile => 'Mobile number';

  @override
  String get validationFirstName => 'Enter your first name';

  @override
  String get validationLastName => 'Enter your last name';

  @override
  String get validationMobileRequired => 'Enter your mobile number';

  @override
  String get validationMobileInvalid => 'Invalid Ecuadorian mobile number';

  @override
  String get onboardingSignOutPrompt => 'Not you? Sign out';

  @override
  String get onboardingVehicleTitle => 'Your vehicle';

  @override
  String get onboardingVehicleSubtitle => 'These details will be reviewed by our team.';

  @override
  String get vehiclePlate => 'License plate';

  @override
  String get vehicleBrand => 'Make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Year';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleColorHint => 'White';

  @override
  String get vehicleRegistrationNumber => 'Registration number';

  @override
  String get validationPlate => 'Enter the license plate';

  @override
  String get validationYearInvalid => 'Invalid year';

  @override
  String get validationRegistrationNumber => 'Enter the registration number';

  @override
  String get onboardingSaving => 'Saving...';

  @override
  String get onboardingSubmit => 'Sign me up';

  @override
  String get photoSheetTitle => 'Profile photo';

  @override
  String get photoTakePhoto => 'Take a photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get myVehicleTitle => 'My vehicle';

  @override
  String get vehicleStatusApproved => 'Vehicle approved';

  @override
  String get vehicleStatusRejected => 'Vehicle rejected';

  @override
  String get vehicleStatusInReview => 'Under review';

  @override
  String get adminTitle => 'Administration';

  @override
  String get adminSearchHint => 'Search by name, email or phone';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterPending => 'Pending';

  @override
  String get adminFilterRejected => 'Rejected';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterBlocked => 'Blocked';

  @override
  String get adminNoResults => 'No results found';

  @override
  String get adminNoDrivers => 'No registered drivers';

  @override
  String get adminReview => 'Review';

  @override
  String get adminChangeRole => 'Change role';

  @override
  String adminPageOf(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String adminPage(int page) {
    return 'Page $page';
  }

  @override
  String get adminStatusBlocked => 'Blocked';

  @override
  String get adminStatusApproved => 'Approved';

  @override
  String get adminStatusRejected => 'Rejected';

  @override
  String get adminStatusPending => 'Pending';

  @override
  String get adminDriverDetailTitle => 'Driver detail';

  @override
  String get adminDeleteDriver => 'Delete driver';

  @override
  String adminDeleteDriverBody(String driverName) {
    return 'Are you sure you want to delete $driverName? This action cannot be undone.';
  }

  @override
  String get adminNoModeratePermission => 'You do not have permission to manage this account\'s status.';

  @override
  String get adminUnblock => 'Unblock';

  @override
  String get adminUnblockDriver => 'Unblock driver';

  @override
  String adminUnblockDriverBody(String driverName) {
    return 'Are you sure you want to unblock $driverName? They will be able to receive rides again immediately.';
  }

  @override
  String get adminBlock => 'Block';

  @override
  String get adminBlockDriver => 'Block driver';

  @override
  String get adminBlockReasonHelp => 'This reason will be shown directly to the driver in the app.';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminRejectDriver => 'Reject driver';

  @override
  String get adminRejectReasonHelp => 'Tell the driver what they need to fix in order to apply again.';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReasonHint => 'Write the reason...';

  @override
  String get adminReasonRequired => 'This field is required';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminEmailLabel => 'Email';

  @override
  String get adminRating => 'Rating';

  @override
  String get adminFcmToken => 'Notification token';

  @override
  String get adminRegisteredAt => 'Registered on';

  @override
  String get adminUpdatedAt => 'Last updated';

  @override
  String get adminVehicleSection => 'Vehicle';

  @override
  String get adminNoVehicle => 'This driver has no registered vehicle';

  @override
  String get adminAccountBlocked => 'Account blocked';

  @override
  String get adminDriverActive => 'Active driver';

  @override
  String get adminApplicationRejected => 'Application rejected';

  @override
  String get adminPendingApproval => 'Pending approval';

  @override
  String get adminPendingApprovalBody => 'This driver cannot receive rides yet.';

  @override
  String get failureNoPermission => 'You do not have permission for this action';

  @override
  String get failureDriverNotFound => 'The driver no longer exists';

  @override
  String get failureDriversFetchFailed => 'The driver list could not be loaded';

  @override
  String get failureDriverUpdateFailed => 'The driver information could not be updated';

  @override
  String get failureDriverDeleteFailed => 'The driver could not be deleted';

  @override
  String get failureBlockReasonMissing => 'The block reason is missing';

  @override
  String get failureRejectReasonMissing => 'The rejection reason is missing';

  @override
  String get failureDriverNotApproved => 'A driver who is not approved cannot be blocked';

  @override
  String get failureGpsDisabled => 'Your device\'s GPS service is turned off.';

  @override
  String get failureLocationUpdateFailed => 'Your location could not be updated.';

  @override
  String get failureRideTaken => 'The ride was already taken by another driver or is no longer available.';

  @override
  String get failureRideUnavailable => 'The request is no longer available.';

  @override
  String get failureRideAcceptFailed => 'The ride could not be accepted.';

  @override
  String get failureRideCancelNotAllowed => 'You do not have permission to cancel this ride.';

  @override
  String get failureRideCancelUnavailable => 'The ride is no longer available to cancel.';

  @override
  String get failureRideCancelFailed => 'The ride could not be cancelled. Try again.';

  @override
  String get failureTripFinishNotAllowed => 'You do not have permission to finish this ride.';

  @override
  String get failureTripFinishUnavailable => 'The ride is no longer available to finish.';

  @override
  String get failureTripFinishFailed => 'The ride could not be finished. Try again.';

  @override
  String get failureArrivalNotifyFailed => 'We could not report your arrival. Try again.';

  @override
  String get failureActiveTripCheckFailed => 'We could not check whether you have a ride in progress.';

  @override
  String get failureChatWriteNotAllowed => 'You do not have permission to write in this ride.';

  @override
  String get failureChatRideFinished => 'The ride already ended, no more messages can be sent.';

  @override
  String get failureChatSendFailed => 'The message could not be sent. Try again.';

  @override
  String get failureAccountHasActiveRide => 'You have an active ride. Finish or cancel it before deleting your account.';

  @override
  String get failureAccountDeleteFailed => 'Your account could not be deleted. Try again.';

  @override
  String get failureDriverProfileCheckFailed => 'We could not verify your driver information';

  @override
  String get failureVehicleFetchFailed => 'The vehicle information could not be loaded';

  @override
  String get failureProfileSaveFailed => 'Your information could not be saved. Try again.';

  @override
  String get failureImagePickFailed => 'The selected image could not be loaded';

  @override
  String get failureSessionVerifyFailed => 'We could not verify your session. Try again.';

  @override
  String get failureSignInFailed => 'Sign-in failed. Try again.';

  @override
  String get failureSignOutFailed => 'Sign-out failed. Try again.';

  @override
  String get failureUnexpected => 'Something went wrong. Try again.';

  @override
  String get failureChatMessagesLoadFailed => 'The messages could not be loaded. Try again.';

  @override
  String get failureProfileLoadFailed => 'Your information could not be loaded';

  @override
  String isolateRideTowards(String place) {
    return 'Ride to $place';
  }

  @override
  String get commonNewRide => 'New ride';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';
}
