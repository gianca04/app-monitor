class Employee {
  final int? id;
  final String? documentType;
  final String? documentNumber;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? address;
  final String? dateContract;
  final String? dateBirth;
  final String? sex;
  final int? positionId;
  final bool? active;

  Employee({
    this.id,
    this.documentType,
    this.documentNumber,
    this.firstName,
    this.lastName,
    this.fullName,
    this.address,
    this.dateContract,
    this.dateBirth,
    this.sex,
    this.positionId,
    this.active,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String?,
      address: json['address'] as String?,
      dateContract: json['date_contract'] as String?,
      dateBirth: json['date_birth'] as String?,
      sex: json['sex'] as String?,
      positionId: json['position'] as int?,
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'document_number': documentNumber,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'address': address,
      'date_contract': dateContract,
      'date_birth': dateBirth,
      'sex': sex,
      'position': positionId,
      'active': active,
    };
  }

  Employee copyWith({
    int? id,
    String? documentType,
    String? documentNumber,
    String? firstName,
    String? lastName,
    String? fullName,
    String? address,
    String? dateContract,
    String? dateBirth,
    String? sex,
    int? positionId,
    bool? active,
  }) {
    return Employee(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      dateContract: dateContract ?? this.dateContract,
      dateBirth: dateBirth ?? this.dateBirth,
      sex: sex ?? this.sex,
      positionId: positionId ?? this.positionId,
      active: active ?? this.active,
    );
  }
}