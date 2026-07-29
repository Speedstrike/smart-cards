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

import 'results_screen.dart';

import '../constants.dart';
import '../services/openrouter.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  bool _isValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  CardDifficulty _difficulty = CardDifficulty.intermediate;
  CardTone _tone = CardTone.academic;
  CardStyle _style = CardStyle.questionAnswer;
  AnswerLength _answerLength = AnswerLength.medium;

  @override
  void initState() {
    super.initState();
    _topicController.addListener(_validateInputs);
    _countController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    final topic = _topicController.text.trim();
    final count = int.tryParse(_countController.text);
    final valid = topic.isNotEmpty && count != null && count > 0;
    if (valid != _isValid) setState(() => _isValid = valid);
  }

  FlashcardGenerationOptions get _generationOptions {
    return FlashcardGenerationOptions(difficulty: _difficulty, tone: _tone, style: _style, answerLength: _answerLength);
  }

  String _difficultyLabel(CardDifficulty difficulty) {
    return switch (difficulty) {
      CardDifficulty.introductory => Constants.generationDifficultyIntroductory,
      CardDifficulty.intermediate => Constants.generationDifficultyIntermediate,
      CardDifficulty.advanced => Constants.generationDifficultyAdvanced
    };
  }

  String _toneLabel(CardTone tone) {
    return switch (tone) {
      CardTone.concise => Constants.generationToneConcise,
      CardTone.friendly => Constants.generationToneFriendly,
      CardTone.academic => Constants.generationToneAcademic
    };
  }

  String _styleLabel(CardStyle style) {
    return switch (style) {
      CardStyle.questionAnswer => Constants.generationStyleQA,
      CardStyle.cloze => Constants.generationStyleCloze,
      CardStyle.multipleChoice => Constants.generationStyleMultipleChoice
    };
  }

  String _answerLengthLabel(AnswerLength length) {
    return switch (length) {
      AnswerLength.short => Constants.generationAnswerShort,
      AnswerLength.medium => Constants.generationAnswerMedium,
      AnswerLength.detailed => Constants.generationAnswerDetailed
    };
  }

  Future<T?> _showChoiceSheet<T>({required String title, required List<(T value, String label)> choices}) async {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(title),
        actions: choices.map((choice) => CupertinoActionSheetAction(onPressed: () => Navigator.of(popupContext).pop(choice.$1), child: Text(choice.$2))).toList(),
        cancelButton: CupertinoActionSheetAction(isDefaultAction: true, onPressed: () => Navigator.of(popupContext).pop(), child: const Text(Constants.aiSettingsDone))
      )
    );
  }

  Future<void> _pickDifficulty() async {
    final value = await _showChoiceSheet<CardDifficulty>(
      title: Constants.aiDifficultyLabel,
      choices: const [
        (CardDifficulty.introductory, Constants.generationDifficultyIntroductory),
        (CardDifficulty.intermediate, Constants.generationDifficultyIntermediate),
        (CardDifficulty.advanced, Constants.generationDifficultyAdvanced)
      ]
    );
    if (value != null) setState(() => _difficulty = value);
  }

  Future<void> _pickTone() async {
    final value = await _showChoiceSheet<CardTone>(
      title: Constants.aiToneLabel,
      choices: const [
        (CardTone.concise, Constants.generationToneConcise),
        (CardTone.friendly, Constants.generationToneFriendly),
        (CardTone.academic, Constants.generationToneAcademic)
      ]
    );
    if (value != null) setState(() => _tone = value);
  }

  Future<void> _pickStyle() async {
    final value = await _showChoiceSheet<CardStyle>(
      title: Constants.aiStyleLabel,
      choices: const [
        (CardStyle.questionAnswer, Constants.generationStyleQA),
        (CardStyle.cloze, Constants.generationStyleCloze),
        (CardStyle.multipleChoice, Constants.generationStyleMultipleChoice)
      ]
    );
    if (value != null) setState(() => _style = value);
  }

  Future<void> _pickAnswerLength() async {
    final value = await _showChoiceSheet<AnswerLength>(
      title: Constants.aiAnswerLengthLabel,
      choices: const [
        (AnswerLength.short, Constants.generationAnswerShort),
        (AnswerLength.medium, Constants.generationAnswerMedium),
        (AnswerLength.detailed, Constants.generationAnswerDetailed)
      ]
    );
    if (value != null) setState(() => _answerLength = value);
  }

  Widget _optionRow({required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Constants.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Constants.border)
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                    )
                  )
                ]
              )
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 18, color: CupertinoColors.activeBlue)
          ]
        )
      )
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Constants.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Constants.aiSettingsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue
            )
          ),
          const SizedBox(height: 4),
          Text(
            Constants.aiSettingsSubtitle,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey
            )
          ),
          const SizedBox(height: 16),
          _optionRow(label: Constants.aiDifficultyLabel, value: _difficultyLabel(_difficulty), onTap: _pickDifficulty),
          const SizedBox(height: 12),
          _optionRow(label: Constants.aiToneLabel, value: _toneLabel(_tone), onTap: _pickTone),
          const SizedBox(height: 12),
          _optionRow(label: Constants.aiStyleLabel, value: _styleLabel(_style), onTap: _pickStyle),
          const SizedBox(height: 12),
          _optionRow(label: Constants.aiAnswerLengthLabel, value: _answerLengthLabel(_answerLength), onTap: _pickAnswerLength)
        ]
      )
    );
  }

  Future<void> _generateFlashcards() async {
    if (!_isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topic = _topicController.text.trim();
      final count = int.parse(_countController.text);
      final flashcards = await OpenRouter.generateFlashcards(topic: topic, count: count, options: _generationOptions);

      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ResultsScreen(flashcards: flashcards, title: topic)
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
      if (mounted) setState(() => _isLoading = false);
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.activeBlue, size: 40)
        ),
        border: null
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              Constants.aiTitle,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue
              )
            ),
            const SizedBox(height: 8),
            const Text(
              Constants.aiInstructions,
              style: TextStyle(
                fontSize: 20,
                color: CupertinoColors.systemBackground
              )
            ),
            const SizedBox(height: 24),
            _buildAdvancedSettings(),
            const SizedBox(height: 14),
            CupertinoTextField(
              controller: _topicController,
              placeholder: Constants.aiTopicPlaceholder,
              placeholderStyle: const TextStyle(color: CupertinoColors.inactiveGray),
              style: const TextStyle(color: CupertinoColors.white),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Constants.inputBackground,
                borderRadius: BorderRadius.circular(8)
              )
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _countController,
              placeholder: Constants.flashcardCountPlaceholder,
              placeholderStyle: const TextStyle(color: CupertinoColors.inactiveGray),
              style: const TextStyle(color: CupertinoColors.white),
              padding: const EdgeInsets.all(12),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: BoxDecoration(
                color: Constants.inputBackground,
                borderRadius: BorderRadius.circular(8)
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
            const SizedBox(height: 16),
            if (_isLoading)
              const CupertinoActivityIndicator(radius: 16)
            else if (_isValid)
              CupertinoButton.filled(
                onPressed: _generateFlashcards,
                child: Text(Constants.continueButtonText)
              )
          ]
        )
      )
    );
  }
}