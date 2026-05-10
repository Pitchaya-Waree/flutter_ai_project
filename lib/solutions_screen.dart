import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// --- โมเดลข้อมูลสำหรับเก็บวิธีทำ ---
class SolutionStep {
  final String title;
  final String mathExpression;
  final String explanation;

  SolutionStep({
    required this.title,
    required this.mathExpression,
    required this.explanation,
  });
}

class SolutionData {
  final String originalEquation;
  final List<String> topics;
  final List<SolutionStep> steps;
  final String finalAnswer;

  SolutionData({
    required this.originalEquation,
    required this.topics,
    required this.steps,
    required this.finalAnswer,
  });
}

// --- หน้าจอย่อย SolutionsScreen ---
class SolutionsScreen extends StatefulWidget {
  final String? equation; // รับสมการที่พิมพ์จาก Editor
  final File? imageFile; // รับรูปภาพที่แสกนจากกล้อง

  const SolutionsScreen({Key? key, this.equation, this.imageFile})
    : super(key: key);

  @override
  _SolutionsScreenState createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  bool _isLoading = true;
  SolutionData? _solutionData;
  String? _errorMessage;

  // โทนสีตามดีไซน์
  final Color bgColor = const Color(0xFFF8F9F4);
  final Color darkGreenText = const Color(0xFF385A42);
  final Color badgeGreen = const Color(0xFFBBE5B6);
  final Color lightGreyBox = const Color(0xFFF0F0F0);
  final Color finalAnswerBg = const Color(0xFFBCE8B5);

  @override
  void initState() {
    super.initState();
    _fetchSolutionFromAI();
  }

  // --- ฟังก์ชันจำลองการเรียก AI API ---
  Future<void> _fetchSolutionFromAI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 💡 ตรงนี้คือจุดที่คุณต้องใส่ HTTP Request เพื่อยิง API ของคุณจริงๆ
      // ตัวอย่าง:
      // var response = await http.post(
      //   Uri.parse('https://your-ai-api.com/solve'),
      //   body: {'equation': widget.equation},
      //   // หรือส่งรูปแบบ MultipartRequest ถ้ามี widget.imageFile
      // );

      // จำลองเวลาโหลด API 2 วินาที
      await Future.delayed(const Duration(seconds: 2));

      // จำลองข้อมูล JSON ที่ AI ตอบกลับมา (เลียนแบบรูปภาพ)
      String mockJsonResponse = '''
      {
        "originalEquation": "2x² + 5x - 3 = 0",
        "topics": ["พีชคณิต", "สมการกำลังสอง"],
        "steps": [
          {
            "title": "ขั้นตอนที่ 1: แยกตัวประกอบของสมการกำลังสอง",
            "mathExpression": "(2x - 1)(x + 3) = 0",
            "explanation": "หาตัวเลขสองตัวที่คูณกันได้ -6 (จาก 2 * -3) และบวกกันได้ 5 ตัวเลขนั้นคือ 6 และ -1"
          },
          {
            "title": "ขั้นตอนที่ 2: ตั้งค่าแต่ละวงเล็บให้เท่ากับศูนย์",
            "mathExpression": "2x - 1 = 0 หรือ x + 3 = 0",
            "explanation": "ตามคุณสมบัติของศูนย์ หากผลคูณของสองนิพจน์เท่ากับศูนย์ อย่างน้อยหนึ่งนิพจน์ต้องเท่ากับศูนย์"
          },
          {
            "title": "ขั้นตอนที่ 3: แก้สมการหาค่า x",
            "mathExpression": "2x = 1 => x = 1/2\\nx = -3",
            "explanation": ""
          }
        ],
        "finalAnswer": "x = 1/2, -3"
      }
      ''';

      // แปลง JSON เป็น Object
      final Map<String, dynamic> data = json.decode(mockJsonResponse);

      List<SolutionStep> parsedSteps = (data['steps'] as List)
          .map(
            (step) => SolutionStep(
              title: step['title'],
              mathExpression: step['mathExpression'],
              explanation: step['explanation'],
            ),
          )
          .toList();

      setState(() {
        _solutionData = SolutionData(
          originalEquation:
              widget.equation ??
              data['originalEquation'], // ถ้ามี text ให้ใช้ text ก่อน
          topics: List<String>.from(data['topics']),
          steps: parsedSteps,
          finalAnswer: data['finalAnswer'],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "เกิดข้อผิดพลาดในการวิเคราะห์โจทย์ กรุณาลองใหม่อีกครั้ง";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF385A42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Solver",
          style: TextStyle(
            color: Color(0xFF385A42),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF385A42)),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF385A42)),
            SizedBox(height: 16),
            Text(
              "AI กำลังคิดวิธีทำ...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_solutionData == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOriginalEquationCard(_solutionData!),
                const SizedBox(height: 24),

                // หัวข้อขั้นตอนการแก้โจทย์
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ขั้นตอนการแก้โจทย์",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreenText,
                      ),
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                  ],
                ),

                // สร้างรายการ Timeline วิธีทำ
                ..._solutionData!.steps.asMap().entries.map((entry) {
                  int idx = entry.key;
                  bool isLast = idx == _solutionData!.steps.length - 1;
                  return _buildTimelineStep(entry.value, isLast);
                }).toList(),

                const SizedBox(height: 16),
                _buildFinalAnswerCard(_solutionData!.finalAnswer),
              ],
            ),
          ),
        ),

        // ปุ่มด้านล่าง
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildOriginalEquationCard(SolutionData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            "สมการต้นฉบับ",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            data.originalEquation,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.topics.map((topic) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: darkGreenText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(SolutionStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ส่วนเส้นและจุดของ Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkGreenText,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // ส่วนการ์ดรายละเอียด
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  // รวบ border ไว้ในตัวเดียว แล้วกำหนดทีละด้าน
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                    left: BorderSide(
                      color: darkGreenText,
                      width: 4,
                    ), // แถบสีเขียวด้านซ้ายการ์ด
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightGreyBox,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step.mathExpression,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (step.explanation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        step.explanation,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAnswerCard(String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: finalAnswerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text(
                "คำตอบสุดท้าย",
                style: TextStyle(
                  color: darkGreenText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: darkGreenText,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: darkGreenText),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.share_outlined, color: darkGreenText),
              label: Text(
                "แชร์",
                style: TextStyle(color: darkGreenText, fontSize: 16),
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.bookmark_border, color: darkGreenText),
              label: Text(
                "บันทึก",
                style: TextStyle(color: darkGreenText, fontSize: 16),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
