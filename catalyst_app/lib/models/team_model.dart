class Team {
  final String id;
  final String hackathonId;
  final String creatorId;
  final String? name;
  final String? description;
  final List<String> requiredSkills;
  final int? maxMembers;
  final String? commitmentLevel;
  final String? availability;
  final DateTime? createdAt;

  // Matching fields (specifically for Join Team Recommendation)
  final double? matchingScore;
  final String? matchingExplanation;
  final int membersCount;

  Team({
    required this.id,
    required this.hackathonId,
    required this.creatorId,
    this.name,
    this.description,
    this.requiredSkills = const [],
    this.maxMembers,
    this.commitmentLevel,
    this.availability,
    this.createdAt,
    this.matchingScore,
    this.matchingExplanation,
    this.membersCount = 0,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      hackathonId: json['hackathon_id'],
      creatorId: json['creator_id'],
      name: json['name'],
      description: json['description'],
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      maxMembers: json['max_members'],
      commitmentLevel: json['commitment_level'],
      availability: json['availability'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      matchingScore: (json['matching_score'] as num?)?.toDouble(),
      matchingExplanation: json['matching_explanation'],
      membersCount: json['members_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hackathon_id': hackathonId,
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'required_skills': requiredSkills,
      'max_members': maxMembers,
      'commitment_level': commitmentLevel,
      'availability': availability,
      'created_at': createdAt?.toIso8601String(),
      'matching_score': matchingScore,
      'matching_explanation': matchingExplanation,
      'members_count': membersCount,
    };
  }
}
