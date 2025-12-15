import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';
import 'chat.dart';


class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      // 0: Home
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${user?.email ?? 'Student'} 👋",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "This is the student home page.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),

      // 1: Profile
      const Center(child: Text("Profile Page", style: TextStyle(fontSize: 20))),

      // 2: Study
      const Center(child: Text("Study Page", style: TextStyle(fontSize: 20))),

      // 3: Chat
      const ChatPage(),

      // 4: Message ⭐ NEW
      const Center(child: Text("Message Page", style: TextStyle(fontSize: 20))),
      // 4: Settings (Logout)
      Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Logout"),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Student Home")),

      body: pages[_selectedIndex],

      // ⭐ Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Study"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Message"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
