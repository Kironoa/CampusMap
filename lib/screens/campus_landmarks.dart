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
    category: 'building',
    description: 'Administrative and academic hub',
    position: LatLng(8.064562, 123.751025),
  ),
  CampusLandmark(
    id: 'canteen',
    name: 'Campus Canteen',
    category: 'facility',
    description: 'Student dining area',
    position: LatLng(8.0643, 123.7505),
  ),
  CampusLandmark(
    id: 'deans_office',
    name: "Dean's Office",
    category: 'office',
    description: '2nd Floor, Main Building',
    position: LatLng(8.064562, 123.751025),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'registrar',
    name: 'Registrar',
    category: 'office',
    description: 'Student records and enrollment',
    position: LatLng(8.064540, 123.750980),
  ),
  CampusLandmark(
    id: 'computer_lab',
    name: 'Computer Laboratory',
    category: 'lab',
    description: 'IT and programming lab',
    position: LatLng(8.064580, 123.751060),
    floor: '2F',
  ),
  CampusLandmark(
    id: 'library',
    name: 'Library',
    category: 'facility',
    description: 'Academic resources and study area',
    position: LatLng(8.064510, 123.750940),
  ),
  CampusLandmark(
    id: 'gym',
    name: 'Gymnasium',
    category: 'facility',
    description: 'Sports and events venue',
    position: LatLng(8.064490, 123.750890),
  ),
  CampusLandmark(
    id: 'cashier',
    name: 'Cashier',
    category: 'office',
    description: 'Payment and fees',
    position: LatLng(8.064530, 123.751010),
  ),
  CampusLandmark(
    id: 'guidance',
    name: 'Guidance Office',
    category: 'office',
    description: 'Student welfare and counseling',
    position: LatLng(8.064550, 123.751030),
  ),
  CampusLandmark(
    id: 'clinic',
    name: 'School Clinic',
    category: 'facility',
    description: 'Medical and first aid',
    position: LatLng(8.064500, 123.750960),
  ),
  CampusLandmark(
    id: 'science_lab',
    name: 'Science Laboratory',
    category: 'lab',
    description: 'Physics, Chemistry, Biology lab',
    position: LatLng(8.064570, 123.751050),
    floor: '1F',
  ),
  CampusLandmark(
    id: 'auditorium',
    name: 'Auditorium',
    category: 'facility',
    description: 'Events and assemblies',
    position: LatLng(8.064480, 123.750920),
  ),
  CampusLandmark(
    id: 'boys_restroom',
    name: 'Boys Restroom',
    category: 'restroom',
    description: 'Ground floor male restroom',
    position: LatLng(8.064520, 123.751000),
  ),
  CampusLandmark(
    id: 'girls_restroom',
    name: 'Girls Restroom',
    category: 'restroom',
    description: 'Ground floor female restroom',
    position: LatLng(8.064515, 123.750990),
  ),
  CampusLandmark(
    id: 'parking',
    name: 'Student Parking',
    category: 'facility',
    description: 'Bike and motor parking area',
    position: LatLng(8.064280, 123.750480),
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
  return tcgcLandmarks.where((l) => l.category == category.toLowerCase()).toList();
}