class CityModel {
  final String name;
  final int id;

  CityModel({required this.name, required this.id});
}

List<CityModel> cities = [
  CityModel(id: 0, name: "جميع المدن"),
  CityModel(id: 1, name: "غزة"),
  CityModel(id: 2, name: "خانيونس"),
  CityModel(id: 3, name: "رفح"),
  CityModel(id: 4, name: "دير البلح"),
];
class CategoryModel {
  final String name;
  final int id;

  CategoryModel({required this.name, required this.id});
}

List<CategoryModel> cate = [
  CategoryModel(id: 0, name: "مطاعم"),
  CategoryModel(id: 1, name: "سوبر ماركت"),
  CategoryModel(id: 2, name: "ملابس"),
  CategoryModel(id: 3, name: "احذية"),
  CategoryModel(id: 4, name: "خدمات"),
];