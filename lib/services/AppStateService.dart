enum AppScreen {
  friendsList,
  chat,
  other,
}

class AppState {
  static AppScreen currentScreen = AppScreen.other;
  static String? currentChatId;
}
