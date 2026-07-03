import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ThemeEvent {}

class ThemeLoadTenant extends ThemeEvent {
  final Color color;
  final String? logoUrl;
  final String? tenantName;

  ThemeLoadTenant({required this.color, this.logoUrl, this.tenantName});
}

class ThemeReset extends ThemeEvent {}

// State
class ThemeState {
  final Color themeColor;
  final String? logoUrl;
  final String? tenantName;

  ThemeState({required this.themeColor, this.logoUrl, this.tenantName});

  factory ThemeState.initial() => ThemeState(themeColor: Colors.indigo, logoUrl: null, tenantName: null);
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<ThemeLoadTenant>((event, emit) {
      emit(ThemeState(
        themeColor: event.color,
        logoUrl: event.logoUrl,
        tenantName: event.tenantName,
      ));
    });

    on<ThemeReset>((event, emit) {
      emit(ThemeState.initial());
    });
  }
}
