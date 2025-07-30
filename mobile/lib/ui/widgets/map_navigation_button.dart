import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/improved_map_screen.dart';

class MapNavigationButton extends StatelessWidget {
  final int? categoryId;
  final String? categoryName;

  const MapNavigationButton({
    Key? key,
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImprovedMapScreen(
                categoryId: categoryId,
                categoryName: categoryName,
              ),
            ),
          );
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.viewOnMap,
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF142FE2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}