import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'recipe_detail_screen.dart'; // Import the RecipeDetailScreen

class DishesScreen extends StatefulWidget {
  final String category;

  const DishesScreen({Key? key, required this.category}) : super(key: key);

  @override
  _DishesScreenState createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  List<dynamic> _dishes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDishes();
  }

  Future<void> fetchDishes() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/filter.php?c=${widget.category}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _dishes = json.decode(response.body)['meals'] ??
            []; // Ensure meals is not null
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load dishes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Dishes'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dishes.isEmpty
              ? Center(child: Text('No dishes found'))
              : ListView.builder(
                  itemCount: _dishes.length,
                  itemBuilder: (context, index) {
                    final dish = _dishes[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          navigateToRecipeDetail(dish['idMeal']);
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8.0),
                          leading: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(
                                    '${dish['strMealThumb']}/preview'),
                              ),
                            ),
                          ),
                          title: Text(dish['strMeal'] ?? ''),
                          subtitle: Text(dish['strArea'] ?? ''),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void navigateToRecipeDetail(String mealId) async {
    final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final recipe = json.decode(response.body)['meals'][0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(recipe: recipe),
        ),
      );
    } else {
      throw Exception('Failed to load recipe details');
    }
  }
}
