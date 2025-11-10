class TestScore {
  final int studentId;
  final String testID;
  final String testName; // Will be same as testID since MongoDB doesn't store name
  final int score; // correct count
  final int incorrect;
  final int totalQuestions;
  final String studentFirstName; // Will need to get from User object
  final String studentLastName; // Will need to get from User object
  final DateTime dateTaken; // Not in MongoDB, use current date

  TestScore({
    required this.studentId,
    required this.testID,
    required this.testName,
    required this.score,
    required this.incorrect,
    required this.totalQuestions,
    required this.studentFirstName,
    required this.studentLastName,
    required this.dateTaken,
  });

  // IMPORTANT: The firstName and lastName parameters must be here for api_service.dart to work
  factory TestScore.fromJson(Map<String, dynamic> json, {String? firstName, String? lastName}) {
    return TestScore(
      studentId: json['SID'] ?? 0,
      testID: json['testID'] ?? 'unknown',
      testName: json['testID'] ?? 'Unknown Test', // Use testID as testName since MongoDB doesn't store name
      score: json['correct'] ?? 0, // MongoDB stores 'correct' not 'score'
      incorrect: json['incorrect'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      studentFirstName: firstName ?? 'Unknown', // Use the parameter passed in
      studentLastName: lastName ?? 'Student', // Use the parameter passed in
      dateTaken: DateTime.now(), // MongoDB doesn't store date
    );
  }
}