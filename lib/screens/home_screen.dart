import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchRecipes('');
  }

  Future<void> fetchRecipes(String query) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _recipes = json.decode(response.body)['meals'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load recipes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                fetchRecipes(value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: SizedBox(
                          width: 70,
                          height: 70,
                          child: Image.network(
                            '${recipe['strMealThumb']}/preview',
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(recipe['strMeal']),
                        subtitle: Text(recipe['strCategory']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
