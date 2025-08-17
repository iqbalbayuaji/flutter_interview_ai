import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../models/interview_config.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final InterviewConfig _config = Get.arguments as InterviewConfig;
  late final ChatController c = Get.put(ChatController(config: _config));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: c.messages.length,
                itemBuilder: (_, i) {
                  final m = c.messages[i];
                  final isUser = m.sender == Sender.user;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() => c.isLoading.value ? const LinearProgressIndicator(minHeight: 2) : const SizedBox(height: 2)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c.textController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...'
                      ),
                      onSubmitted: (_) => c.sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: c.sendText,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            onPressed: c.toggleListening,
            label: Text(c.isListening.value ? 'Mendengarkan...' : 'Bicara'),
            icon: Icon(c.isListening.value ? Icons.hearing : Icons.mic),
          )),
    );
  }
}
