import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shipcheck/src/project.dart';
import 'package:shipcheck/src/commands/audit.dart' show auditProject;
import 'package:shipcheck/src/generators/privacy.dart' show DependencyScan;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('shipcheck_test');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  test('detects a Flutter project and audits it', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo_app
description: A demo app for testing.
version: 1.2.0
environment:
  sdk: ^3.4.0
dependencies:
  flutter:
    sdk: flutter
''');
    Directory(p.join(temp.path, 'test')).createSync();
    File(p.join(temp.path, 'LICENSE')).writeAsStringSync('MIT');
    File(p.join(temp.path, 'README.md')).writeAsStringSync('# Demo\n');
    Directory(p.join(temp.path, '.github', 'workflows')).createSync(recursive: true);
    File(p.join(temp.path, '.github', 'workflows', 'ci.yml')).writeAsStringSync('on: push');
    File(p.join(temp.path, 'PRIVACY.md')).writeAsStringSync('# Privacy');
    final screenshots = Directory(p.join(temp.path, 'screenshots'))..createSync();
    File(p.join(screenshots.path, 'shot.png')).writeAsBytesSync(<int>[1, 2, 3]);

    final project = ProjectInfo.detect(temp.path);
    expect(project.kind, ProjectKind.flutter);
    expect(project.name, 'demo_app');
    expect(project.version, '1.2.0');

    final report = auditProject(project);
    expect(report.grade, 'A');
    expect(report.score, greaterThan(80));
  });

  test('flags a bare project with a low grade', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: bare
version: 0.0.0
''');
    final project = ProjectInfo.detect(temp.path);
    final report = auditProject(project);
    expect(report.grade, anyOf('D', 'F'));
    expect(report.checks, isNotEmpty);
  });

  test('privacy policy generation from dependency scan', () {
    File(p.join(temp.path, 'pubspec.yaml')).writeAsStringSync('''
name: tracker_app
description: An app with analytics.
version: 0.1.0
dependencies:
  http: ^1.0.0
  firebase_analytics: ^11.0.0
''');
    final project = ProjectInfo.detect(temp.path);
    final scan = DependencyScan.scan(project);
    expect(scan.hasNetwork, isTrue);
    expect(scan.hasAnalytics, isTrue);
    expect(scan.notablePackages, containsAll(['http', 'firebase_analytics']));
  });
}
