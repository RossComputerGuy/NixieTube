import 'package:petitparser/petitparser.dart';

import 'expression/assert.dart';
import 'expression/attrset.dart';
import 'expression/eval.dart';
import 'expression/function.dart';
import 'expression/inherit.dart';
import 'expression/letin.dart';
import 'expression/logical.dart';
import 'expression/math.dart';
import 'expression/merge.dart';
import 'expression/or.dart';
import 'expression/with.dart';
import 'expression.dart';

import 'identifier.dart';
import 'path.dart';

class NixParser extends GrammarDefinition {
  const NixParser({
    this.globalScope = const {},
    this.doEvalReduce = true,
  });

  final Map<Object, Object?> globalScope;
  final bool doEvalReduce;

  Parser token(Object input) {
    if (input is Parser) {
      return input.token().trim(ref0(hiddenStuffWhitespace));
    } else if (input is String) {
      return token(input.toParser()).labeled(input);
    }
    throw ArgumentError.value(input, 'Invalid token parser');
  }

  /* Tokens */

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
          .map((value) => value);

  // FIXME: handle ''${expr}
  Parser<List<List<dynamic>>> multiLineStringLexicalToken() =>
      (string("''").token() &
              (ref0(identifierExpressionLexicalToken) | any())
                  .token()
                  .starLazy(string("''")) &
              string("''").token())
          .map((value) => value[1].fold(<List<dynamic>>[], (prev, token) {
                var list = prev;

                final line = value[0].line;
                final reline = token.line - line;

                while (list.length < reline) {
                  list.add(<Object?>[]);
                }

                if (token.value is String) {
                  final newline = token.value.indexOf('\n');
                  if (newline == -1) {
                    final curr = list[reline - 1];
                    if (curr.isNotEmpty && curr[curr.length - 1] is String) {
                      curr[curr.length - 1] += token.value;
                    } else {
                      if (curr.length > 0 || token.value != ' ')
                        curr.add(token.value);
                    }
                  }
                } else {
                  list[reline - 1].add(token.value);
                }
                return list;
              }));

  Parser<List<dynamic>> singleLineStringLexicalToken() => (char('"') &
              (ref0(identifierExpressionLexicalToken) |
                      ref0(stringContentDoubleQuotedLexicalToken))
                  .star() &
              char('"') |
          (ref0(identifierExpressionLexicalToken) | pattern('^"\n\r')).star() &
              char('"'))
      .labeled('singleLineStringLexicalToken')
      .map((value) => (value.length == 3 ? value[1] : value[0])
              .fold(<Object?>[], (prev, item) {
            if (prev.isEmpty || item.runtimeType != prev.last.runtimeType) {
              prev.add(item);
            } else if (prev.last is String && item is String) {
              prev.last += item;
            }
            return prev;
          }));

  Parser stringContentDoubleQuotedLexicalToken() =>
      (pattern('^\\"\n\r') | char('\\') & pattern('\n\r'))
          .labeled('stringContentDoubleQuotedLexicalToken');

  Parser letterLexicalToken() => letter() | char('_');

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
              char('-') |
              string("'") |
              digit())
          .labeled('identifierPartLexicalToken');

  Parser identifierExpressionLexicalToken() =>
      (string('\${').token() & ref0(expression) & string('}').token())
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
      (ref1(token, '..').map((value) => value.value)) |
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

  Parser<dynamic> expression() =>
      ((ref0(withExpression) | ref0(assertExpression)).star() &
              ref0(innerExpression))
          .map((value) {
        final expr = NixExpression(
          value[1],
          withs: value[0]
              .whereType<NixWithExpression>()
              .map((value) => value.value)
              .toList(),
          asserts: value[0]
              .whereType<NixAssertExpression>()
              .map((value) => value.value)
              .toList(),
        );

        if (expr.isConstant(globalScope) && doEvalReduce) {
          return expr.constEval(globalScope);
        }

        return expr;
      });

  Parser parenExpression() =>
      (ref1(token, '(') & ref0(expression) & ref1(token, ')'))
          .map((value) => value[1]);

  Parser innerExpression() => (ref0(letInExpression) |
      ref0(ifElseExpression) |
      ref0(funcExpression) |
      ref0(listExpression) |
      ref0(attrSetExpression) |
      ref0(logicalExpression));

  Parser<NixLogicalExpression> logicalExpression() => (ref1(token, '!')
              .optional() &
          (ref0(parenExpression) |
              ref0(mergeListExpression) |
              ref0(mergeAttrExpression) |
              ref0(hasAttrExpression) |
              ref0(orExpression) |
              ref0(mathExpression) |
              ref0(literal) |
              ref0(evalExpression)))
      .map((value) => NixLogicalExpression(value[1],
          isNegative: value[0] is Token ? value[0].value == '!' : false));

  Parser evalExpression() =>
      (ref0(identifierList) & ref0(innerExpression).star())
          .labeled('evalExpression')
          .map((value) {
        final expr = NixEvalExpression(value[0], value[1]);

        if (expr.isConstant(globalScope) && doEvalReduce) {
          return expr.constEval(globalScope);
        }

        return expr;
      });

  Parser letInExpression() =>
      (ref0(letToken) & ref0(field).star() & ref0(inToken) & ref0(expression))
          .map((value) {
        final fields = value[1];
        final expr = NixLetInExpression(
          value[3],
          fields: Map.fromEntries(fields
              .whereType<MapEntry<Object, Object?>>()
              .cast<MapEntry<Object, Object?>>()
              .toList()),
          inherits: fields.whereType<NixInheritExpression>().toList(),
        );

        if (expr.isConstant(globalScope) && doEvalReduce) {
          return expr.constEval(globalScope);
        }
        return expr;
      });

  Parser field() =>
      ((ref0(inheritExpression) | ref0(normalField)) & ref1(token, ';'))
          .map((value) => value[0]);

  Parser<MapEntry<Object, Object?>> normalField() =>
      ((ref0(identifierList) | ref0(stringLexicalToken)) &
              ref1(token, '=') &
              ref0(expression))
          .map((value) => MapEntry(value[0], value[2]));

  Parser<NixInheritExpression> inheritExpression() => (ref0(inheritToken) &
          ref0(inheritFrom).optional() &
          ref0(identifier).plus())
      .labeled('inheritExpression')
      .map((value) => NixInheritExpression(value[2].cast<NixIdentifier>(),
          value[1] is List ? value[1][1] : null));

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

  Parser mathExpression() => (ref0(mathExpressionSide) &
              (ref0(mathOperator) & ref0(mathExpressionSide))
                  .map((value) => NixMathExpressionSide(value[0], value[1]))
                  .plus())
          .labeled('mathExpression')
          .map((value) {
        final expr = NixMathExpression(value[0], value[1]);
        if (expr.isConstant(globalScope) && doEvalReduce)
          return expr.constEval(globalScope);
        return expr;
      });

  Parser mathExpressionSide() =>
      ref0(parenExpression) |
      ref0(ifElseExpression) |
      ref0(hasAttrExpression) |
      ref0(orExpression) |
      ref0(literal) |
      ref0(identifierList) |
      ref0(evalExpression);

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

  Parser<NixOrExpression> orExpression() =>
      (ref0(identifierList) & ref0(orToken) & ref0(expression))
          .labeled('orExpression')
          .map((value) => NixOrExpression(value[0], value[2]));

  Parser<NixAssertExpression> assertExpression() =>
      (ref0(assetToken) & ref0(innerExpression) & ref1(token, ';'))
          .map((value) {
        final expr = NixAssertExpression(value[1]);
        if (expr.isConstant(globalScope) && doEvalReduce) {
          return expr.constEval(globalScope);
        }
        return expr;
      });

  Parser<NixWithExpression> withExpression() =>
      (ref0(withToken) & ref0(innerExpression) & ref1(token, ';'))
          .map((value) => NixWithExpression(value[1]));

  Parser funcExpression() => (ref0(funcArguments) & ref0(expression))
          .labeled('funcExpression')
          .map((value) {
        final expr = NixFunctionExpression(value[0].cast<Object>(), value[1]);
        if (expr.isConstant(globalScope) && doEvalReduce) {
          return expr.constEval(globalScope);
        }
        return expr;
      });

  Parser funcArguments() =>
      ref0(funcArgumentsElement).plus().labeled('funcArguments');

  Parser funcArgumentsElement() =>
      ((ref0(identifier) | ref0(funcArgumentsElementAttrSet)) &
              ref1(token, ':'))
          .labeled('funcArgumentsElement')
          .map((value) => value[0]);

  Parser funcArgumentsElementAttrSet() => ((ref1(token, '{') &
              ref0(funcArgumentsElementAttrSetFieldList).optional() &
              ref1(token, '}') &
              (ref1(token, '@') & ref0(identifier)).optional())
          .map((value) => NixFunctionArgumentExpression(
              value[1], value[3] != null ? value[1] : null)) |
      ((ref0(identifier) & ref1(token, '@')).optional() &
              ref1(token, '{') &
              ref0(funcArgumentsElementAttrSetFieldList).optional() &
              ref1(token, '}'))
          .map((value) => NixFunctionArgumentExpression(
              value[2], value[0] != null ? value[0][1] : null)));

  Parser<Map<Object, Object?>> funcArgumentsElementAttrSetFieldList() =>
      (ref0(funcArgumentsElementField) &
              (ref1(token, ',') &
                      ref0(funcArgumentsElementField)
                          .plusSeparated(ref1(token, ',')))
                  .map((value) => value[1].elements)
                  .optional())
          .map((value) => Map.fromEntries([value[0], ...value[1]]));

  Parser<MapEntry<Object, Object?>> funcArgumentsElementField() =>
      (ref0(identifier) & (ref1(token, '?') & ref0(expression)).optional()).map(
          (value) => MapEntry(value[0], value[1] != null ? value[1][1] : null));

  Parser mergeListExpression() => (ref0(mergeListExpressionSide) &
          (ref1(token, '++') & ref0(mergeListExpressionSide)).plus())
      .labeled('mergeListExpression')
      .map((value) => NixMergeExpression(NixMergeOperation.list,
          [value[0], ...value[1].map((value) => value[1])]));

  Parser mergeListExpressionSide() =>
      (ref0(listExpression) | ref0(identifierList) | ref0(parenExpression))
          .labeled('mergeListExpressionSide');

  Parser<List<Object?>> listExpression() =>
      (ref1(token, '[') & ref0(listElement).star() & ref1(token, ']'))
          .labeled('listExpression')
          .map((value) => value[1]);

  Parser listElement() => (ref0(listExpression) |
          ref0(attrSetExpression) |
          ref0(literal) |
          ref0(orExpression) |
          ref0(evalExpression) |
          ref0(identifierList) |
          ref0(parenExpression))
      .labeled('listElement');

  Parser mergeAttrExpression() => (ref0(mergeAttrExpressionSide) &
          (ref1(token, '//') & ref0(mergeAttrExpressionSide)).plus())
      .labeled('mergeAttrExpression')
      .map((value) => NixMergeExpression(NixMergeOperation.attrset,
          [value[0], ...value[1].map((value) => value[1])]));

  Parser mergeAttrExpressionSide() =>
      (ref0(attrSetExpression) | ref0(identifierList) | ref0(parenExpression))
          .labeled('mergeAttrExpressionSide');

  Parser attrSetExpression() => (ref0(recToken).optional() &
              ref1(token, '{') &
              ref0(field).star() &
              ref1(token, '}'))
          .labeled('attrSetExpression')
          .map((value) {
        final fields = value[2];
        return NixAttributeSetExpression(
          fields: Map.fromEntries(fields
              .whereType<MapEntry<Object, Object?>>()
              .cast<MapEntry<Object, Object?>>()
              .toList()),
          inherits: fields.whereType<NixInheritExpression>().toList(),
          isRec: value[0] is Token ? value[0].value == 'rec' : false,
        );
      });

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
