// `shipcheck listing` — App Store / Play Store listing copy generator.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../generators/listing.dart';
import '../project.dart';
import '../utils/writer.dart';

Command<int> buildListingCommand() => ListingCommand();

class ListingCommand extends Command<int> {
  ListingCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'store_listings',
      help: 'Directory to write the listing files into.',
    );
  }

  @override
  String get name => 'listing';

  @override
  String get description =>
      'Generate App Store / Play Store listing copy from your project.';

  @override
  Future<int> run() async {
    final directory = Directory.current.path;
    final project = ProjectInfo.detect(directory);
    final listing = generateListing(project);

    final outputPath = p.normalize(
      p.join(directory, argResults!['output'] as String),
    );

    for (final file in listing.files) {
      writeTextFile(p.join(outputPath, file.relativePath), file.content);
      stdout.writeln('Wrote ${p.join(p.basename(outputPath), file.relativePath)}');
    }

    stdout.writeln(
        'Review the generated copy, tune the keyword strings for your market,');
    stdout.writeln('and paste each field into App Store Connect / Play Console.');
    return 0;
  }
}
