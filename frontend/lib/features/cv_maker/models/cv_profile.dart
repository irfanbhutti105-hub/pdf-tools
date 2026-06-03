class CvExperience {
  String role;
  String company;
  String period;
  String description;

  CvExperience({
    this.role = '',
    this.company = '',
    this.period = '',
    this.description = '',
  }); 

  Map<String, dynamic> toJson() => {
        'role': role,
        'company': company,
        'period': period,
        'description': description,
      };

  factory CvExperience.fromJson(Map<String, dynamic> json) => CvExperience(
        role: json['role'] as String? ?? '',
        company: json['company'] as String? ?? '',
        period: json['period'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class CvEducation {
  String degree;
  String school;
  String period;

  CvEducation({
    this.degree = '',
    this.school = '',
    this.period = '',
  });

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'school': school,
        'period': period,
      };

  factory CvEducation.fromJson(Map<String, dynamic> json) => CvEducation(
        degree: json['degree'] as String? ?? '',
        school: json['school'] as String? ?? '',
        period: json['period'] as String? ?? '',
      );
}

class CvProfile {
  String id;
  String title;
  DateTime updatedAt;
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String location;
  String website;
  String summary;
  String photoBase64;
  List<CvExperience> experience;
  List<CvEducation> education;
  List<String> skills;
  List<String> languages;

  CvProfile({
    String? id,
    this.title = 'Untitled CV',
    DateTime? updatedAt,
    this.fullName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
    this.summary = '',
    this.photoBase64 = '',
    List<CvExperience>? experience,
    List<CvEducation>? education,
    List<String>? skills,
    List<String>? languages,
  })  : id = id ?? '',
        updatedAt = updatedAt ?? DateTime.now(),
        experience = experience ?? [],
        education = education ?? [],
        skills = skills ?? [],
        languages = languages ?? [];

  factory CvProfile.sample() => CvProfile(
        id: 'sample_id',
        title: 'Alex Morgan - Designer CV',
        updatedAt: DateTime.now(),
        fullName: 'Alex Morgan',
        jobTitle: 'Senior Product Designer',
        email: 'alex.morgan@email.com',
        phone: '+1 (555) 012-3456',
        location: 'San Francisco, CA',
        website: 'alexmorgan.design',
        photoBase64: '',
        summary:
            'Creative product designer with 8+ years crafting user-centered digital experiences for SaaS and mobile products. Passionate about design systems and measurable business impact.',
        experience: [
          CvExperience(
            role: 'Senior Product Designer',
            company: 'NovaTech Solutions',
            period: '2021 — Present',
            description:
                'Lead design for B2B dashboard used by 50k+ users. Reduced onboarding time by 35% through UX research and iterative prototyping.',
          ),
          CvExperience(
            role: 'UI/UX Designer',
            company: 'Pixel Studio',
            period: '2018 — 2021',
            description:
                'Designed mobile apps and marketing sites for startup clients. Collaborated with engineering on design handoff and component libraries.',
          ),
        ],
        education: [
          CvEducation(
            degree: 'B.A. Graphic Design',
            school: 'Rhode Island School of Design',
            period: '2014 — 2018',
          ),
        ],
        skills: [
          'Figma',
          'Design Systems',
          'User Research',
          'Prototyping',
          'Adobe CC',
          'HTML/CSS',
        ],
        languages: ['English (Native)', 'Spanish (Professional)'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'fullName': fullName,
        'jobTitle': jobTitle,
        'email': email,
        'phone': phone,
        'location': location,
        'website': website,
        'summary': summary,
        'photoBase64': photoBase64,
        'experience': experience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills,
        'languages': languages,
      };

  factory CvProfile.fromJson(Map<String, dynamic> json) => CvProfile(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled CV',
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now() 
            : DateTime.now(),
        fullName: json['fullName'] as String? ?? '',
        jobTitle: json['jobTitle'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        website: json['website'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        photoBase64: json['photoBase64'] as String? ?? '',
        experience: (json['experience'] as List<dynamic>?)
                ?.map((e) => CvExperience.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        education: (json['education'] as List<dynamic>?)
                ?.map((e) => CvEducation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
        languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  CvProfile copyWith({
    String? id,
    String? title,
    DateTime? updatedAt,
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? website,
    String? summary,
    String? photoBase64,
    List<CvExperience>? experience,
    List<CvEducation>? education,
    List<String>? skills,
    List<String>? languages,
  }) {
    return CvProfile(
      id: id ?? this.id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      summary: summary ?? this.summary,
      photoBase64: photoBase64 ?? this.photoBase64,
      experience: experience ?? List.from(this.experience),
      education: education ?? List.from(this.education),
      skills: skills ?? List.from(this.skills),
      languages: languages ?? List.from(this.languages),
    );
  }
}
