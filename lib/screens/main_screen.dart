import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'my_recipes_screen.dart';
import 'favorites.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    MyRecipesScreen(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Handle initial arguments if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int? index = ModalRoute.of(context)?.settings.arguments as int?;
      if (index != null) {
        setState(() {
          _selectedIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon.png',
              height: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Cookable',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: _selectedIndex == 0 ? Colors.amber : Colors.grey),
            label: 'Home',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category,
                color: _selectedIndex == 1 ? Colors.amber : Colors.grey),
            label: 'Categories',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark,
                color: _selectedIndex == 2 ? Colors.amber : Colors.grey),
            label: 'My Recipes',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite,
                color: _selectedIndex == 3 ? Colors.amber : Colors.grey),
            label: 'Favorites',
            backgroundColor: Colors.white,
          ),
        ],
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
