import 'package:args/args.dart';
// `shipcheck audit` — launch-readiness scorecard.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../project.dart';
import '../utils/writer.dart';

Command<int> buildAuditCommand() => AuditCommand();

class AuditCommand extends Command<int> {
  @override
  String get name => 'audit';

  @override
  String get description =>
      'Score a project\'s launch-readiness (0-100 with A-F grade).';

  @override
  final argParser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Write the report as Markdown to this path instead of stdout.',
    );

  @override
  @override
  Future<int> run() async {
    final directory = Directory.current.path;
    final project = ProjectInfo.detect(directory);
    final report = auditProject(project);

    final outputPath = argResults?['output'] as String?;
    if (outputPath != null) {
      final path = p.normalize(p.join(directory, outputPath));
      writeTextFile(path, report.toMarkdown());
      stdout.writeln('Report written to ${p.relative(path, from: directory)}');
    } else {
      stdout.writeln(report.toMarkdown());
    }
    return 0;
  }
}

/// Runs every launch-readiness check against [project].
AuditReport auditProject(ProjectInfo project) {
  final directory = project.directory;
  final checks = <AuditCheck>[];

  void add(String id, String title, bool passed, int weight, String detail) {
    checks.add(
      AuditCheck(id: id, title: title, passed: passed, weight: weight, detail: detail),
    );
  }

  // 1. Metadata completeness
  add(
    'description',
    'Project description exists',
    project.description.trim().isNotEmpty,
    10,
    project.description.trim().isEmpty
        ? 'No description found — store listings need one.'
        : 'Found: "${_truncate(project.description, 60)}"',
  );

  // 2. Version is beyond the default
  add(
    'version',
    'Version is set beyond 0.0.0',
    project.version != '0.0.0',
    10,
    'Detected version ${project.version}',
  );

  // 3. README
  final readmeExists = _existsAny(directory, const ['README.md', 'readme.md']);
  add(
    'readme',
    'README present',
    readmeExists,
    15,
    readmeExists ? 'README.md found' : 'Add a README — it feeds your site and listing.',
  );

  // 4. LICENSE
  final licenseExists = _existsAny(
    directory,
    const ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'license'],
  );
  add(
    'license',
    'LICENSE present',
    licenseExists,
    10,
    licenseExists ? 'License file found' : 'App stores and registries require a license.',
  );

  // 5. Tests exist
  final hasTests = Directory(p.join(directory, 'test')).existsSync() ||
      Directory(p.join(directory, '__tests__')).existsSync();
  add(
    'tests',
    'Test directory present',
    hasTests,
    15,
    hasTests ? 'Tests found' : 'Add tests before launch — crashes after launch hurt ratings.',
  );

  // 6. CI configuration
  final hasCi = _existsAny(directory, const [
    '.github/workflows',
    '.gitlab-ci.yml',
    'bitbucket-pipelines.yml',
  ]) ||
      Directory(p.join(directory, '.github', 'workflows')).existsSync();
  add(
    'ci',
    'CI pipeline configured',
    hasCi,
    10,
    hasCi ? 'CI configuration found' : 'Continuous integration catches launch-blocking regressions.',
  );

  // 7. Changelog
  final hasChangelog =
      _existsAny(directory, const ['CHANGELOG.md', 'changelog.md']);
  add(
    'changelog',
    'Changelog present',
    hasChangelog,
    5,
    hasChangelog ? 'Changelog found' : 'Run `shipcheck release` to generate one from git history.',
  );

  // 8. Privacy policy (only for app-ish projects)
  final needsPrivacy = project.kind == ProjectKind.flutter ||
      project.kind == ProjectKind.ios ||
      project.kind == ProjectKind.android;
  if (needsPrivacy) {
    final hasPrivacy = _existsAny(directory, const [
      'PRIVACY.md',
      'privacy.md',
      'privacy_policy.md',
    ]);
    add(
      'privacy',
      'Privacy policy present',
      hasPrivacy,
      15,
      hasPrivacy
          ? 'Privacy policy found'
          : 'Both stores require a privacy policy URL — run `shipcheck privacy`.',
    );
  }

  // 9. Icons present (app projects)
  if (needsPrivacy) {
    final hasIcons = _existsAny(directory, const [
      'assets/app_icon.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ]);
    add(
      'icons',
      'App icons present',
      hasIcons,
      5,
      hasIcons ? 'Icon assets found' : 'Add app icons — stores reject placeholder icons.',
    );
  }

  // 10. Screenshots present
  final hasScreenshots = _anyFileIn(
    directory,
    const ['screenshot', 'screenshots', 'images', 'assets/screenshots'],
  );
  add(
    'screenshots',
    'Screenshots present',
    hasScreenshots,
    10,
    hasScreenshots
        ? 'Screenshot assets found'
        : 'Store listings without screenshots convert poorly.',
  );

  return AuditReport(project: project, checks: checks);
}

bool _existsAny(String directory, List<String> names) => names.any((name) {
      final entityPath = p.join(directory, name);
      return FileSystemEntity.typeSync(entityPath) != FileSystemEntityType.notFound;
    });

bool _anyFileIn(String directory, List<String> dirs) {
  for (final dirName in dirs) {
    final dir = Directory(p.join(directory, dirName));
    if (dir.existsSync()) {
      final hasFiles = dir
          .listSync()
          .whereType<File>()
          .where((file) => p.extension(file.path).toLowerCase() == '.png')
          .isNotEmpty;
      if (hasFiles) return true;
    }
  }
  return false;
}

String _truncate(String text, int length) =>
    text.length <= length ? text : '${text.substring(0, length)}…';
