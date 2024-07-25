import 'package:flutter/material.dart';
import 'start_cooking.dart'; // Import the StartCookingScreen

class IngredientsChecklistScreen extends StatefulWidget {
  final Map<String, String> ingredients;
  final String instructions;

  const IngredientsChecklistScreen({
    Key? key,
    required this.ingredients,
    required this.instructions,
  }) : super(key: key);

  @override
  _IngredientsChecklistScreenState createState() =>
      _IngredientsChecklistScreenState();
}

class _IngredientsChecklistScreenState
    extends State<IngredientsChecklistScreen> {
  late Map<String, bool> _checklist;

  @override
  void initState() {
    super.initState();
    _checklist = widget.ingredients
        .map((ingredient, measure) => MapEntry(ingredient, false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingredients Checklist'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _selectAll,
              icon: Icon(Icons.check_circle),
              color: Colors.amber, // Icon color
              tooltip: 'Select All',
              iconSize: 30, // Size of the icon
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: _buildChecklist(),
        ),
      ),
      floatingActionButton: _allChecked()
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StartCookingScreen(
                      instructions: widget.instructions,
                    ),
                  ),
                );
              },
              label: Text('Start Cooking'),
              icon: Icon(Icons.kitchen),
              backgroundColor: Colors.amber, // Floating action button color
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Widget> _buildChecklist() {
    return _checklist.keys.map((ingredient) {
      return CheckboxListTile(
        title: Text('$ingredient - ${widget.ingredients[ingredient]}'),
        value: _checklist[ingredient],
        onChanged: (bool? value) {
          setState(() {
            _checklist[ingredient] = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.amber, // Checkbox color when toggled
      );
    }).toList();
  }

  bool _allChecked() {
    return _checklist.values.every((isChecked) => isChecked);
  }

  void _selectAll() {
    setState(() {
      _checklist.updateAll((key, value) => true);
    });
  }
}
