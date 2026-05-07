import 'package:flutter/material.dart';
import '../../domain/entities.dart';

class FamilyAvatar extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final VoidCallback? onTap;

  const FamilyAvatar({super.key, required this.member, this.size = 56, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: member.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(color: member.color.withAlpha(76), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                member.initial,
                style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (member.isOnline)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                ),
              Text(member.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
