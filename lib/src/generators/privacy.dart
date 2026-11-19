// Privacy policy and data-disclosure generation.

import 'dart:io';

import '../project.dart';

/// Scans the project's dependency manifests for network/ads/analytics
/// packages that typically indicate data collection.
class DependencyScan {
  final bool hasNetwork;
  final bool hasAds;
  final bool hasAnalytics;
  final List<String> notablePackages;

  DependencyScan({
    required this.hasNetwork,
    required this.hasAds,
    required this.hasAnalytics,
    required this.notablePackages,
  });

  static DependencyScan scan(ProjectInfo project) {
    final content = _manifestContent(project.directory);
    final lower = content.toLowerCase();

    bool any(List<String> needles) => needles.any(lower.contains);

    final network = any(['http', 'dio', 'socket', 'graphql', 'fetch', 'axios']);
    final ads = any(['admob', 'google_mobile_ads', 'adsense', 'unity_ads']);
    final analytics = any([
      'firebase_analytics',
      'analytics',
      'mixpanel',
      'amplitude',
      'sentry',
      'crashlytics',
    ]);

    final notable = <String>[];
    for (final match in RegExp(r'^\s{2}([a-z_0-9]+):', multiLine: true)
        .allMatches(content)) {
      final name = match.group(1)!;
      if (const {
        'http', 'dio', 'firebase_analytics', 'firebase_core', 'sentry',
        'google_mobile_ads', 'mixpanel', 'amplitude', 'socket', 'web_socket_channel',
      }.contains(name)) {
        notable.add(name);
      }
    }

    return DependencyScan(
      hasNetwork: network,
      hasAds: ads,
      hasAnalytics: analytics,
      notablePackages: notable,
    );
  }

  static String _manifestContent(String directory) {
    final buffer = StringBuffer();
    for (final name in const ['pubspec.yaml', 'package.json']) {
      final file = _file(directory, name);
      if (file != null) buffer.writeln(file);
    }
    return buffer.toString();
  }

  static String? _file(String directory, String name) {
    final file = File('$directory/$name');
    return file.existsSync() ? file.readAsStringSync() : null;
  }
}

/// Generates a complete privacy policy in Markdown.
String generatePrivacyPolicy(ProjectInfo project, String contact) {
  final scan = DependencyScan.scan(project);
  final appName = project.name.replaceAll(RegExp(r'[_\-]'), ' ');

  final collected = StringBuffer();
  if (scan.hasNetwork) {
    collected.writeln('- **Content you load over the network** — the app may '
        'fetch data you request. This data travels between your device and '
        'the service you use; the developer does not store it.');
  }
  if (scan.hasAnalytics) {
    collected.writeln('- **Usage analytics and crash reports** — the app may '
        'collect anonymized diagnostics to improve stability.');
  }
  if (scan.hasAds) {
    collected.writeln('- **Advertising identifiers** — the app may use ads '
        'SDKs that collect device identifiers to personalize ads.');
  }
  if (collected.isEmpty) {
    collected.writeln(
        '- **Nothing.** ${_title(appName)} does not collect, transmit, or store any personal data.');
  }

  final thirdParties = scan.notablePackages.isEmpty
      ? 'No third-party services receive data from ${_title(appName)}.'
      : 'Third-party SDKs currently linked: ${scan.notablePackages.join(', ')}. '
          'See each provider\'s own policy for how they process data.';

  return '''
# Privacy Policy for ${_title(appName)}

_Last updated: ${DateTime.now().toIso8601String().substring(0, 10)}_

## Overview

${_title(appName)} (${'"$contact"'}) is provided as open-source software.
This policy explains what data the app handles and what rights you have.

## Data the app may process

$collected

## Third parties

$thirdParties

## Data we do NOT collect

- We do not ask for your name, email, or contacts unless a feature you use
  explicitly requires it, and we tell you when it does.
- We do not sell or rent data to anyone.

## Your choices

- Uninstalling the app removes all app-local data from your device.
- To request deletion of any server-side data (if applicable), contact us
  at $contact.

## Changes

Updates to this policy will be posted in the app's repository with a new
"last updated" date.

## Contact

Questions: $contact
''';
}

/// Generates the App Store "App Privacy" / Play "Data safety" worksheet.
String generateDisclosure(ProjectInfo project) {
  final scan = DependencyScan.scan(project);
  final appName = project.name.replaceAll(RegExp(r'[_\-]'), ' ');

  final answers = StringBuffer();

  String answer(bool condition, String yes, String no) =>
      condition ? '→ $yes' : '→ $no';

  answers.writeln('### Does ${_title(appName)} collect data linked to you?');
  answers.writeln(answer(
    scan.hasAnalytics || scan.hasAds,
    'Yes — review the analytics/ads SDKs below and declare the specific '
        'identifiers they use.',
    'No data is collected or linked to your identity.',
  ));
  answers.writeln();
  answers.writeln('### Networking libraries detected');
  answers.writeln(scan.notablePackages.isEmpty
      ? '→ None — declare "no data collected" in the store questionnaire.'
      : '→ ${scan.notablePackages.join(', ')}');
  answers.writeln();
  answers.writeln('### Checklist before you submit');
  answers.writeln('- [ ] Every SDK listed above has a data-declaration entry');
  answers.writeln('- [ ] Privacy policy URL is live and reachable');
  answers.writeln('- [ ] Account-deletion path exists if the app has accounts');
  answers.writeln('- [ ] The answers here match what the app truly does');

  return '''
# Data-collection disclosure worksheet — ${_title(appName)}

Use these answers when filling the **App Privacy (App Store)** and
**Data Safety (Play Console)** forms. They are derived from a dependency
scan — verify each one against your actual runtime behavior.

$answers
''';
}

String _title(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
