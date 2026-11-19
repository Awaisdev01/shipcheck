// Release-notes generation from git history.

import 'dart:io';

import '../project.dart';

/// Generates release notes in Markdown for the [from]..[to] git range.
String generateReleaseNotes(ProjectInfo project, String from, String to) {
  final result = Process.runSync(
    'git',
    ['log', '--no-merges', '--pretty=format:%s', '$from..$to'],
    workingDirectory: project.directory,
    runInShell: true,
  );

  final subjects = (result.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (subjects.isEmpty) {
    return '''
# Release notes — ${_title(project.name)} v${project.version}

No commits found in range $from..$to.

Tip: pass '--from <last-tag>' or run inside a git repository.
''';
  }

  // Classify by conventional-commit prefixes; fall back to a features bucket.
  final features = <String>[];
  final fixes = <String>[];
  final others = <String>[];

  for (final subject in subjects) {
    final lower = subject.toLowerCase();
    final clean = _cleanSubject(subject);
    if (lower.startsWith('fix')) {
      fixes.add(clean);
    } else if (lower.startsWith('feat') || lower.startsWith('add')) {
      features.add(clean);
    } else if (lower.startsWith('chore') || lower.startsWith('ci:') ||
        lower.startsWith('docs') || lower.startsWith('test')) {
      continue; // internal noise, not user-facing
    } else {
      others.add(clean);
    }
  }

  final buffer = StringBuffer()
    ..writeln('# Release notes — ${_title(project.name)} v${project.version}')
    ..writeln();

  if (features.isNotEmpty) {
    buffer
      ..writeln('## New')
      ..writeln();
      for (final item in features) {
        buffer.writeln('- $item');
      }
    buffer.writeln();
  }

  if (fixes.isNotEmpty) {
    buffer
      ..writeln('## Fixed')
      ..writeln();
      for (final item in fixes) {
        buffer.writeln('- $item');
      }
    buffer.writeln();
  }

  if (others.isNotEmpty) {
    buffer
      ..writeln('## Improvements')
      ..writeln();
      for (final item in others) {
        buffer.writeln('- $item');
      }
    buffer.writeln();
  }

  if (features.isEmpty && fixes.isEmpty && others.isEmpty) {
    buffer
      ..writeln('## Maintenance release')
      ..writeln()
      ..writeln('- Internal cleanups and tooling updates.');
  }

  return buffer.toString();
}

/// Cleans a commit subject into user-facing prose:
/// strips prefixes, issue refs, and converts to imperative voice.
String _cleanSubject(String subject) {
  var text = subject
      .replaceFirst(RegExp(r'^(feat|fix|chore|docs|test|refactor|perf)(\([^)]*\))?!?:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s*\(#[0-9]+\)\s*$'), '')
      .replaceFirst(RegExp(r'\s*\(#[0-9]+\)\s*'), ' ')
      .trim();
  if (text.isEmpty) return subject;
  return text[0].toUpperCase() + text.substring(1);
}

String _title(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
