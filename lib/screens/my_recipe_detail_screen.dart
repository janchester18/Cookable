import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'ingredients_checklist.dart'; // Import the IngredientsChecklistScreen
import 'package:path_provider/path_provider.dart'; // For mobile file access
import 'package:universal_html/html.dart' as html;

class MyRecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final Function(Map<String, dynamic>)?
      onDelete; // Optional callback for delete action

  const MyRecipeDetailScreen({
    Key? key,
    required this.recipe,
    this.onDelete, // Optional callback
  }) : super(key: key);

  @override
  _MyRecipeDetailScreenState createState() => _MyRecipeDetailScreenState();
}

class _MyRecipeDetailScreenState extends State<MyRecipeDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<List<Map<String, dynamic>>> _readJsonFile() async {
    try {
      if (kIsWeb) {
        // Web: Use local storage or some other method for web
        final jsonString = html.window.localStorage['recipes'];
        if (jsonString != null) {
          final dynamic jsonList = jsonDecode(jsonString);
          // Check if the JSON list is indeed a List
          if (jsonList is List) {
            return jsonList
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else {
            print('Unexpected JSON format: $jsonList');
          }
        }
      } else {
        // Mobile: Read from file system
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/recipes.json');
        if (file.existsSync()) {
          final jsonString = await file.readAsString();
          final dynamic jsonList = jsonDecode(jsonString);
          // Check if the JSON list is indeed a List
          if (jsonList is List) {
            return jsonList
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else {
            print('Unexpected JSON format: $jsonList');
          }
        }
      }
    } catch (e) {
      print('Error reading JSON file: $e');
    }
    return [];
  }

  Future<void> _writeJsonFile(List<Map<String, dynamic>> recipes) async {
    try {
      if (kIsWeb) {
        // Web: Save to local storage
        final jsonString = jsonEncode(recipes);
        html.window.localStorage['recipes'] = jsonString;
      } else {
        // Mobile: Write to file system
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/recipes.json');
        final jsonString = jsonEncode(recipes);
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print('Error writing JSON file: $e');
    }
  }

  void _deleteRecipe() async {
    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recipe'),
        content: Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog

              // Read the JSON file
              List<Map<String, dynamic>> recipes = await _readJsonFile();

              // Remove the recipe
              recipes.removeWhere((recipe) =>
                  recipe['strMeal'] ==
                  widget.recipe['strMeal']); // Adjust key if needed

              // Write the updated list back to the JSON file
              await _writeJsonFile(recipes);

              // Call the onDelete callback if provided
              if (widget.onDelete != null) {
                widget.onDelete!(widget.recipe);
              }

              // Do not navigate back automatically; just close the dialog
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe['strMeal'] ?? 'Recipe Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteRecipe, // Trigger delete action
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealImage(),
            SizedBox(height: 20),
            Text(
              'Category: ${widget.recipe['strCategory'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Area: ${widget.recipe['strArea'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildIngredientsList(),
            ),
            SizedBox(height: 20),
            Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '${widget.recipe['strInstructions'] ?? 'No instructions available'}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientsChecklistScreen(
                ingredients: _buildIngredientsMap(),
                instructions: widget.recipe['strInstructions'] ??
                    'No instructions available',
              ),
            ),
          );
        },
        label: Text(
          'Start Shopping',
          style: TextStyle(color: Colors.black), // Black text color
        ),
        icon: Icon(
          Icons.shopping_cart,
          color: Colors.black, // Black icon color
        ),
        backgroundColor: Colors.amber, // Amber color for button background
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMealImage() {
    final imageUrl = widget.recipe['strMealThumb'] ?? '';
    final imageData = widget.recipe['imageData'] as String?;
    final imagePath = widget.recipe['imagePath'] as String?;

    if (kIsWeb && imageData != null) {
      // Decode base64 image data for web
      return Container(
        width: double.infinity,
        height: 250,
        child: Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.error),
            );
          },
        ),
      );
    } else if (!kIsWeb && imagePath != null) {
      // Load image from file path for mobile
      return Container(
        width: double.infinity,
        height: 250,
        child: Image.file(
          io.File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.error),
            );
          },
        ),
      );
    } else if (imageUrl.isNotEmpty) {
      // Fallback to network image
      return Container(
        width: double.infinity,
        height: 250,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.error),
            );
          },
        ),
      );
    } else {
      // Placeholder image
      return Container(
        width: double.infinity,
        height: 250,
        child: Center(
          child: Icon(
            Icons.image,
            size: 100,
            color: Colors.grey[300],
          ),
        ),
      );
    }
  }

  List<Widget> _buildIngredientsList() {
    List<Widget> widgets = [];
    for (int i = 1; i <= 20; i++) {
      final String? ingredient = widget.recipe['strIngredient$i'];
      final String? measure = widget.recipe['strMeasure$i'];

      if (ingredient != null && ingredient.isNotEmpty) {
        widgets.add(
          Text(
            '$ingredient - $measure',
            style: TextStyle(fontSize: 16),
          ),
        );
      } else {
        break; // Exit the loop if no more ingredients
      }
    }
    return widgets;
  }

  Map<String, String> _buildIngredientsMap() {
    Map<String, String> ingredientsMap = {};
    for (int i = 1; i <= 20; i++) {
      final String? ingredient = widget.recipe['strIngredient$i'];
      final String? measure = widget.recipe['strMeasure$i'];

      if (ingredient != null && ingredient.isNotEmpty) {
        ingredientsMap[ingredient] = measure ?? '';
      } else {
        break; // Exit the loop if no more ingredients
      }
    }
    return ingredientsMap;
  }
}
