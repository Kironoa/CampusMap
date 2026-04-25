import 'package:google_maps_flutter/google_maps_flutter.dart';

class CampusLandmark {
  final String id;
  final String name;
  final String category;
  final String description;
  final LatLng position;
  final String? floor;
  
  const CampusLandmark({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.position,
    this.floor,
  });
}

const List<CampusLandmark> tcgcLandmarks = [
  CampusLandmark(
    id: 'main_building',
    name: 'Main Building',
    category: 'Buildings',
    description: 'Administrative and academic hub of TCGC',
    position: LatLng(8.064562, 123.751025),
  ),
  CampusLandmark(
    id: 'new_buildings',
    name: 'New Academic Buildings',
    category: 'Buildings',
    description: 'Newly constructed classrooms and lecture halls',
    position: LatLng(8.064620, 123.751100),
  ),
  CampusLandmark(
    id: 'old_buildings',
    name: 'Old Buildings',
    category: 'Buildings',
    description: 'Heritage buildings with historic significance',
    position: LatLng(8.064540, 123.750980),
  ),
  CampusLandmark(
    id: 'deans_office',
    name: "Dean's Office",
    category: 'Offices',
    description: "Administrative offices for academic deans",
    position: LatLng(8.064562, 123.751025),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'registrar',
    name: 'Registrar',
    category: 'Offices',
    description: 'Student records, enrollment, and transcript requests',
    position: LatLng(8.064540, 123.750980),
  ),
  CampusLandmark(
    id: 'cashier',
    name: 'Cashier',
    category: 'Offices',
    description: 'Payment and fees collection',
    position: LatLng(8.064530, 123.751010),
  ),
  CampusLandmark(
    id: 'guidance',
    name: 'Guidance Office',
    category: 'Offices',
    description: 'Student welfare, counseling, and career guidance',
    position: LatLng(8.064550, 123.751030),
  ),
  CampusLandmark(
    id: 'admin_office',
    name: 'Administration Office',
    category: 'Offices',
    description: 'General administration and human resources',
    position: LatLng(8.064535, 123.751015),
  ),
  CampusLandmark(
    id: 'computer_lab',
    name: 'Computer Laboratory',
    category: 'Labs',
    description: 'IT and programming lab with 50+ workstations',
    position: LatLng(8.064580, 123.751060),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'science_lab',
    name: 'Science Laboratory',
    category: 'Labs',
    description: 'Physics, Chemistry, and Biology lab facilities',
    position: LatLng(8.064570, 123.751050),
    floor: '1F',
  ),
  CampusLandmark(
    id: 'language_lab',
    name: 'Language Laboratory',
    category: 'Labs',
    description: 'Audio-visual language learning center',
    position: LatLng(8.064565, 123.751045),
    floor: '3F',
  ),
  CampusLandmark(
    id: 'canteen',
    name: 'Campus Canteen',
    category: 'Facilities',
    description: 'Student dining area with various food stalls',
    position: LatLng(8.0643, 123.7505),
  ),
  CampusLandmark(
    id: 'library',
    name: 'Library',
    category: 'Facilities',
    description: 'Academic resources, study area, and digital archives',
    position: LatLng(8.064510, 123.750940),
  ),
  CampusLandmark(
    id: 'gym',
    name: 'Gymnasium',
    category: 'Facilities',
    description: 'Indoor sports and events venue',
    position: LatLng(8.064490, 123.750890),
  ),
  CampusLandmark(
    id: 'auditorium',
    name: 'Auditorium',
    category: 'Facilities',
    description: 'Events, assemblies, and cultural programs venue',
    position: LatLng(8.064480, 123.750920),
  ),
  CampusLandmark(
    id: 'clinic',
    name: 'School Clinic',
    category: 'Facilities',
    description: 'Medical services and first aid station',
    position: LatLng(8.064500, 123.750960),
  ),
  CampusLandmark(
    id: 'parking',
    name: 'Student Parking',
    category: 'Facilities',
    description: 'Bike and motor parking area',
    position: LatLng(8.064280, 123.750480),
  ),
  CampusLandmark(
    id: 'covered_court',
    name: 'Covered Court',
    category: 'Facilities',
    description: 'Outdoor basketball and volleyball court',
    position: LatLng(8.064475, 123.750870),
  ),
  CampusLandmark(
    id: 'student_lounge',
    name: 'Student Lounge',
    category: 'Facilities',
    description: 'Relaxation and socialization area for students',
    position: LatLng(8.064555, 123.751055),
    floor: '1F',
  ),
];

List<CampusLandmark> searchLandmarks(String query) {
  if (query.isEmpty) return tcgcLandmarks;
  final lowerQuery = query.toLowerCase();
  return tcgcLandmarks.where((landmark) {
    return landmark.name.toLowerCase().contains(lowerQuery) ||
           landmark.description.toLowerCase().contains(lowerQuery) ||
           landmark.category.toLowerCase().contains(lowerQuery);
  }).toList();
}

List<CampusLandmark> filterByCategory(String category) {
  if (category.isEmpty || category == 'All') return tcgcLandmarks;
  return tcgcLandmarks.where((l) => 
    l.category.toLowerCase() == category.toLowerCase()
  ).toList();
}