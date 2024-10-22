import 'package:nixietube_parser/nixietube_parser.dart';
import 'package:test/test.dart';

void main() {
  test('Asserts', () {
    expect(NixAssertExpression(false).hashCode, -7474038219152082308);
    expect(NixAssertExpression(true).hashCode, 826976763423733234);
    expect(
        NixAssertExpression(NixIdentifierList([
          NixIdentifier(['value'])
        ])).hashCode,
        -4204942221593731550);
  });
}
