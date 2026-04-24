import 'package:naviapp/models/resource_model.dart';
import 'programs/bscs_data.dart';
import 'programs/business_data.dart';
import 'programs/polsci_data.dart';

class LibraryData {
  static final List<ResourceCategory> categories = [
    bscsCategory,
    businessCategory,
    polSciCategory,
  ];
}
