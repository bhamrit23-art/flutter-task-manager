/// Form field validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  // Deliberately loose: something@something.tld. Firebase does the strict
  // check, and stricter patterns reject valid addresses such as name+tag@.
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address';
    if (!_emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? Function(String?) required(String message) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please choose a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
