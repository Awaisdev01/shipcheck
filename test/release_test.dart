import 'dart:io';

import 'package:shipcheck/src/generators/release.dart';
import 'package:shipcheck/src/project.dart';
import 'package:test/test.dart';

void main() {
  test('generates release notes from real git history', () {
    final temp = Directory.systemTemp.createTempSync('shipcheck_git');
    addTearDown(() => temp.deleteSync(recursive: true));
    _run(temp, ['git', 'init']);
    _run(temp, ['git', 'config', 'user.email', 't@t.com']);
    _run(temp, ['git', 'config', 'user.name', 't']);
    File('${temp.path}/a.txt').writeAsStringSync('1');
    _run(temp, ['git', 'add', '.']);
    _run(temp, ['git', 'commit', '-m', 'feat: add habit streaks']);
    File('${temp.path}/a.txt').writeAsStringSync('2');
    _run(temp, ['git', 'add', '.']);
    _run(temp, ['git', 'commit', '-m', 'fix: correct timezone drift']);

    final project = ProjectInfo(
      kind: ProjectKind.dart,
      name: 'demo',
      version: '1.0.0',
      description: 'd',
      directory: temp.path,
    );
    final notes = generateReleaseNotes(project, 'HEAD~1', 'HEAD');
    expect(notes, contains('Fixed'));
    expect(notes.toLowerCase(), contains('timezone drift'));
  });
}

void _run(Directory dir, List<String> args) {
  final result = Process.runSync(args.first, args.sublist(1),
      workingDirectory: dir.path, runInShell: true);
  if (result.exitCode != 0) {
    throw StateError('git failed: ${result.stderr}');
  }
}
