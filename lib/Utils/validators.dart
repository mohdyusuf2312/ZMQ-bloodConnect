class Validators {
  static String? valiadatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters
    final cleanedValue = value.replaceAll(RegExp(r'\D'), '');

    // Check if it's a valid Indian phone number (10 digits)
    if (cleanedValue.length != 10) {
      return "Please enter a valid 10 digit number";
    }

    return null;
  }
}
