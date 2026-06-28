class FormValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9.!#$%&*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
  );

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (email.length > 254) {
      return 'Email không được vượt quá 254 ký tự.';
    }
    if (email.contains(' ') || !_emailPattern.hasMatch(email)) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (password.length < 6) {
      return 'Mật khẩu cần tối thiểu 6 ký tự.';
    }
    if (password.length > 128) {
      return 'Mật khẩu không được vượt quá 128 ký tự.';
    }
    return null;
  }

  static String? newPassword(String? value) {
    final basicError = loginPassword(value);
    if (basicError != null) {
      return basicError;
    }

    final password = value ?? '';
    if (password.trim() != password) {
      return 'Mật khẩu không được bắt đầu hoặc kết thúc bằng khoảng trắng.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return 'Mật khẩu cần có cả chữ và số.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }
    if (confirmPassword != password) {
      return 'Mật khẩu nhập lại không khớp.';
    }
    return null;
  }

  static String? changedPassword(String? value, String currentPassword) {
    final error = newPassword(value);
    if (error != null) {
      return error;
    }
    if (value == currentPassword) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }
    return null;
  }

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Vui lòng nhập tên hiển thị.';
    }
    if (name.length < 2) {
      return 'Tên hiển thị cần tối thiểu 2 ký tự.';
    }
    if (name.length > 50) {
      return 'Tên hiển thị không được vượt quá 50 ký tự.';
    }
    if (RegExp(r'[<>\\/{}\[\]|]').hasMatch(name)) {
      return 'Tên hiển thị có ký tự không hợp lệ.';
    }
    return null;
  }

  static String? avatarUrl(String? value) {
    final avatar = value?.trim() ?? '';
    if (avatar.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(avatar);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'Avatar URL không hợp lệ.';
    }
    return null;
  }
}
