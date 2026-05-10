// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// ----- API SERVICE (คุณต้องแก้ไขส่วนนี้) -----
class ApiService {
  final String _apiUrl =
      'https://api.example.com/solve'; // แทนที่ด้วย API URL จริงของคุณ
  final String _apiKey = 'YOUR_API_KEY'; // แทนที่ด้วย API Key ของคุณ

  Future<Map<String, dynamic>?> solveEquation(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
        return json.decode(response.body);
      } else {
        print('Error: ${response.statusCode}');
        print('Body: ${response.body}');
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

  MathSolverBottomNavBar({
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
              icon: Icon(Icons.summarize_outlined), // ใช้ไอคอน Σ ใกล้เคียงสุด
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

    // 1. วาด overlay ทึบแสงกึ่งโปร่งใสรอบนอก
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paintOverlay);

    // 2. คำนวณและวาดกรอบใสตรงกลาง
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

    // 3. วาดมุมสี่เหลี่ยมสีเขียวด้านใน
    final rrect = RRect.fromRectAndRadius(
      frameRect,
      Radius.circular(borderRadius),
    );
    final path = Path();

    // มุมซ้ายบน
    path.moveTo(rrect.left, rrect.top + cornerLength);
    path.lineTo(rrect.left, rrect.top + borderRadius);
    path.quadraticBezierTo(
      rrect.left,
      rrect.top,
      rrect.left + borderRadius,
      rrect.top,
    );
    path.lineTo(rrect.left + cornerLength, rrect.top);

    // มุมขวาบน
    path.moveTo(rrect.right - cornerLength, rrect.top);
    path.lineTo(rrect.right - borderRadius, rrect.top);
    path.quadraticBezierTo(
      rrect.right,
      rrect.top,
      rrect.right,
      rrect.top + borderRadius,
    );
    path.lineTo(rrect.right, rrect.top + cornerLength);

    // มุมขวาล่าง
    path.moveTo(rrect.right, rrect.bottom - cornerLength);
    path.lineTo(rrect.right, rrect.bottom - borderRadius);
    path.quadraticBezierTo(
      rrect.right,
      rrect.bottom,
      rrect.right - borderRadius,
      rrect.bottom,
    );
    path.lineTo(rrect.right - cornerLength, rrect.bottom);

    // มุมซ้ายล่าง
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

  const ScanScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndSendToAI() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final imageFile = File(image.path);

      // แสดง Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 20),
              Text("กำลังวิเคราะห์สมการ..."),
            ],
          ),
        ),
      );

      // ส่ง API
      final result = await _apiService.solveEquation(imageFile);

      Navigator.pop(context); // ปิด Loading Dialog

      if (result != null) {
        // แสกนสำเร็จ: ไปหน้า Solutions (ต้องสร้างหน้าต่างนี้แยก)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SolutionsScreen(resultData: result, imageFile: imageFile),
          ),
        );
      } else {
        // แสกนล้มเหลว
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ขออภัย แสกนสมการไม่สำเร็จ ลองใหม่อีกครั้ง")),
        );
      }
    } catch (e) {
      print('Error during capture/API call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                // 1. Camera Preview
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),

                // 2. Camera Overlay (Scanning Frame)
                Positioned.fill(
                  child: CustomPaint(
                    painter: CameraOverlayPainter(
                      overlayColor: Colors.black54, // พื้นหลังกึ่งโปร่งใส
                      frameWidth: 280, // ปรับตามต้องการ
                      frameHeight: 180, // ปรับตามต้องการ
                      strokeColor: Colors.green, // กรอบสีเขียว
                    ),
                  ),
                ),

                // 3. Text instruction below frame
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

                // 4. Flash icon top-right
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

                // 5. Camera Controls (Gallery, Shutter, Editor)
                Positioned(
                  bottom: 80,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // แกลเลอรี
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {},
                        ),
                      ),
                      // ปุ่มถ่ายรูป
                      GestureDetector(
                        onTap: _captureAndSendToAI,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Color.fromRGBO(38, 92, 168, 1),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green[800], // สีเขียวเหมือนในรูป
                              ),
                            ),
                          ),
                        ),
                      ),
                      // เครื่องคิดเลข
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.calculate_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: MathSolverBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {},
      ),
    );
  }
}

// ----- SOLUTIONS SCREEN (หน้าสมมติที่จะแสดงผลลัพธ์) -----
class SolutionsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  final File imageFile;

  const SolutionsScreen({
    Key? key,
    required this.resultData,
    required this.imageFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Solution")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "สมการ:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // ตัวอย่าง API RESPONSE: {"equation": "1+2(x-3)=4/x"}
              Text(
                resultData['equation'] ?? '',
                style: TextStyle(fontSize: 24, color: Colors.blue),
              ),
              SizedBox(height: 20),
              Text(
                "ผลลัพธ์:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // ตัวอย่าง API RESPONSE: {"solution": ["x=3/2", "x=4"]}
              Text(
                resultData['solution']?.toString() ?? '',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Text(
                "รูปภาพที่แสกน:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Image.file(imageFile),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final List<CameraDescription>? cameras;

  const MyApp({Key? key, this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Solver AI',
      home: cameras != null && cameras!.isNotEmpty
          ? ScanScreen(cameras: cameras!)
          : const Scaffold(body: Center(child: Text('No cameras available'))),
    );
  }
}

// ----- MAIN ENTRY POINT -----
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}
