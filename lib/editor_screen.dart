import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

import 'solutions_screen.dart';
import 'constants/app_colors.dart'; // 🔴 นำเข้าสี
import 'widgets/math_display.dart'; // 🔴 นำเข้าหน้าจอแสดงผล
import 'widgets/math_keyboard.dart'; // 🔴 นำเข้าแป้นพิมพ์

class EditorScreen extends StatefulWidget {
  // 🟢 เปลี่ยนมาใช้ super.key แทน สั้นลงและลบ warning ได้
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  String _equation = "0";
  String _result = "";
  bool _isScientific = false;

  // ฟังก์ชันคำนวณผลลัพธ์
  void _calculate() {
    if (_equation.isEmpty || _equation == "0") return;
    try {
      String finalEquation = _equation
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265359')
          .replaceAll('√', 'sqrt');

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(finalEquation);
      ContextModel cm = ContextModel();
      RealEvaluator evaluator = RealEvaluator(cm);
      double eval = evaluator.evaluate(exp).toDouble();

      setState(() {
        _result = eval.toString();
        if (_result.endsWith(".0")) {
          _result = _result.substring(0, _result.length - 2);
        }
      });
    } catch (e) {
      setState(() {
        _result = "Error";
      });
    }
  }

  // ฟังก์ชันจัดการเมื่อกดปุ่ม
  void _onKeyPress(String value) {
    setState(() {
      if (value == "AC") {
        _equation = "0";
        _result = "";
      } else if (value == "⌫") {
        if (_equation.length > 1) {
          _equation = _equation.substring(0, _equation.length - 1);
        } else {
          _equation = "0";
          _result = "";
        }
      } else if (value == "=") {
        _calculate();
      } else {
        if (_result.isNotEmpty) {
          _result = "";
        }

        String addValue = value;
        if (value == "x²") {
          addValue = "^2";
        } else if (["sin", "cos", "tan", "ln", "log"].contains(value)) {
          addValue = "$value(";
        } else if (value == "√") {
          addValue = "√(";
        }

        _equation = (_equation == "0") ? addValue : _equation + addValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Solver",
          style: TextStyle(
            color: Color(0xFF8BA08E),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. หน้าจอแสดงผล (เรียกใช้จากไฟล์ที่แยกไว้)
          MathDisplay(
            equation: _equation,
            result: _result,
            onClear: () => _onKeyPress("AC"),
          ),

          const SizedBox(height: 10),

          // 2. แป้นพิมพ์ (เรียกใช้จากไฟล์ที่แยกไว้)
          Expanded(
            child: MathKeyboard(
              isScientific: _isScientific,
              onKeyPress: _onKeyPress,
              onToggleMode: () =>
                  setState(() => _isScientific = !_isScientific),
            ),
          ),

          // 3. ปุ่มแก้สมการ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreenBtnColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SolutionsScreen(equation: _equation),
                    ),
                  );
                },
                child: const Text(
                  "แก้สมการ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
