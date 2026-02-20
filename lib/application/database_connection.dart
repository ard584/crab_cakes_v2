abstract interface class DatabaseConnection<T> {
  T open(String path);
}