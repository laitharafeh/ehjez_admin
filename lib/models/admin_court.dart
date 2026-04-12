class AdminCourt {
  final String id;
  final String name;
  final String phone;
  final String? location;
  final String? category;
  final String? startTime;
  final String? endTime;
  // ISO weekdays: 1=Mon … 7=Sun. Defaults to all 7 days.
  final List<int> workingDays;
  final String? imageUrl;
  final String? image2Url;
  final String? image3Url;
  /// Role of the currently logged-in user for this court: 'owner' or 'staff' / 'coach'.
  final String role;

  const AdminCourt({
    required this.id,
    required this.name,
    required this.phone,
    this.location,
    this.category,
    this.startTime,
    this.endTime,
    this.workingDays = const [1, 2, 3, 4, 5, 6, 7],
    this.imageUrl,
    this.image2Url,
    this.image3Url,
    this.role = 'owner',
  });

  bool get isOwner => role == 'owner';

  factory AdminCourt.fromMap(Map<String, dynamic> map) {
    return AdminCourt(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String?,
      category: map['category'] as String?,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      workingDays: (map['working_days'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      imageUrl: map['image_url'] as String?,
      image2Url: map['image2_url'] as String?,
      image3Url: map['image3_url'] as String?,
      role: map['role'] as String? ?? 'owner',
    );
  }

  AdminCourt copyWith({String? role}) => AdminCourt(
        id: id,
        name: name,
        phone: phone,
        location: location,
        category: category,
        startTime: startTime,
        endTime: endTime,
        workingDays: workingDays,
        imageUrl: imageUrl,
        image2Url: image2Url,
        image3Url: image3Url,
        role: role ?? this.role,
      );
}
