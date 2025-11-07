class ApiConstants {
  // Base URL for the BookMate API
  static const String baseUrl = 'https://c921dc921426.ngrok-free.app';

  // API endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';

  static const String usersSearch = '/users/search';

  static const String booksMy = '/books/my';
  static const String booksAdd = '/books/add';
  static String booksDelete(int bookId) => '/books/$bookId';

  static const String mates = '/mates';
  static const String matesRequests = '/mates/requests';
  static String matesAdd(String username) => '/mates/add/$username';
  static String matesAccept(String username) => '/mates/accept/$username';
  static String matesReject(String username) => '/mates/reject/$username';
  static String matesRemove(String username) => '/mates/remove/$username';

  static const String snippetsSend = '/snippets/send';
  static const String snippetsReceived = '/snippets/received';
  static const String snippetsSent = '/snippets/sent';
  static String snippetsDelete(int snippetId) => '/snippets/$snippetId';

  // SharedPreferences keys
  static const String accessTokenKey = 'access_token';
  static const String currentUserKey = 'current_user';
  static const String avatarSeedKey = 'avatar_seed';
}
