import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/avatar_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  final AvatarStorageService _avatarStorageService = AvatarStorageService();
  User? _user;
  UserModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _profileErrorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _profileSubscription;

  User? get user => _user;
  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get profileErrorMessage => _profileErrorMessage;

  AuthProvider() {
    _authSubscription = _authService.user.listen(_handleAuthChanged);
  }

  Future<void> _handleAuthChanged(User? user) async {
    _user = user;
    await _profileSubscription?.cancel();
    _profile = null;
    _errorMessage = null;
    _profileErrorMessage = null;

    if (user != null) {
      await _userRepository.ensureUserProfile(user);
      _profileSubscription = _userRepository.streamUser(user.uid).listen((
        profile,
      ) {
        _profile = profile;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() async {
      await _authService.signIn(email, password);
    });
  }

  Future<bool> loginWithGoogle() async {
    return _runAuthAction(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<bool> register(String email, String password) async {
    return _runAuthAction(() async {
      await _authService.register(email, password);
    });
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return _runAuthAction(() async {
      await _authService.sendPasswordResetEmail(email);
    });
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _runAuthAction(() async {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  Future<String?> uploadAvatarImage(XFile image) async {
    final currentUser = _user;
    if (currentUser == null) {
      _profileErrorMessage = 'Không tìm thấy người dùng đang đăng nhập.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      return await _avatarStorageService.uploadAvatar(
        userId: currentUser.uid,
        image: image,
      );
    } on FormatException catch (error) {
      _profileErrorMessage = error.message;
      return null;
    } catch (_) {
      _profileErrorMessage = 'Không thể upload avatar. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String avatar,
  }) async {
    final currentUser = _user;
    if (currentUser == null) {
      _profileErrorMessage = 'Không tìm thấy người dùng đang đăng nhập.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      await _authService.updateProfile(displayName: name, photoUrl: avatar);
      await _userRepository.updateProfile(
        UserModel(
          userId: currentUser.uid,
          name: name,
          email: currentUser.email ?? '',
          avatar: avatar,
        ),
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _profileErrorMessage = _messageForCode(error.code);
      return false;
    } catch (_) {
      _profileErrorMessage = 'Không thể cập nhật profile. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    _profileErrorMessage = null;
    await _authService.signOut();
  }

  void clearError() {
    _errorMessage = null;
    _profileErrorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _messageForCode(error.code);
      return false;
    } on GoogleSignInException catch (error) {
      _errorMessage = _messageForGoogleSignInCode(error.code);
      return false;
    } catch (_) {
      _errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _messageForGoogleSignInCode(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return 'Đã hủy đăng nhập Google.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Cấu hình Google Sign-In chưa đúng. Hãy kiểm tra SHA và google-services.json.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Không thể mở màn hình đăng nhập Google.';
      default:
        return 'Không thể đăng nhập bằng Google. Vui lòng thử lại.';
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'weak-password':
        return 'Mật khẩu cần tối thiểu 6 ký tự.';
      case 'requires-recent-login':
        return 'Phiên đăng nhập đã cũ. Vui lòng đăng xuất và đăng nhập lại.';
      case 'no-current-user':
        return 'Không tìm thấy người dùng đang đăng nhập.';
      default:
        return 'Không thể hoàn tất yêu cầu. Vui lòng thử lại.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
