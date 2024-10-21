import 'package:nixietube_parser/nixietube_parser.dart';
import 'package:test/test.dart';

void main() {
  test('Asserts', () {
    expect(NixAssertExpression(false).hashCode, -7474038219152082308);
  });
}
