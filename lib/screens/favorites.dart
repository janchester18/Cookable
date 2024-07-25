import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart'; // For mobile file access
import 'package:universal_html/html.dart' as html;
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      List<Map<String, dynamic>> favorites = [];

      if (kIsWeb) {
        // Web: Use local storage
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

      setState(() {
        _favorites = favorites;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _refreshFavorites() async {
    await _loadFavorites(); // Refresh the list
  }

  void _removeFavorite(Map<String, dynamic> recipe) {
    setState(() {
      _favorites.removeWhere((item) => item['strMeal'] == recipe['strMeal']);
      _saveFavorites();
    });
  }

  Future<void> _saveFavorites() async {
    try {
      final jsonString = jsonEncode(_favorites);

      if (kIsWeb) {
        html.window.localStorage['favorites'] = jsonString;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/favorites.json');
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: _favorites.isEmpty
            ? Center(
                child: Text(
                'No favorites added yet!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ))
            : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final recipe = _favorites[index];
                  return FavoriteListItem(
                    recipe: recipe,
                    onRemove: () => _removeFavorite(recipe),
                  );
                },
              ),
      ),
    );
  }
}

class FavoriteListItem extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onRemove;

  const FavoriteListItem({
    Key? key,
    required this.recipe,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildMealImage(recipe),
      title: Text(recipe['strMeal'] ?? 'Unknown'),
      subtitle: Text('${recipe['strCategory'] ?? 'Unknown'}'),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline),
        onPressed: onRemove,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
    );
  }

  Widget _buildMealImage(Map<String, dynamic> recipe) {
    final imageUrl = recipe['strMealThumb'] ?? '';
    final imageData = recipe['imageData'] as String?;
    final imagePath = recipe['imagePath'] as String?;

    if (kIsWeb && imageData != null) {
      // Decode base64 image data for web
      return Container(
        width: 50,
        height: 50,
        child: Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.error));
          },
        ),
      );
    } else if (!kIsWeb && imagePath != null) {
      // Load image from file path for mobile
      return Container(
        width: 50,
        height: 50,
        child: Image.file(
          io.File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.error));
          },
        ),
      );
    } else if (imageUrl.isNotEmpty) {
      // Fallback to network image
      return Container(
        width: 50,
        height: 50,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.error));
          },
        ),
      );
    } else {
      // Placeholder image
      return Container(
        width: 50,
        height: 50,
        child: Center(
          child: Icon(
            Icons.image,
            size: 30,
            color: Colors.grey[300],
          ),
        ),
      );
    }
  }
}
