// Shared types: project detection and the audit/report models.

import 'dart:io';

import 'package:path/path.dart' as p;

/// The kind of project detected in a directory.
enum ProjectKind {
  flutter,
  dart,
  node,
  ios,
  android,
  unknown;

  /// Human label used in generated copy.
  String get label => switch (this) {
        ProjectKind.flutter => 'Flutter',
        ProjectKind.dart => 'Dart',
        ProjectKind.node => 'Node.js',
        ProjectKind.ios => 'iOS',
        ProjectKind.android => 'Android',
        ProjectKind.unknown => 'unknown',
      };
}

/// A detected project: kind, name, version, and assorted metadata.
class ProjectInfo {
  final ProjectKind kind;
  final String name;
  final String version;
  final String description;
  final String directory;

  ProjectInfo({
    required this.kind,
    required this.name,
    required this.version,
    required this.description,
    required this.directory,
  });

  /// Detects the project in [directory].
  static ProjectInfo detect(String directory) {
    final kind = detectKind(directory);
    var name = p.basename(directory);
    var version = '0.0.0';
    var description = '';

    final pubspec = File(p.join(directory, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      name = _yamlScalar(content, 'name') ?? name;
      version = _yamlScalar(content, 'version') ?? version;
      description = _yamlScalar(content, 'description') ?? description;
    }

    final packageJson = File(p.join(directory, 'package.json'));
    if (packageJson.existsSync()) {
      final content = packageJson.readAsStringSync();
      name = _jsonScalar(content, '"name"') ?? name;
      version = _jsonScalar(content, '"version"') ?? version;
      description = _jsonScalar(content, '"description"') ?? description;
    }

    return ProjectInfo(
      kind: kind,
      name: name,
      version: version,
      description: description,
      directory: directory,
    );
  }

  static ProjectKind detectKind(String directory) {
    final hasPubspec = File(p.join(directory, 'pubspec.yaml')).existsSync();
    if (hasPubspec) {
      final content = File(p.join(directory, 'pubspec.yaml')).readAsStringSync();
      if (content.contains('sdk: flutter') || content.contains('flutter:')) {
        return ProjectKind.flutter;
      }
      return ProjectKind.dart;
    }
    if (File(p.join(directory, 'package.json')).existsSync()) {
      return ProjectKind.node;
    }
    if (File(p.join(directory, 'Runner.xcodeproj')).existsSync() ||
        Directory(p.join(directory, 'ios')).existsSync()) {
      return ProjectKind.ios;
    }
    if (Directory(p.join(directory, 'android')).existsSync()) {
      return ProjectKind.android;
    }
    return ProjectKind.unknown;
  }

  static String? _yamlScalar(String content, String key) {
    final match = RegExp('^$key:\\s*["\']?([^#\\n]*?)["\']?\\s*(#.*)?\$',
            multiLine: true)
        .firstMatch(content);
    return match?.group(1)?.trim();
  }

  static String? _jsonScalar(String content, String quotedKey) {
    final match =
        RegExp('$quotedKey\\s*:\\s*"([^"]*)"').firstMatch(content);
    return match?.group(1);
  }
}

/// A single audit check result.
class AuditCheck {
  final String id;
  final String title;
  final bool passed;
  final int weight;
  final String detail;

  AuditCheck({
    required this.id,
    required this.title,
    required this.passed,
    required this.weight,
    required this.detail,
  });

  /// Markdown bullet for reports.
  String get markdown {
    final icon = passed ? '✅' : '❌';
    return '- $icon **$title** — $detail';
  }
}

/// The result of a full audit: checks plus score and grade.
class AuditReport {
  final ProjectInfo project;
  final List<AuditCheck> checks;

  AuditReport({required this.project, required this.checks});

  int get maxScore =>
      checks.fold(0, (total, check) => total + check.weight);

  int get score =>
      checks.fold(0, (total, check) => total + (check.passed ? check.weight : 0));

  String get grade {
    final percent = maxScore == 0 ? 0 : (score * 100 ~/ maxScore);
    if (percent >= 90) return 'A';
    if (percent >= 75) return 'B';
    if (percent >= 60) return 'C';
    if (percent >= 40) return 'D';
    return 'F';
  }

  String get percentLabel =>
      maxScore == 0 ? '0' : (score * 100 ~/ maxScore).toString();

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Launch-readiness report — ${project.name} v${project.version}')
      ..writeln()
      ..writeln('**Score: $score/$maxScore ($percentLabel%) — Grade: $grade**')
      ..writeln()
      ..writeln('## Checks')
      ..writeln();
    for (final check in checks) {
      buffer.writeln(check.markdown);
    }
    return buffer.toString();
  }
}

/// A generated artifact with a target path and content.
class GeneratedFile {
  final String relativePath;
  final String content;

  GeneratedFile(this.relativePath, this.content);
}
