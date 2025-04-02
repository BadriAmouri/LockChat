// views/screens/incoming_requests.dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/request_item.dart';
import '../widgets/wave_clipper.dart';
import 'send_request_screen.dart';

class ChatRequestListScreen extends StatefulWidget {
  const ChatRequestListScreen({super.key});

  @override
  State<ChatRequestListScreen> createState() => _ChatRequestListScreenState();
}

class _ChatRequestListScreenState extends State<ChatRequestListScreen> {
  // Sample request data - in a real app, this would come from a service or API
  final List<Map<String, dynamic>> _requests = [
    {'username': 'sarah_92', 'date': '2025/04/01', 'id': '1'},
    {'username': 'john_doe', 'date': '2025/03/30', 'id': '2'},
    {'username': 'tech_guru', 'date': '2025/03/29', 'id': '3'},
    {'username': 'creative_mind', 'date': '2025/03/28', 'id': '4'},
    {'username': 'flutter_dev', 'date': '2025/03/27', 'id': '5'},
  ];

  void _handleConfirm(String requestId) {
    //logic to accept the request
    setState(() {
      _requests.removeWhere((request) => request['id'] == requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted!'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _handleDecline(String requestId) {
    //logic to decline the request
    setState(() {
      _requests.removeWhere((request) => request['id'] == requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request declined'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SendRequestScreen()),
          );
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Purple wave top decoration
          Stack(
            children: [
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 200,
                  color: AppColors.darkpurple.withOpacity(0.8),
                ),
              ),
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: const [
                      Text(
                        'PWA',
                        style: TextStyle(
                          fontSize: 40,
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
                      SizedBox(height: 10),
                      Text(
                        'Chat Requests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: 50,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),

          // Request count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Requests (${_requests.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Send Request button
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SendRequestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Request'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkpurple,
                  ),
                ),
              ],
            ),
          ),

          // Request list
          Expanded(
            child:
                _requests.isEmpty
                    ? const Center(
                      child: Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.subtitle,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return RequestItem(
                          username: request['username'],
                          date: request['date'],
                          onConfirm: () => _handleConfirm(request['id']),
                          onDecline: () => _handleDecline(request['id']),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
