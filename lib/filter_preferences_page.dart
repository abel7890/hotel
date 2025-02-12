import 'package:flutter/material.dart';

class FilterPreferencesPage extends StatelessWidget {
  const FilterPreferencesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Filter Preferences")),
      body: const Center(
        child: Text("Here you can filter rooms by preferences."),
      ),
    );
  }
}
