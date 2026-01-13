class PersonnelItem {
  final String id; // ID interno para manejo de UI (Riverpod)
  final int? employeeId; // ID de la base de datos
  final String name;
  final String? employeeFullName;
  final double hh; // Horas hombre
  final int? positionId; // ID del cargo
  final String positionName;
  final bool isNotRegistered;

  const PersonnelItem({
    required this.id,
    this.employeeId,

    required this.name,
    required this.hh,
    this.positionId,
    required this.positionName,
    required this.isNotRegistered,
    this.employeeFullName,
  });

  // Este método genera exactamente el formato de tu JSON
  Map<String, dynamic> toJson() {
    return {
      "employee_id": employeeId,
      "employee_name": name,
      "employee_full_name": employeeFullName,
      "hh": hh
          .toString(), // Lo pasamos a string si el API lo requiere como en tu ejemplo
      "position_id": positionId,
      "position_name": positionName,
      "is_not_registered": isNotRegistered,
    };
  }

  PersonnelItem copyWith({
    String? name,
    double? hh,
    String? positionName,
    String? employeeFullName,
    bool? isNotRegistered,
    int? employeeId,
    int? positionId,
  }) {
    return PersonnelItem(
      id: id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      hh: hh ?? this.hh,
      employeeFullName: employeeFullName ?? this.employeeFullName,
      positionId: positionId ?? this.positionId,
      positionName: positionName ?? this.positionName,
      isNotRegistered: isNotRegistered ?? this.isNotRegistered,
    );
  }
}
