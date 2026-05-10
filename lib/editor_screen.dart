import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart'; // สำหรับการคำนวณ

class EditorScreen extends StatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  String _equation = "0"; 
  String _result = "";    
  bool _isScientific = false; // ตัวแปรสลับโหมดวิทย์/ปกติ

  // ชุดสีตามดีไซน์เดิม (Light Theme)
  final Color bgColor = const Color(0xFFF8F9F4);
  final Color greenKeyColor = const Color(0xFFCDEACD);
  final Color redKeyColor = const Color(0xFFE28A7F);
  final Color beigeKeyColor = const Color(0xFFE6DEC9);
  final Color darkGreenBtnColor = const Color(0xFF4E6B50);
  final Color lightGreyKeyColor = const Color(0xFFEFEFEF);

  // ฟังก์ชันคำนวณผลลัพธ์
  void _calculate() {
    if (_equation.isEmpty || _equation == "0") return;
    try {
      String finalEquation = _equation;
      // แปลงสัญลักษณ์ให้เป็นรูปแบบที่ math_expressions เข้าใจ
      finalEquation = finalEquation.replaceAll('×', '*');
      finalEquation = finalEquation.replaceAll('÷', '/');
      finalEquation = finalEquation.replaceAll('π', '3.14159265359');
      finalEquation = finalEquation.replaceAll('√', 'sqrt');

      Parser p = Parser();
      Expression exp = p.parse(finalEquation);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        _result = eval.toString();
        if (_result.endsWith(".0")) {
          _result = _result.substring(0, _result.length - 2);
        }
      });
    } catch (e) {
      setState(() {
        _result = "Error"; // ถ้าสมการไม่สมบูรณ์ให้ขึ้น Error
      });
    }
  }

  // ฟังก์ชันเมื่อกดปุ่มต่างๆ
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
        // จัดการการพิมพ์สัญลักษณ์พิเศษ
        String addValue = value;
        if (value == "x²") addValue = "^2";
        else if (value == "sin" || value == "cos" || value == "tan" || value == "ln" || value == "log") addValue = "$value(";
        else if (value == "√") addValue = "√(";

        if (_equation == "0") {
          _equation = addValue;
        } else {
          _equation += addValue;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
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
          // 1. กรอบแสดงผลสมการ (Display Area)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("โหมดแก้ไข", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // ให้เลื่อนไปด้านขวาสุดเสมอเวลาพิมพ์ยาวๆ
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _equation,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Container(margin: const EdgeInsets.only(left: 4, bottom: 4), width: 2, height: 32, color: darkGreenBtnColor),
                      ],
                    ),
                  ),
                ),
                if (_result.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "= $_result",
                      style: const TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. แป้นพิมพ์ (Keypad Area)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isScientific ? _buildScientificKeypad() : _buildStandardKeypad(),
            ),
          ),

          // 3. ปุ่ม "แก้สมการ" (Solve Button)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreenBtnColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  // สั่งคำนวณทันทีเมื่อกดปุ่ม "แก้สมการ"
                  _calculate();
                  print("Solving equation: $_equation");
                },
                child: const Text(
                  "แก้สมการ",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Layout แป้นพิมพ์ปกติ ---
  Widget _buildStandardKeypad() {
    return Column(
      children: [
        // แถวที่ 1: สามเหลี่ยมอยู่ซ้ายสุด คู่กับ AC
        _buildRow([
          _KeyModel(icon: Icons.square_foot, bgColor: lightGreyKeyColor, iconColor: Colors.black54, isToggle: true),
          _KeyModel(text: "AC", bgColor: redKeyColor, textColor: Colors.white),
          _KeyModel(text: "x²", bgColor: lightGreyKeyColor),
          _KeyModel(text: "π", bgColor: lightGreyKeyColor),
          _KeyModel(icon: Icons.backspace_outlined, bgColor: redKeyColor, iconColor: Colors.white, isBackspace: true),
        ], isFiveColumn: true),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "7"), _KeyModel(text: "8"), _KeyModel(text: "9"), _KeyModel(text: "÷", bgColor: greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "4"), _KeyModel(text: "5"), _KeyModel(text: "6"), _KeyModel(text: "×", bgColor: greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "1"), _KeyModel(text: "2"), _KeyModel(text: "3"), _KeyModel(text: "-", bgColor: greenKeyColor)]),
        const SizedBox(height: 10),
        _buildRow([_KeyModel(text: "0"), _KeyModel(text: "."), _KeyModel(text: "=", bgColor: beigeKeyColor), _KeyModel(text: "+", bgColor: greenKeyColor)]),
      ],
    );
  }

  // --- Layout แป้นพิมพ์วิทยาศาสตร์ ---
  Widget _buildScientificKeypad() {
    return Column(
      children: [
        // แถวที่ 1
        _buildRow([
          _KeyModel(icon: Icons.square_foot, bgColor: greenKeyColor, iconColor: darkGreenBtnColor, isToggle: true), // ไฮไลท์เมื่อเปิดวิทย์
          _KeyModel(text: "AC", bgColor: redKeyColor, textColor: Colors.white),
          _KeyModel(text: "sin", bgColor: lightGreyKeyColor),
          _KeyModel(text: "cos", bgColor: lightGreyKeyColor),
          _KeyModel(icon: Icons.backspace_outlined, bgColor: redKeyColor, iconColor: Colors.white, isBackspace: true),
        ], isFiveColumn: true),
        const SizedBox(height: 8),
        // แถวที่ 2 (ฟังก์ชันวิทย์เพิ่มเติม)
        _buildRow([
          _KeyModel(text: "tan", bgColor: lightGreyKeyColor),
          _KeyModel(text: "(", bgColor: lightGreyKeyColor),
          _KeyModel(text: ")", bgColor: lightGreyKeyColor),
          _KeyModel(text: "√", bgColor: lightGreyKeyColor),
          _KeyModel(text: "^", bgColor: lightGreyKeyColor),
        ], isFiveColumn: true),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "7"), _KeyModel(text: "8"), _KeyModel(text: "9"), _KeyModel(text: "÷", bgColor: greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "4"), _KeyModel(text: "5"), _KeyModel(text: "6"), _KeyModel(text: "×", bgColor: greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "1"), _KeyModel(text: "2"), _KeyModel(text: "3"), _KeyModel(text: "-", bgColor: greenKeyColor)]),
        const SizedBox(height: 8),
        _buildRow([_KeyModel(text: "0"), _KeyModel(text: "."), _KeyModel(text: "=", bgColor: beigeKeyColor), _KeyModel(text: "+", bgColor: greenKeyColor)]),
      ],
    );
  }

  // Helper สร้างแถว
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

  // Helper สร้างปุ่มแต่ละปุ่ม
  Widget _buildButton(_KeyModel key) {
    return InkWell(
      onTap: () {
        if (key.isToggle) {
          setState(() => _isScientific = !_isScientific);
        } else if (key.isBackspace) {
          _onKeyPress("⌫");
        } else if (key.text != null) {
          _onKeyPress(key.text!);
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
                    fontSize: key.text!.length > 2 ? 18 : 22, // ปรับขนาดตัวอักษรให้เล็กลงถ้าเป็นคำว่า sin, cos, tan
                    color: key.textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// Model เก็บข้อมูลแต่ละปุ่มเพื่อให้จัดการง่ายขึ้น
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