// lib/ui/widgets/no_services_view.dart
import 'package:flutter/material.dart';

class NoServicesView extends StatelessWidget {
  const NoServicesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun service disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}