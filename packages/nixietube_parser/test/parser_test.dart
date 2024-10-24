import 'package:nixietube_parser/nixietube_parser.dart';
import 'package:petitparser/debug.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

void main() {
  test('Lint the parser', () {
    final parse = NixParser();
    final parser = parse.build();

    expect(linter(parser), isEmpty);
  });

  test('Number type should return a number', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.numberToken());

    expect(parser.parse('1234').value, 1234);
    expect(parser.parse('-5678').value, -5678);
    expect(parser.parse('3.14').value, 3.14);
    expect(parser.parse('-5.69').value, -5.69);
  });

  test('Null should be null', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.nullToken());
    final result = parser.parse('null');

    expect(result.value, null);
  });

  test('True should be true', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.trueToken());
    final result = parser.parse('true');

    expect(result.value, true);
  });

  test('False should be false', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.falseToken());
    final result = parser.parse('false');

    expect(result.value, false);
  });

  test('Strings', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.stringLexicalToken());

    // TODO: write expect once string parsing fully works
    expect(parser.parse("""''
    Hello,
    world
    \${1 + 2}
    ''""").value, [
      ['Hello,'],
      ['world'],
      [3],
      [],
    ]);

    expect(parser.parse('"Hello, world \${1 + 2}"').value, [
      'Hello, world ',
      3,
    ]);
  });

  test('Paths', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.pathToken());

    expect(parser.parse("../.").value, NixPath(['..', '.']));
    expect(parser.parse("../..").value, NixPath(['..', '..']));
  });

  test('Math expressions', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.mathExpression());

    expect(parser.parse('1 + 1').value, 2);
    expect(parser.parse('1 * 1').value, 1);
    expect(parser.parse('1 / 1').value, 1);
    expect(parser.parse('1 - 1').value, 0);
  });

  test('Expressions', () {
    final parse = NixParser();
    final parser = parse.build();

    expect(parser.parse('assert true; null').value, null);
    expect(parser.parse('with { a = 1; }; a + 1').value, 2);
    expect(parser.parse('let a = 1; in a + 1').value, 2);
  });

  test('Identifier list', () {
    final parse = NixParser();
    final parser = parse.buildFrom(parse.identifierList());

    expect(
        parser.parse('{ x = 5; }.x').value,
        NixIdentifierList([
          NixAttributeSetExpression(
            fields: {
              NixIdentifierList([
                NixIdentifier(['x'])
              ]): 5,
            },
          ),
          NixIdentifier(['x']),
        ]));
  });
}
