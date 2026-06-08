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

import 'package:file_picker/file_picker.dart';

import 'dart:io';

import 'results_screen.dart';

import '../constants.dart';
import '../services/openrouter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _fileName;
  File? _selectedFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.first.name;
        _selectedFile = File(result.files.first.path!);
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contents = await _selectedFile!.readAsString();
      final flashcards = await OpenRouter.processText(
        text: contents,
        count: 10
      );

      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ResultsScreen(
              flashcards: flashcards,
              title: _fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'Flashcards'
            )
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
                    Constants.uploadTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Constants.uploadInstructions,
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
                          onPressed: _isLoading ? null : _pickFiles,
                          child: Icon(
                            CupertinoIcons.cloud_upload,
                            size: 100,
                            color: _isLoading? CupertinoColors.systemGrey : CupertinoColors.systemTeal
                          )
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload files',
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
                              color: CupertinoColors.systemRed.withOpacity(0.1),
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
                        if (_fileName != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Selected: $_fileName',
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.activeBlue
                            )
                          ),
                          const SizedBox(height: 100),
                          if (_isLoading)
                            const CupertinoActivityIndicator(radius: 16)
                          else
                            CupertinoButton.filled(
                              onPressed: _processFile,
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