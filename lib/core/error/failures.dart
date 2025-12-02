abstract class Failure {
  const Failure();
  String get message;
}

class ServerFailure extends Failure {
  final String _message;

  const ServerFailure(this._message);

  @override
  String get message => _message;
}

class CacheFailure extends Failure {
  final String _message;

  const CacheFailure(this._message);

  @override
  String get message => _message;
}
