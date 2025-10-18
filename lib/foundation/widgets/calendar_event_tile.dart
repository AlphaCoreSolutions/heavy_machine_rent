import 'package:flutter/material.dart';
import 'package:heavy_new/core/models/admin/request.dart';

class CalendarEventTile extends StatelessWidget {
  final RequestModel request;

  const CalendarEventTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          'Request #${request.requestNo ?? '-'}',
          style: TextStyle(color: color.primary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.equipment?.title != null)
              Text('Equipment: ${request.equipment!.title}'),
            Text('From: ${request.fromDate}'),
            Text('To: ${request.toDate}'),
          ],
        ),
      ),
    );
  }
}
