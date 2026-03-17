import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pocketcrm/core/di/providers.dart';

part 'voice_note_provider.freezed.dart';
part 'voice_note_provider.g.dart';

enum VoiceNoteStatus { idle, recording, transcribing, review, error }

@freezed
class VoiceNoteState with _$VoiceNoteState {
  factory VoiceNoteState({
    @Default(VoiceNoteStatus.idle) VoiceNoteStatus status,
    @Default('') String transcribedText,
    @Default(0) int recordingSeconds,
    String? errorMessage,
  }) = _VoiceNoteState;
}

@riverpod
class VoiceNoteNotifier extends _$VoiceNoteNotifier {
  final SpeechToText _speech = SpeechToText();
  Timer? _timer;

  @override
  VoiceNoteState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _speech.cancel();
    });
    return VoiceNoteState();
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = state.copyWith(
        status: VoiceNoteStatus.error,
        errorMessage: 'Microphone permission denied',
      );
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (val) {
          state = state.copyWith(
            status: VoiceNoteStatus.error,
            errorMessage: 'Speech recognition error: ${val.errorMsg}',
          );
          _stopTimer();
        },
      );

      if (!available) {
        state = state.copyWith(
          status: VoiceNoteStatus.error,
          errorMessage: 'Speech-to-Text not available on this device',
        );
        return;
      }

      state = state.copyWith(
        status: VoiceNoteStatus.recording,
        recordingSeconds: 0,
        transcribedText: '',
        errorMessage: null,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.recordingSeconds >= 120) {
          stopRecording();
        } else {
          state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
        }
      });

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            state = state.copyWith(
              status: VoiceNoteStatus.review,
              transcribedText: result.recognizedWords,
            );
          }
        },
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 120),
      );
    } catch (e) {
      state = state.copyWith(
        status: VoiceNoteStatus.error,
        errorMessage: 'Error initializing speech-to-text: $e',
      );
    }
  }

  Future<void> stopRecording() async {
    _stopTimer();
    state = state.copyWith(status: VoiceNoteStatus.transcribing);
    await _speech.stop();
    // In case no speech was detected, speech_to_text won't emit finalResult.
    // Wait a little bit for the final result to arrive.
    // If it's already review state, we do nothing.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.status == VoiceNoteStatus.transcribing) {
         state = state.copyWith(
            status: VoiceNoteStatus.review,
            transcribedText: '',
          );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _stopTimer();
    _speech.stop();
    state = VoiceNoteState();
  }

  Future<void> saveNote(String contactId, String text) async {
    state = state.copyWith(status: VoiceNoteStatus.transcribing); // Using transcribing as loading state
    try {
      final repo = await ref.read(crmRepositoryProvider.future);
      await repo.createNote(
        contactId: contactId,
        body: '🎤 $text',
      );
      // Invalidate the provider
      ref.invalidate(contactNotesProvider(contactId));
      state = state.copyWith(status: VoiceNoteStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: VoiceNoteStatus.error,
        errorMessage: 'Error saving note: $e',
      );
    }
  }
}
