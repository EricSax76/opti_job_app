import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/candidate.dart';
import 'package:infojobs_flutter_app/data/models/company.dart';
import 'package:infojobs_flutter_app/data/repositories/auth_repository.dart';
import 'package:infojobs_flutter_app/utils/app_exception.dart';

final authControllerProvider =
    ChangeNotifierProvider<AuthController>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  Candidate? _candidate;
  Company? _company;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Candidate? get candidate => _candidate;
  Company? get company => _company;
  bool get isAuthenticated => _candidate != null || _company != null;

  Future<void> loginCandidate({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.loginCandidate(
        email: email,
        password: password,
      );
      _candidate = result;
      _company = null;
      _errorMessage = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Candidate login failed: $error\n$stackTrace');
      _errorMessage = 'No se pudo iniciar sesión. Verifica tus credenciales.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.registerCandidate(
        name: name,
        email: email,
        password: password,
      );
      _candidate = result;
      _company = null;
      _errorMessage = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Candidate register failed: $error\n$stackTrace');
      _errorMessage = 'No se pudo completar el registro.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.loginCompany(
        email: email,
        password: password,
      );
      _company = result;
      _candidate = null;
      _errorMessage = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Company login failed: $error\n$stackTrace');
      _errorMessage = 'No se pudo iniciar sesión.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final result = await _repository.registerCompany(
        name: name,
        email: email,
        password: password,
      );
      _company = result;
      _candidate = null;
      _errorMessage = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Company register failed: $error\n$stackTrace');
      _errorMessage = 'No se pudo completar el registro.';
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _repository.logout();
    _candidate = null;
    _company = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
