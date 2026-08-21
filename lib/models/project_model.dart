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

/// One photo attached to a property. `type` is an unlabeled API enum;
/// empirically `1` is the general gallery/exterior photo bucket, so that's
/// what's used for the main image carousel — other types are kept around
/// for future use (e.g. floor-plan or amenity photo sets) rather than
/// discarded.
class PropertyImageModel {
  const PropertyImageModel({required this.url, required this.type});

  final String url;
  final int type;

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) {
    return PropertyImageModel(url: json['image'] as String? ?? '', type: json['type'] as int? ?? 1);
  }
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
/// traditional "floor plan" card, sourced from `grouped_apartments`.
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
/// from `property_units`.
class PropertyUnitModel {
  const PropertyUnitModel({
    required this.id,
    required this.aptNo,
    this.area,
    this.price,
    this.floorNo,
    this.floorPlanImage,
    this.status = '',
  });

  final int id;
  final String aptNo;
  final double? area;
  final double? price;
  final int? floorNo;
  final String? floorPlanImage;
  final String status;

  factory PropertyUnitModel.fromJson(Map<String, dynamic> json) {
    return PropertyUnitModel(
      id: json['id'] as int? ?? 0,
      aptNo: json['apt_no'] as String? ?? '—',
      area: (json['area'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      floorNo: json['floor_no'] as int?,
      floorPlanImage: json['floor_plan_image'] as String?,
      status: json['status'] as String? ?? '',
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
/// "summary" fields; the detail endpoint (`/property/{id}/`) additionally
/// populates the "detail" fields (nullable/empty by default). Use
/// [mergeDetail] to combine a cached list-summary with a freshly fetched
/// detail record so nothing already known (e.g. the richer developer
/// profile) gets lost.
class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.address,
    required this.addressText,
    required this.deliveryDate,
    required this.minArea,
    required this.lowPrice,
    required this.propertyTypeCode,
    required this.propertyStatusCode,
    required this.salesStatusCode,
    required this.city,
    required this.district,
    required this.developer,
    required this.subunitCount,
    this.updatedAt,
    this.salesStatusLabel,
    // Detail-only fields — empty/null when this came from the list endpoint.
    this.description,
    this.downPayment,
    this.completionRate,
    this.residentialUnits,
    this.commercialUnits,
    this.paymentMinimumDownPayment,
    this.postDelivery,
    this.rentalGuarantee,
    this.rentalGuaranteeValue,
    this.propertyImages = const <PropertyImageModel>[],
    this.facilities = const <FacilityModel>[],
    this.groupedApartments = const <GroupedApartmentModel>[],
    this.paymentPlans = const <PaymentPlanModel>[],
    this.propertyUnits = const <PropertyUnitModel>[],
  });

  // Summary fields (present on both list + detail responses)
  final int id;
  final LocalizedText title;
  final String cover;
  final String address; // raw "lat,lng" string
  final String addressText; // Google Maps share link
  final int deliveryDate; // YYYYMM, e.g. 202601
  final double minArea;
  final double lowPrice;
  final int propertyTypeCode;
  final int propertyStatusCode; // 1 = Ready, 2 = Off-Plan (see propertyStatusLabel)
  final int salesStatusCode;
  final NamedRef city;
  final NamedRef district;
  final DeveloperModel developer;
  final SubunitCount subunitCount;
  final DateTime? updatedAt;

  /// Only reliably known from the detail endpoint, which returns
  /// `sales_status` as `{id, name}` instead of a bare code.
  final LocalizedText? salesStatusLabel;

  // Detail-only fields
  final LocalizedText? description;
  final double? downPayment;
  final int? completionRate;
  final int? residentialUnits;
  final int? commercialUnits;
  final int? paymentMinimumDownPayment;
  final bool? postDelivery;
  final bool? rentalGuarantee;
  final double? rentalGuaranteeValue;
  final List<PropertyImageModel> propertyImages;
  final List<FacilityModel> facilities;
  final List<GroupedApartmentModel> groupedApartments;
  final List<PaymentPlanModel> paymentPlans;
  final List<PropertyUnitModel> propertyUnits;

  bool get isDetailLoaded => description != null;

  double? get latitude => _addressParts.$1;
  double? get longitude => _addressParts.$2;

  (double?, double?) get _addressParts {
    final List<String> parts = address.split(',');
    if (parts.length != 2) return (null, null);
    return (double.tryParse(parts[0].trim()), double.tryParse(parts[1].trim()));
  }

  /// Converts the API's `YYYYMM` integer into a real [DateTime] (day fixed
  /// to the 1st, since no day is given). Returns null for unparsable/zero
  /// values.
  DateTime? get handoverDate {
    if (deliveryDate <= 0) return null;
    final int year = deliveryDate ~/ 100;
    final int month = deliveryDate % 100;
    if (year < 1900 || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  /// "Ready" / "Off-Plan" — inferred from observed data (property_status
  /// 1 consistently corresponds to already-delivered projects, 2 to
  /// projects still under construction regardless of nominal delivery
  /// date). Falls back to a generic label for any other code.
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

  /// Best-effort sales-status label. Only code `1` ("Available") is
  /// confirmed directly from the API (the detail endpoint's `sales_status`
  /// object); other codes fall back to a non-committal "For Sale" rather
  /// than guessing a specific status that could be wrong.
  String get salesStatusDisplay {
    if (salesStatusLabel != null && salesStatusLabel!.display.isNotEmpty) {
      return salesStatusLabel!.display;
    }
    return salesStatusCode == 1 ? 'Available' : 'For Sale';
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

  factory ProjectModel.fromListJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      title: LocalizedText.fromJson(json['title']),
      cover: json['cover'] as String? ?? '',
      address: json['address'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      deliveryDate: json['delivery_date'] as int? ?? 0,
      minArea: (json['min_area'] as num?)?.toDouble() ?? 0,
      lowPrice: (json['low_price'] as num?)?.toDouble() ?? 0,
      propertyTypeCode: json['property_type'] as int? ?? 0,
      propertyStatusCode: json['property_status'] as int? ?? 0,
      salesStatusCode: json['sales_status'] as int? ?? 0,
      city: NamedRef.fromJson(json['city'] as Map<String, dynamic>?),
      district: NamedRef.fromJson(json['district'] as Map<String, dynamic>?),
      developer: DeveloperModel.fromJson(json['developer'] as Map<String, dynamic>?),
      subunitCount: SubunitCount.fromJson(json['subunit_count'] as Map<String, dynamic>?),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  factory ProjectModel.fromDetailJson(Map<String, dynamic> json) {
    final dynamic salesStatusRaw = json['sales_status'];
    return ProjectModel(
      id: json['id'] as int,
      title: LocalizedText.fromJson(json['title']),
      cover: json['cover'] as String? ?? '',
      address: json['address'] as String? ?? '',
      addressText: json['address_text'] as String? ?? '',
      deliveryDate: json['delivery_date'] as int? ?? 0,
      minArea: (json['min_area'] as num?)?.toDouble() ?? 0,
      lowPrice: (json['low_price'] as num?)?.toDouble() ?? 0,
      propertyTypeCode: json['property_type'] as int? ?? 0,
      propertyStatusCode: json['property_status'] as int? ?? 0,
      salesStatusCode: salesStatusRaw is Map<String, dynamic>
          ? (salesStatusRaw['id'] as int? ?? 0)
          : (salesStatusRaw as int? ?? 0),
      salesStatusLabel:
          salesStatusRaw is Map<String, dynamic> ? LocalizedText.fromJson(salesStatusRaw['name']) : null,
      city: NamedRef.fromJson(json['city'] as Map<String, dynamic>?),
      district: NamedRef.fromJson(json['district'] as Map<String, dynamic>?),
      developer: DeveloperModel.fromJson(json['developer'] as Map<String, dynamic>?),
      subunitCount: const SubunitCount(value: '', label: LocalizedText()),
      description: LocalizedText.fromJson(json['description']),
      downPayment: (json['downPayment'] as num?)?.toDouble(),
      completionRate: json['completion_rate'] as int?,
      residentialUnits: json['residential_units'] as int?,
      commercialUnits: json['commercial_units'] as int?,
      paymentMinimumDownPayment: json['payment_minimum_down_payment'] as int?,
      postDelivery: json['post_delivery'] as bool?,
      rentalGuarantee: json['guarantee_rental_guarantee'] as bool?,
      rentalGuaranteeValue: (json['guarantee_rental_guarantee_value'] as num?)?.toDouble(),
      propertyImages: (json['property_images'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => PropertyImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      facilities: (json['facilities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => FacilityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupedApartments: (json['grouped_apartments'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => GroupedApartmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentPlans: (json['payment_plans'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => PaymentPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      propertyUnits: (json['property_units'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => PropertyUnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Combines this record with a freshly fetched [detail] record: detail's
  /// core fields win (they're authoritative/fresher), detail-only
  /// collections are adopted wholesale, and the developer profile is
  /// merged so a slim detail-response developer doesn't blank out the
  /// richer logo/contact info already known from the list response.
  ProjectModel mergeDetail(ProjectModel detail) {
    return ProjectModel(
      id: detail.id,
      title: detail.title,
      cover: detail.cover.isNotEmpty ? detail.cover : cover,
      address: detail.address.isNotEmpty ? detail.address : address,
      addressText: detail.addressText.isNotEmpty ? detail.addressText : addressText,
      deliveryDate: detail.deliveryDate != 0 ? detail.deliveryDate : deliveryDate,
      minArea: detail.minArea != 0 ? detail.minArea : minArea,
      lowPrice: detail.lowPrice != 0 ? detail.lowPrice : lowPrice,
      propertyTypeCode: detail.propertyTypeCode,
      propertyStatusCode: detail.propertyStatusCode,
      salesStatusCode: detail.salesStatusCode,
      salesStatusLabel: detail.salesStatusLabel,
      city: detail.city.id != 0 ? detail.city : city,
      district: detail.district.id != 0 ? detail.district : district,
      developer: detail.developer.mergeWith(developer),
      subunitCount: subunitCount,
      updatedAt: updatedAt,
      description: detail.description,
      downPayment: detail.downPayment,
      completionRate: detail.completionRate,
      residentialUnits: detail.residentialUnits,
      commercialUnits: detail.commercialUnits,
      paymentMinimumDownPayment: detail.paymentMinimumDownPayment,
      postDelivery: detail.postDelivery,
      rentalGuarantee: detail.rentalGuarantee,
      rentalGuaranteeValue: detail.rentalGuaranteeValue,
      propertyImages: detail.propertyImages,
      facilities: detail.facilities,
      groupedApartments: detail.groupedApartments,
      paymentPlans: detail.paymentPlans,
      propertyUnits: detail.propertyUnits,
    );
  }
}
