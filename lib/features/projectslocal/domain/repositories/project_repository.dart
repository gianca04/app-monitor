import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class ProjectRepository {
  Future<Either<Failure, void>> syncProjects();
}