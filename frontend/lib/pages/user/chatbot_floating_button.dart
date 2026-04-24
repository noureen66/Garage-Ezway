import 'package:flutter/material.dart';
import 'package:frontend/pages/user/faq.dart';

class ChatbotFloatingButton extends StatefulWidget {
  const ChatbotFloatingButton({super.key});

  @override
  _ChatbotFloatingButtonState createState() => _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState extends State<ChatbotFloatingButton> {
  double posX = 300;
  double posY = 600;
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const buttonSize = 60.0;
    final minTop = padding.top + 120;
    return Stack(
      children: [
        Container(),
        Positioned(
          left: posX,
          top: posY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                posX += details.delta.dx;
                posY += details.delta.dy;
                final maxTop = screenSize.height - buttonSize - padding.bottom;
                if (posY < minTop) posY = minTop;
                if (posY > maxTop) posY = maxTop;
              });
            },
            onPanEnd: (details) {
              setState(() {
                if (posX + buttonSize / 2 < screenSize.width / 2) {
                  posX = 0;
                } else {
                  posX = screenSize.width - buttonSize;
                }
              });
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQPage()),
              );
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.android, color: Colors.black87, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}
