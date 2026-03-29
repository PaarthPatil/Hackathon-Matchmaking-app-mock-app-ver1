class Hackathon {
  final String id;
  final String title;
  final String? description;
  final String? organizer;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? mode;
  final String? location;
  final String? prizePool;
  final int? maxTeamSize;
  final List<String> tags;

  Hackathon({
    required this.id,
    required this.title,
    this.description,
    this.organizer,
    this.startDate,
    this.endDate,
    this.mode,
    this.location,
    this.prizePool,
    this.maxTeamSize,
    this.tags = const [],
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) {
    return Hackathon(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      organizer: json['organizer'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      mode: json['mode'],
      location: json['location'],
      prizePool: json['prize_pool'],
      maxTeamSize: json['max_team_size'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizer': organizer,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'mode': mode,
      'location': location,
      'prize_pool': prizePool,
      'max_team_size': maxTeamSize,
      'tags': tags,
    };
  }
}
