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

import 'screens/create_screen.dart';

class GradientButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const GradientButton({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap
  });

  @override
  GradientButtonState createState() => GradientButtonState();
}

class GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double iconBoxSize = 64;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        height: CreateScreen.buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [CupertinoColors.activeBlue, CupertinoColors.systemPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4)
            )
          ]
        ),
        padding: const EdgeInsets.only(left: 0, right: 16),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: CreateScreen.buttonHeight,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 7),
              child: Icon(
                widget.icon,
                color: CupertinoColors.systemBackground,
                size: iconBoxSize * 0.7
              )
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: CupertinoColors.systemBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1
                    )
                  ),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: CupertinoColors.systemBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.normal
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