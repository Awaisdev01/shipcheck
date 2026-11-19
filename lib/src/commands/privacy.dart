// `shipcheck privacy` — privacy policy + data-disclosure generation.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generators/privacy.dart';
import '../project.dart';
import '../utils/writer.dart';

Command<int> buildPrivacyCommand() => PrivacyCommand();

class PrivacyCommand extends Command<int> {
  PrivacyCommand() {
    argParser
      ..addOption(
        'contact',
        help: 'Contact email shown in the policy (e.g. dev@example.com).',
      )
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'PRIVACY.md',
        help: 'Output file for the policy.',
      )
      ..addOption(
        'disclosure',
        defaultsTo: 'data_disclosure.md',
        help: 'Output file for the store data-collection disclosure.',
      );
  }

  @override
  String get name => 'privacy';

  @override
  String get description =>
      'Generate a privacy policy and data-collection disclosure.';

  @override
  Future<int> run() async {
    final directory = Directory.current.path;
    final project = ProjectInfo.detect(directory);
    final contact = (argResults?['contact'] as String?) ?? 'you@example.com';

    final policy = generatePrivacyPolicy(project, contact);
    final disclosure = generateDisclosure(project);

    final policyPath = p.normalize(
      p.join(directory, argResults!['output'] as String),
    );
    writeTextFile(policyPath, policy);
    stdout.writeln('Wrote ${p.relative(policyPath, from: directory)}');

    final disclosurePath = p.normalize(
      p.join(directory, argResults!['disclosure'] as String),
    );
    writeTextFile(disclosurePath, disclosure);
    stdout.writeln('Wrote ${p.relative(disclosurePath, from: directory)}');

    stdout.writeln(
        'Note: generated policies are a starting point, not legal advice.');
    stdout.writeln(
        'Edit the data-handling statements and host the policy publicly.');
    return 0;
  }
}
