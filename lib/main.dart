// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/authservice.dart';
import 'package:test_app/firebase_options.dart';
import 'package:test_app/home.dart';
import 'package:test_app/login_screen.dart';
import 'package:test_app/screens/mnemonic_scrren.dart';
import 'package:test_app/services/contract.dart';
import 'package:test_app/services/mnemonic.dart';
import 'package:test_app/state/auth_state.dart';
import 'package:test_app/state/author_poems.dart';
import 'package:test_app/state/mnemonic_state.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/state/rewards.dart';
import 'package:test_app/state/user.dart';


void main() async{
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   await Supabase.initialize(
    url: 'https://tfxbcnluzthdrwhtrntb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM',
  );
  final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');

  runApp(
    
    ChangeNotifierProvider(
      create: (_) => AuthService(
      supabaseClient
      ),
      child:
      MultiBlocProvider(providers: [

      BlocProvider(create: (_) => PoetryCubit(poetsLoomService: PoetsLoomService(
        rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      ))),


      
      BlocProvider(create: (_) => MnemonicCubit(
        MnemonicService( baseUrl: "https://poetsloom-mnemonic.onrender.com")
      )),


      BlocProvider(create: (_) => AddPoemCubit( PoetsLoomService(
               rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      ))),
       BlocProvider(create: (_) => AuthCubit(
        AuthService(supabaseClient)
       )),
        BlocProvider(create: (_) => RewardsCubit( PoetsLoomService(
               rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      ))),
 BlocProvider(create: (_) => AuthorPoemsCubit( poetsLoomService: PoetsLoomService(
               rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      )))
      ,
       BlocProvider(create: (_) => WithdrawCubit( PoetsLoomService(
               rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/bTJkxdz694BiZKrP7qINHw7NQUrpnd75',
        contractAddress: '0xF0F5234959166Cc8D2Ee9F4C4e029cdbdac93266',
        privateKey: "dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070"

      )))

      ],

      child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poetry DApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        fontFamily: 'Lora',
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? HomeScreen() : PrivateKeyInputScreen();
        },
      ),
    );
  }
}

