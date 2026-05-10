import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

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
    // เรียกใช้งาน AI ทันทีเมื่อเปิดหน้านี้ขึ้นมา
    _fetchSolutionFromAI();
  }

  // --- ฟังก์ชันเรียก AI API (Gemini) ---
  Future<void> _fetchSolutionFromAI() async {
    // ถ้าไม่มีข้อมูลอะไรส่งมาเลย ให้แจ้งเตือน
    if (widget.equation == null && widget.imageFile == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "ไม่พบข้อมูลโจทย์ปัญหา";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🔴 ดึงค่า API Key จากไฟล์ .env ที่ซ่อนไว้
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
      
      if (apiKey.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ไม่พบ API Key ในระบบ กรุณาตรวจสอบไฟล์ .env";
        });
        return;
      }

      // ใช้ apiKey ที่ดึงมาต่อเข้ากับ URL
      final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

      // คำสั่ง Prompt
      final String systemInstruction =
          """คุณคือผู้เชี่ยวชาญด้านคณิตศาสตร์ ฉันจะส่งรูปภาพสมการ หรือข้อความสมการให้คุณ ให้คุณแก้สมการนั้นและแสดงวิธีทำทีละขั้นตอน และ คุณต้องตอบกลับมาในรูปแบบ JSON เท่านั้น ตามโครงสร้างนี้:
{
  "originalEquation": "สมการที่อ่านได้",
  "topics": ["หัวข้อที่เกี่ยวข้อง1", "หัวข้อที่เกี่ยวข้อง2"],
  "steps": [
    { "title": "ชื่อขั้นตอน", "mathExpression": "สมการในขั้นตอนนี้", "explanation": "คำอธิบาย" }
  ],
  "finalAnswer": "คำตอบสุดท้าย"
}""";

      // เตรียมส่วนประกอบของข้อมูลที่จะส่ง (Parts)
      List<Map<String, dynamic>> parts = [];

      // 1. ใส่ Prompt สั่งการเสมอ
      parts.add({"text": systemInstruction});

      // 2. ถ้ามีสมการแบบข้อความส่งมา ให้เติมเข้าไปใน Prompt
      if (widget.equation != null && widget.equation!.isNotEmpty) {
        parts.add({"text": "\nโจทย์ปัญหาคือ: ${widget.equation}"});
      }

      // 3. ถ้ามีรูปภาพส่งมา ให้แปลงเป็น Base64 แล้วแนบไปด้วย
      if (widget.imageFile != null) {
        final bytes = await widget.imageFile!.readAsBytes();
        final base64Image = base64Encode(bytes);
        parts.add({
          "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
        });
      }

      // สร้าง Request Body
      final Map<String, dynamic> requestBody = {
        "contents": [
          {"parts": parts},
        ],
        "generationConfig": {
          "response_mime_type": "application/json", // บังคับให้ AI ตอบเป็น JSON
        },
      };

      // ยิงคำขอไปที่ Gemini
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // ใช้ utf8.decode เพื่อป้องกันปัญหาภาษาไทยกลายเป็นภาษาต่างดาว
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        String aiResponseText =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // บางครั้ง AI อาจจะใส่ ```json ครอบมา ให้ตัดออกก่อน
        if (aiResponseText.startsWith("```json")) {
          aiResponseText = aiResponseText
              .replaceAll("```json", "")
              .replaceAll("```", "")
              .trim();
        }

        // แปลงข้อความ JSON ให้กลายเป็น Object Dart
        final Map<String, dynamic> data = json.decode(aiResponseText);

        List<SolutionStep> parsedSteps = (data['steps'] as List)
            .map(
              (step) => SolutionStep(
                title: step['title'].toString(),
                mathExpression: step['mathExpression'].toString(),
                explanation: step['explanation']?.toString() ?? '',
              ),
            )
            .toList();

        setState(() {
          _solutionData = SolutionData(
            // ใช้สมการจาก AI ก่อน ถ้าไม่มีค่อยใช้จากหน้า Editor
            originalEquation:
                data['originalEquation']?.toString() ?? widget.equation ?? '-',
            topics: List<String>.from(data['topics'] ?? []),
            steps: parsedSteps,
            finalAnswer: data['finalAnswer']?.toString() ?? '-',
          );
          _isLoading = false;
        });
      } else {
        print("====== API ERROR ======");
        print("Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");
        print("=======================");

        setState(() {
          _isLoading = false;
          // เอา Status Code มาโชว์บนหน้าจอชั่วคราว จะได้รู้ว่าพังที่โค้ดไหน
          _errorMessage =
              "ไม่สามารถเชื่อมต่อ AI ได้ (Code: ${response.statusCode})\nกรุณาลองใหม่อีกครั้ง";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "เกิดข้อผิดพลาดในการวิเคราะห์ข้อมูล";
        print("Error details: $e");
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSolutionFromAI,
              child: const Text("ลองใหม่อีกครั้ง"),
            ),
          ],
        ),
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
          if (data.topics.isNotEmpty)
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