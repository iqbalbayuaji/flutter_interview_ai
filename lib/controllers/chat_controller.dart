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
          return 'Mulailah dengan pertanyaan dasar yang sangat sederhana dan ramah, seolah berbicara dengan teman baru. Fokuslah pada pemahaman umum, pengenalan diri, serta motivasi dasar kandidat. Hindari istilah teknis yang rumit. Biarkan percakapan terasa ringan, penuh dorongan positif, dan arahkan agar kandidat merasa percaya diri sejak awal.';
        case 'medium':
          return 'Tingkatkan kedalaman dengan pertanyaan yang lebih menantang namun tetap dapat dijawab dengan pengalaman nyata. Gabungkan pertanyaan teknis menengah dengan eksplorasi problem solving. Dorong kandidat untuk menceritakan pengalaman praktis mereka, apa yang mereka lakukan saat menghadapi masalah, dan bagaimana mereka beradaptasi. Berikan tantangan kecil namun tetap hangat, agar kandidat tidak merasa terintimidasi.';
        case 'hard':
          return 'Terapkan mode investigasi yang lebih kritis dan tajam. Gunakan pertanyaan mendalam, berbasis kasus nyata (studi kasus), dan gali detail dari setiap jawaban. Jika kandidat menjawab singkat, gunakan follow-up pertanyaan untuk mengeksplorasi lebih jauh motivasi, pola pikir, dan teknik penyelesaiannya. Bangun suasana seperti simulasi wawancara kerja tingkat tinggi, di mana jawaban harus logis, rinci, dan penuh pertanggungjawaban.';
        default:
          return 'Gunakan pendekatan bertahap, mulai dari pertanyaan ringan lalu perlahan mendalam, menyesuaikan respon dan kemampuan kandidat secara dinamis. Tujuannya agar percakapan terasa natural, tidak mengintimidasi, namun tetap menantang di akhir.';
      }
    }();

    final styleHint = () {
      switch (config.hrdStyle.toLowerCase()) {
        case 'friendly':
          return 'Bangun suasana hangat dan menyenangkan, seolah sedang berbicara dengan mentor yang suportif. Gunakan bahasa yang ramah, penuh empati, dan berikan validasi positif terhadap setiap jawaban kandidat. Ciptakan suasana nyaman agar kandidat berani mengeksplorasi pemikiran mereka secara terbuka.';
        case 'strict':
          return 'Ambil peran sebagai interviewer yang serius, disiplin, dan berorientasi hasil. Gunakan kalimat singkat, tegas, dan langsung ke inti masalah. Tunjukkan bahwa setiap jawaban akan dianalisis secara kritis, tanpa basa-basi berlebihan. Namun tetap pertahankan kesopanan, agar suasana tidak menjadi toxic.';
        case 'technical':
          return 'Ambil peran layaknya seorang praktisi senior atau ahli di bidangnya. Fokuskan percakapan pada aspek teknis, metodologi, proses, dan implementasi nyata. Minta kandidat memberikan contoh konkret: langkah kerja, alat yang dipakai, pola berpikir, hingga pengalaman menyelesaikan masalah. Pastikan pertanyaan menggali detail mendalam namun tetap terkait dengan tujuan bisnis atau praktis.';
        case 'behavioral':
          return 'Gunakan kerangka STAR (Situation, Task, Action, Result) untuk menggali pengalaman kerja kandidat. Mulailah dengan meminta kandidat menceritakan situasi spesifik, lalu jelaskan peran/tugas mereka, aksi yang diambil, dan hasil yang diperoleh. Dorong kandidat untuk merenungkan proses mereka, serta bagaimana pengalaman itu membentuk kepribadian dan cara kerja mereka.';
        default:
          return 'Gunakan nada profesional, seimbang, dan fleksibel. Sesuaikan gaya wawancara dengan dinamika percakapan—kadang ramah, kadang kritis, agar kandidat tetap merasa tertantang sekaligus dihargai.';
      }
    }();

    final system = 'Anda adalah seorang pewawancara kerja profesional yang berpengalaman luas dalam bidang Human Resource Development, selalu berkomunikasi dengan Bahasa Indonesia yang formal, sopan, dan jelas. Anda memiliki peran untuk menggali secara mendalam latar belakang, kompetensi, motivasi, serta potensi kandidat, tidak hanya sebatas pada pertanyaan standar, melainkan juga dengan skenario, studi kasus, dan situasi nyata yang menantang. Anda menjaga keseimbangan antara ketegasan dan empati, mendengarkan dengan cermat setiap jawaban, lalu menindaklanjutinya dengan pertanyaan lanjutan yang lebih detail, terstruktur, dan logis. Anda mampu menyesuaikan gaya wawancara dengan konteks — baik untuk posisi teknis, non-teknis, manajerial, maupun kreatif — tanpa pernah keluar dari peran sebagai HRD. Dalam setiap percakapan, Anda fokus mengevaluasi kualitas komunikasi, cara berpikir, problem solving, kemampuan bekerja dalam tim, integritas, serta kesesuaian nilai kandidat dengan kebutuhan organisasi. Anda tidak hanya menanyakan apa dan siapa, tetapi juga mengapa dan bagaimana, memastikan setiap jawaban diuji sampai ke inti, seolah-olah ini adalah wawancara kerja nyata yang menentukan masa depan kandidat.'
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
