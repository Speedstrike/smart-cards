// MIT License
//
// Copyright (c) 2026 Aaryan Karlapalem
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'dart:io';

import 'results_screen.dart';

import '../constants.dart';
import '../services/openrouter.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _scannedImage;
  bool _isLoading = false;
  bool _isExtracting = false;
  String? _errorMessage;
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _recognizedTextController = TextEditingController();
  late final TextRecognizer _textRecognizer;

  bool get _isCountValid {
    final count = int.tryParse(_countController.text);
    return count != null && count > 0;
  }

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void dispose() {
    _countController.dispose();
    _recognizedTextController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _scanImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _scannedImage = File(pickedFile.path);
        _errorMessage = null;
        _recognizedTextController.clear();
      });
      await _extractTextFromImage();
    }
  }

  Future<void> _extractTextFromImage() async {
    if (_scannedImage == null) return;

    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _errorMessage = Constants.scanOcrUnavailable;
      });
      return;
    }

    setState(() {
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(_scannedImage!.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text.trim();

      if (extractedText.isEmpty) {
        setState(() {
          _errorMessage = Constants.scanOcrEmpty;
        });
      }
      else {
        _recognizedTextController.text = extractedText;
      }
    }
    catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
    finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  Future<void> _processImage() async {
    if (_scannedImage == null || !_isCountValid) return;

    final recognizedText = _recognizedTextController.text.trim();
    if (recognizedText.isEmpty) {
      setState(() {
        _errorMessage = Constants.scanOcrEmpty;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final flashcards = await OpenRouter.processText(
        text: recognizedText,
        count: int.parse(_countController.text)
      );

      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ResultsScreen(flashcards: flashcards, title: 'From Scan')
          )
        );
      }
    }
    catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
            size: 40
          ),
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
        border: null
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              Constants.scanTitle,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue
              )
            ),
            const SizedBox(height: 8),
            Text(
              Constants.scanInstructions,
              style: const TextStyle(
                fontSize: 20,
                color: CupertinoColors.systemBackground
              )
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading? null : _scanImage,
                    child: Icon(
                      CupertinoIcons.camera_on_rectangle,
                      size: 100,
                      color: _isLoading? CupertinoColors.systemGrey : CupertinoColors.systemTeal
                    )
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _scannedImage == null? Constants.scanTitle : Constants.scanRetakeButton,
                    style: TextStyle(
                      fontSize: 18,
                      color: _isLoading? CupertinoColors.systemGrey : CupertinoColors.systemTeal,
                      fontWeight: FontWeight.w500
                    )
                  )
                ]
              )
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemRed)
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 14
                  )
                )
              )
            ],
            if (_scannedImage != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _scannedImage!,
                    height: 220,
                    fit: BoxFit.cover
                  )
                )
              ),
              const SizedBox(height: 16),
              if (_isExtracting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      CupertinoActivityIndicator(radius: 16),
                      SizedBox(height: 12),
                      Text(
                        Constants.scanRecognizingText,
                        style: TextStyle(
                          color: CupertinoColors.systemGrey2,
                          fontSize: 14
                        )
                      )
                    ]
                  )
                )
              else ...[
                Text(
                  Constants.scanRecognizedTextLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white
                  )
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _recognizedTextController,
                  placeholder: Constants.scanOcrPlaceholder,
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.inactiveGray
                  ),
                  style: const TextStyle(color: CupertinoColors.white),
                  padding: const EdgeInsets.all(12),
                  maxLines: 8,
                  minLines: 4,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: BoxDecoration(
                    color: Constants.inputBackground,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  onChanged: (_) => setState(() {})
                )
              ],
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _countController,
                placeholder: Constants.flashcardCountPlaceholder,
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.inactiveGray
                ),
                style: const TextStyle(color: CupertinoColors.white),
                padding: const EdgeInsets.all(12),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: BoxDecoration(
                  color: Constants.inputBackground,
                  borderRadius: BorderRadius.circular(8)
                ),
                onChanged: (_) => setState(() {})
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CupertinoActivityIndicator(radius: 16))
              else
                CupertinoButton.filled(
                  onPressed:(_isCountValid && !_isExtracting && _recognizedTextController.text.trim().isNotEmpty)? _processImage : null,
                  child: Text(Constants.continueButtonText)
                ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _isExtracting? null : _extractTextFromImage,
                child: const Text(Constants.scanExtractButton)
              )
            ]
          ]
        )
      )
    );
  }
}