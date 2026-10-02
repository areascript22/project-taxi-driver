part of 'admin_bloc.dart';

@immutable
sealed class AdminEvent {}

class AdminLoadRequested extends AdminEvent {}

class AdminSearchChanged extends AdminEvent {
  final String query;

  AdminSearchChanged({required this.query});
}

class AdminPageChanged extends AdminEvent {
  final int page;

  AdminPageChanged({required this.page});
}

class AdminRoleChangeRequested extends AdminEvent {
  final String uid;
  final String role;

  AdminRoleChangeRequested({required this.uid, required this.role});
}
