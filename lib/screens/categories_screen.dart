import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dishes_screen.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    final url =
        Uri.parse('https://www.themealdb.com/api/json/v1/1/categories.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _categories = json.decode(response.body)['categories'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load categories');
    }
  }

  void navigateToDishesScreen(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DishesScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final String categoryName = category['strCategory'];
                final String thumbnailUrl = category['strCategoryThumb'];

                return Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    leading: thumbnailUrl != null
                        ? SizedBox(
                            width: 70,
                            height: 70,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                    title: Text(categoryName),
                    onTap: () {
                      navigateToDishesScreen(categoryName);
                    },
                  ),
                );
              },
            ),
    );
  }
}
