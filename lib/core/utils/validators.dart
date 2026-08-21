import 'package:flutter/widgets.dart' show TextEditingController;

/// Reusable form-field validators for the Contact / Register Interest forms.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? name(String? value) {
    final String? req = required(value, field: 'Name');
    if (req != null) return req;
    if (value!.trim().length < 2) return 'Enter a valid name';
    return null;
  }

  static String? email(String? value) {
    final String? req = required(value, field: 'Email');
    if (req != null) return req;
    final RegExp pattern = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!pattern.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    final String? req = required(value, field: 'Phone number');
    if (req != null) return req;
    final RegExp pattern = RegExp(r'^\+?[0-9\s\-]{7,15}$');
    if (!pattern.hasMatch(value!.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    if (value.trim().length > 1000) return 'Message is too long';
    return null;
  }

  static String? username(String? value) {
    final String? req = required(value, field: 'Username');
    if (req != null) return req;
    if (value!.trim().length < 3) return 'Username must be at least 3 characters';
    final RegExp pattern = RegExp(r'^[\w.@+\-]+$');
    if (!pattern.hasMatch(value.trim())) return 'Only letters, numbers and . @ + - _ are allowed';
    return null;
  }

  static String? password(String? value) {
    final String? req = required(value, field: 'Password');
    if (req != null) return req;
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(TextEditingController passwordController) {
    return (String? value) {
      final String? req = required(value, field: 'Confirm password');
      if (req != null) return req;
      if (value != passwordController.text) return 'Passwords do not match';
      return null;
    };
  }

  /// Optional-field variants — used on Profile edit, where email/phone/name
  /// may be left blank but must still be well-formed if provided.
  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return phone(value);
  }
}
