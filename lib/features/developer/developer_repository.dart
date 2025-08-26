class DeveloperRepository {
  final _developers = [
    Developer(
      id: '1',
      email: 'siv.devil3@gmail.com',
      passwordHash: '123',
    ),
  ];

  Future<List<Developer>> getDeveloper() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _developers;
  }
}

class Developer {
  final String id;
  final String email;
  final String passwordHash;

  Developer({
    required this.id,
    required this.email,
    required this.passwordHash,
  });
}