import '../models/models.dart';

/// True when the student is already past stream selection and is in a stream this career doesn't accept.
bool needsStreamSwitch(Career c, StudentContext ctx) {
  final decided = ctx.level.index >= StudyLevel.class11.index && ctx.stream != AcademicStream.undecided;
  return decided && c.eligibleStreams.isNotEmpty && !c.eligibleStreams.contains(ctx.stream);
}
