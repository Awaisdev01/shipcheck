// `shipcheck site` — one-page marketing site generator.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generators/site.dart';
import '../project.dart';
import '../utils/writer.dart';

Command<int> buildSiteCommand() => SiteCommand();

class SiteCommand extends Command<int> {
  SiteCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'site',
        help: 'Directory to write index.html into.',
      )
      ..addOption(
        'repo',
        help: 'Repository URL to link (e.g. https://github.com/you/app).',
      );
  }

  @override
  String get name => 'site';

  @override
  String get description =>
      'Generate a one-page marketing site for your project.';

  @override
  Future<int> run() async {
    final directory = Directory.current.path;
    final project = ProjectInfo.detect(directory);
    final repoUrl = argResults?['repo'] as String?;

    final html = generateSite(project, repoUrl: repoUrl);

    final outputPath = p.normalize(
      p.join(directory, argResults!['output'] as String),
    );
    final index = p.join(outputPath, 'index.html');
    writeTextFile(index, html);
    stdout.writeln('Wrote ${p.relative(index, from: directory)}');
    stdout.writeln('Open it directly in a browser, or host it on GitHub Pages.');
    return 0;
  }
}
