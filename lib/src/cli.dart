// CLI entry point: wires up the command registry.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'commands/audit.dart';
import 'commands/listing.dart';
import 'commands/privacy.dart';
import 'commands/release.dart';
import 'commands/site.dart';

const version = '0.1.0';

/// Runs shipcheck with the given arguments. Exposed for tests.
Future<int> run(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'shipcheck',
    'The last mile of shipping apps.',
  )
    ..addCommand(buildAuditCommand())
    ..addCommand(buildListingCommand())
    ..addCommand(buildPrivacyCommand())
    ..addCommand(buildReleaseCommand())
    ..addCommand(buildSiteCommand())
    ..argParser.addFlag(
      'version',
      negatable: false,
      help: 'Show the shipcheck version.',
    );

  if (arguments.contains('--version')) {
    // ignore: avoid_print
    print('shipcheck $version');
    return 0;
  }

  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr(error.message);
    return 64;
  }
}

void stderr(String message) {
  // ignore: avoid_print
  print('Error: $message');
}

// Keep ArgParser imported for tooling consistency.
// ignore: unused_element
final ArgParser _unused = ArgParser();
