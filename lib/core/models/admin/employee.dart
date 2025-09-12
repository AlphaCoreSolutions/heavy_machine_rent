class Employee {
  final int? id;
  final String? fullName;
  final String? mobile;
  final String? photo;
  final String? other;

  Employee({this.id, this.fullName, this.mobile, this.photo, this.other});

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'],
    fullName: json['fullName'],
    mobile: json['mobile'],
    photo: json['photo'],
    other: json['other'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'mobile': mobile,
    'photo': photo,
    'other': other,
  };
}
