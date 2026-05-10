import 'package:flutter/material.dart';
import '../constants/app_colors.dart'; // ดึงสีมาใช้

class MathKeyboard extends StatelessWidget {
  final bool isScientific;
  final Function(String) onKeyPress;
  final VoidCallback onToggleMode;

  const MathKeyboard({
    super.key,
    required this.isScientific,
    required this.onKeyPress,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isScientific ? _buildScientificKeypad() : _buildStandardKeypad(),
    );
  }

  Widget _buildStandardKeypad() {
    return Column(
      children: [
        _buildRow([
          _KeyModel(icon: Icons.square_foot, bgColor: AppColors.lightGreyKeyColor, iconColor: Colors.black54, isToggle: true),
          _KeyModel(text: "AC", bgColor: AppColors.redKeyColor, textColor: Colors.white),
          _KeyModel(text: "x²", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: "π", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(icon: Icons.backspace_outlined, bgColor: AppColors.redKeyColor, iconColor: Colors.white, isBackspace: true),
        ], isFiveColumn: true),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "7"), _KeyModel(text: "8"), _KeyModel(text: "9"), _KeyModel(text: "÷", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "4"), _KeyModel(text: "5"), _KeyModel(text: "6"), _KeyModel(text: "×", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "1"), _KeyModel(text: "2"), _KeyModel(text: "3"), _KeyModel(text: "-", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "0"), _KeyModel(text: "."), _KeyModel(text: "=", bgColor: AppColors.beigeKeyColor), _KeyModel(text: "+", bgColor: AppColors.greenKeyColor)]),
      ],
    );
  }

  Widget _buildScientificKeypad() {
    return Column(
      children: [
        _buildRow([
          _KeyModel(icon: Icons.square_foot, bgColor: AppColors.greenKeyColor, iconColor: AppColors.darkGreenBtnColor, isToggle: true),
          _KeyModel(text: "AC", bgColor: AppColors.redKeyColor, textColor: Colors.white),
          _KeyModel(text: "sin", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: "cos", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(icon: Icons.backspace_outlined, bgColor: AppColors.redKeyColor, iconColor: Colors.white, isBackspace: true),
        ], isFiveColumn: true),
        const SizedBox(height: 8),
        _buildRow([
          _KeyModel(text: "tan", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: "(", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: ")", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: "√", bgColor: AppColors.lightGreyKeyColor),
          _KeyModel(text: "^", bgColor: AppColors.lightGreyKeyColor),
        ], isFiveColumn: true),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "7"), _KeyModel(text: "8"), _KeyModel(text: "9"), _KeyModel(text: "÷", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "4"), _KeyModel(text: "5"), _KeyModel(text: "6"), _KeyModel(text: "×", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "1"), _KeyModel(text: "2"), _KeyModel(text: "3"), _KeyModel(text: "-", bgColor: AppColors.greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "0"), _KeyModel(text: "."), _KeyModel(text: "=", bgColor: AppColors.beigeKeyColor), _KeyModel(text: "+", bgColor: AppColors.greenKeyColor)]),
      ],
    );
  }

  Widget _buildRow(List<_KeyModel> keys, {bool isFiveColumn = false}) {
    return Expanded(
      child: Row(
        children: keys.asMap().entries.map((entry) {
          int idx = entry.key;
          _KeyModel key = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: idx == 0 ? 0 : (isFiveColumn ? 6 : 12)),
              child: _buildButton(key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton(_KeyModel key) {
    return InkWell(
      onTap: () {
        if (key.isToggle) {
          onToggleMode();
        } else if (key.isBackspace) {
          onKeyPress("⌫");
        } else if (key.text != null) {
          onKeyPress(key.text!);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: key.bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: key.bgColor == null ? Colors.grey.shade300 : Colors.transparent),
        ),
        child: Center(
          child: key.icon != null
              ? Icon(key.icon, color: key.iconColor ?? Colors.black54, size: 24)
              : Text(
                  key.text!,
                  style: TextStyle(
                    fontSize: key.text!.length > 2 ? 18 : 22,
                    color: key.textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// Model เก็บข้อมูลแต่ละปุ่ม
class _KeyModel {
  final String? text;
  final IconData? icon;
  final Color? bgColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isToggle;
  final bool isBackspace;

  _KeyModel({
    this.text,
    this.icon,
    this.bgColor,
    this.textColor,
    this.iconColor,
    this.isToggle = false,
    this.isBackspace = false,
  });
}