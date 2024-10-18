# Nixie Tube Parser

Subpackage of Nixie Tube itself responsible for parsing the Nix language. This implements the Nix 2.18 syntax using petitparser.

## Features

- Reduces expressions by evaluating expressions with fully satisfied inputs
- **TODO** Reproducible objects for caching
- **TODO** Prediction of work expressions take

## Getting Started

You can try out the parser by using `dart run nixietube_parser_example.dart` or `dart compile exe example/nixietube_parser_example.dart`
for better performance. However, this does not contain the full Nixie Tube evaluator.

## Usage

Utilizing this parser is simple, only requires `import "package:nixietube_parser/nixietube_parser.dart";`
and using `NixParser().build()` to get a fully constructed parser.

```dart
print((const NixParser()).build().parse('1 + 1').value);
// Prints "2"
```

## Additional information

- [petitparser](https://github.com/petitparser/dart-petitparser)
- [Nix 2.18 language manual](https://nix.dev/manual/nix/2.18/language)
