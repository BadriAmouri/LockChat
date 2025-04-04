import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/wave_clipper.dart';

class HeaderWaveWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const HeaderWaveWidget({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

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
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 45,
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
