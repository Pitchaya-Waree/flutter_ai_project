import 'package:flutter/material.dart';
import '../constants/app_colors.dart'; // ดึงสีมาใช้ (ปรับ path ให้ตรงกับโปรเจกต์ของคุณ)

class MathDisplay extends StatelessWidget {
  final String equation;
  final String result;
  final VoidCallback onClear;

  const MathDisplay({
    Key? key,
    required this.equation,
    required this.result,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // หัวข้อ โหมดแก้ไข และ ปุ่มถังขยะ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "โหมดแก้ไข",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // อนิเมชั่นสลับตัวเลข
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<bool>(result.isNotEmpty && result != "Error"),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (result.isNotEmpty && result != "Error") ...[
                  Text(
                    result,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreenBtnColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    equation,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ] else ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          equation,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4, bottom: 4),
                          width: 2,
                          height: 32,
                          color: AppColors.darkGreenBtnColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}