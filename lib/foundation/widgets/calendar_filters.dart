import 'package:flutter/material.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;
import '../../core/models/equipment/equipment.dart';

class CalendarEquipmentFilter extends StatelessWidget {
  final void Function(Equipment) onEquipmentSelected;

  const CalendarEquipmentFilter({super.key, required this.onEquipmentSelected});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Equipment>>(
      future: api.Api.advanceSearchEquipments('select * from equipments'),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, index) {
            final eq = items[index];
            return ListTile(
              title: Text(eq.title),
              onTap: () => onEquipmentSelected(eq),
            );
          },
        );
      },
    );
  }
}
