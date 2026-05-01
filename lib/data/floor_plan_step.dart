class FloorPlanStep {
  final int? id;
  final String floorPlanId;
  final String description;
  final double x;
  final double y;
  final int stepOrder;

  FloorPlanStep({
    this.id,
    required this.floorPlanId,
    required this.description,
    required this.x,
    required this.y,
    required this.stepOrder,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'floor_plan_id': floorPlanId,
    'description': description,
    'x': x,
    'y': y,
    'step_order': stepOrder,
  };

  factory FloorPlanStep.fromMap(Map<String, dynamic> map) => FloorPlanStep(
    id: map['id'] as int?,
    floorPlanId: map['floor_plan_id'] as String,
    description: map['description'] as String,
    x: (map['x'] as num).toDouble(),
    y: (map['y'] as num).toDouble(),
    stepOrder: map['step_order'] as int,
  );

  FloorPlanStep copyWith({
    int? id,
    String? floorPlanId,
    String? description,
    double? x,
    double? y,
    int? stepOrder,
  }) => FloorPlanStep(
    id: id ?? this.id,
    floorPlanId: floorPlanId ?? this.floorPlanId,
    description: description ?? this.description,
    x: x ?? this.x,
    y: y ?? this.y,
    stepOrder: stepOrder ?? this.stepOrder,
  );
}
