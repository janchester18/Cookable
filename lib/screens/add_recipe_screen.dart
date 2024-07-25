import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class AddRecipeScreen extends StatefulWidget {
  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  XFile? _image; // For mobile
  Uint8List? _imageData; // For web

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _measurementControllers = [];
  final List<TextEditingController> _instructionControllers = [];
  final List<Map<String, String>> _ingredients = [
    {'ingredient': '', 'measurement': ''}
  ];
  final List<String> _instructions = [''];

  @override
  void initState() {
    super.initState();
    // Initialize controllers for the first ingredient and instruction
    _ingredientControllers.add(TextEditingController());
    _measurementControllers.add(TextEditingController());
    _instructionControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _dishNameController.dispose();
    _categoryController.dispose();
    _areaController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _measurementControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // For web
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]!);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _imageData = reader.result as Uint8List;
            _image = null; // Clear mobile image if web image is picked
          });
        });
      });
    } else {
      // For mobile
      final XFile? pickedImage =
          await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = pickedImage;
        _imageData = null; // Clear web image data if mobile image is picked
      });
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    if (kIsWeb) {
      await _pickImage();
    } else {
      final XFile? pickedImage = await _picker.pickImage(source: source);
      setState(() {
        _image = pickedImage;
        _imageData = null; // Clear web image data if mobile image is picked
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRecipe() async {
    final recipe = {
      'strMeal': _dishNameController.text,
      'strCategory': _categoryController.text,
      'strArea': _areaController.text,
      'strInstructions':
          _instructions.join('\n'), // Combine instructions into a single string
      // Handling ingredients and measurements
      ...Map.fromIterable(_ingredients.asMap().entries,
          key: (e) => 'strIngredient${e.key + 1}',
          value: (e) => e.value['ingredient']),
      ...Map.fromIterable(_ingredients.asMap().entries,
          key: (e) => 'strMeasure${e.key + 1}',
          value: (e) => e.value['measurement']),
      'imageData': _imageData != null ? base64Encode(_imageData!) : null,
      'imagePath': _image != null ? _image!.path : null,
    };

    if (!kIsWeb) {
      // Only for mobile
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/recipes.json');

      List<Map<String, dynamic>> recipes = [];
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        recipes = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }

      recipes.add(recipe);
      await file.writeAsString(jsonEncode(recipes));
    }

    Navigator.pop(context, recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Recipe'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: _image != null
                        ? Image.file(io.File(_image!.path), fit: BoxFit.cover)
                        : _imageData != null
                            ? Image.memory(_imageData!,
                                fit: BoxFit.cover) // Web
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      color: Colors.grey[600]),
                                  Text(
                                    'Select Image',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              TextField(
                controller: _dishNameController,
                decoration: InputDecoration(labelText: 'Dish Name'),
              ),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: _areaController,
                decoration: InputDecoration(labelText: 'Area'),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingredients'),
                  ..._ingredients.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> ingredient = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                                hintText: 'Ingredient ${index + 1}'),
                            onChanged: (value) {
                              setState(() {
                                _ingredients[index]['ingredient'] = value;
                              });
                            },
                            controller: _ingredientControllers[index],
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                                hintText: 'Measurement ${index + 1}'),
                            onChanged: (value) {
                              setState(() {
                                _ingredients[index]['measurement'] = value;
                              });
                            },
                            controller: _measurementControllers[index],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_ingredients.length > 1) {
                                _ingredients.removeAt(index);
                                _ingredientControllers.removeAt(index);
                                _measurementControllers.removeAt(index);
                              }
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _ingredients
                              .add({'ingredient': '', 'measurement': ''});
                          _ingredientControllers.add(TextEditingController());
                          _measurementControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(Icons.add, color: Colors.amber),
                      label: Text('Add Ingredient',
                          style: TextStyle(color: Colors.amber)),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions'),
                  ..._instructions.asMap().entries.map((entry) {
                    int index = entry.key;
                    String instruction = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration:
                                InputDecoration(hintText: 'Step ${index + 1}'),
                            onChanged: (value) {
                              setState(() {
                                _instructions[index] = value;
                              });
                            },
                            controller: _instructionControllers[index],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_instructions.length > 1) {
                                _instructions.removeAt(index);
                                _instructionControllers.removeAt(index);
                              }
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _instructions.add('');
                          _instructionControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(Icons.add, color: Colors.amber),
                      label: Text('Add Instruction',
                          style: TextStyle(color: Colors.amber)),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitRecipe,
                  child: Text('Submit Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.amber, // Set the button color to amber
                    foregroundColor: Colors.white, // Set the text color
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
