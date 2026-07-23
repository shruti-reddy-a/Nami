class AppStrings {
  // General
  static const String appName = 'NAMI';
  static const String tagLine = 'Find your flow.';
  // Navigation Tabs
  static const String tabHome = 'Home';
  static const String tabPlanner = 'Planner';
  static const String tabProgress = 'Progress';
  static const String tabSettings = 'Settings';
  
  // Login
  static const String emailLabel = 'Email address';
  static const String emailHint = 'name@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';
  static const String forgotPassword = 'Forgot?';
  static const String getStarted = 'Get Started';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String login = 'Login';
  static const String orDivider = 'OR';
  static const String googleLogin = 'Google';
  static const String appleLogin = 'Apple';

  // Dashboard
  static const String welcomeTitle = 'Welcome to Nami';
  static const String welcomeSubtitle = 'Build habits with compassion — consistency, not perfection.';
  static const String createFirstHabit = 'Create your first habit';
  static const String logSuccessMessage = 'Nice — your consistency improved!';
  static const String sevenDay = '7-Day';
  static const String thirtyDay = '30-Day';

  // Habit Detail
  static const String insights = 'Insights';
  static const String insightGreat = "You're finding a great rhythm! Keep riding this wave.";
  static const String insightGood = "Small wins add up. You're building consistency at your own pace.";
  static const String insightSlow = "It's okay to pause or have slow weeks. Consider adjusting your goal if it feels like too much right now.";
  static const String recentLogs = 'Recent Logs';
  static const String noLogsYet = 'No logs yet. Start building your wave!';

  // Add / Edit Habit
  static const String editHabit = 'Edit Habit';
  static const String newHabit = 'New Habit';
  static const String habitTitleQuestion = 'What habit do you want to track?';
  static const String habitTitleHint = 'e.g., Read a book, Meditate';
  static const String habitTitleError = 'Please enter a habit title';
  static const String habitTimeQuestion = 'What time of day?';
  static const String timeAnytime = 'Anytime';
  static const String timeMorning = 'Morning';
  static const String timeAfternoon = 'Afternoon';
  static const String timeEvening = 'Evening';
  static const String timeCustom = 'Custom time...';
  static const String habitFrequencyQuestion = 'How often would you like to do this?';
  static const String customRecurrence = 'Custom...';
  static const String repeatEvery = 'Repeat every';
  static const String repeatOn = 'Repeat on';
  static const String days = 'day(s)';
  static const String weeks = 'week(s)';
  static const String months = 'month(s)';
  
  static const String saveChanges = 'Save Changes';
  static const String createHabit = 'Create Habit';
  static const String targetUpdateNotice = 'Updating target won’t erase past progress; it will change how future consistency is calculated.';

  // Helper methods
  static String targetPreview(String schedule) => 'Schedule: $schedule';
}
