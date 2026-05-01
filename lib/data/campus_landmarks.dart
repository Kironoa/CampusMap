import 'package:flutter/material.dart';
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
    position: LatLng(8.0591, 123.9442),
  ),
  CampusLandmark(
    id: 'new_buildings',
    name: 'New Academic Buildings',
    category: 'Buildings',
    description: 'Newly constructed classrooms and lecture halls',
    position: LatLng(8.0593, 123.9444),
  ),
  CampusLandmark(
    id: 'old_buildings',
    name: 'Old Buildings',
    category: 'Buildings',
    description: 'Heritage buildings with historic significance',
    position: LatLng(8.0589, 123.9438),
  ),
  CampusLandmark(
    id: 'deans_office',
    name: "Dean's Office",
    category: 'Offices',
    description: "Administrative offices for academic deans",
    position: LatLng(8.0592, 123.9441),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'registrar',
    name: 'Registrar',
    category: 'Offices',
    description: 'Student records, enrollment, and transcript requests',
    position: LatLng(8.0591, 123.9440),
  ),
  CampusLandmark(
    id: 'cashier',
    name: 'Cashier',
    category: 'Offices',
    description: 'Payment and fees collection',
    position: LatLng(8.0590, 123.9441),
  ),
  CampusLandmark(
    id: 'guidance',
    name: 'Guidance Office',
    category: 'Offices',
    description: 'Student welfare, counseling, and career guidance',
    position: LatLng(8.0592, 123.9439),
  ),
  CampusLandmark(
    id: 'admin_office',
    name: 'Administration Office',
    category: 'Offices',
    description: 'General administration and human resources',
    position: LatLng(8.0593, 123.9440),
  ),
  CampusLandmark(
    id: 'computer_lab',
    name: 'Computer Laboratory',
    category: 'Labs',
    description: 'IT and programming lab with 50+ workstations',
    position: LatLng(8.0594, 123.9438),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'science_lab',
    name: 'Science Laboratory',
    category: 'Labs',
    description: 'Physics, Chemistry, and Biology lab facilities',
    position: LatLng(8.0593, 123.9437),
    floor: '1F',
  ),
  CampusLandmark(
    id: 'language_lab',
    name: 'Language Laboratory',
    category: 'Labs',
    description: 'Audio-visual language learning center',
    position: LatLng(8.0592, 123.9436),
    floor: '3F',
  ),
  CampusLandmark(
    id: 'canteen',
    name: 'Campus Canteen',
    category: 'Facilities',
    description: 'Student dining area with various food stalls',
    position: LatLng(8.0590, 123.9435),
  ),
  CampusLandmark(
    id: 'library',
    name: 'Library',
    category: 'Facilities',
    description: 'Academic resources, study area, and digital archives',
    position: LatLng(8.0588, 123.9439),
  ),
  CampusLandmark(
    id: 'gym',
    name: 'Gymnasium',
    category: 'Facilities',
    description: 'Indoor sports and events venue',
    position: LatLng(8.0587, 123.9441),
  ),
  CampusLandmark(
    id: 'auditorium',
    name: 'Auditorium',
    category: 'Facilities',
    description: 'Events, assemblies, and cultural programs venue',
    position: LatLng(8.0589, 123.9443),
  ),
  CampusLandmark(
    id: 'clinic',
    name: 'School Clinic',
    category: 'Facilities',
    description: 'Medical services and first aid station',
    position: LatLng(8.0591, 123.9444),
  ),
  CampusLandmark(
    id: 'parking',
    name: 'Student Parking',
    category: 'Facilities',
    description: 'Bike and motor parking area',
    position: LatLng(8.0585, 123.9436),
  ),
  CampusLandmark(
    id: 'covered_court',
    name: 'Covered Court',
    category: 'Facilities',
    description: 'Outdoor basketball and volleyball court',
    position: LatLng(8.0587, 123.9444),
  ),
  CampusLandmark(
    id: 'student_lounge',
    name: 'Student Lounge',
    category: 'Facilities',
    description: 'Relaxation and socialization area for students',
    position: LatLng(8.0594, 123.9442),
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

IconData categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'buildings'  => Icons.business_outlined,
    'offices'    => Icons.meeting_room_outlined,
    'labs'       => Icons.computer_outlined,
    'facilities' => Icons.sports_basketball_outlined,
    _            => Icons.place_outlined,
  };
}

Color categoryColor(String category) {
  return switch (category.toLowerCase()) {
    'buildings'  => const Color(0xFF2563EB),
    'offices'    => const Color(0xFFEA580C),
    'labs'       => const Color(0xFF7C3AED),
    'facilities' => const Color(0xFF059669),
    _            => const Color(0xFF0891B2),
  };
}

List<String> get landmarkCategories {
  final cats = tcgcLandmarks.map((l) => l.category).toSet().toList();
  cats.sort();
  return cats;
}