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

import 'package:image_picker/image_picker.dart';

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
  String? _errorMessage;

  Future<void> _scanImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _scannedImage = File(pickedFile.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _processImage() async {
    if (_scannedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const placeholderText = 'Please ensure the image contains text or notes to convert to flashcards.';

      final flashcards = await OpenRouter.processText(text: placeholderText, count: 5);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 175),
                  Center(
                    child: Column(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isLoading ? null : _scanImage,
                          child: Icon(
                            CupertinoIcons.camera_on_rectangle,
                            size: 100,
                            color: _isLoading? CupertinoColors.systemGrey : CupertinoColors.systemTeal
                          )
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Constants.scanTitle,
                          style: TextStyle(
                            fontSize: 18,
                            color: _isLoading? CupertinoColors.systemGrey : CupertinoColors.systemTeal,
                            fontWeight: FontWeight.w500
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
                                height: 200,
                                fit: BoxFit.cover
                              )
                            )
                          ),
                          const SizedBox(height: 100),
                          if (_isLoading)
                            const CupertinoActivityIndicator(radius: 16)
                          else
                            CupertinoButton.filled(
                              onPressed: _processImage,
                              child: Text(Constants.continueButtonText)
                            )
                        ]
                      ]
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}