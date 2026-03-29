import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  void _next() {
    if (_currentStep < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.go('/home');
    }
  }

  void _skip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Onboarding Step ${_currentStep + 1}/5'),
        actions: [
          TextButton(onPressed: _skip, child: const Text('Skip')),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentStep = i),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
          _buildStep5(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _next,
          child: Text(_currentStep == 4 ? 'Finish' : 'Next'),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'Name')),
          TextField(decoration: InputDecoration(labelText: 'Username')),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8,
        children: ['Flutter', 'React', 'Python', 'Node', 'Go'].map((skill) {
          return FilterChip(label: Text(skill), onSelected: (val) {});
        }).toList(),
      ),
    );
  }

  Widget _buildStep3() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(decoration: InputDecoration(labelText: 'Tech Stack (e.g. MERN, Flutter/Firebase)')),
    );
  }

  Widget _buildStep4() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'GitHub URL')),
          TextField(decoration: InputDecoration(labelText: 'LinkedIn URL')),
          TextField(decoration: InputDecoration(labelText: 'Portfolio URL')),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Preferred Roles (comma separated)')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Availability'),
            items: ['Full-time', 'Part-time', 'Weekends only'].map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
