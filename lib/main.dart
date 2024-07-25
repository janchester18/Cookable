import 'package:flutter/material.dart';
import 'recipe_app.dart'; // Import your RecipeApp
import 'screens/my_recipes_screen.dart'; // Import MyRecipesScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RecipeApp(), // Set RecipeApp as the home widget
      routes: {
        '/my_recipes_screen': (context) => MyRecipesScreen(),
        // Define other routes here as needed
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
