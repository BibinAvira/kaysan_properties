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

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'en': en, 'ar': ar, 'fa': fa};
}

/// A simple `{id, name}` reference used for both `city` and `district`.
/// Reelly's project `location` object gives these as plain display
/// strings (no numeric id of their own attached to the project), so [id]
/// is synthesized from the name — stable and unique enough for local
/// grouping/equality checks (Areas, filter chips), just not a real
/// server-side id.
class NamedRef {
  const NamedRef({required this.id, required this.name});

  final int id;
  final LocalizedText name;

  factory NamedRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NamedRef(id: 0, name: LocalizedText());
    return NamedRef(
        id: json['id'] as int? ?? 0,
        name: LocalizedText.fromJson(json['name']));
  }

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'name': name.toJson()};
}

/// Developer partner. Reelly's `/developers` directory returns the full
/// profile (logo, website, contact info, description); a project only
/// ever carries the developer's plain *name* string, so
/// [ProjectsRepository] resolves the real [id]/[logo]/etc. by matching
/// that name against a once-fetched, cached copy of the directory (see
/// [ProjectsRepository.developerDirectory]). A project whose developer
/// name doesn't match anything in the directory still gets a usable
/// (if id-less) [DeveloperModel] via [DeveloperModel.placeholder].
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

  /// Used when a project's developer name has no match in the cached
  /// `/developers` directory — [id] is synthesized from the name so
  /// equality/grouping (Areas, Developer Details linking) still works,
  /// just without a real server-side id to fetch more detail by.
  factory DeveloperModel.placeholder(String name) {
    final String display = name.isNotEmpty ? name : 'Unknown Developer';
    return DeveloperModel(id: display.hashCode, name: display);
  }

  factory DeveloperModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? logo = json['logo'] as Map<String, dynamic>?;
    return DeveloperModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Developer',
      slug: json['slug_name'] as String? ?? '',
      logo: logo?['url'] as String? ?? '',
      website: json['website'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: '',
      overview: json['description'] as String?,
    );
  }
}

/// "9+", "1", etc. — a display-ready bedroom-count summary. Reelly gives
/// this as a numeric `min_bedrooms`/`max_bedrooms` range rather than a
/// single free-text label, so [display] is synthesized from that range
/// (see [ProjectModel._subunitFromBedrooms]) instead of coming straight
/// off the wire.
class SubunitCount {
  const SubunitCount({required this.value, required this.label});

  final String value;
  final LocalizedText label;

  String get display =>
      label.display.isNotEmpty ? '$value ${label.display}' : value;
}

/// One photo attached to a property. `type` was an unlabeled enum from an
/// earlier backend (kept so [ProjectModel.galleryImages]'s `type == 1`
/// filter still works); every image gathered from Reelly's media fields is
/// tagged `1`.
class PropertyImageModel {
  const PropertyImageModel({required this.url, required this.type});

  final String url;
  final int type;
}

/// A building facility/amenity (`{id, name}` — Reelly also gives an icon
/// image per amenity, not currently used since the UI resolves its own
/// icon by keyword-matching the name).
class FacilityModel {
  const FacilityModel({required this.id, required this.name});

  final int id;
  final LocalizedText name;
}

/// A summarized unit typology within the project, e.g. "Studio starting at
/// AED 1.4M" — built from Reelly's `typical_units[]` (bedroom count + price
////size range per typology), the closest equivalent to a traditional
/// "floor plan" card.
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

  String get title {
    final String roomsDisplay = rooms.display;
    final String type = unitType.display;
    if (roomsDisplay.isEmpty) return type;
    return '$type · ${roomsDisplay}BR';
  }
}

/// A single, individually listed unit for sale within the project, sourced
/// from `/projects/{id}/units` — an Enterprise-tier-gated Reelly endpoint,
/// so [ProjectsRepository.getById] treats a failure here as "no unit-level
/// data available" rather than a hard error.
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

  /// The unit's type/bedroom count, e.g. "Studio", "2" — shown as the
  /// unit's "type" in the units list.
  final String bedroomLabel;

  factory PropertyUnitModel.fromJson(Map<String, dynamic> json) {
    final num? bedrooms = json['bedrooms'] as num?;
    return PropertyUnitModel(
      id: json['id'] as int? ?? 0,
      aptNo: json['unit_number'] as String? ?? json['name'] as String? ?? '—',
      area: (json['area'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      floorNo: int.tryParse('${json['floor'] ?? ''}'),
      floorPlanImage:
          (json['layout'] as Map<String, dynamic>?)?['url'] as String?,
      status: json['status'] as String? ?? '',
      bedroomLabel: bedrooms == null
          ? ''
          : (bedrooms == 0 ? 'Studio' : '$bedrooms'),
    );
  }
}

/// One line item within a payment plan, e.g. "On Booking — 10%".
class PaymentPlanValueModel {
  const PaymentPlanValueModel({required this.name, required this.value});

  final String name;
  final String value;
}

/// A payment plan option with its milestone breakdown, built from Reelly's
/// `payment_plans[].steps[]` (each step: `{name, percentage}`).
/// [description] carries a "Post-Handover" tag when the plan extends past
/// handover ([PaymentPlanModel._isPostHandover]).
class PaymentPlanModel {
  const PaymentPlanModel(
      {required this.name, required this.description, required this.values});

  final LocalizedText name;
  final LocalizedText description;
  final List<PaymentPlanValueModel> values;
}

/// A property/project. The list endpoint (`/projects`) populates the
/// "summary" fields; the detail endpoint (`/projects/{id}`) additionally
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
    this.highPrice = 0,
    required this.propertyTypeCode,
    required this.propertyType,
    required this.propertyStatusCode,
    required this.salesStatusCode,
    required this.city,
    required this.district,
    this.countryId,
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
  final String address; // "lat,lng" built from location.latitude/longitude
  final String addressText; // not supplied by the API; always ''
  final int deliveryDate; // YYYYMM parsed from completion_datetime
  final String deliveryDateLabel; // API's free-text completion_date, e.g. "DEC 2024"
  final double minArea;
  final double lowPrice;

  /// Reelly's `max_price` — the most expensive unit; 0 when unknown. With
  /// [lowPrice] it gives the project's price span, which the price filter
  /// matches by overlap (see [ProjectsRepository.applyFilter]).
  final double highPrice;
  final int propertyTypeCode;
  final String propertyType; // joined available_unit_types_display, e.g. "Apartment, Villa"
  final int propertyStatusCode; // 1 = Ready, 2 = Off-Plan (see propertyStatusLabel)
  final int salesStatusCode;
  final NamedRef city;
  final NamedRef district;

  /// Reelly's `location.country` id (219 = UAE); null when missing.
  final int? countryId;
  final DeveloperModel developer;
  final SubunitCount subunitCount;
  final DateTime? updatedAt;

  /// Populated directly from the API's `sale_status_display` string.
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

  /// Converts the parsed `YYYYMM` [deliveryDate] into a real [DateTime]
  /// (day fixed to the 1st, since no day is given). Returns null for
  /// unparsable/zero values — callers should fall back to
  /// [deliveryDateLabel] (the API's original free-text string) rather than
  /// [propertyStatusLabel] where possible, since it carries more info.
  DateTime? get handoverDate {
    if (deliveryDate <= 0) return null;
    final int year = deliveryDate ~/ 100;
    final int month = deliveryDate % 100;
    if (year < 1900 || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  /// "Ready" / "Off-Plan" — derived from [propertyStatusCode].
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

  /// Sales-status label, straight from the API's `sale_status_display`
  /// (e.g. "On Sale", "Out of Stock"), falling back to a non-committal
  /// default only if that string was missing.
  String get salesStatusDisplay {
    if (salesStatusLabel != null && salesStatusLabel!.display.isNotEmpty) {
      return salesStatusLabel!.display;
    }
    return 'For Sale';
  }

  /// Main gallery images (`type == 1`), falling back to just [cover] if
  /// no gallery photos are present (e.g. on a not-yet-detail-loaded card).
  ///
  /// [cover] — the same image shown as the property card's thumbnail — is
  /// always pinned first so the detail page's gallery opens on the photo
  /// the user already saw on the card, rather than whatever order the API
  /// happened to return the `type == 1` images in.
  List<String> get galleryImages {
    final List<String> gallery = propertyImages
        .where((PropertyImageModel img) => img.type == 1 && img.url.isNotEmpty)
        .map((PropertyImageModel img) => img.url)
        .toList();
    if (gallery.isEmpty) {
      return cover.isNotEmpty ? <String>[cover] : <String>[];
    }
    if (cover.isNotEmpty) {
      gallery.remove(cover);
      gallery.insert(0, cover);
    }
    return gallery;
  }

  /// Orders by [deliveryDate] ascending (soonest handover first), with
  /// projects that have no parseable handover date (0 — typically an
  /// already-`Ready` property) pushed to the end rather than sorting
  /// first, which a naive ascending-int compare would otherwise do since
  /// 0 is the smallest possible value.
  static int compareHandoverSoonest(ProjectModel a, ProjectModel b) {
    final int keyA = a.deliveryDate == 0 ? 999999 : a.deliveryDate;
    final int keyB = b.deliveryDate == 0 ? 999999 : b.deliveryDate;
    return keyA.compareTo(keyB);
  }

  /// [value] if it is a string, else null — for API fields whose type
  /// isn't reliable.
  static String? _text(Object? value) => value is String ? value : null;

  static NamedRef _namedRef(String? name) {
    final String display = name ?? '';
    return NamedRef(id: display.hashCode, name: LocalizedText(en: display));
  }

  /// Synthesizes a bedroom-range display string ("Studio", "2", "1-3")
  /// from Reelly's numeric `min_bedrooms`/`max_bedrooms` — there's no
  /// single free-text bedroom label on this API the way the previous
  /// backend provided one.
  static SubunitCount _subunitFromBedrooms(num? min, num? max) {
    String label(num n) => n == 0 ? 'Studio' : '${n.toInt()}';
    if (min == null && max == null) {
      return const SubunitCount(value: '', label: LocalizedText());
    }
    final num lo = min ?? max!;
    final num hi = max ?? min!;
    final String value = lo == hi ? label(lo) : '${label(lo)}-${label(hi)}';
    return SubunitCount(value: value, label: const LocalizedText());
  }

  /// Best-effort turns the API's ISO `completion_datetime` into a sortable
  /// `YYYYMM` int, so handovers compare by month (Home's Off-Plan pick uses
  /// [compareHandoverSoonest]). Falls
  /// back to parsing the free-text `completion_date` label (e.g. "Q4
  /// 2027", "DEC 2024") for the rare record missing the ISO field.
  /// Returns 0 (unsortable/unset) for anything unparseable — e.g. an
  /// already-`Ready` project with no future completion date.
  static int _parseDeliveryDate(String? isoDateTime, String? label) {
    final DateTime? iso =
        isoDateTime == null ? null : DateTime.tryParse(isoDateTime);
    if (iso != null) return iso.year * 100 + iso.month;
    return _parseLabel(label);
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

  static const int _earliestPlausibleYear = 2000;

  static int _parseLabel(String? label) {
    if (label == null || label.isEmpty) return 0;

    final RegExpMatch? quarter =
        RegExp(r'Q\s*([1-4]).*?(\d{4})', caseSensitive: false)
            .firstMatch(label);
    if (quarter != null) {
      final int q = int.parse(quarter.group(1)!);
      final int year = int.parse(quarter.group(2)!);
      if (year < _earliestPlausibleYear) return 0;
      return year * 100 + q * 3;
    }

    final RegExpMatch? monthName =
        RegExp(r'([A-Za-z]+)\D{0,4}(\d{4})', caseSensitive: false)
            .firstMatch(label);
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

  static List<PropertyImageModel> _urls(Iterable<String> urls) => urls
      .where((String u) => u.isNotEmpty)
      .map((String u) => PropertyImageModel(url: u, type: 1))
      .toList();

  static String? _mediaUrl(dynamic media) =>
      (media as Map<String, dynamic>?)?['url'] as String?;

  static List<String> _mediaListUrls(dynamic list) => (list as List<dynamic>? ?? <dynamic>[])
      .map((dynamic e) => _mediaUrl(e) ?? '')
      .where((String u) => u.isNotEmpty)
      .toList();

  /// Fields present on both the list (`/projects`) and detail
  /// (`/projects/{id}`) responses. [developers] is the cached
  /// name→[DeveloperModel] directory from [ProjectsRepository] — passed in
  /// so every project can resolve a real developer id/logo instead of a
  /// name-only placeholder; omitted (or a miss) falls back to
  /// [DeveloperModel.placeholder].
  static ProjectModel _fromCommonJson(
    Map<String, dynamic> json, {
    Map<String, DeveloperModel>? developers,
    List<PropertyImageModel> propertyImages = const <PropertyImageModel>[],
    int? completionRate,
    List<FacilityModel> facilities = const <FacilityModel>[],
    List<GroupedApartmentModel> groupedApartments = const <GroupedApartmentModel>[],
    List<PaymentPlanModel> paymentPlans = const <PaymentPlanModel>[],
  }) {
    final Map<String, dynamic>? location =
        json['location'] as Map<String, dynamic>?;
    final double? lat = (location?['latitude'] as num?)?.toDouble();
    final double? lng = (location?['longitude'] as num?)?.toDouble();
    final String deliveryDateLabel = json['completion_date'] as String? ?? '';
    final String developerName = json['developer'] as String? ?? '';
    final List<String> unitTypes =
        (json['available_unit_types_display'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => '$e')
            .toList();

    return ProjectModel(
      id: json['id'] as int,
      title: LocalizedText(en: json['name'] as String? ?? ''),
      cover: _mediaUrl(json['cover_image']) ?? '',
      address: lat != null && lng != null ? '$lat,$lng' : '',
      addressText: '',
      deliveryDate:
          _parseDeliveryDate(json['completion_datetime'] as String?, deliveryDateLabel),
      deliveryDateLabel: deliveryDateLabel,
      minArea: (json['min_size'] as num?)?.toDouble() ?? 0,
      lowPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
      highPrice: (json['max_price'] as num?)?.toDouble() ?? 0,
      propertyTypeCode: 0,
      propertyType: unitTypes.join(', '),
      propertyStatusCode: json['construction_status'] == 'completed' ? 1 : 2,
      salesStatusCode: 0,
      salesStatusLabel: LocalizedText.fromJson(json['sale_status_display']),
      // Reelly sometimes sends `city` as a numeric id rather than a name
      // (seen when `region` is empty), so these are read leniently.
      city: _namedRef((_text(location?['region'])?.isNotEmpty ?? false)
          ? _text(location!['region'])
          : _text(location?['city'])),
      district: _namedRef(_text(location?['district'])),
      countryId: location?['country'] is int ? location!['country'] as int : null,
      developer: developers?[developerName] ??
          DeveloperModel.placeholder(developerName),
      subunitCount: _subunitFromBedrooms(
          json['min_bedrooms'] as num?, json['max_bedrooms'] as num?),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      description: LocalizedText(
          en: json['overview'] as String? ??
              json['short_description'] as String? ??
              ''),
      completionRate: completionRate,
      residentialUnits: json['units_count'] as int?,
      propertyImages: propertyImages,
      facilities: facilities,
      groupedApartments: groupedApartments,
      paymentPlans: paymentPlans,
    );
  }

  factory ProjectModel.fromListJson(
    Map<String, dynamic> json, {
    Map<String, DeveloperModel>? developers,
  }) {
    return _fromCommonJson(json, developers: developers);
  }

  factory ProjectModel.fromDetailJson(
    Map<String, dynamic> json, {
    Map<String, DeveloperModel>? developers,
  }) {
    return _fromCommonJson(
      json,
      developers: developers,
      propertyImages: _urls(<String>[
        ..._mediaListUrls(json['interior']),
        ..._mediaListUrls(json['lobby']),
        ..._mediaListUrls(json['architecture']),
      ]).map((PropertyImageModel i) => i.url).toSet().map(
          (String url) => PropertyImageModel(url: url, type: 1)).toList(),
      completionRate: (json['readiness_progress'] as num?)?.round(),
      facilities: (json['project_amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => _amenityFromJson(e as Map<String, dynamic>))
          .toList(),
      groupedApartments:
          (json['typical_units'] as List<dynamic>? ?? <dynamic>[])
              .toList()
              .asMap()
              .entries
              .map((MapEntry<int, dynamic> e) =>
                  _typicalUnitFromJson(e.key, e.value as Map<String, dynamic>))
              .toList(),
      paymentPlans: (json['payment_plans'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => _paymentPlanFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static FacilityModel _amenityFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? amenity =
        json['amenity'] as Map<String, dynamic>?;
    return FacilityModel(
      id: json['id'] as int? ?? 0,
      name: LocalizedText(en: amenity?['name'] as String? ?? ''),
    );
  }

  static GroupedApartmentModel _typicalUnitFromJson(
      int index, Map<String, dynamic> json) {
    final num bedrooms = json['bedrooms'] as num? ?? 0;
    final String roomsDisplay = bedrooms == 0 ? '' : '${bedrooms.toInt()}';
    return GroupedApartmentModel(
      id: index,
      unitType: LocalizedText(en: bedrooms == 0 ? 'Studio' : 'Apartment'),
      rooms: LocalizedText(en: roomsDisplay),
      minPrice: (json['from_price_aed'] as num?)?.toDouble() ?? 0,
      minArea: (json['from_size_sqft'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Builds a [PaymentPlanModel] from Reelly's `{name, is_handover,
  /// months_after_handover, steps: [{name, percentage}]}` shape.
  static PaymentPlanModel _paymentPlanFromJson(Map<String, dynamic> json) {
    final List<dynamic> steps = json['steps'] as List<dynamic>? ?? <dynamic>[];
    final List<PaymentPlanValueModel> values = steps
        .map((dynamic e) => e as Map<String, dynamic>)
        .map((Map<String, dynamic> step) => PaymentPlanValueModel(
              name: step['name'] as String? ?? '',
              value: '${step['percentage'] ?? 0}%',
            ))
        .toList();

    final bool isPostHandover = (json['is_handover'] as bool? ?? false) ||
        ((json['months_after_handover'] as num?) ?? 0) > 0;

    return PaymentPlanModel(
      name: LocalizedText(en: json['name'] as String? ?? 'Payment Plan'),
      description: isPostHandover
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
      addressText:
          detail.addressText.isNotEmpty ? detail.addressText : addressText,
      deliveryDate:
          detail.deliveryDate != 0 ? detail.deliveryDate : deliveryDate,
      deliveryDateLabel: detail.deliveryDateLabel.isNotEmpty
          ? detail.deliveryDateLabel
          : deliveryDateLabel,
      minArea: detail.minArea != 0 ? detail.minArea : minArea,
      lowPrice: detail.lowPrice != 0 ? detail.lowPrice : lowPrice,
      highPrice: detail.highPrice != 0 ? detail.highPrice : highPrice,
      propertyTypeCode: detail.propertyTypeCode,
      propertyType:
          detail.propertyType.isNotEmpty ? detail.propertyType : propertyType,
      propertyStatusCode: detail.propertyStatusCode,
      salesStatusCode: detail.salesStatusCode,
      salesStatusLabel: detail.salesStatusLabel ?? salesStatusLabel,
      city: detail.city.id != 0 ? detail.city : city,
      district: detail.district.id != 0 ? detail.district : district,
      countryId: detail.countryId ?? countryId,
      developer: detail.developer.id != 0 ? detail.developer : developer,
      subunitCount: detail.subunitCount.display.isNotEmpty
          ? detail.subunitCount
          : subunitCount,
      updatedAt: detail.updatedAt ?? updatedAt,
      description: detail.description ?? description,
      completionRate: detail.completionRate ?? completionRate,
      rentalGuarantee: detail.rentalGuarantee ?? rentalGuarantee,
      rentalGuaranteeValue: detail.rentalGuaranteeValue ?? rentalGuaranteeValue,
      propertyImages: detail.propertyImages.isNotEmpty
          ? detail.propertyImages
          : propertyImages,
      downPayment: detail.downPayment,
      residentialUnits: detail.residentialUnits,
      commercialUnits: detail.commercialUnits,
      paymentMinimumDownPayment: detail.paymentMinimumDownPayment,
      postDelivery: detail.postDelivery,
      facilities: detail.facilities,
      groupedApartments: detail.groupedApartments,
      paymentPlans: detail.paymentPlans,
      propertyUnits: detail.propertyUnits.isNotEmpty
          ? detail.propertyUnits
          : propertyUnits,
    );
  }

  /// Attaches units fetched from the separate `/projects/{id}/units`
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
      highPrice: highPrice,
      propertyTypeCode: propertyTypeCode,
      propertyType: propertyType,
      propertyStatusCode: propertyStatusCode,
      salesStatusCode: salesStatusCode,
      salesStatusLabel: salesStatusLabel,
      city: city,
      district: district,
      countryId: countryId,
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
