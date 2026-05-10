import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🔴 สำหรับใช้ .env

import 'models/solution_model.dart';
import 'widgets/solution_cards.dart';

class SolutionsScreen extends StatefulWidget {
  final String? equation;
  final File? imageFile;

  const SolutionsScreen({super.key, this.equation, this.imageFile});

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  bool _isLoading = true;
  SolutionData? _solutionData;
  String? _errorMessage;

  // โทนสีของหน้าจอ
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
      _showError("ไม่พบข้อมูลโจทย์ปัญหา");
      return;
    }

    try {
      // 🔴 ดึง API Key จากไฟล์ .env
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        _showError("ไม่พบ API Key ในระบบ (ตรวจสอบไฟล์ .env)");
        return;
      }

      final String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=$apiKey';

      final requestBody = await _prepareRequestBody();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        _parseResponse(response.body);
      } else {
        _showError("เชื่อมต่อ AI ไม่สำเร็จ (Status: ${response.statusCode})");
      }
    } catch (e) {
      _showError("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<Map<String, dynamic>> _prepareRequestBody() async {
    const prompt =
        """คุณคือผู้เชี่ยวชาญด้านคณิตศาสตร์ แก้โจทย์ต่อไปนี้และตอบกลับเป็น JSON เท่านั้น:
    {
      "originalEquation": "สมการ",
      "topics": ["หัวข้อ"],
      "steps": [{"title": "ขั้นตอน(ภาษาไทย)", "mathExpression": "สมการ", "explanation": "คำอธิบาย"}],
      "finalAnswer": "คำตอบ"
    }""";

    List<Map<String, dynamic>> parts = [
      {"text": prompt},
    ];

    if (widget.equation?.isNotEmpty ?? false) {
      parts.add({"text": "โจทย์: ${widget.equation}"});
    }

    if (widget.imageFile != null) {
      final bytes = await widget.imageFile!.readAsBytes();
      parts.add({
        "inline_data": {"mime_type": "image/jpeg", "data": base64Encode(bytes)},
      });
    }

    return {
      "contents": [
        {"parts": parts},
      ],
      "generationConfig": {"response_mime_type": "application/json"},
    };
  }

  void _parseResponse(String body) {
    final decoded = json.decode(body);
    String aiText = decoded['candidates'][0]['content']['parts'][0]['text'];

    // ทำความสะอาด JSON string ถ้ามี markdown
    aiText = aiText.replaceAll("```json", "").replaceAll("```", "").trim();
    final data = json.decode(aiText);

    setState(() {
      _solutionData = SolutionData(
        originalEquation: data['originalEquation'] ?? widget.equation ?? '-',
        topics: List<String>.from(data['topics'] ?? []),
        steps: (data['steps'] as List)
            .map(
              (s) => SolutionStep(
                title: s['title'] ?? '',
                mathExpression: s['mathExpression'] ?? '',
                explanation: s['explanation'] ?? '',
              ),
            )
            .toList(),
        finalAnswer: data['finalAnswer'] ?? '-',
      );
      _isLoading = false;
    });
  }

  void _showError(String msg) => setState(() {
    _isLoading = false;
    _errorMessage = msg;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkGreenText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Solver",
          style: TextStyle(
            color: darkGreenText,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  // 🟢 ฟังก์ชันแก้ไข: สร้างกรอบ Scanner ที่โปร่งใสตรงกลาง และมืดรอบข้าง
  Widget _buildScannerOverlay(double screenWidth, double screenHeight) {
    double scanAreaSize = 250;
    // ปรับสีรอบข้างให้มืดลง 50%
    Color overlayColor = Colors.black.withOpacity(0.5);

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. พื้นที่สีมืดรอบกรอบ
          Positioned.fill(
            child: Column(
              children: [
                // บน
                Container(
                  color: overlayColor,
                  height:
                      (screenHeight - scanAreaSize - 150) /
                      2, // ปรับให้เหมาะกับปุ่ม
                ),
                Row(
                  children: [
                    // ซ้าย
                    Container(
                      color: overlayColor,
                      width: (screenWidth - scanAreaSize) / 2,
                      height: scanAreaSize,
                    ),
                    // กล่อง Scanner (ตรงกลาง) - โปร่งใส
                    Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      color: Colors.transparent, // 🟢 ทำให้โปร่งใส 100%
                    ),
                    // ขวา
                    Container(
                      color: overlayColor,
                      width: (screenWidth - scanAreaSize) / 2,
                      height: scanAreaSize,
                    ),
                  ],
                ),
                // ล่าง
                Container(
                  color: overlayColor,
                  height:
                      (screenHeight - scanAreaSize - 150) / 2 +
                      150, // ครอบคลุมถึงด้านล่าง
                ),
              ],
            ),
          ),
          // 2. เส้นขอบสีเขียวของ Scanner
          Positioned(
            top: (screenHeight - scanAreaSize - 150) / 2,
            left: (screenWidth - scanAreaSize) / 2,
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(16),
                // 🟢 ลบสีขาว cloudy และลบ BackdropFilter ที่เคยอยู่ตรงนี้ออก
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError();
    if (_solutionData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OriginalEquationCard(
            data: _solutionData!,
            badgeColor: badgeGreen,
            textColor: darkGreenText,
          ),
          const SizedBox(height: 24),
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
          ..._solutionData!.steps.asMap().entries.map(
            (e) => StepCard(
              step: e.value,
              index: e.key,
              badgeColor: badgeGreen,
              textColor: darkGreenText,
            ),
          ),
          FinalAnswerCard(
            answer: _solutionData!.finalAnswer,
            bgColor: finalAnswerBg,
            textColor: darkGreenText,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: darkGreenText),
        const SizedBox(height: 16),
        const Text("AI กำลังคิดวิธีทำ..."),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ElevatedButton(
          onPressed: _fetchSolutionFromAI,
          child: const Text("ลองใหม่"),
        ),
      ],
    ),
  );
}
