import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../models/message.dart';
import '../services/groq_service.dart';
import '../models/interview_config.dart';

class ChatController extends GetxController {
  final InterviewConfig config;
  ChatController({required this.config});

  final messages = <Message>[].obs;
  final textController = TextEditingController();
  final isListening = false.obs;
  final isLoading = false.obs;

  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final _groq = GroqService();

  @override
  void onInit() {
    super.onInit();
    _initTts();
    // Optional: greeting or instructions
    messages.add(
      Message(
        sender: Sender.ai,
        text:
            'Halo! Sesi interview siap dimulai. Kesulitan: ${config.difficulty}. Gaya HRD: ${config.hrdStyle}. Tekan ikon mikrofon untuk menjawab dengan suara atau ketik pesan lalu kirim.',
      ),
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  List<Map<String, String>> _toGroqMessages() {
    final difficultyHint = () {
      switch (config.difficulty.toLowerCase()) {
        case 'easy':
          return 'Pertanyaan sederhana, fokus pada dasar-dasar, tempo santai.';
        case 'medium':
          return 'Pertanyaan menengah, eksplorasi pengalaman dan problem solving.';
        case 'hard':
          return 'Pertanyaan mendalam, tantang kandidat dengan studi kasus dan follow-up.';
        default:
          return 'Pertanyaan bertahap menyesuaikan kemampuan kandidat.';
      }
    }();

    final styleHint = () {
      switch (config.hrdStyle.toLowerCase()) {
        case 'friendly':
          return 'Nada ramah, suportif, dan membangun kepercayaan diri.';
        case 'strict':
          return 'Nada tegas, to the point, dan kritis namun tetap sopan.';
        case 'technical':
          return 'Fokus pada aspek teknis, minta contoh konkret dan detail implementasi.';
        case 'behavioral':
          return 'Fokus pada perilaku, gunakan kerangka STAR (Situation, Task, Action, Result).';
        default:
          return 'Nada profesional dan seimbang.';
      }
    }();

    final system = 'Anda adalah pewawancara kerja profesional. Bahasa: Indonesia. '
        'Konfigurasi: Kesulitan=${config.difficulty}, Gaya HRD=${config.hrdStyle}. '
        'Panduan kesulitan: $difficultyHint '
        'Panduan gaya: $styleHint '
        'Aturan: ajukan satu pertanyaan per giliran, berikan umpan balik ringkas dan tips praktis saat perlu.';

    final history = <Map<String, String>>[
      {'role': 'system', 'content': system}
    ];
    for (final m in messages) {
      history.add({
        'role': m.sender == Sender.user ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    return history;
  }

  Future<void> sendText() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    textController.clear();
    messages.add(Message(sender: Sender.user, text: text));
    await _askGroq();
  }

  Future<void> _askGroq() async {
    try {
      isLoading.value = true;
      final reply = await _groq.chat(_toGroqMessages());
      final msg = Message(sender: Sender.ai, text: reply);
      messages.add(msg);
      await speak(msg.text);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleListening() async {
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
      return;
    }

    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (e) {
        isListening.value = false;
        Get.snackbar('Speech error', e.errorMsg);
      },
    );

    if (!available) {
      Get.snackbar('Speech', 'Speech recognition tidak tersedia');
      return;
    }

    isListening.value = true;
    await _speech.listen(
      localeId: 'id_ID',
      onResult: (result) async {
        final text = result.recognizedWords.trim();
        if (result.finalResult && text.isNotEmpty) {
          isListening.value = false;
          messages.add(Message(sender: Sender.user, text: text));
          await _speech.stop();
          await _askGroq();
        }
      },
    );
  }

  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  void onClose() {
    textController.dispose();
    _speech.stop();
    _tts.stop();
    super.onClose();
  }
}
