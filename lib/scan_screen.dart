import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
// import 'package:flutter/foundation.dart';

import 'editor_screen.dart';
import 'solutions_screen.dart';
import 'bottom_nav_bar.dart';

// ----- CAMERA OVERLAY PAINTER -----
// กรองแสงหน้ากล้องเพื่อจำลองกรอบ (ยังคงไว้ตามโครงสร้างเดิมของคุณ)
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

// ----- SCAN SCREEN WIDGET -----
class ScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScanScreen({super.key, required this.cameras});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high, // ปรับความละเอียดให้สูงเพื่อการแสกนที่แม่นยำ
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔴 ฟังก์ชันใหม่: แสดงหน้าจอตัดรูปภาพ (Crop) เพื่อให้ผู้ใช้ปรับกรอบ
  Future<void> _cropImage(String sourcePath) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      // 🔴 ย้าย aspectRatioPresets เข้ามาไว้ข้างใน uiSettings
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ปรับกรอบครอบโจทย์',
          toolbarColor: Colors.green[800],
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false, // อนุญาตให้ปรับสัดส่วนเองได้ฟรี
          // 🔴 ของ Android ใส่ตรงนี้
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(
          title: 'ปรับกรอบครอบโจทย์',
          // 🔴 ของ iOS ใส่ตรงนี้
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
      ],
    );

    // ถ้ายืนยันการตัดรูป (croppedFile ไม่เป็น null) ให้ส่งรูปไปหน้า Solutions
    if (croppedFile != null) {
      _navigateToSolutions(File(croppedFile.path));
    }
  }

  // 🔴 3. ฟังก์ชันใหม่: นำทางไปยังหน้า SolutionsScreen พร้อมส่งรูป
  void _navigateToSolutions(File finalImageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolutionsScreen(imageFile: finalImageFile),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      // 🔴 4. แทนที่จะส่งไปโดยตรง ให้ส่งไปตัดรูปก่อน
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      _cropImage(image.path);
    } catch (e) {
      debugPrint('Error capture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          "Solver",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Colors.black),
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
                const Positioned(
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
                      icon: const Icon(Icons.flash_off, color: Colors.white),
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
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        radius: 28,
                        child: IconButton(
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: _pickFromGallery,
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
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: MathSolverBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditorScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SolutionsScreen()),
            );
          }
        },
      ),
    );
  }
}
