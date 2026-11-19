// One-page marketing site generation.

import 'dart:io';

import '../project.dart';

/// Generates a self-contained index.html with inline CSS.
String generateSite(ProjectInfo project, {String? repoUrl}) {
  final appName = _title(project.name.replaceAll(RegExp(r'[_\-]'), ' '));
  final tagline = project.description.trim().isEmpty
      ? 'A ${project.kind.label} app'
      : project.description.trim();
  final bullets = _readmeBullets(project.directory);
  final repoLink = repoUrl == null
      ? ''
      : '<a class="btn secondary" href="$repoUrl">Source code</a>';

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$appName — $tagline</title>
<meta name="description" content="$tagline">
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.6;
    background: #0f1115;
    color: #e8eaf0;
  }
  .hero { max-width: 720px; margin: 0 auto; padding: 96px 24px 48px; text-align: center; }
  .hero h1 { font-size: 44px; margin: 0 0 8px; letter-spacing: -0.5px; }
  .hero .tagline { font-size: 20px; color: #9aa1ad; margin: 0 0 32px; }
  .btn {
    display: inline-block; padding: 12px 24px; border-radius: 12px;
    background: #4c8dff; color: #fff; text-decoration: none; font-weight: 600;
    margin: 0 6px;
  }
  .btn.secondary { background: #232733; color: #e8eaf0; }
  .features { max-width: 720px; margin: 0 auto; padding: 24px 24px 96px; }
  .features ul { list-style: none; padding: 0; display: grid; gap: 12px; }
  .features li {
    background: #171a21; border: 1px solid #262b36; border-radius: 12px;
    padding: 14px 18px;
  }
  footer { text-align: center; color: #6b7280; font-size: 13px; padding-bottom: 48px; }
  footer a { color: #9aa1ad; }
</style>
</head>
<body>
<section class="hero">
  <h1>$appName</h1>
  <p class="tagline">$tagline</p>
  <a class="btn" href="${repoUrl ?? '#'}">Get it</a>
  $repoLink
</section>
<section class="features">
  <ul>
$bullets
  </ul>
</section>
<footer>
  Built with ${project.kind.label} · v${project.version} · ${DateTime.now().year}
</footer>
</body>
</html>
''';
}

/// Reads README bullets and renders them as site feature cards.
String _readmeBullets(String directory) {
  String readme = '';
  for (final name in const ['README.md', 'readme.md']) {
    final file = File('$directory/$name');
    if (file.existsSync()) {
      readme = file.readAsStringSync();
      break;
    }
  }
  final items = <String>[];
  for (final line in readme.split('\n')) {
    final match = RegExp(r'^\s*[-*]\s+(.+)$').firstMatch(line);
    if (match != null) {
      final text = match.group(1)!
          .trim()
          .replaceAll(RegExp(r'[*`]'), '')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      if (text.length > 8 && text.length < 90) {
        items.add('    <li>$text</li>');
      }
    }
    if (items.length >= 5) break;
  }
  if (items.isEmpty) {
    items.add('    <li>Simple, focused, and open source.</li>');
  }
  return items.join('\n');
}

String _title(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
