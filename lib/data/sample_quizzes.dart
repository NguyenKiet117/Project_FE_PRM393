import 'dart:math';
import '../engine/distractor_generator.dart';
import '../models/question.dart';
import '../models/quiz_set.dart';

/// Dữ liệu mẫu để dựng UI khi parser Excel (Member 1) và DB (Member 2) chưa xong.
List<QuizSet> sampleQuizzes({Random? random}) => [
      // Bộ 1: kiểu file 2 cột (như Sheet mẫu) -> engine tự sinh đáp án nhiễu.
      QuizSet(
        id: 'flutter-basics',
        title: 'Flutter Basics',
        description: 'Câu hỏi nền tảng về Flutter & Dart.',
        category: 'Mobile Dev',
        timeLimit: const Duration(minutes: 5),
        questions: DistractorGenerator.generate(const [
          RawQA('What programming language is used for Flutter?', 'Dart'),
          RawQA('What state management package is recommended by Google?', 'Provider'),
          RawQA('Which database is built into Flutter for local storage?', 'SQLite'),
          RawQA('What widget is used for repeating list items efficiently?',
              'ListView.builder'),
          RawQA('What format are vector graphics usually saved as in Flutter?', 'SVG'),
        ], random: random),
      ),
      // Bộ 2: kiểu file đủ cột B-F (4 lựa chọn + Correct Key) như Stitch.
      QuizSet(
        id: 'scrum-practice',
        title: 'PRM393 Practice Quiz: Agile & Scrum',
        description: 'Sprint Planning, ceremonies, backlog refinement.',
        category: 'Software Engineering',
        timeLimit: const Duration(minutes: 15),
        questions: const [
          Question(
            id: 'q1',
            text: "Which Scrum ceremony is dedicated to inspecting the team's "
                'working process and identifying improvements?',
            options: [
              'Daily Standup Meeting',
              'Sprint Retrospective',
              'Sprint Review & Demo',
              'Backlog Refinement Session',
            ],
            correctIndex: 1,
            hint: 'Focus on internal continuous team improvement.',
            explanation: 'The Retrospective is where the team inspects itself.',
            category: 'Scrum Artifacts',
          ),
          Question(
            id: 'q2',
            text: 'How long is the timebox of a Daily Scrum?',
            options: ['5 minutes', '15 minutes', '30 minutes', '60 minutes'],
            correctIndex: 1,
            explanation: 'The Daily Scrum is capped at 15 minutes.',
            category: 'Scrum Events',
          ),
        ],
      ),
    ];
