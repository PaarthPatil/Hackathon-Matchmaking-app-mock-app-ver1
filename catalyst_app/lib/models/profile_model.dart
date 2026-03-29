class Profile {
  final String id;
  final String? name;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final int xp;
  final int level;
  final List<String> skills;
  final List<String> techStack;
  final List<String> githubLink;
  final List<String> linkedinLink;
  final List<String> portfolioLink;
  final int hackathonsJoined;
  final int wins;
  final int teamsJoined;
  final List<String> roles;
  final String availability;
  final String experienceLevel;
  final bool lookingForTeam;

  Profile({
    required this.id,
    this.name,
    this.username,
    this.bio,
    this.avatarUrl,
    this.xp = 0,
    this.level = 1,
    this.skills = const [],
    this.techStack = const [],
    this.githubLink = const [],
    this.linkedinLink = const [],
    this.portfolioLink = const [],
    this.hackathonsJoined = 0,
    this.wins = 0,
    this.teamsJoined = 0,
    this.roles = const [],
    this.availability = 'Available',
    this.experienceLevel = 'Beginner',
    this.lookingForTeam = false,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    int? xp,
    int? level,
    List<String>? skills,
    List<String>? techStack,
    List<String>? githubLink,
    List<String>? linkedinLink,
    List<String>? portfolioLink,
    int? hackathonsJoined,
    int? wins,
    int? teamsJoined,
    List<String>? roles,
    String? availability,
    String? experienceLevel,
    bool? lookingForTeam,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      skills: skills ?? this.skills,
      techStack: techStack ?? this.techStack,
      githubLink: githubLink ?? this.githubLink,
      linkedinLink: linkedinLink ?? this.linkedinLink,
      portfolioLink: portfolioLink ?? this.portfolioLink,
      hackathonsJoined: hackathonsJoined ?? this.hackathonsJoined,
      wins: wins ?? this.wins,
      teamsJoined: teamsJoined ?? this.teamsJoined,
      roles: roles ?? this.roles,
      availability: availability ?? this.availability,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      lookingForTeam: lookingForTeam ?? this.lookingForTeam,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      skills: List<String>.from(json['skills'] ?? []),
      techStack: List<String>.from(json['tech_stack'] ?? []),
      githubLink: List<String>.from(json['github_link'] ?? []),
      linkedinLink: List<String>.from(json['linkedin_link'] ?? []),
      portfolioLink: List<String>.from(json['portfolio_link'] ?? []),
      hackathonsJoined: json['hackathons_joined'] ?? 0,
      wins: json['wins'] ?? 0,
      teamsJoined: json['teams_joined'] ?? 0,
      roles: List<String>.from(json['roles'] ?? []),
      availability: json['availability'] ?? 'Available',
      experienceLevel: json['experience_level'] ?? 'Beginner',
      lookingForTeam: json['looking_for_team'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'xp': xp,
      'level': level,
      'skills': skills,
      'tech_stack': techStack,
      'github_link': githubLink,
      'linkedin_link': linkedinLink,
      'portfolio_link': portfolioLink,
      'hackathons_joined': hackathonsJoined,
      'wins': wins,
      'teams_joined': teamsJoined,
      'roles': roles,
      'availability': availability,
      'experience_level': experienceLevel,
      'looking_for_team': lookingForTeam,
    };
  }
}
