class FloorPlanStep {
  final int? id;
  final String floorPlanId;
  final String description;
  final double x;
  final double y;
  final int stepOrder;

  const FloorPlanStep({
    this.id,
    required this.floorPlanId,
    required this.description,
    required this.x,
    required this.y,
    required this.stepOrder,
  });
}
