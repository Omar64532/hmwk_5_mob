import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QuizSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QuizSetupScreen extends StatefulWidget {
  @override
  _QuizSetupScreenState createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _categories = <String, int>{};
  String _selectedCategory = '9'; 
  String _difficulty = 'easy';
  String _questionType = 'multiple';
  int _questionCount = 5;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final url = Uri.parse('https://opentdb.com/api_category.php');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        for (var category in data['trivia_categories']) {
          _categories[category['name']] = category['id'];
        }
      });
    }
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          category: _selectedCategory,
          difficulty: _difficulty,
          questionType: _questionType,
          questionCount: _questionCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Select Category'),
              items: _categories.entries
                  .map((e) => DropdownMenuItem(
                        value: e.value.toString(),
                        child: Text(e.key),
                      ))
                  .toList(),
              value: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value as String;
                });
              },
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Select Difficulty'),
              items: ['easy', 'medium', 'hard']
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.capitalize()),
                      ))
                  .toList(),
              value: _difficulty,
              onChanged: (value) {
                setState(() {
                  _difficulty = value as String;
                });
              },
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Select Question Type'),
              items: ['multiple', 'boolean']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.capitalize()),
                      ))
                  .toList(),
              value: _questionType,
              onChanged: (value) {
                setState(() {
                  _questionType = value as String;
                });
              },
            ),
            Slider(
              label: 'Questions: $_questionCount',
              min: 5,
              max: 15,
              divisions: 2,
              value: _questionCount.toDouble(),
              onChanged: (value) {
                setState(() {
                  _questionCount = value.toInt();
                });
              },
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _startQuiz,
              child: Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String category;
  final String difficulty;
  final String questionType;
  final int questionCount;

  QuizScreen({
    required this.category,
    required this.difficulty,
    required this.questionType,
    required this.questionCount,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final url = Uri.parse(
        'https://opentdb.com/api.php?amount=${widget.questionCount}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.questionType}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _questions.addAll(data['results']);
        _loading = false;
      });
    }
  }

  void _checkAnswer(String answer) {
    if (answer == _questions[_currentIndex]['correct_answer']) {
      _score++;
    }
    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz Completed!'),
              Text('Score: $_score/${_questions.length}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Go to Setup'),
              ),
            ],
          ),
        ),
      );
    }
    final question = _questions[_currentIndex];
    final options = [...question['incorrect_answers'], question['correct_answer']];
    options.shuffle();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${_currentIndex + 1}/${_questions.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question['question'],
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ...options.map((option) => ElevatedButton(
                  onPressed: () => _checkAnswer(option),
                  child: Text(option),
                )),
            Spacer(),
            Text('Score: $_score'),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + this.substring(1);
  }
}
