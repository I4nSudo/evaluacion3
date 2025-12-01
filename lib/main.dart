// main.dart

import 'package:flutter/material.dart';
import 'login_page.dart';

// Constantes globales
const String baseUrl = "http://localhost:8000";

void main() => runApp(const MyApp());

// ----------------------------------------------------
// 2. WIDGET PRINCIPAL Y TEMAS
// ----------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
Widget build(BuildContext context) {
 // Definición de colores y estilos para toda la app
 final primaryColor = const Color(0xFF0D47A1); // Azul oscuro
 final secondaryColor = const Color(0xFF1565C0); // Azul medio

 return MaterialApp(
 debugShowCheckedModeBanner: false,
 title: 'Paquexpress',
 theme: ThemeData(
 primaryColor: primaryColor,
 scaffoldBackgroundColor: const Color(0xFF607D8B), // Azul claro
 appBarTheme: AppBarTheme(
 backgroundColor: secondaryColor,
 foregroundColor: Colors.white,
),
 elevatedButtonTheme: ElevatedButtonThemeData(
 style: ElevatedButton.styleFrom(
 backgroundColor: primaryColor,
 foregroundColor: Colors.white,
 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
 textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 ),
 inputDecorationTheme: InputDecorationTheme(
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(10),
 borderSide: BorderSide(color: primaryColor),
 ),
 focusedBorder: OutlineInputBorder(
 borderRadius: BorderRadius.circular(10),
 borderSide: BorderSide(color: secondaryColor, width: 2),
 ),
 filled: true,
 fillColor: Colors.white,
 ),
 ),
 // La página de inicio es el Login
home: const LoginPage(),
 );
}
}
