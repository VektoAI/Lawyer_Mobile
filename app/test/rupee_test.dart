import 'package:flutter_test/flutter_test.dart';
import 'package:munshi_mobile/utils/rupee.dart';

void main() {
  group('rupee', () {
    test('symbol always comes first, never gets pushed to the end', () {
      expect(rupee(1000), '₹1,000');
      expect(rupee(999), '₹999');
    });

    test('uses Indian lakh/crore grouping, not Western thousands', () {
      expect(rupee(0), '₹0');
      expect(rupee(999), '₹999');
      expect(rupee(1000), '₹1,000');
      expect(rupee(12345), '₹12,345');
      expect(rupee(100000), '₹1,00,000');
      expect(rupee(1234567), '₹12,34,567');
      expect(rupee(12345678), '₹1,23,45,678');
    });

    test('handles negative amounts', () {
      expect(rupee(-500), '-₹500');
      expect(rupee(-100000), '-₹1,00,000');
    });
  });
}
