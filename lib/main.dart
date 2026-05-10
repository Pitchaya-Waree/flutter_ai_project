// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'editor_screen.dart';
import 'solutions_screen.dart';
import 'package:http/http.dart' as http;

// ----- API SERVICE -----
class ApiService {
  // 1. ใส่ API Key ของคุณที่นี่
  final String _apiKey = 'AIzaSyDd1Zh8Ea0-qRjXEmW-nQIqKQzE3VypSy0';

  Future<Map<String, dynamic>?> solveEquation(File imageFile) async {
    // 2. URL ของ Gemini (ใช้รุ่น 1.5 Flash)
    final String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    try {
      // 3. แปลงรูปภาพเป็น Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 4. สร้าง Payload ส่งไปให้ Gemini
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Analyze this math problem. Solve it step by step. Output ONLY valid JSON matching this structure: {\"originalEquation\": \"...\", \"topics\": [\"...\"], \"steps\": [{\"title\": \"...\", \"mathExpression\": \"...\", \"explanation\": \"...\"}], \"finalAnswer\": \"...\"}",
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg", // ปรับตามประเภทรูปภาพ
                  "data": base64Image,
                },
              },
            ],
          },
        ],
        // บังคับให้ Gemini ตอบเป็น JSON
        "generationConfig": {"response_mime_type": "application/json"},
      };

      // 5. ส่ง Request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // ดึงข้อความ JSON ออกมาจาก Response ของ Gemini
        String aiResponseText =
            data['candidates'][0]['content']['parts'][0]['text'];

        // แปลงข้อความนั้นเป็น Map ส่งกลับไปให้ SolutionsScreen ของเรา
        return json.decode(aiResponseText);
      } else {
        print('API Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}

// ----- BOTTOM NAV BAR WIDGET -----
class MathSolverBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const MathSolverBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              label: 'Scan',
              activeIcon: _buildActiveIcon(Icons.camera_alt_outlined),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              label: 'Editor',
              activeIcon: _buildActiveIcon(Icons.calculate_outlined),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize_outlined),
              label: 'Solutions',
              activeIcon: _buildActiveIcon(Icons.summarize_outlined),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              label: 'History',
              activeIcon: _buildActiveIcon(Icons.history_outlined),
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActiveIcon(IconData iconData) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[100],
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: Colors.green[800], size: 28),
    );
  }
}

// ----- CAMERA OVERLAY PAINTER -----
class CameraOverlayPainter extends CustomPainter {
  final Color overlayColor;
  final double frameWidth;
  final double frameHeight;
  final double borderRadius;
  final double cornerLength;
  final double cornerWidth;
  final Color strokeColor;

  CameraOverlayPainter({
    required this.overlayColor,
    required this.frameWidth,
    required this.frameHeight,
    this.borderRadius = 12.0,
    this.cornerLength = 20.0,
    this.cornerWidth = 4.0,
    this.strokeColor = Colors.green,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintOverlay = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paintOverlay);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: frameWidth,
      height: frameHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );

    final rrect = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(borderRadius),
    );
    final path = Path();

    path.moveTo(rrect.left, rrect.top + cornerLength);
    path.lineTo(rrect.left, rrect.top + borderRadius);
    path.quadraticBezierTo(
      rrect.left,
      rrect.top,
      rrect.left + borderRadius,
      rrect.top,
    );
    path.lineTo(rrect.left + cornerLength, rrect.top);

    path.moveTo(rrect.right - cornerLength, rrect.top);
    path.lineTo(rrect.right - borderRadius, rrect.top);
    path.quadraticBezierTo(
      rrect.right,
      rrect.top,
      rrect.right,
      rrect.top + borderRadius,
    );
    path.lineTo(rrect.right, rrect.top + cornerLength);

    path.moveTo(rrect.right, rrect.bottom - cornerLength);
    path.lineTo(rrect.right, rrect.bottom - borderRadius);
    path.quadraticBezierTo(
      rrect.right,
      rrect.bottom,
      rrect.right - borderRadius,
      rrect.bottom,
    );
    path.lineTo(rrect.right - cornerLength, rrect.bottom);

    path.moveTo(rrect.left + cornerLength, rrect.bottom);
    path.lineTo(rrect.left + borderRadius, rrect.bottom);
    path.quadraticBezierTo(
      rrect.left,
      rrect.bottom,
      rrect.left,
      rrect.bottom - borderRadius,
    );
    path.lineTo(rrect.left, rrect.bottom - cornerLength);

    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----- MAIN SCREEN (SCAN) -----
class ScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanScreen({super.key, required this.cameras});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker(); // 🔴 สร้างตัวแปรสำหรับเลือกรูป

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ฟังก์ชันส่วนกลางสำหรับส่งรูปไป AI และแสดง Loading
  Future<void> _processImage(File imageFile) async {
    // แค่สั่งเปิดหน้า SolutionsScreen แล้วส่งรูปไปให้เลย AI จะทำงานในหน้านั้นเอง
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolutionsScreen(imageFile: imageFile),
      ),
    );
  }

  // 🔴 ฟังก์ชันสำหรับเปิด Gallery
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      _processImage(File(pickedFile.path));
    }
  }

  // ฟังก์ชันสำหรับถ่ายรูป
  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      print('Error capture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          "Solver",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: CameraOverlayPainter(
                      overlayColor: Colors.black54,
                      frameWidth: 280,
                      frameHeight: 180,
                      strokeColor: Colors.green,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 220,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "จัดสมการให้อยู่ในกรอบเพื่อสแกน",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.flash_off, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔴 ปุ่ม Gallery ที่แก้ไขแล้ว
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed:
                              _pickFromGallery, // เรียกฟังก์ชันเปิด Gallery
                        ),
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.calculate_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditorScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
        },
      ),
      bottomNavigationBar: MathSolverBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 1) {
            // กดปุ่ม Editor (ที่เคยทำไว้เผื่อต้องการ)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditorScreen()),
            );
          } else if (index == 2) {
            // 🔴 กดปุ่ม Solutions
            Navigator.push(
              context,
              MaterialPageRoute(
                // ส่งค่าว่างๆ ไปก่อน เพราะเราแค่กดเข้ามาดูเฉยๆ ไม่ได้มีสมการส่งมา
                builder: (context) => const SolutionsScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

// ----- MAIN APP WRAPPER -----
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Math Solver AI',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

// ----- MAIN ENTRY POINT -----
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(
    MaterialApp(
      title: 'Math Solver AI',
      debugShowCheckedModeBanner: false,
      home: ScanScreen(cameras: cameras),
    ),
  );
}
