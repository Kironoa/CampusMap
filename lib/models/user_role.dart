enum UserRole {
  student(
    label: 'Student',
    gateHint: 'Gates 1 & 5',
    description: 'Student walk-in access through Gate 1 or Gate 5.',
  ),
  faculty(
    label: 'Faculty',
    gateHint: 'Gates 3 & 5',
    description: 'Faculty walk-in access through Gate 3 or Gate 5.',
  ),
  ojt(
    label: 'OJT',
    gateHint: 'Gates 3 & 5',
    description: 'OJT walk-in access through Gate 3 or Gate 5.',
  ),
  visitor(
    label: 'Visitor',
    gateHint: 'Gates 3 & 5',
    description: 'Visitor walk-in access through Gate 3 or Gate 5.',
  );

  const UserRole({
    required this.label,
    required this.gateHint,
    required this.description,
  });

  final String label;
  final String gateHint;
  final String description;
}
