import 'package:flutter/material.dart';

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