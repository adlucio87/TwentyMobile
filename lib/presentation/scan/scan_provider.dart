import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/services/business_card_parser.dart';

part 'scan_provider.freezed.dart';
part 'scan_provider.g.dart';

enum ScanStatus { idle, processing, done, error }

@freezed
class ScanState with _$ScanState {
  factory ScanState({
    @Default(ScanStatus.idle) ScanStatus status,
    BusinessCardData? parsedData,
    String? rawText,
    String? errorMessage,
  }) = _ScanState;
}

@Riverpod(keepAlive: true)
class ScanNotifier extends _$ScanNotifier {
  @override
  ScanState build() {
    if (kDebugMode) debugPrint('SCAN: ScanNotifier build() called (isNew: true)');
    ref.keepAlive();
    return ScanState();
  }

  Future<void> processImage(XFile imageFile) async {
    state = state.copyWith(status: ScanStatus.processing);
    if (kDebugMode) debugPrint('SCAN: Starting processImage for ${imageFile.path}');

    try {
      // 1. ML Kit OCR
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final rawText = recognized.text;
      if (kDebugMode) {
        debugPrint('SCAN: OCR Raw Text length: ${rawText.length}');
        debugPrint('SCAN: OCR Raw Text: \n$rawText');
      }

      if (rawText.trim().isEmpty) {
        if (kDebugMode) debugPrint('SCAN: Error - Raw text is empty');
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: 'No text found. Try again with a clearer photo.',
        );
        return;
      }

      // 2. Parsing algoritmo
      final parsed = BusinessCardParser.parse(rawText);

      if (kDebugMode) {
        debugPrint('SCAN: Parsing complete. Confidence: ${parsed.confidence}');
        debugPrint('SCAN: Parsed Data: $parsed');
      }

      if (!parsed.hasMinimumData) {
        if (kDebugMode) debugPrint('SCAN: Error - Not enough data found');
        state = state.copyWith(
          status: ScanStatus.error,
          errorMessage: 'Unable to read the card. Please try again.',
        );
        return;
      }

      state = state.copyWith(
        status: ScanStatus.done,
        parsedData: parsed,
        rawText: rawText,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('SCAN: Catch error: $e');
        debugPrint('SCAN: Stack trace: $stack');
      }
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Error during scan: $e',
      );
    }
  }

  void reset() => state = ScanState();
}