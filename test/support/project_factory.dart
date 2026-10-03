import 'package:kaysan_properties/models/project_model.dart';

/// "Today" for every ranking/sort test, so results don't drift with the clock.
final DateTime testNow = DateTime(2026, 10, 3);

/// Developers the factory resolves by name (Emaar = featured id 72).
const Map<String, DeveloperModel> testDevelopers = <String, DeveloperModel>{
  'Emaar': DeveloperModel(id: 72, name: 'Emaar'),
  'Samana': DeveloperModel(id: 900, name: 'Samana'),
};

/// A complete, listable Reelly `/projects` record; [overrides] replace or
/// null out any field.
ProjectModel project(int id, [Map<String, dynamic> overrides = const <String, dynamic>{}]) {
  return ProjectModel.fromListJson(<String, dynamic>{
    'id': id,
    'name': 'Project $id',
    'developer': 'Dev $id',
    'construction_status': 'under_construction',
    'sale_status': 'on_sale',
    'construction_start_date': '2026-06-01',
    'construction_end_date': '2029-06-30',
    'completion_datetime': '2029-06-30T00:00:00Z',
    'min_price': 1500000.0,
    'max_price': 3000000.0,
    'min_size': 700.0,
    'max_size': 1500.0,
    'min_bedrooms': 1,
    'max_bedrooms': 3,
    'available_unit_types_display': <String>['Apartment'],
    'location': <String, dynamic>{'district': 'Dubai Marina', 'region': 'Dubai', 'country': 219},
    'cover_image': <String, dynamic>{
      'url': 'https://example.com/$id.jpg',
      'metadata': <String, dynamic>{'width': 1600},
    },
    'updated_at': '2026-10-01T00:00:00Z',
    ...overrides,
  }, developers: testDevelopers);
}

/// A project handing over in [year]-[month] (null = undated).
ProjectModel handingOver(int id, int? year, int? month,
    {bool ready = false, Map<String, dynamic> extra = const <String, dynamic>{}}) {
  final String? date = year == null
      ? null
      : '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-28';
  return project(id, <String, dynamic>{
    'completion_datetime': date == null ? null : '${date}T00:00:00Z',
    'construction_end_date': date,
    'completion_date': null,
    'construction_status': ready ? 'completed' : 'under_construction',
    ...extra,
  });
}
