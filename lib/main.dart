// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quizcraft/widgets/auth/auth.dart';
import 'package:quizcraft/firebase_options.dart';
import 'package:quizcraft/services/provider_model.dart';

// Main entry point for the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const MyApp()),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF78249d),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(
              color: Colors.black54,
            ), 
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ), 
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, 
          foregroundColor: Colors
              .black, 
          elevation: 0.5, 
          surfaceTintColor: Colors
              .transparent, 
          shadowColor: Colors
              .transparent, 
          centerTitle: true, 
          titleTextStyle: TextStyle(
            
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        cardTheme: CardThemeData(
          
          elevation: 0.5, 
          shape: RoundedRectangleBorder(
            
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 0,
          ), 
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              Colors.white,
            ), 
            backgroundColor: WidgetStatePropertyAll(
              Color(0xFF673AB7),
            ), 
          ),
        ),
        
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF78249d), 
          foregroundColor: Colors.white, 
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, 
          fillColor: const Color(
            0xFFF9F9F9,
          ), 
          contentPadding: const EdgeInsets.symmetric(
            
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ), 
          border: OutlineInputBorder(
            
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF78249d), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          floatingLabelBehavior:
              FloatingLabelBehavior.never, 
        ),
      ),
      
      home: const Auth(),
    );
  }
}
