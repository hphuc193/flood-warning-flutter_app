class EvacuationStep {
  final int step;
  final String title;
  final String description;
  final String icon;
  final String type; // 'info', 'checklist_reference', 'map_reference', 'warning', 'sos_reference'
  final String? videoUrl;

  EvacuationStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.videoUrl,
  });

  factory EvacuationStep.fromJson(Map<String, dynamic> json) {
    return EvacuationStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '', // Ánh xạ chính xác key 'description'
      icon: json['icon'] ?? '',
      type: json['type'] ?? 'info',
      videoUrl: json['video_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'title': title,
    'description': description,
    'icon': icon,
    'type': type,
    'video_url': videoUrl,
  };
}