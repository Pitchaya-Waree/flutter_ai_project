import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class SolutionsScreen extends StatefulWidget {
  final String? equation;
  final File? imageFile;

  const SolutionsScreen({Key? key, this.equation, this.imageFile}) : super(key: key);

  @override
  _SolutionsScreenState createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  bool _isLoading = true;
  SolutionData? _solutionData;
  String? _errorMessage;

  final Color bgColor = const Color(0xFFF8F9F4);
  final Color darkGreenText = const Color(0xFF385A42);
  final Color badgeGreen = const Color(0xFFBBE5B6);
  final Color finalAnswerBg = const Color(0xFFBCE8B5);

  @override
  void initState() {
    super.initState();
    _fetchSolutionFromAI();
  }

  Future<void> _fetchSolutionFromAI() async {
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
      //  ใส่ API KEY ใหม่ตรงนี้ 
      final String apiKey = 'Your_API ??????'; 
 final String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=$apiKey';

      final String systemInstruction = """คุณคือผู้เชี่ยวชาญด้านคณิตศาสตร์ ฉันจะส่งรูปภาพสมการ หรือข้อความสมการให้คุณ ให้คุณแก้สมการนั้นและแสดงวิธีทำทีละขั้นตอน และ คุณต้องตอบกลับมาในรูปแบบ JSON เท่านั้น ตามโครงสร้างนี้:
{
  "originalEquation": "สมการที่อ่านได้",
  "topics": ["หัวข้อที่เกี่ยวข้อง1", "หัวข้อที่เกี่ยวข้อง2"],
  "steps": [
    { "title": "ชื่อขั้นตอน (ภาษาไทย) ", "mathExpression": "สมการในขั้นตอนนี้", "explanation": "คำอธิบาย" }
  ],
  "finalAnswer": "คำตอบสุดท้าย"
}""";

      List<Map<String, dynamic>> parts = [{"text": systemInstruction}];

      if (widget.equation != null && widget.equation!.isNotEmpty) {
        parts.add({"text": "\nโจทย์ปัญหาคือ: ${widget.equation}"});
      }

      if (widget.imageFile != null) {
        final bytes = await widget.imageFile!.readAsBytes();
        final base64Image = base64Encode(bytes);
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Image
          }
        });
      }

      final Map<String, dynamic> requestBody = {
        "contents": [{"parts": parts}],
        "generationConfig": {"response_mime_type": "application/json"}
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        String aiResponseText = responseData['candidates'][0]['content']['parts'][0]['text'];

        if (aiResponseText.startsWith("```json")) {
          aiResponseText = aiResponseText.replaceAll("```json", "").replaceAll("```", "").trim();
        }

        print("====== AI RESPONSE ======");
        print(aiResponseText);
        print("=========================");

        final Map<String, dynamic> data = json.decode(aiResponseText);

        List<SolutionStep> parsedSteps = [];
        if (data['steps'] != null && data['steps'] is List) {
          parsedSteps = (data['steps'] as List).map((step) {
            return SolutionStep(
              title: step['title']?.toString() ?? 'ขั้นตอน',
              mathExpression: step['mathExpression']?.toString() ?? '',
              explanation: step['explanation']?.toString() ?? '',
            );
          }).toList();
        }

        setState(() {
          _solutionData = SolutionData(
            originalEquation: data['originalEquation']?.toString() ?? widget.equation ?? '-',
            topics: List<String>.from(data['topics'] ?? []),
            steps: parsedSteps,
            finalAnswer: data['finalAnswer']?.toString() ?? '-',
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "เชื่อมต่อ AI ไม่สำเร็จ (ตรวจสอบ API Key)";
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "เกิดข้อผิดพลาดในการประมวลผล";
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
          icon: Icon(Icons.arrow_back, color: darkGreenText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Solver", style: TextStyle(color: darkGreenText, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: darkGreenText),
            const SizedBox(height: 16),
            const Text("AI กำลังคิดวิธีทำ...", style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchSolutionFromAI, child: const Text("ลองใหม่อีกครั้ง"))
          ],
        ),
      );
    }

    if (_solutionData == null) {
      return const SizedBox();
    }

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
                Text("ขั้นตอนการแก้โจทย์", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkGreenText)),
                const Divider(thickness: 1),
                const SizedBox(height: 16),
                
                if (_solutionData!.steps.isEmpty)
                   const Padding(
                     padding: EdgeInsets.all(16.0),
                     child: Text("ไม่มีขั้นตอนเพิ่มเติม", style: TextStyle(color: Colors.grey)),
                   ),
                
                // 🟢 วาดกล่องด้วยดีไซน์ใหม่ รับรองไม่มีล่องหน!
                Column(
                  children: _solutionData!.steps.asMap().entries.map((entry) {
                    return _buildModernStepCard(entry.value, entry.key);
                  }).toList(),
                ),

                const SizedBox(height: 16),
                _buildFinalAnswerCard(_solutionData!.finalAnswer),
              ],
            ),
          ),
        ),
        // _buildBottomButtons(),
      ],
    );
  }

  Widget _buildOriginalEquationCard(SolutionData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          const Text("สมการต้นฉบับ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(data.originalEquation, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (data.topics.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.topics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: badgeGreen, borderRadius: BorderRadius.circular(20)),
                    child: Text(topic, style: TextStyle(color: darkGreenText, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // 🟢🟢 ดีไซน์การ์ดแบบใหม่ สวยงาม ปลอดภัย และแสดงข้อความ 100% 🟢🟢
  Widget _buildModernStepCard(SolutionStep step, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkGreenText.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนหัว (หมายเลขขั้นตอน + ชื่อ)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: badgeGreen, shape: BoxShape.circle),
                child: Text("${index + 1}", style: TextStyle(color: darkGreenText, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title.isNotEmpty ? step.title : 'อธิบายขั้นตอน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkGreenText),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // ส่วนสมการ
          if (step.mathExpression.isNotEmpty && step.mathExpression != '-')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8F9F4), borderRadius: BorderRadius.circular(12)),
              child: Text(
                step.mathExpression,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          
          // ส่วนคำอธิบาย
          if (step.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                step.explanation,
                style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
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
      decoration: BoxDecoration(color: finalAnswerBg, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Text("คำตอบสุดท้าย", style: TextStyle(color: darkGreenText, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(answer, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: darkGreenText)),
            ],
          ),
          Positioned(right: 0, child: Icon(Icons.check_circle_outline, size: 60, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  // Widget _buildBottomButtons() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     color: bgColor,
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: OutlinedButton.icon(
  //             style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: darkGreenText), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //             icon: Icon(Icons.share_outlined, color: darkGreenText),
  //             label: Text("แชร์", style: TextStyle(color: darkGreenText, fontSize: 16)),
  //             onPressed: () {},
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
  //             icon: Icon(Icons.bookmark_border, color: darkGreenText),
  //             label: Text("บันทึก", style: TextStyle(color: darkGreenText, fontSize: 16)),
  //             onPressed: () {},
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}