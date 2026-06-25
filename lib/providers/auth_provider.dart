import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.user.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    User? user = await _authService.signIn(email, password);
    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    User? user = await _authService.register(email, password);
    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
