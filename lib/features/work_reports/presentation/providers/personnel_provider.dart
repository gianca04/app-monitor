import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/personnel.dart';

// 1. Quitamos la dependencia de employeesProvider
final personnelProvider =
    StateNotifierProvider<PersonnelNotifier, List<PersonnelItem>>((ref) {
      return PersonnelNotifier();
    });

class PersonnelNotifier extends StateNotifier<List<PersonnelItem>> {
  PersonnelNotifier() : super([]);

  void addPersonnel(PersonnelItem person) {
    final alreadyInList = state.any((e) => e.employeeId == person.employeeId);

    if (alreadyInList && person.employeeId != null) {
      return;
    }

    state = [...state, person];
  }

  void removePersonnel(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updatePersonnel(String id, PersonnelItem updated) {
    state = [
      for (final item in state)
        if (item.id == id) updated else item,
    ];
  }

  void clear() => state = [];
}
