import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rrpkbeiwstpwsffjgazr.supabase.co',
    anonKey: 'sb_publishable_EEHNqP-E3USdy6qNsUxOGQ_swWA0aCc',
  );

  runApp(const App());
}