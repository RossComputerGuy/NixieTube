import 'dart:io';
import 'package:nixietube_parser/nixietube_parser.dart';

void main(List<String> args) {
  final parser = (const NixParser()).build();

  if (args.isEmpty) {
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      print(parser.parse(line!));
    }
  } else {
    final file = File(args[0]).readAsStringSync();
    print(parser.parse(file));
  }
}
