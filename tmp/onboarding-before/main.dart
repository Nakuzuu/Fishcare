import 'package:flutter/material.dart';

import 'master_repository.dart';
import 'product_app.dart';
import 'cycle_repository.dart';
import 'feed_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final master = SqliteMasterRepository();
  final cycles = SqliteCycleRepository(master);
  runApp(
    FishCareApp(
      repository: master,
      cycles: cycles,
      feeds: FeedRepository(master, cycles),
    ),
  );
}
