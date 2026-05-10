// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'scan_screen.dart'; 

Future<void> main() async {
  // รับรองว่า Widgets ถูก Initialized ก่อนเรียกปลั๊กอิน
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดค่า API Key จากไฟล์ .env
  await dotenv.load(fileName: ".env");

  // ค้นหากล้องที่มีในเครื่อง
  final cameras = await availableCameras();

  // รันแอป
  runApp(
    MaterialApp(
      title: 'Math Solver AI',
      debugShowCheckedModeBanner: false,
      home: ScanScreen(cameras: cameras), // เปิดหน้า ScanScreen เป็นหน้าแรก
    ),
  );
}