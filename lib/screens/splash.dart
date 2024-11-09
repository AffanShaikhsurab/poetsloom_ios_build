// splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
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
import 'package:test_app/services/contract.dart';
import 'package:test_app/services/mnemonic.dart';
import 'package:test_app/state/auth_state.dart';
import 'package:test_app/state/author_poems.dart';
import 'package:test_app/state/fav_state.dart';
import 'package:test_app/state/mnemonic_state.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/state/rewards.dart';
import 'package:test_app/state/user.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  String? contractAddress;
  late SupabaseClient supabaseClient;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        _initializeServices(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (mounted) {
        _navigateToApp();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize app: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Supabase
      await Supabase.initialize(
        url: 'https://tfxbcnluzthdrwhtrntb.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM',
      );

      supabaseClient = Supabase.instance.client;
      await _getContractInfo();

    } catch (e) {
      throw Exception('Initialization failed: ${e.toString()}');
    }
  }

  Future<void> _getContractInfo() async {
    try {
      final results = await supabaseClient
          .from("info")
          .select("*")
          .eq("type", "contract_address");
      
      contractAddress = results[0]["data"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("contract_address", contractAddress!);
    } catch (e) {
      throw Exception('Failed to get contract info: ${e.toString()}');
    }
  }

  void _navigateToApp() {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => PoetryCubit(
                poetsLoomService: PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                )
              )
            ),
            BlocProvider(
              create: (context) => PoetryCubit(
                poetsLoomService: PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                ),
              )..loadInitialPoems(0),
            ),
            BlocProvider(
              create: (_) => MnemonicCubit(
                MnemonicService(baseUrl: "https://poetsloom-mnemonic.onrender.com")
              )
            ),
            BlocProvider(
              create: (_) => AddPoemCubit(
                PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                )
              )
            ),
            BlocProvider(
              create: (_) => AuthCubit(AuthService(supabaseClient))
            ),
            BlocProvider(
              create: (_) => RewardsCubit(
                PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                )
              )
            ),
            BlocProvider(
              create: (_) => AuthorPoemsCubit(
                poetsLoomService: PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                )
              )
            ),
            BlocProvider(
              create: (_) => WithdrawCubit(
                PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                )
              )
            ),
            BlocProvider(
              create: (context) => FavoritePoemsCubit(
                poetsLoomService: PoetsLoomService(
                  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
                  contractAddress: contractAddress!,
                ),
                poetryCubit: context.read<PoetryCubit>(),
              ),
            ),
          ],
          child: auth.isAuthenticated ? HomeScreen() : OnboardingScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 0, 6, 20),
    body: FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Container with rounded image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 18, 19, 50).withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover, // Ensures image fills the space properly
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
           
           
       
          ],
        ),
      ),
    ),
  );
}
}
