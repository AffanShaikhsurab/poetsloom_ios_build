// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/authservice.dart';
import 'package:test_app/firebase_options.dart';
import 'package:test_app/home.dart';
import 'package:test_app/login_screen.dart';
import 'package:test_app/onboarding/onboarding.dart';
import 'package:test_app/screens/explore_screen.dart';
import 'package:test_app/screens/mnemonic_scrren.dart';
import 'package:test_app/screens/splash.dart';
import 'package:test_app/services/contract.dart';
import 'package:test_app/services/mnemonic.dart';
import 'package:test_app/state/auth_state.dart';
import 'package:test_app/state/author_poems.dart';
import 'package:test_app/state/fav_state.dart';
import 'package:test_app/state/mnemonic_state.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/state/rewards.dart';
import 'package:test_app/state/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(
        SupabaseClient(
          'https://tfxbcnluzthdrwhtrntb.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM'
        )
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoetsLoom',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Lora',
      ),
      home: SplashScreen(), // Start with splash screen
    );
  }
}