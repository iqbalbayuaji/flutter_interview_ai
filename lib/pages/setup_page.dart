import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/interview_config.dart';
import 'chat_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String _difficulty = 'medium';
  String _hrdStyle = 'friendly';

  final _difficulties = const [
    {'label': 'Mudah', 'value': 'easy'},
    {'label': 'Sedang', 'value': 'medium'},
    {'label': 'Sulit', 'value': 'hard'},
  ];

  final _styles = const [
    {'label': 'Ramah', 'value': 'friendly'},
    {'label': 'Tegas', 'value': 'strict'},
    {'label': 'Teknis', 'value': 'technical'},
    {'label': 'Behavioral', 'value': 'behavioral'},
  ];

  void _start() {
    final cfg = InterviewConfig(difficulty: _difficulty, hrdStyle: _hrdStyle);
    Get.to(() => ChatPage(), arguments: cfg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Interview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih tingkat kesulitan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _difficulties
                  .map((e) => DropdownMenuItem(
                        value: e['value']!,
                        child: Text(e['label']!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
            ),
            const SizedBox(height: 20),
            const Text('Pilih gaya HRD', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _hrdStyle,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _styles
                  .map((e) => DropdownMenuItem(
                        value: e['value']!,
                        child: Text(e['label']!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _hrdStyle = v ?? _hrdStyle),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Interview'),
                onPressed: _start,
              ),
            )
          ],
        ),
      ),
    );
  }
}
