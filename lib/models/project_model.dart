/// A trilingual string as returned throughout the API (`{en, ar, fa}`).
/// [display] picks the best available value with an English-first
/// fallback — the app doesn't yet offer in-app language switching, so a
/// single deterministic choice is used everywhere text is shown.
class LocalizedText {
  const LocalizedText({this.en = '', this.ar = '', this.fa = ''});

  final String en;
  final String ar;
  final String fa;

  String get display => en.isNotEmpty ? en : (ar.isNotEmpty ? ar : fa);

  bool get isEmpty => en.isEmpty && ar.isEmpty && fa.isEmpty;

  factory LocalizedText.fromJson(dynamic json) {
    if (json == null) return const LocalizedText();
    if (json is String) return LocalizedText(en: json);
    final Map<String, dynamic> map = json as Map<String, dynamic>;
    return LocalizedText(
      en: map['en'] as String? ?? '',
      ar: map['ar'] as String? ?? '',
      fa: map['fa'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'en': en, 'ar': ar, 'fa': fa};
}

/// A simple `{id, name}` reference used for both `city` and `district`.
class NamedRef {
  const NamedRef({required this.id, required this.name});

  final int id;
  final LocalizedText name;

  factory NamedRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NamedRef(id: 0, name: LocalizedText());
    return NamedRef(id: json['id'] as int? ?? 0, name: LocalizedText.fromJson(json['name']));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name.toJson()};
}

/// Developer partner. The list endpoint returns a rich object (logo,
/// website, contact info, overview); the detail endpoint returns only
/// `{id, name}`. [merge] lets the repository layer fill in the gaps from
/// whichever copy has more data.
class DeveloperModel {
  const DeveloperModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.logo = '',
    this.website = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.overview,
  });

  final int id;
  final String name;
  final String slug;
  final String logo;
  final String website;
  final String email;
  final String phone;
  final String address;
  final String? overview;

  factory DeveloperModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DeveloperModel(id: 0, name: 'Unknown Developer');
    return DeveloperModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Developer',
      slug: json['slug'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      website: json['website'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      overview: json['overview'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'slug': slug,
        'logo': logo,
        'website': website,
        'email': email,
        'phone': phone,
        'address': address,
        'overview': overview,
      };

  /// Fills any blank field on this copy with a non-blank value from
  /// [richer] — used when a slim detail-response developer is merged with
  /// the fuller developer object already cached from the list response.
  DeveloperModel mergeWith(DeveloperModel richer) {
    return DeveloperModel(
      id: id != 0 ? id : richer.id,
      name: name.isNotEmpty && name != 'Unknown Developer' ? name : richer.name,
      slug: slug.isNotEmpty ? slug : richer.slug,
      logo: logo.isNotEmpty ? logo : richer.logo,
      website: website.isNotEmpty ? website : richer.website,
      email: email.isNotEmpty ? email : richer.email,
      phone: phone.isNotEmpty ? phone : richer.phone,
      address: address.isNotEmpty ? address : richer.address,
      overview: overview ?? richer.overview,
    );
  }
}

/// "9+", "1", etc. — the API mixes numeric and string values here, so it's
/// normalized to a display [value] string plus a localized unit [label].
class SubunitCount {
  const SubunitCount({required this.value, required this.label});

  final String value;
  final LocalizedText label;

  factory SubunitCount.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubunitCount(value: '', label: LocalizedText());
    return SubunitCount(
      value: '${json['value']}',
      label: LocalizedText.fromJson(json['label']),
    );
  }

  String get display => label.display.isNotEmpty ? '$value ${label.display}' : value;
}

/// One photo attached to a property. `type` was an unlabeled enum from the
/// previous backend (kept so [ProjectModel.galleryImages]'s `type == 1`
/// filter still works); the X-OPP API's flat `images` array has no such
/// distinction, so every image built from it is tagged `1`.
class PropertyImageModel {
  const PropertyImageModel({required this.url, required this.type});

  final String url;
  final int type;
}

/// A building facility/amenity (`{id, name}` only — no icon hint from the
/// API, so the UI resolves an icon by keyword-matching the name).
class FacilityModel {
  const FacilityModel({required this.id, required this.name});

  final int id;
  final LocalizedText name;

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(id: json['id'] as int? ?? 0, name: LocalizedText.fromJson(json['name']));
  }
}

/// A summarized unit typology within the project, e.g. "Apartment / 2
/// bedrooms starting at AED 4.7M" — this is the closest equivalent to a
/// traditional "floor plan" card. The X-OPP API has no per-type price/area
/// breakdown to build this from (only an overall bedroom/price/area range
/// per project), so [ProjectModel.groupedApartments] is currently always
/// empty; this class and its `fromJson` are kept in case a future catalog
/// or endpoint restores that data.
class GroupedApartmentModel {
  const GroupedApartmentModel({
    required this.id,
    required this.unitType,
    required this.rooms,
    required this.minPrice,
    required this.minArea,
  });

  final int id;
  final LocalizedText unitType;
  final LocalizedText rooms;
  final double minPrice;
  final double minArea;

  factory GroupedApartmentModel.fromJson(Map<String, dynamic> json) {
    return GroupedApartmentModel(
      id: json['id'] as int? ?? 0,
      unitType: LocalizedText.fromJson(json['unit_type']),
      rooms: LocalizedText.fromJson(json['rooms']),
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
      minArea: (json['min_area'] as num?)?.toDouble() ?? 0,
    );
  }

  String get title {
    final String roomsDisplay = rooms.display;
    final String type = unitType.display;
    if (roomsDisplay.isEmpty) return type;
    return '$type · ${roomsDisplay}BR';
  }
}

/// A single, individually listed unit for sale within the project, sourced
/// from the `/properties/{id}/units/` endpoint.
class PropertyUnitModel {
  const PropertyUnitModel({
    required this.id,
    required this.aptNo,
    this.area,
    this.price,
    this.floorNo,
    this.floorPlanImage,
    this.status = '',
    this.bedroomLabel = '',
  });

  final int id;
  final String aptNo;
  final double? area;
  final double? price;
  final int? floorNo;
  final String? floorPlanImage;
  final String status;

  /// The unit's type/bedroom count, e.g. "Studio", "2" — the API's
  /// `bedroom_label`. Shown as the unit's "type" in the units list.
  final String bedroomLabel;

  factory PropertyUnitModel.fromJson(Map<String, dynamic> json) {
    return PropertyUnitModel(
      id: json['id'] as int? ?? 0,
      aptNo: json['unit_no'] as String? ?? '—',
      area: (json['area'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      // The API's floor is free text (e.g. "G", "12") rather than a
      // guaranteed integer, so a non-numeric floor just leaves this null.
      floorNo: int.tryParse('${json['floor_no'] ?? ''}'),
      floorPlanImage: json['floor_plan_image'] as String?,
      status: json['status'] as String? ?? '',
      bedroomLabel: json['bedroom_label'] as String? ?? '',
    );
  }
}

/// One line item within a payment plan, e.g. "On Booking & 1st Payment —
/// 10%".
class PaymentPlanValueModel {
  const PaymentPlanValueModel({required this.name, required this.value});

  final String name;
  final String value;

  factory PaymentPlanValueModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanValueModel(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

/// A payment plan option, e.g. "60/40", with its milestone breakdown.
///
/// The X-OPP API gives each plan as `{name, down_payment_pct,
/// during_construction_pct, on_handover_pct, post_delivery_payment}` rather
/// than free-text milestone lines, so [ProjectModel.fromDetailJson]
/// synthesizes [values] from those percentages and uses
/// [post_delivery_payment] to fill [description] with a "Post-Handover"
/// tag — everything else about this class (and the card that renders it)
/// is unchanged.
class PaymentPlanModel {
  const PaymentPlanModel({required this.name, required this.description, required this.values});

  final LocalizedText name;
  final LocalizedText description;
  final List<PaymentPlanValueModel> values;

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      values: (json['values'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => PaymentPlanValueModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A property/project. The list endpoint (`/properties/`) populates the
/// "summary" fields; the detail endpoint (`/properties/{id}/`) additionally
/// populates the "detail" fields (nullable/empty by default). Use
/// [mergeDetail] to combine a cached list-summary with a freshly fetched
/// detail record so nothing already known gets lost, and [withPropertyUnits]
/// to attach the project's units once fetched from their own endpoint.
class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.address,
    required this.addressText,
    required this.deliveryDate,
    required this.deliveryDateLabel,
    required this.minArea,
    required this.lowPrice,
    required this.propertyTypeCode,
    required this.propertyType,
    required this.propertyStatusCode,
    required this.salesStatusCode,
    required this.city,
    required this.district,
    required this.developer,
    required this.subunitCount,
    this.updatedAt,
    this.salesStatusLabel,
    this.description,
    this.completionRate,
    this.rentalGuarantee,
    this.rentalGuaranteeValue,
    this.propertyImages = const <PropertyImageModel>[],
    // Detail-only fields — empty/null when this came from the list endpoint.
    this.downPayment,
    this.residentialUnits,
    this.commercialUnits,
    this.paymentMinimumDownPayment,
    this.postDelivery,
    this.facilities = const <FacilityModel>[],
    this.groupedApartments = const <GroupedApartmentModel>[],
    this.paymentPlans = const <PaymentPlanModel>[],
    this.propertyUnits = const <PropertyUnitModel>[],
  });

  // Summary fields (present on both list + detail responses)
  final int id;
  final LocalizedText title;
  final String cover;
  final String address; // "lat,lng" built from the API's latitude/longitude
  final String addressText; // no longer supplied by the API; always ''
  final int deliveryDate; // YYYYMM best-effort parsed from deliveryDateLabel
  final String deliveryDateLabel; // API's free-text delivery_date, e.g. "Q4 2027"
  final double minArea;
  final double lowPrice;
  final int propertyTypeCode;
  final String propertyType; // raw API string, e.g. "Apartment, Villa"
  final int propertyStatusCode; // 1 = Ready, 2 = Off-Plan (see propertyStatusLabel)
  final int salesStatusCode;
  final NamedRef city;
  final NamedRef district;
  final DeveloperModel developer;
  final SubunitCount subunitCount;
  final DateTime? updatedAt;

  /// Populated directly from the API's `sales_status_name` string.
  final LocalizedText? salesStatusLabel;

  final LocalizedText? description;
  final int? completionRate;
  final bool? rentalGuarantee;
  final double? rentalGuaranteeValue;
  final List<PropertyImageModel> propertyImages;

  // Detail-only fields
  final double? downPayment;
  final int? residentialUnits;
  final int? commercialUnits;
  final int? paymentMinimumDownPayment;
  final bool? postDelivery;
  final List<FacilityModel> facilities;
  final List<GroupedApartmentModel> groupedApartments;
  final List<PaymentPlanModel> paymentPlans;
  final List<PropertyUnitModel> propertyUnits;

  bool get isDetailLoaded => description != null;

  /// True for a project still marked "Off-Plan" whose handover date has
  /// already passed — almost certainly stale/uncorrected source data
  /// (a genuinely off-plan project can't have already been handed over),
  /// so it's filtered out of the browsable catalog by
  /// [ProjectsRepository] rather than shown as an "upcoming" listing.
  /// A `Ready` property with a past date is fine — that's just what
  /// "already delivered" means — so this only ever applies to code `2`.
  bool get isStaleOffPlan {
    final DateTime? handover = handoverDate;
    if (propertyStatusCode != 2 || handover == null) return false;
    final DateTime now = DateTime.now();
    // Compared against the start of the current month, not the exact
    // instant — handoverDate itself is only ever month-precision (day
    // fixed to the 1st), so a handover dated this same month shouldn't
    // read as "already past" just because today is later in it.
    return handover.isBefore(DateTime(now.year, now.month, 1));
  }

  double? get latitude => _addressParts.$1;
  double? get longitude => _addressParts.$2;

  (double?, double?) get _addressParts {
    final List<String> parts = address.split(',');
    if (parts.length != 2) return (null, null);
    return (double.tryParse(parts[0].trim()), double.tryParse(parts[1].trim()));
  }

  /// Converts the best-effort-parsed `YYYYMM` [deliveryDate] into a real
  /// [DateTime] (day fixed to the 1st, since no day is given). Returns null
  /// for unparsable/zero values — callers should fall back to
  /// [deliveryDateLabel] (the API's original free-text string) rather than
  /// [propertyStatusLabel] where possible, since it carries more info.
  DateTime? get handoverDate {
    if (deliveryDate <= 0) return null;
    final int year = deliveryDate ~/ 100;
    final int month = deliveryDate % 100;
    if (year < 1900 || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  /// "Ready" / "Off-Plan" — derived from the API's `property_status_name`
  /// ("Ready" / "Off Plan"). Falls back to a generic label if that string
  /// is missing or unrecognized.
  String get propertyStatusLabel {
    switch (propertyStatusCode) {
      case 1:
        return 'Ready';
      case 2:
        return 'Off-Plan';
      default:
        return 'Project';
    }
  }

  /// Sales-status label, straight from the API's `sales_status_name`
  /// (e.g. "On Sale", "Sold Out"), falling back to a non-committal default
  /// only if that string was missing.
  String get salesStatusDisplay {
    if (salesStatusLabel != null && salesStatusLabel!.display.isNotEmpty) {
      return salesStatusLabel!.display;
    }
    return 'For Sale';
  }

  /// Main gallery images (`type == 1`), falling back to just [cover] if
  /// no gallery photos are present (e.g. on a not-yet-detail-loaded card).
  List<String> get galleryImages {
    final List<String> gallery = propertyImages
        .where((PropertyImageModel img) => img.type == 1 && img.url.isNotEmpty)
        .map((PropertyImageModel img) => img.url)
        .toList();
    return gallery.isNotEmpty ? gallery : (cover.isNotEmpty ? <String>[cover] : <String>[]);
  }

  /// Orders by [deliveryDate] ascending (soonest handover first), with
  /// projects that have no parseable handover date (0 — typically an
  /// already-`Ready` property, or an Off-Plan one with an unrecognized
  /// date format) pushed to the end rather than sorting first, which a
  /// naive ascending-int compare would otherwise do since 0 is the
  /// smallest possible value.
  static int compareHandoverSoonest(ProjectModel a, ProjectModel b) {
    final int keyA = a.deliveryDate == 0 ? 999999 : a.deliveryDate;
    final int keyB = b.deliveryDate == 0 ? 999999 : b.deliveryDate;
    return keyA.compareTo(keyB);
  }

  /// Maps the API's free-text `property_status_name` onto the 1/Ready,
  /// 2/Off-Plan codes the rest of the app already filters/displays by.
  static int _statusCodeFromName(String? name) {
    final String n = (name ?? '').toLowerCase();
    if (n.contains('ready')) return 1;
    if (n.contains('off')) return 2;
    return 0;
  }

  static const Map<String, int> _monthNames = <String, int>{
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// The catalog's earliest plausible real handover year. Below this, a
  /// parsed date is treated as unsortable/unset rather than real — see
  /// [_parseDeliveryDate]'s doc comment for why this matters.
  static const int _earliestPlausibleYear = 2000;

  /// Best-effort turns a free-text delivery date into a sortable `YYYYMM`
  /// int, so [ProjectSort.handoverSoonest] keeps working. The live catalog
  /// sends a mix of formats — a plain `"YYYYMM"` code (e.g. `"202609"`),
  /// `"Q4 2027"`, a month name (`"December 2027"`, `"june 2029"`), a full
  /// date (`"2028-09-30"`), or an empty string for a `Ready` property —
  /// far more variety than the integration doc's single example suggests.
  ///
  /// A number of entries also send the literal string `"197001"` — an
  /// upstream data artifact (almost certainly an unset/zero timestamp on
  /// their side rendered as "Jan 1970") rather than a real handover date.
  /// No genuine off-plan or ready property predates [_earliestPlausibleYear],
  /// so any parse landing before it is treated the same as "no date" —
  /// this is what fixes handover dates showing as 1970 in the app.
  ///
  /// Returns 0 (unsortable/unset) for anything unparseable or implausible.
  static int _parseDeliveryDate(String? label) {
    if (label == null || label.isEmpty) return 0;

    final RegExpMatch? yyyymm = RegExp(r'^(\d{4})(\d{2})$').firstMatch(label);
    if (yyyymm != null) {
      final int year = int.parse(yyyymm.group(1)!);
      final int month = int.parse(yyyymm.group(2)!);
      if (month >= 1 && month <= 12 && year >= _earliestPlausibleYear) {
        return year * 100 + month;
      }
      return 0;
    }

    final RegExpMatch? isoDate = RegExp(r'^(\d{4})[-/](\d{1,2})[-/]\d{1,2}$').firstMatch(label);
    if (isoDate != null) {
      final int year = int.parse(isoDate.group(1)!);
      final int month = int.parse(isoDate.group(2)!);
      if (month >= 1 && month <= 12 && year >= _earliestPlausibleYear) {
        return year * 100 + month;
      }
      return 0;
    }

    final RegExpMatch? quarter = RegExp(r'Q\s*([1-4]).*?(\d{4})', caseSensitive: false).firstMatch(label);
    if (quarter != null) {
      final int q = int.parse(quarter.group(1)!);
      final int year = int.parse(quarter.group(2)!);
      if (year < _earliestPlausibleYear) return 0;
      return year * 100 + q * 3;
    }

    final RegExpMatch? monthName =
        RegExp(r'([A-Za-z]+)\D{0,4}(\d{4})', caseSensitive: false).firstMatch(label);
    if (monthName != null) {
      final int? month = _monthNames[monthName.group(1)!.toLowerCase()];
      final int year = int.parse(monthName.group(2)!);
      if (month != null && year >= _earliestPlausibleYear) {
        return year * 100 + month;
      }
    }

    final RegExpMatch? yearOnly = RegExp(r'^\D*(\d{4})\D*$').firstMatch(label);
    if (yearOnly != null) {
      final int year = int.parse(yearOnly.group(1)!);
      if (year >= _earliestPlausibleYear) return year * 100 + 1;
    }

    return 0;
  }

  /// True if [label] contains a 4-digit year token older than
  /// [_earliestPlausibleYear] — used to blank out known sentinel garbage
  /// (e.g. `"197001"`) from the *displayed* fallback label too, not just
  /// the sortable [deliveryDate] int, so a raw meaningless string like
  /// "197001" never reaches the screen even as plain text.
  static bool _looksLikeSentinelYear(String label) {
    final RegExpMatch? anyYear = RegExp(r'(\d{4})').firstMatch(label);
    if (anyYear == null) return false;
    return int.parse(anyYear.group(1)!) < _earliestPlausibleYear;
  }

  /// The API's raw `delivery_date` with known sentinel garbage (see
  /// [_looksLikeSentinelYear]) blanked out, so [deliveryDateLabel] never
  /// shows something meaningless like "197001" even as a last-resort
  /// fallback string.
  static String _cleanDeliveryDateLabel(String raw) => _looksLikeSentinelYear(raw) ? '' : raw;

  static NamedRef _namedRef(String? name) {
    final String display = name ?? '';
    return NamedRef(id: display.hashCode, name: LocalizedText(en: display));
  }

  static DeveloperModel _developer(String? name) {
    final String display = (name != null && name.isNotEmpty) ? name : 'Unknown Developer';
    return DeveloperModel(id: display.hashCode, name: display);
  }

  static List<PropertyImageModel> _images(Map<String, dynamic> json) {
    return (json['images'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => PropertyImageModel(url: e as String? ?? '', type: 1))
        .where((PropertyImageModel img) => img.url.isNotEmpty)
        .toList();
  }

  factory ProjectModel.fromListJson(Map<String, dynamic> json) {
    final String deliveryDateLabel = _cleanDeliveryDateLabel(json['delivery_date'] as String? ?? '');
    return ProjectModel(
      id: json['id'] as int,
      title: LocalizedText.fromJson(json['title']),
      cover: json['cover'] as String? ?? '',
      address: json['latitude'] != null && json['longitude'] != null
          ? '${json['latitude']},${json['longitude']}'
          : '',
      addressText: '',
      deliveryDate: _parseDeliveryDate(deliveryDateLabel),
      deliveryDateLabel: deliveryDateLabel,
      minArea: (json['area_from'] as num?)?.toDouble() ?? 0,
      lowPrice: (json['price_from'] as num?)?.toDouble() ?? 0,
      propertyTypeCode: 0,
      propertyType: json['property_type'] as String? ?? '',
      propertyStatusCode: _statusCodeFromName(json['property_status_name'] as String?),
      salesStatusCode: 0,
      salesStatusLabel: LocalizedText.fromJson(json['sales_status_name']),
      city: _namedRef(json['city'] as String?),
      district: _namedRef(json['district'] as String?),
      developer: _developer(json['developer_name'] as String?),
      subunitCount: SubunitCount(value: json['bedroom_labels'] as String? ?? '', label: const LocalizedText()),
      updatedAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      description: LocalizedText.fromJson(json['description']),
      completionRate: json['completion_rate'] as int?,
      rentalGuarantee: json['has_rental_guarantee'] as bool?,
      rentalGuaranteeValue: (json['rental_guarantee_pct'] as num?)?.toDouble(),
      propertyImages: _images(json),
    );
  }

  factory ProjectModel.fromDetailJson(Map<String, dynamic> json) {
    final String deliveryDateLabel = _cleanDeliveryDateLabel(json['delivery_date'] as String? ?? '');
    return ProjectModel(
      id: json['id'] as int,
      title: LocalizedText.fromJson(json['title']),
      cover: json['cover'] as String? ?? '',
      address: json['latitude'] != null && json['longitude'] != null
          ? '${json['latitude']},${json['longitude']}'
          : '',
      addressText: '',
      deliveryDate: _parseDeliveryDate(deliveryDateLabel),
      deliveryDateLabel: deliveryDateLabel,
      minArea: (json['area_from'] as num?)?.toDouble() ?? 0,
      lowPrice: (json['price_from'] as num?)?.toDouble() ?? 0,
      propertyTypeCode: 0,
      propertyType: json['property_type'] as String? ?? '',
      propertyStatusCode: _statusCodeFromName(json['property_status_name'] as String?),
      salesStatusCode: 0,
      salesStatusLabel: LocalizedText.fromJson(json['sales_status_name']),
      city: _namedRef(json['city'] as String?),
      district: _namedRef(json['district'] as String?),
      developer: _developer(json['developer_name'] as String?),
      subunitCount: SubunitCount(value: json['bedroom_labels'] as String? ?? '', label: const LocalizedText()),
      updatedAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      description: LocalizedText.fromJson(json['description']),
      completionRate: json['completion_rate'] as int?,
      rentalGuarantee: json['has_rental_guarantee'] as bool?,
      rentalGuaranteeValue: (json['rental_guarantee_pct'] as num?)?.toDouble(),
      propertyImages: _images(json),
      downPayment: (json['down_payment_pct'] as num?)?.toDouble(),
      residentialUnits: json['residential_units'] as int?,
      commercialUnits: json['commercial_units'] as int?,
      paymentMinimumDownPayment: json['down_payment_amount'] as int?,
      postDelivery: json['post_delivery_payment'] as bool?,
      facilities: (json['amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => FacilityModel(id: (e as String).hashCode, name: LocalizedText(en: e)))
          .toList(),
      // No per-unit-type price/area breakdown in this API — see
      // GroupedApartmentModel's doc comment. Individual units still come
      // from the separate /units/ endpoint via [withPropertyUnits].
      groupedApartments: const <GroupedApartmentModel>[],
      paymentPlans: (json['payment_plans'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => _paymentPlanFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Builds a [PaymentPlanModel] from the API's `{name, down_payment_pct,
  /// during_construction_pct, on_handover_pct, post_delivery_payment}`
  /// shape — see that class's doc comment for why this isn't a plain
  /// `fromJson` on it.
  static PaymentPlanModel _paymentPlanFromJson(Map<String, dynamic> json) {
    final List<PaymentPlanValueModel> values = <PaymentPlanValueModel>[];
    void addPct(String label, dynamic pct) {
      if (pct != null) values.add(PaymentPlanValueModel(name: label, value: '$pct%'));
    }

    addPct('Down Payment', json['down_payment_pct']);
    addPct('During Construction', json['during_construction_pct']);
    addPct('On Handover', json['on_handover_pct']);

    return PaymentPlanModel(
      name: LocalizedText(en: json['name'] as String? ?? 'Payment Plan'),
      description: (json['post_delivery_payment'] as bool? ?? false)
          ? const LocalizedText(en: 'Post-Handover')
          : const LocalizedText(),
      values: values,
    );
  }

  /// Combines this record with a freshly fetched [detail] record: detail's
  /// core fields win (they're authoritative/fresher), and detail-only
  /// collections are adopted wholesale.
  ProjectModel mergeDetail(ProjectModel detail) {
    return ProjectModel(
      id: detail.id,
      title: detail.title,
      cover: detail.cover.isNotEmpty ? detail.cover : cover,
      address: detail.address.isNotEmpty ? detail.address : address,
      addressText: detail.addressText.isNotEmpty ? detail.addressText : addressText,
      deliveryDate: detail.deliveryDate != 0 ? detail.deliveryDate : deliveryDate,
      deliveryDateLabel: detail.deliveryDateLabel.isNotEmpty ? detail.deliveryDateLabel : deliveryDateLabel,
      minArea: detail.minArea != 0 ? detail.minArea : minArea,
      lowPrice: detail.lowPrice != 0 ? detail.lowPrice : lowPrice,
      propertyTypeCode: detail.propertyTypeCode,
      propertyType: detail.propertyType.isNotEmpty ? detail.propertyType : propertyType,
      propertyStatusCode: detail.propertyStatusCode,
      salesStatusCode: detail.salesStatusCode,
      salesStatusLabel: detail.salesStatusLabel ?? salesStatusLabel,
      city: detail.city.id != 0 ? detail.city : city,
      district: detail.district.id != 0 ? detail.district : district,
      developer: detail.developer.mergeWith(developer),
      subunitCount: detail.subunitCount.display.isNotEmpty ? detail.subunitCount : subunitCount,
      updatedAt: detail.updatedAt ?? updatedAt,
      description: detail.description ?? description,
      completionRate: detail.completionRate ?? completionRate,
      rentalGuarantee: detail.rentalGuarantee ?? rentalGuarantee,
      rentalGuaranteeValue: detail.rentalGuaranteeValue ?? rentalGuaranteeValue,
      propertyImages: detail.propertyImages.isNotEmpty ? detail.propertyImages : propertyImages,
      downPayment: detail.downPayment,
      residentialUnits: detail.residentialUnits,
      commercialUnits: detail.commercialUnits,
      paymentMinimumDownPayment: detail.paymentMinimumDownPayment,
      postDelivery: detail.postDelivery,
      facilities: detail.facilities,
      groupedApartments: detail.groupedApartments,
      paymentPlans: detail.paymentPlans,
      propertyUnits: detail.propertyUnits.isNotEmpty ? detail.propertyUnits : propertyUnits,
    );
  }

  /// Attaches units fetched from the separate `/properties/{id}/units/`
  /// endpoint (see [ProjectsRepository.getById]) — everything else about
  /// the record is left as-is.
  ProjectModel withPropertyUnits(List<PropertyUnitModel> units) {
    return ProjectModel(
      id: id,
      title: title,
      cover: cover,
      address: address,
      addressText: addressText,
      deliveryDate: deliveryDate,
      deliveryDateLabel: deliveryDateLabel,
      minArea: minArea,
      lowPrice: lowPrice,
      propertyTypeCode: propertyTypeCode,
      propertyType: propertyType,
      propertyStatusCode: propertyStatusCode,
      salesStatusCode: salesStatusCode,
      salesStatusLabel: salesStatusLabel,
      city: city,
      district: district,
      developer: developer,
      subunitCount: subunitCount,
      updatedAt: updatedAt,
      description: description,
      completionRate: completionRate,
      rentalGuarantee: rentalGuarantee,
      rentalGuaranteeValue: rentalGuaranteeValue,
      propertyImages: propertyImages,
      downPayment: downPayment,
      residentialUnits: residentialUnits,
      commercialUnits: commercialUnits,
      paymentMinimumDownPayment: paymentMinimumDownPayment,
      postDelivery: postDelivery,
      facilities: facilities,
      groupedApartments: groupedApartments,
      paymentPlans: paymentPlans,
      propertyUnits: units,
    );
  }
}
