import 'package:flutter/material.dart';

AppBar buildAppTopBar({
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: const Color(0xFF0B0B0F),
    foregroundColor: Colors.white,
    elevation: 0,
    titleSpacing: 12,
    centerTitle: false,
    title: Row(
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
    actions: actions,
  );
}
