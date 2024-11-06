import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_app/authservice.dart';

// Auth States
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}
class AuthError extends AuthState {
  final String errorMessage;
  const AuthError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  Future<void> login({
    required String email, 
    required String password, 
        required String mnemonic

  }) async {
    try {
      emit(AuthLoading());
      await _authService.login(
        email: email, 
        password: password, 
        mnemonic: mnemonic
      );
      final user = _authService.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signup({
    required String username,
    required String password,
    required String author_name
  }) async {
    try {
      emit(AuthLoading());
      await _authService.signup(
        username: username,
        password: password,
        author_name: author_name
        
      );
      final user = _authService.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Signup failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}