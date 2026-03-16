class Student {
  final int? id;
  final String name;
  final int age;
  final String address;

  /// This value is not persisted in the local database. It is populated from
  /// Firebase favorites for the current user.
  final bool isFavorite;

  Student({
    this.id,
    required this.name,
    required this.age,
    required this.address,
    this.isFavorite = false,
  });

  Student copyWith({int? id, String? name, int? age, String? address, bool? isFavorite}) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      address: address ?? this.address,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      address: map['address'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'name': name, 'age': age, 'address': address};
  }
}
