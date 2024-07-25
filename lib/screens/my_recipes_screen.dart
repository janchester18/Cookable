import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html; // Import for web support
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' as io;

import 'add_recipe_screen.dart';
import 'my_recipe_detail_screen.dart'; // Import RecipeDetailScreen

class MyRecipesScreen extends StatefulWidget {
  @override
  _MyRecipesScreenState createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    List<Map<String, dynamic>> recipes = await _readJsonFile();
    setState(() {
      _recipes = recipes;
    });
  }

  Future<List<Map<String, dynamic>>> _readJsonFile() async {
    if (kIsWeb) {
      final jsonString = html.window.localStorage['recipes'];
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((item) => item as Map<String, dynamic>).toList();
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/recipes.json');
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((item) => item as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  Future<void> _writeJsonFile(List<Map<String, dynamic>> recipes) async {
    if (kIsWeb) {
      final jsonString = jsonEncode(recipes);
      html.window.localStorage['recipes'] = jsonString;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/recipes.json');
      final jsonString = jsonEncode(recipes);
      await file.writeAsString(jsonString);
    }
  }

  Widget _buildRecipeThumbnail(Map<String, dynamic> recipe) {
    final imageData = recipe['imageData'] as String?;
    final imagePath = recipe['imagePath'] as String?;

    if (kIsWeb && imageData != null) {
      // Decode base64 image data for web
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && imagePath != null) {
      // Load image from file path for mobile
      return Image.file(
        io.File(imagePath),
        fit: BoxFit.cover,
      );
    } else {
      // Placeholder image
      return Icon(
        Icons.image,
        size: 100,
        color: Colors.grey[300],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _recipes.isEmpty
          ? Center(
              child: Text(
                'No recipes yet!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: SizedBox(
                    width: 70,
                    height: 70,
                    child: _buildRecipeThumbnail(recipe),
                  ),
                  title: Text(recipe['strMeal'] ?? 'Unnamed Dish'),
                  subtitle: Text(recipe['strCategory'] ?? 'No Category'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyRecipeDetailScreen(
                          recipe: recipe,
                          onDelete: (deletedRecipe) async {
                            List<Map<String, dynamic>> recipes =
                                await _readJsonFile();
                            setState(() {
                              recipes.removeWhere((r) =>
                                  r['strMeal'] == deletedRecipe['strMeal']);
                              _recipes = recipes;
                            });
                            await _writeJsonFile(recipes);
                            Navigator.pop(context,
                                true); // Pass a result to indicate deletion
                          },
                        ),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        _loadRecipes(); // Reload recipes if any were deleted
                      });
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newRecipe = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipeScreen()),
          );

          if (newRecipe != null) {
            setState(() {
              _recipes.add(newRecipe as Map<String, dynamic>);
            });
            await _writeJsonFile(_recipes); // Ensure the new recipe is saved
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.amber, // Set the button color to amber
      ),
    );
  }
}
