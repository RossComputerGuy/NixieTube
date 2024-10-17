import 'package:petitparser/petitparser.dart';

import 'expression/assert.dart';
import 'expression/eval.dart';
import 'expression/math.dart';
import 'expression/merge.dart';
import 'expression/or.dart';
import 'expression/import.dart';
import 'expression/with.dart';
import 'expression.dart';

import 'identifier.dart';
import 'path.dart';

class NixParser extends GrammarDefinition {
  const NixParser();

  Parser token(Object input) {
    if (input is Parser) {
      return input.token().trim(ref0(hiddenStuffWhitespace));
    } else if (input is String) {
      return token(input.toParser()).labeled(input);
    }
    throw ArgumentError.value(input, 'Invalid token parser');
  }

  /* Tokens */

  Parser importToken() => ref1(token, 'import');
  Parser derivationToken() => ref1(token, 'derivation');
  Parser builtinsToken() => ref1(token, 'builtins');
  Parser letToken() => ref1(token, 'let');
  Parser inToken() => ref1(token, 'in');
  Parser withToken() => ref1(token, 'with');
  Parser inheritToken() => ref1(token, 'inherit');
  Parser ifToken() => ref1(token, 'if');
  Parser thenToken() => ref1(token, 'then');
  Parser elseToken() => ref1(token, 'else');
  Parser recToken() => ref1(token, 'rec');

  Parser orToken() => ref1(token, 'or');
  Parser assetToken() => ref1(token, 'assert');
  Parser<Null> nullToken() => ref1(token, 'null').trim().map((_) => null);
  Parser<bool> trueToken() => ref1(token, 'true').trim().map((_) => true);
  Parser<bool> falseToken() => ref1(token, 'false').trim().map((_) => false);

  Parser<num> numberToken() => (ref1(token, '-').optional() &
              (ref0(number) & (ref1(token, '.') & ref0(number)).optional()))
          .trim()
          .labeled('numberToken')
          .map((value) {
        final hasNeg = value[0] is Token ? value[0].value == '-' : false;
        final hasDec = value[1][1] is List;
        final base = value[1][0] * (hasNeg ? -1 : 1);

        if (hasDec) {
          // TODO: be smart and shift the digits
          return double.parse('$base.${value[1][1][1]}');
        }
        return base;
      });

  Parser<int> number() => digit()
      .plusString()
      .trim()
      .labeled('number')
      .map((value) => int.parse(value));

  Parser<List<dynamic>> stringLexicalToken() =>
      (ref0(multiLineStringLexicalToken) | ref0(singleLineStringLexicalToken))
          .labeled('stringLexicalToken')
          .map((value) => [value]);

  // TODO: escape for inner expression
  Parser<List<List<dynamic>>> multiLineStringLexicalToken() =>
      (string("''") & any().starLazy(string("''")).flatten() & string("''"))
          .map((value) => value[1]
              .split('\n')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty as bool)
              .map((v) => [v])
              .toList()
              .cast<List<dynamic>>());

  // TODO: escape for inner expression
  Parser<List<dynamic>> singleLineStringLexicalToken() => (char('"') &
              ref0(stringContentDoubleQuotedLexicalToken).star().flatten() &
              char('"') |
          pattern('^"\n\r').star() & char('"'))
      .labeled('singleLineStringLexicalToken')
      .map((value) => [value[1]]);

  Parser stringContentDoubleQuotedLexicalToken() =>
      (pattern('^\\"\n\r') | char('\\') & pattern('\n\r'))
          .labeled('stringContentDoubleQuotedLexicalToken');

  Parser letterLexicalToken() => letter();

  Parser identifierLexicalToken() => (ref0(identifierStartLexicalToken) &
          ref0(identifierPartLexicalToken)
              .star()
              .labeled('identifierPartLexicalToken star'))
      .labeled('identifierLexicalToken')
      .map((value) => NixIdentifier([value[0], ...value[1]]));

  Parser identifierStartLexicalToken() => (ref0(builtinsToken) |
          ref0(identifierExpressionLexicalToken) |
          ref0(letterLexicalToken))
      .labeled('identifierStartLexicalToken')
      .map((value) => value is Token ? value.value : value);

  Parser identifierPartLexicalToken() =>
      (ref0(identifierExpressionLexicalToken) |
              ref0(letterLexicalToken) |
              ref0(number))
          .labeled('identifierPartLexicalToken');

  Parser identifierExpressionLexicalToken() =>
      (ref1(token, '\${') & ref0(expression) & ref1(token, '}'))
          .map((value) => value[1]);

  Parser<NixPath> pathToken() =>
      ((ref0(pathTokenElementDown) | ref0(pathTokenElementCurr)) &
              (ref0(pathTokenElement) &
                  (ref1(token, '/') &
                          ref0(pathTokenElement)
                              .plusSeparated(ref1(token, '/'))
                              .map((value) => value.elements))
                      .map((value) => value[1])
                      .optional()))
          .map((value) => NixPath([
                value[0],
                value[1][0],
                ...(value[1][1] is List ? value[1][1] : []),
              ]));

  Parser pathTokenElement() =>
      ref0(pathTokenElementDown) |
      ref0(pathTokenElementCurr) |
      ref0(pathTokenElementName) |
      (ref1(token, '.').map((value) => value.value));

  Parser pathTokenElementDown() => string('../')
      .labeled('pathTokenElementDown')
      .map((value) => value.substring(0, value.length - 1));
  Parser pathTokenElementCurr() => string('./')
      .labeled('pathTokenElementCurr')
      .map((value) => value.substring(0, value.length - 1));
  Parser pathTokenElementName() =>
      (ref0(identifierList) | ref0(singleLineStringLexicalToken))
          .labeled('pathTokenElementName');

  /* Expressions */

  @override
  Parser start() => ref0(expression).end();

  Parser<NixExpression> expression() =>
      ((ref0(withExpression) | ref0(assertExpression)).star() &
              ref0(innerExpression))
          .map((value) => NixExpression(
                value[1],
                withs: value[0]
                    .whereType<NixWithExpression>()
                    .map((value) => value.value)
                    .toList(),
                asserts: value[0]
                    .whereType<NixAssertExpression>()
                    .map((value) => value.value)
                    .toList(),
              ));

  Parser parenExpression() =>
      (ref1(token, '(') & ref0(expression) & ref1(token, ')'))
          .map((value) => value[1]);

  Parser innerExpression() => (ref0(letInExpression) |
      ref0(derivationExpression) |
      ref0(ifElseExpression) |
      ref0(importExpression) |
      ref0(funcExpression) |
      ref0(listExpression) |
      ref0(attrSetExpression) |
      ref0(logicalExpression));

  Parser logicalExpression() => ref1(token, '!').optional() & (ref0(parenExpression) |
      ref0(mergeListExpression) |
      ref0(mergeAttrExpression) |
      ref0(hasAttrExpression) |
      ref0(orExpression) |
      ref0(mathExpression) |
      ref0(literal) |
      ref0(evalExpression));

  Parser evalExpression() =>
      (ref0(identifierList) & ref0(innerExpression).star())
          .labeled('evalExpression')
          .map((value) => NixEvalExpression(value[0], value[1]));

  Parser letInExpression() =>
      (ref0(letToken) & ref0(field).plus() & ref0(inToken) & ref0(expression))
          .labeled('letInExpression');

  Parser field() =>
      (ref0(inheritExpression) |
          (ref0(identifierList) & ref1(token, '=') & ref0(expression))) &
      ref1(token, ';');

  Parser derivationExpression() => (ref0(derivationToken) &
          ref1(token, '{') &
          ref0(field).plus() &
          ref1(token, '}'))
      .labeled('derivationExpression');

  Parser inheritExpression() =>
      (ref0(inheritToken) & ref0(inheritFrom).optional() & ref0(identifier))
          .labeled('inheritExpression');

  Parser inheritFrom() =>
      ref1(token, '(') & ref0(identifierList) & ref1(token, ')');

  Parser hasAttrExpression() =>
      (ref0(identifier) & ref1(token, '?') & ref0(identifierList))
          .labeled('hasAttrExpression');

  Parser ifElseExpression() => (ref0(ifToken) &
          ref0(logicalExpression) &
          ref0(thenToken) &
          ref0(expression) &
          ref0(elseToken) &
          ref0(expression))
      .labeled('ifElseExpression');

  Parser mathExpression() =>
      (ref0(mathExpressionSide) & ref0(mathOperator) & ref0(mathExpressionSide))
          .labeled('mathExpression');

  Parser mathExpressionSide() =>
      ref0(parenExpression) |
      ref0(ifElseExpression) |
      ref0(importExpression) |
      ref0(hasAttrExpression) |
      ref0(orExpression) |
      ref0(literal) |
      ref0(identifierList);

  Parser<NixMathOperator> mathOperator() => (ref1(token, '+') |
          ref1(token, '-') |
          ref1(token, '*') |
          ref1(token, '/') |
          ref1(token, '==') |
          ref1(token, '!=') |
          ref1(token, '>') |
          ref1(token, '<') |
          ref1(token, '>=') |
          ref1(token, '<=') |
          ref1(token, '->'))
      .map((token) => switch (token.value) {
            '+' => NixMathOperator.add,
            '-' => NixMathOperator.sub,
            '*' => NixMathOperator.mul,
            '/' => NixMathOperator.div,
            '==' => NixMathOperator.equal,
            '!=' => NixMathOperator.notEqual,
            '>' => NixMathOperator.gt,
            '<' => NixMathOperator.lt,
            '>=' => NixMathOperator.gtEqual,
            '<=' => NixMathOperator.ltEqual,
            '->' => NixMathOperator.impl,
            (_) => throw Exception('Unknown operator ${token.value}'),
          });

  Parser<NixImportExpression> importExpression() =>
      (ref0(importToken) & ref0(innerExpression).star())
          .map((value) => NixImportExpression(value[1]));

  Parser<NixOrExpression> orExpression() =>
      (ref0(identifierList) & ref0(orToken) & ref0(expression))
          .labeled('orExpression')
          .map((value) => NixOrExpression(value[0], value[2]));

  Parser<NixAssertExpression> assertExpression() =>
      (ref0(assetToken) & ref0(innerExpression) & ref1(token, ';'))
          .map((value) => NixAssertExpression(value[1]));

  Parser<NixWithExpression> withExpression() =>
      (ref0(withToken) & ref0(innerExpression) & ref1(token, ';'))
          .map((value) => NixWithExpression(value[1]));

  Parser funcExpression() =>
      (ref0(funcArguments) & ref0(expression)).labeled('funcExpression');

  Parser funcArguments() => ref0(funcArgumentsElement)
      .plusSeparated(ref1(token, ':'))
      .labeled('funcArguments');

  Parser funcArgumentsElement() => (ref0(identifier) |
          (ref1(token, '{') &
              (ref0(funcArgumentsElementField) &
                      (ref1(token, ',') &
                              ref0(funcArgumentsElementField)
                                  .plusSeparated(ref1(token, ',')))
                          .optional())
                  .optional() &
              ref1(token, '}')))
      .labeled('funcArgumentsElement');

  Parser funcArgumentsElementField() =>
      ref0(identifier) & (ref1(token, '?') & ref0(expression)).optional();

  Parser mergeListExpression() => (ref0(mergeListExpressionSide) &
          ref1(token, '++') &
          ref0(mergeListExpressionSide))
      .labeled('mergeListExpression')
      .map((value) =>
          NixMergeExpression(NixMergeOperation.list, value[0], value[2]));

  Parser mergeListExpressionSide() => (ref0(listExpression) |
          ref0(literal) |
          ref0(identifierList) |
          ref0(parenExpression))
      .labeled('mergeListExpressionSide');

  Parser listExpression() =>
      (ref1(token, '[') & ref0(listElement).star() & ref1(token, ']'))
          .labeled('listExpression');

  Parser listElement() => (ref0(listExpression) |
          ref0(attrSetExpression) |
          ref0(literal) |
          ref0(identifierList))
      .labeled('listElement');

  Parser mergeAttrExpression() => (ref0(mergeAttrExpressionSide) &
          ref1(token, '//') &
          ref0(mergeAttrExpressionSide))
      .labeled('mergeAttrExpression')
      .map((value) =>
          NixMergeExpression(NixMergeOperation.attrset, value[0], value[2]));

  Parser mergeAttrExpressionSide() =>
      (ref0(attrSetExpression) | ref0(identifierList) | ref0(parenExpression))
          .labeled('mergeAttrExpressionSide');

  Parser attrSetExpression() => (ref0(recToken).optional() &
          ref1(token, '{') &
          ref0(field).plus() &
          ref1(token, '}'))
      .labeled('attrSetExpression');

  Parser attrSetListElementValueOptional() =>
      (ref1(token, '?') & ref0(expression))
          .labeled('attrSetListElementValueOptional');

  Parser literal() => ref1(
          token,
          (ref0(nullToken) |
              ref0(trueToken) |
              ref0(falseToken) |
              ref0(pathToken) |
              ref0(numberToken) |
              ref0(stringLexicalToken)))
      .map((value) => value.value);

  Parser identifier() =>
      ref1(token, ref0(identifierLexicalToken)).map((value) => value.value);

  Parser<NixIdentifierList> identifierList() => ref0(identifier)
      .plusSeparated(ref1(token, '.'))
      .map((value) => NixIdentifierList(value.elements));

  /* Whitespace & newlines */

  Parser newlineLexicalToken() => pattern('\n\r');

  Parser hiddenWhitespace() => ref0(hiddenStuffWhitespace).plus();

  Parser hiddenStuffWhitespace() =>
      ref0(visibleWhitespace) |
      ref0(singleLineComment) |
      ref0(multiLineComment);

  Parser visibleWhitespace() => whitespace();

  Parser singleLineComment() =>
      string('#') &
      ref0(newlineLexicalToken).neg().star() &
      ref0(newlineLexicalToken).optional();

  Parser multiLineComment() =>
      string('/*') &
      (ref0(multiLineComment) | string('*/').neg()).star() &
      string('*/');
}
