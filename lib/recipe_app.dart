import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // Ensure this import is correct
import 'screens/my_recipes_screen.dart'; // Ensure this import is correct

class RecipeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(), // The initial screen
      routes: {
        '/main_screen': (context) => MainScreen(),
        // Define other routes here if needed
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
            builder: (context) => Scaffold(
                  body: Center(child: Text('Page not found')),
                ));
      },
    );
  }
}
