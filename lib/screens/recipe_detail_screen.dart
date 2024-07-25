import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart'; // For mobile file access
import 'package:universal_html/html.dart' as html;
import 'ingredients_checklist.dart'; // Update this import path if needed

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _saveFavoriteStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber,
        duration: Duration(seconds: 1, milliseconds: 500),
      ),
    );
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      if (kIsWeb) {
        // Web: Use local storage
        final jsonString = html.window.localStorage['favorites'];
        if (jsonString != null) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          final List<Map<String, dynamic>> favorites =
              jsonList.map((item) => item as Map<String, dynamic>).toList();
          setState(() {
            _isFavorite = favorites
                .any((recipe) => recipe['strMeal'] == widget.recipe['strMeal']);
          });
        }
      } else {
        // Mobile: Read from file system
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/favorites.json');
        if (file.existsSync()) {
          final jsonString = await file.readAsString();
          final List<dynamic> jsonList = jsonDecode(jsonString);
          final List<Map<String, dynamic>> favorites =
              jsonList.map((item) => item as Map<String, dynamic>).toList();
          setState(() {
            _isFavorite = favorites
                .any((recipe) => recipe['strMeal'] == widget.recipe['strMeal']);
          });
        }
      }
    } catch (e) {
      print('Error loading favorite status: $e');
    }
  }

  Future<void> _saveFavoriteStatus() async {
    try {
      List<Map<String, dynamic>> favorites = [];

      if (kIsWeb) {
        // Web: Read from local storage
        final jsonString = html.window.localStorage['favorites'];
        if (jsonString != null) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          favorites =
              jsonList.map((item) => item as Map<String, dynamic>).toList();
        }
      } else {
        // Mobile: Read from file system
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/favorites.json');
        if (file.existsSync()) {
          final jsonString = await file.readAsString();
          final List<dynamic> jsonList = jsonDecode(jsonString);
          favorites =
              jsonList.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      if (_isFavorite) {
        // Add to favorites if not already present
        if (!favorites
            .any((recipe) => recipe['strMeal'] == widget.recipe['strMeal'])) {
          favorites.add(widget.recipe);
        }
      } else {
        // Remove from favorites if present
        favorites.removeWhere(
            (recipe) => recipe['strMeal'] == widget.recipe['strMeal']);
      }

      if (kIsWeb) {
        // Web: Save to local storage
        final jsonString = jsonEncode(favorites);
        html.window.localStorage['favorites'] = jsonString;
      } else {
        // Mobile: Write to file system
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/favorites.json');
        final jsonString = jsonEncode(favorites);
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print('Error saving favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe['strMeal'] ?? 'Recipe Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite
                  ? Colors.amber
                  : Colors.grey, // Amber color for favorite
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMealImage(),
              SizedBox(height: 20),
              Text(
                'Category: ${widget.recipe['strCategory'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 10),
              Text(
                'Area: ${widget.recipe['strArea'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 20),
              Text(
                'Ingredients:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildIngredientsList(),
              ),
              SizedBox(height: 20),
              Text(
                'Instructions:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 10),
              Text(
                '${widget.recipe['strInstructions'] ?? 'No instructions available'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(
                  height: 100), // Ensure there's enough space at the bottom
            ],
          ),
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
        label: Text('Start Shopping'),
        icon: Icon(Icons.shopping_cart),
        backgroundColor: Colors.amber, // Amber color for Floating Action Button
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
        break;
      }
    }
    return widgets;
  }

  Map<String, String> _buildIngredientsMap() {
    Map<String, String> ingredients = {};
    for (int i = 1; i <= 20; i++) {
      final String? ingredient = widget.recipe['strIngredient$i'];
      final String? measure = widget.recipe['strMeasure$i'];

      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients[ingredient] = measure ?? '';
      } else {
        break;
      }
    }
    return ingredients;
  }
}
