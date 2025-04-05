import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/wave_clipper.dart';

class HeaderWidget extends StatelessWidget {
  final String text;

  const HeaderWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom Light Purple Wave
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: 220,
            color: const Color.fromARGB(255, 209, 189, 230), // Light Purple
          ),
        ),
        // Top Dark Purple Wave
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: 200,
            color: AppColors.darkpurple.withOpacity(0.8),
          ),
        ),
        // Text and Back Button
        Positioned(
          top: 40,
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 3,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
