import 'package:flutter/material.dart';
import '../../speech_service.dart';
import '../../text_normalizer.dart';
import '../../services/llm_service.dart';
import '../../models/medicine.dart';

import '../widgets/status_card.dart';
import '../widgets/mic_button.dart';
import '../widgets/header_section.dart';
import '../widgets/medicine_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _speech = SpeechService();
  final _llm = LlmService();

  bool _listening = false;
  bool _loading = false;

  String _text = 'Tap mic to start';
  String _liveTranscription = '';
  String _language = 'Detecting...';

  List<Medicine> _medicines = [];

  @override
  void initState() {
    super.initState();
    _detectLanguage();
  }

  Future<void> _detectLanguage() async {
    final languages = await _speech.getAvailableLanguages();
    if (mounted) {
      setState(() {
        _language = languages.contains('en_IN')
            ? '🇮🇳 English (en_IN)'
            : '🇺🇸 English';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_listening) {
      // STOP
      final text = await _speech.stopListening();

      setState(() {
        _listening = false;
        _loading = true;
        _liveTranscription = '';
      });

      await _process(text ?? '');
    } else {
      // START
      setState(() {
        _listening = true;
        _text = "Listening...";
        _medicines = [];
      });

      await _speech.startListening(
        onPartialResult: (t) {
          if (mounted) {
            setState(() => _liveTranscription = t);
          }
        },
        onFinalResult: (t) async {
          if (!mounted) return;

          setState(() {
            _listening = false;
            _loading = true;
          });

          await _process(t);
        },
      );
    }
  }

  Future<void> _process(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
        _text = "⚠️ No speech detected";
      });
      return;
    }

    // ✅ Normalize text
    final normalized = TextNormalizer.normalize(trimmed);

    setState(() {
      _loading = true;
      _text = "Processing prescription...";
      _medicines = [];
    });

    // ✅ Call backend
    final meds = await _llm.extractMedicines(normalized);

    setState(() {
      _loading = false;
    });

    if (meds == null || meds.isEmpty) {
      setState(() {
        _text = "⚠️ No medicines found";
      });
      return;
    }

    setState(() {
      _medicines = meds;
    });
  }

  void _updateMedicine(Medicine oldMed, Medicine updatedMed) {
    setState(() {
      final index = _medicines.indexOf(oldMed);
      if (index != -1) {
        _medicines[index] = updatedMed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔝 Header
            HeaderSection(language: _language),

            // 📊 Main content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _listening
                      ? StatusCard(
                          listening: true,
                          loading: false,
                          text: _text,
                          liveText: _liveTranscription,
                        )
                      : _medicines.isNotEmpty
                          ? ListView(
                              children: _medicines
                                  .map(
                                    (m) => MedicineCard(
                                      med: m,
                                      onUpdated: (updated) =>
                                          _updateMedicine(m, updated),
                                    ),
                                  )
                                  .toList(),
                            )
                          : Center(
                              child: Text(
                                _text,
                                textAlign: TextAlign.center,
                              ),
                            ),
            ),

            // 🎤 Mic + footer
            Column(
              children: [
                MicButton(
                  listening: _listening,
                  onTap: _toggleRecording,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Speak clearly. Auto stops after silence.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}