import 'package:flutter/material.dart';

import 'master_repository.dart';
import 'product_app.dart';
import 'cycle_repository.dart';
import 'feed_repository.dart';
import 'intro_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final master = SqliteMasterRepository();
  final cycles = SqliteCycleRepository(master);
  runApp(
    FishCareApp(
      introStore: const AndroidIntroStore(),
      repository: master,
      cycles: cycles,
      feeds: FeedRepository(master, cycles),
    ),
  );
}
