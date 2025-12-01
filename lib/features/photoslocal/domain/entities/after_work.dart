enum AfterWork {
  yes,
  no,
}

extension AfterWorkExtension on AfterWork {
  static AfterWork fromJson(String value) {
    return AfterWork.values.firstWhere((e) => e.name == value);
  }

  String toJson() {
    return name;
  }
}