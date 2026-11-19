import 'package:shipcheck/src/generators/listing.dart';
import 'package:shipcheck/src/project.dart';
import 'package:test/test.dart';

void main() {
  test('generates store listings within character limits', () {
    final project = ProjectInfo(
      kind: ProjectKind.flutter,
      name: 'my_cool_app',
      version: '1.0.0',
      description: 'Track your daily habits with streaks and insights.',
      directory: '/tmp/nonexistent',
    );

    final listing = generateListing(project);
    final appStore = listing.files.firstWhere((f) => f.relativePath == 'app_store.md').content;
    final play = listing.files.firstWhere((f) => f.relativePath == 'play_store.md').content;

    expect(appStore, contains('My Cool App'));
    expect(appStore, contains('Track'));
    expect(play, contains('Short description'));
    // Title within 30 chars
    final titleMatch = RegExp(r'```\n(My Cool App)\n```').firstMatch(appStore);
    expect(titleMatch, isNotNull);
  });

  test('tagline respects 30 char limit', () {
    final project = ProjectInfo(
      kind: ProjectKind.dart,
      name: 'tool',
      version: '0.1.0',
      description:
          'An extremely long description that goes on and on and definitely exceeds thirty characters.',
      directory: '/tmp/nonexistent',
    );
    final listing = generateListing(project);
    final appStore = listing.files.firstWhere((f) => f.relativePath == 'app_store.md').content;
    final tagline = RegExp(r'```\n(.+)\n```').firstMatch(appStore)!.group(1)!;
    expect(tagline.length, lessThanOrEqualTo(30));
  });
}
