enum UserRole {
  owner('Власник'),
  manager('Менеджер'),
  member('Учасник');

  const UserRole(this.displayName);
  final String displayName;
}