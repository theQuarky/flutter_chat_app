import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onStartSearch;
  final VoidCallback onStopSearch;

  const SearchButton({
    Key? key,
    required this.isSearching,
    required this.onStartSearch,
    required this.onStopSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isSearching
        ? ElevatedButton(
            onPressed: onStopSearch,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop Search'),
          )
        : ElevatedButton(
            onPressed: onStartSearch,
            child: const Text('Start Search'),
          );
  }
}
