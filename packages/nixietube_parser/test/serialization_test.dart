import 'package:nixietube_parser/nixietube_parser.dart';
import 'package:test/test.dart';

void main() {
  test('Asserts', () {
    expect(NixAssertExpression(false).hashCode, 245403957095838170);
    expect(NixAssertExpression(true).hashCode, -1948374485845354201);
    expect(
        NixAssertExpression(NixIdentifierList([
          NixIdentifier(['value'])
        ])).hashCode,
        -5432654907264442069);
  });
}
