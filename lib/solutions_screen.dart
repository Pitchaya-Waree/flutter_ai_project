import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // สำหรับดึงค่าจากไฟล์ .env

import 'models/solution_model.dart';
import 'widgets/solution_cards.dart';

class SolutionsScreen extends StatefulWidget {
  // รับค่ามาจากหน้าอื่น (เช่น หน้าสแกน หรือหน้าคีย์บอร์ด)
  final String? equation;
  final File? imageFile;

  const SolutionsScreen({super.key, this.equation, this.imageFile});

  @override
  State<SolutionsScreen> createState() => _SolutionsScreenState();
}

class _SolutionsScreenState extends State<SolutionsScreen> {
  // ตัวแปรสถานะสำหรับควบคุมหน้าจอ
  bool _isLoading = true;
  SolutionData? _solutionData;
  String? _errorMessage;

  // โทนสีของหน้าจอ
  final Color bgColor = const Color(0xFFF8F9F4);
  final Color darkGreenText = const Color(0xFF385A42);
  final Color badgeGreen = const Color(0xFFBBE5B6);
  final Color finalAnswerBg = const Color(0xFFBCE8B5);

  // 🟢 1. initState: เป็นฟังก์ชันวงจรชีวิต (Lifecycle) ของ Flutter 
  // ถูกเรียกใช้อัตโนมัติ "ครั้งแรกครั้งเดียว" เมื่อเปิดหน้านี้ขึ้นมา
  @override
  void initState() {
    super.initState();
    // สั่งให้เริ่มดึงข้อมูลจาก AI ทันทีที่เปิดหน้าจอ
    _fetchSolutionFromAI();
  }

  // 🟢 2. _fetchSolutionFromAI: ฟังก์ชันหลักในการติดต่อกับ Gemini API
  // ถูกเรียกจาก 2 ที่คือ: 1. จาก initState() ตอนเปิดหน้า 2. จากปุ่ม "ลองใหม่" ตอนเกิด Error
  Future<void> _fetchSolutionFromAI() async {
    // เช็คว่ามีส่งโจทย์หรือรูปภาพมาให้หรือไม่
    if (widget.equation == null && widget.imageFile == null) {
      _showError("ไม่พบข้อมูลโจทย์ปัญหา");
      return;
    }

    try {
      // ดึง API Key จากไฟล์ .env
      final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        _showError("ไม่พบ API Key ในระบบ (ตรวจสอบไฟล์ .env)");
        return;
      }

      final String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=$apiKey';

      // เรียกฟังก์ชัน _prepareRequestBody เพื่อแพ็คข้อมูลก่อนส่ง
      final requestBody = await _prepareRequestBody();
      
      // ส่งคำขอ (Request) ไปยังเซิร์ฟเวอร์ของ Google
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // เช็คว่าเซิร์ฟเวอร์ตอบกลับมาสำเร็จ (Status 200) หรือไม่
      if (response.statusCode == 200) {
        // ส่งข้อมูลที่ได้ไปแปลงเป็น Object ต่อที่ฟังก์ชัน _parseResponse
        _parseResponse(response.body);
      } else {
        _showError("เชื่อมต่อ AI ไม่สำเร็จ (Status: ${response.statusCode})");
      }
    } catch (e) {
      _showError("เกิดข้อผิดพลาด: $e");
    }
  }

  // 🟢 3. _prepareRequestBody: ฟังก์ชันสำหรับเตรียมข้อมูล (Prompt + รูปภาพ)
  // ถูกเรียกใช้ภายในฟังก์ชัน _fetchSolutionFromAI() ก่อนยิง API
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

    // ถ้ามีข้อความสมการส่งมา ให้เติมเข้าไปใน Prompt
    if (widget.equation?.isNotEmpty ?? false) {
      parts.add({"text": "โจทย์: ${widget.equation}"});
    }

    // ถ้ามีไฟล์รูปภาพส่งมา ให้แปลงรูปภาพเป็นรหัส Base64 แล้วแนบไปด้วย
    if (widget.imageFile != null) {
      final bytes = await widget.imageFile!.readAsBytes();
      parts.add({
        "inline_data": {"mime_type": "image/jpeg", "data": base64Encode(bytes)},
      });
    }

    // จัดรูปแบบโครงสร้าง JSON สำหรับส่งให้ Gemini
    return {
      "contents": [
        {"parts": parts},
      ],
      "generationConfig": {"response_mime_type": "application/json"},
    };
  }

  // 🟢 4. _parseResponse: ฟังก์ชันจัดการผลลัพธ์ที่ได้จาก AI
  // ถูกเรียกใช้จาก _fetchSolutionFromAI() เมื่อเชื่อมต่อ API สำเร็จ
  void _parseResponse(String body) {
    // แปลง String ให้อยู่ในรูป Map (JSON)
    final decoded = json.decode(body);
    String aiText = decoded['candidates'][0]['content']['parts'][0]['text'];

    // ลบคำว่า ```json และ ``` ออก (ป้องกันกรณี AI ส่ง Markdown ติดมาด้วย)
    aiText = aiText.replaceAll("```json", "").replaceAll("```", "").trim();
    final data = json.decode(aiText);

    // อัปเดตสถานะ (setState) ให้ UI หน้าจอรีเฟรช และเอาข้อมูลไปวาดเป็นการ์ด
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
      // เปลี่ยนสถานะว่าโหลดเสร็จแล้ว
      _isLoading = false;
    });
  }

  // 🟢 5. _showError: ฟังก์ชันตัวช่วยสำหรับแสดง Error
  // ถูกเรียกใช้เมื่อเกิดข้อผิดพลาดในการโหลด API
  void _showError(String msg) => setState(() {
    _isLoading = false;
    _errorMessage = msg;
  });

  // 🟢 6. build: ฟังก์ชันหลักในการวาด UI
  // จะถูกเรียกอัตโนมัติทุกครั้งที่มีการเรียก setState()
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Solutions'),
        backgroundColor: bgColor,
        foregroundColor: darkGreenText,
        elevation: 0,
      ),
      // เรียกใช้ _buildBody() เพื่อตัดสินใจว่าจะแสดง โหลด / Error / หรือ ข้อมูล
      body: _buildBody(),
    );
  }

  // 🟢 7. _buildBody: ฟังก์ชันจัดการส่วนเนื้อหาตรงกลางหน้าจอ
  // ถูกเรียกจากภายในฟังก์ชัน build()
  Widget _buildBody() {
    // ถ้าสถานะยังโหลดอยู่ ให้ไปดึง UI หน้าโหลด
    if (_isLoading) return _buildLoading();
    
    // ถ้ามี Error ให้ไปดึง UI หน้าแสดง Error
    if (_errorMessage != null) return _buildError();
    
    // กันเหนียว ถ้าข้อมูลเป็น null (ซึ่งไม่ควรเกิดขึ้น) ให้แสดงหน้าว่าง
    if (_solutionData == null) return const SizedBox();

    // ถ้าปกติ ให้ดึง Widget ต่างๆ ที่ทำไว้มาเรียงต่อกันเป็นหน้าจอแบบเลื่อนได้ (Scroll)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // การ์ดแสดงสมการเริ่มต้น
          OriginalEquationCard(
            data: _solutionData!,
            badgeColor: badgeGreen,
            textColor: darkGreenText,
          ),
          const SizedBox(height: 24),
          // หัวข้อ
          if (_solutionData!.topics.isNotEmpty)
            Text(
              'หัวข้อ: ${_solutionData!.topics.join(', ')}',
              style: TextStyle(color: darkGreenText, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          if (_solutionData!.topics.isNotEmpty) const SizedBox(height: 16),
          // วนลูป (map) นำขั้นตอน (steps) ทั้งหมดมาสร้างเป็นการ์ด StepCard ทีละอัน
          ..._solutionData!.steps.asMap().entries.map(
            (e) => StepCard(
              step: e.value,
              index: e.key + 1,
              badgeColor: badgeGreen,
              textColor: darkGreenText,
            ),
          ),
          // การ์ดแสดงคำตอบสุดท้าย
          FinalAnswerCard(
            answer: _solutionData!.finalAnswer,
            bgColor: finalAnswerBg,
            textColor: darkGreenText,
          ),
        ],
      ),
    );
  }

  // 🟢 8. _buildLoading: ฟังก์ชันคืนค่า UI หน้าหมุนๆ (Loading)
  // ถูกเรียกจาก _buildBody()
  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  // 🟢 9. _buildError: ฟังก์ชันคืนค่า UI หน้า Error และปุ่มลองใหม่
  // ถูกเรียกจาก _buildBody()
  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: darkGreenText),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: TextStyle(color: darkGreenText, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _fetchSolutionFromAI,
          style: ElevatedButton.styleFrom(
            backgroundColor: badgeGreen,
            foregroundColor: darkGreenText,
          ),
          child: const Text("ลองใหม่"),
        ),
      ],
    ),
  );
}