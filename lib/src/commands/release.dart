// `shipcheck release` — release notes from git history.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generators/release.dart';
import '../project.dart';
import '../utils/writer.dart';

Command<int> buildReleaseCommand() => ReleaseCommand();

class ReleaseCommand extends Command<int> {
  ReleaseCommand() {
    argParser
      ..addOption(
        'from',
        help: 'Start ref (tag or sha). Defaults to the latest tag, or HEAD~20.',
      )
      ..addOption(
        'to',
        defaultsTo: 'HEAD',
        help: 'End ref for the changelog range.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'RELEASE_NOTES.md',
        help: 'Output file for the release notes.',
      );
  }

  @override
  String get name => 'release';

  @override
  String get description => 'Generate release notes from git history.';

  @override
  Future<int> run() async {
    final directory = Directory.current.path;
    final project = ProjectInfo.detect(directory);

    final from = (argResults?['from'] as String?) ??
        _latestTag(directory) ??
        'HEAD~20';
    final to = argResults!['to'] as String;
    final notes = generateReleaseNotes(project, from, to);

    final outputPath = p.normalize(
      p.join(directory, argResults!['output'] as String),
    );
    writeTextFile(outputPath, notes);
    stdout.writeln('Wrote ${p.relative(outputPath, from: directory)}');
    return 0;
  }

  String? _latestTag(String directory) {
    final result = Process.runSync(
      'git',
      const ['describe', '--tags', '--abbrev=0'],
      workingDirectory: directory,
      runInShell: true,
    );
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }
}
