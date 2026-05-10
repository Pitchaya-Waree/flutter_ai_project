import 'package:flutter/material.dart';

class MathSolverBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const MathSolverBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.camera_alt_outlined),
              label: 'Scan',
              activeIcon: _buildActiveIcon(Icons.camera_alt_outlined),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calculate_outlined),
              label: 'Editor',
              activeIcon: _buildActiveIcon(Icons.calculate_outlined),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.summarize_outlined),
              label: 'Solutions',
              activeIcon: _buildActiveIcon(Icons.summarize_outlined),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              label: 'History',
              activeIcon: _buildActiveIcon(Icons.history_outlined),
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActiveIcon(IconData iconData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[100],
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: Colors.green[800], size: 28),
    );
  }
}