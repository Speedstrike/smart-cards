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
import 'package:flutter/services.dart';

import '../constants.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _topicController.addListener(_validateInputs);
    _countController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final topic = _topicController.text.trim();
    final count = int.tryParse(_countController.text);
    final valid = topic.isNotEmpty && count != null && count > 0;
    if (valid != _isValid) {
      setState(() {
        _isValid = valid;
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Constants.aiTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue
                    )
                  ),
                  SizedBox(height: 8),
                  Text(
                    Constants.aiInstructions,
                    style: TextStyle(
                      fontSize: 20,
                      color: CupertinoColors.systemBackground
                    )
                  )
                ]
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoTextField(
                      controller: _topicController,
                      placeholder: Constants.aiTopicPlaceholder,
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.inactiveGray
                      ),
                      style: TextStyle(color: CupertinoColors.white),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8)
                      )
                    ),
                    SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _countController,
                      placeholder: Constants.aiCountPlaceholder,
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.inactiveGray
                      ),
                      style: TextStyle(color: CupertinoColors.white),
                      padding: EdgeInsets.all(12),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8)
                      )
                    ),
                    if (_isValid) ...[
                      SizedBox(height: 16),
                      CupertinoButton.filled(
                        child: Text(Constants.continueButtonText),
                        onPressed: () {}
                      )
                    ]
                  ]
                )
              )
            ]
          )
        )
      )
    );
  }
}
