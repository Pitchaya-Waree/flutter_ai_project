import 'package:flutter/material.dart';
import '../models/solution_model.dart';

// การ์ดแสดงสมการต้นฉบับ
class OriginalEquationCard extends StatelessWidget {
  final SolutionData data;
  final Color badgeColor;
  final Color textColor;

  const OriginalEquationCard({
    super.key,
    required this.data,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (data.topics.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.topics.map((topic) => _buildBadge(topic)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// การ์ดแสดงขั้นตอนวิธีทำ
class StepCard extends StatelessWidget {
  final SolutionStep step;
  final int index;
  final Color badgeColor;
  final Color textColor;

  const StepCard({
    super.key,
    required this.step,
    required this.index,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: badgeColor,
                radius: 18,
                child: Text("${index + 1}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title.isNotEmpty ? step.title : 'ขั้นตอนที่ ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (step.mathExpression.isNotEmpty && step.mathExpression != '-')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFF8F9F4), borderRadius: BorderRadius.circular(12)),
              child: Text(step.mathExpression, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
          if (step.explanation.isNotEmpty)
            Text(step.explanation, style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}

// การ์ดแสดงคำตอบสุดท้าย
class FinalAnswerCard extends StatelessWidget {
  final String answer;
  final Color bgColor;
  final Color textColor;

  const FinalAnswerCard({super.key, required this.answer, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text("คำตอบสุดท้าย", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(answer, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}