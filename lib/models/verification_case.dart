/// Holds all data collected across the residence verification flow.
/// Passed by reference between screens; each screen fills in its part.
class VerificationCase {
  String id;
  DateTime createdAt;
  bool isFavorite = false;

  String address;
  String applicantName;
  String caseId;
  String clientName;
  String phone;
  String firebaseKey;

  double? latitude;
  double? longitude;
  final List<String> photoPaths = [];
  /// Hosted (imgbb) URLs for the captured photos. Filled during cloud sync.
  final List<String> photoUrls = [];
  final List<GeoPhotoGroup> geoGroups = [];

  bool? traced; // true = Traced, false = Untraced

  // ---- Branch A: Untraced ----
  String reasonOfUntraced = '';
  String requireToTrace = '';
  String callingResponse = '';
  String lastLocation = '';
  String untracedComments = '';

  // ---- Branch B: Traced — neighbour step ----
  String neighbor1 = '';
  String neighbor2 = '';
  bool? neighborConfirmed; // true = confirmed, false = not confirmed

  // ---- Branch B1: Neighbour confirmed ----
  String metPersonName = '';
  String relationWithApplicant = '';
  String residenceConfirmation = '';
  String tenureOfResidence = '';
  String ownershipOfResidence = '';
  String rentAmount = '';
  String landlordName = '';
  String buildingDescription = '';
  String totalFloors = '';
  String applicantFloor = '';
  String landArea = '';
  String localityOfAddress = '';
  String documentShown = '';
  String totalFamilyMembers = '';
  String numberOfEarners = '';
  String verifierComments = '';
  bool? applicantResidingThere;

  // ---- Branch B2: Neighbour not confirmed ----
  String whoIsThat = '';
  String residenceConfirmationB2 = '';
  String totalFloorsB2 = '';
  String addressFloorB2 = '';
  String landAreaB2 = '';
  String localityB2 = '';
  String commentsB2 = '';

  String generatedRemarks = '';
  String finalStatus = '';

  VerificationCase({
    required this.address,
    String? id,
    DateTime? createdAt,
    this.applicantName = '',
    this.caseId = '',
    this.clientName = '',
    this.phone = '',
    this.firebaseKey = '',
    this.isFavorite = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory VerificationCase.fromMap(String id, Map<String, dynamic> map) {
    final c = VerificationCase(
      id: id,
      createdAt: _asDate(map['createdAt']) ?? DateTime.now(),
      address: _asString(map['address']),
      applicantName: _asString(map['applicantName']),
      caseId: _asString(map['caseId']),
      clientName: _asString(map['clientName']),
      phone: _asString(map['phone']),
      firebaseKey: _asString(map['firebaseKey']),
      isFavorite: map['isFavorite'] == true,
    );
    c.latitude = _asDouble(map['latitude']);
    c.longitude = _asDouble(map['longitude']);
    c.photoPaths.addAll(_asStringList(map['photoPaths']));
    c.photoUrls.addAll(_asStringList(map['photoUrls']));
    final groups = map['geoGroups'];
    if (groups is List) {
      for (final item in groups) {
        if (item is Map) {
          c.geoGroups.add(
            GeoPhotoGroup.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    c.syncGeoFields();
    c.traced = map['traced'] is bool ? map['traced'] as bool : null;
    c.reasonOfUntraced = _asString(map['reasonOfUntraced']);
    c.requireToTrace = _asString(map['requireToTrace']);
    c.callingResponse = _asString(map['callingResponse']);
    c.lastLocation = _asString(map['lastLocation']);
    c.untracedComments = _asString(map['untracedComments']);
    c.neighbor1 = _asString(map['neighbor1']);
    c.neighbor2 = _asString(map['neighbor2']);
    c.neighborConfirmed =
        map['neighborConfirmed'] is bool ? map['neighborConfirmed'] as bool : null;
    c.metPersonName = _asString(map['metPersonName']);
    c.relationWithApplicant = _asString(map['relationWithApplicant']);
    c.residenceConfirmation = _asString(map['residenceConfirmation']);
    c.tenureOfResidence = _asString(map['tenureOfResidence']);
    c.ownershipOfResidence = _asString(map['ownershipOfResidence']);
    c.rentAmount = _asString(map['rentAmount']);
    c.landlordName = _asString(map['landlordName']);
    c.buildingDescription = _asString(map['buildingDescription']);
    c.totalFloors = _asString(map['totalFloors']);
    c.applicantFloor = _asString(map['applicantFloor']);
    c.landArea = _asString(map['landArea']);
    c.localityOfAddress = _asString(map['localityOfAddress']);
    c.documentShown = _asString(map['documentShown']);
    c.totalFamilyMembers = _asString(map['totalFamilyMembers']);
    c.numberOfEarners = _asString(map['numberOfEarners']);
    c.verifierComments = _asString(map['verifierComments']);
    c.applicantResidingThere = map['applicantResidingThere'] is bool
        ? map['applicantResidingThere'] as bool
        : null;
    c.whoIsThat = _asString(map['whoIsThat']);
    c.residenceConfirmationB2 = _asString(map['residenceConfirmationB2']);
    c.totalFloorsB2 = _asString(map['totalFloorsB2']);
    c.addressFloorB2 = _asString(map['addressFloorB2']);
    c.landAreaB2 = _asString(map['landAreaB2']);
    c.localityB2 = _asString(map['localityB2']);
    c.commentsB2 = _asString(map['commentsB2']);
    c.generatedRemarks = _asString(map['generatedRemarks']);
    c.finalStatus = _asString(map['finalStatus']);
    return c;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'address': address,
      'applicantName': applicantName,
      'caseId': caseId,
      'clientName': clientName,
      'phone': phone,
      'firebaseKey': firebaseKey,
      'latitude': latitude,
      'longitude': longitude,
      'photoPaths': photoPaths,
      'photoUrls': photoUrls,
      'geoGroups': geoGroups.map((g) => g.toMap()).toList(),
      'traced': traced,
      'reasonOfUntraced': reasonOfUntraced,
      'requireToTrace': requireToTrace,
      'callingResponse': callingResponse,
      'lastLocation': lastLocation,
      'untracedComments': untracedComments,
      'neighbor1': neighbor1,
      'neighbor2': neighbor2,
      'neighborConfirmed': neighborConfirmed,
      'metPersonName': metPersonName,
      'relationWithApplicant': relationWithApplicant,
      'residenceConfirmation': residenceConfirmation,
      'tenureOfResidence': tenureOfResidence,
      'ownershipOfResidence': ownershipOfResidence,
      'rentAmount': rentAmount,
      'landlordName': landlordName,
      'buildingDescription': buildingDescription,
      'totalFloors': totalFloors,
      'applicantFloor': applicantFloor,
      'landArea': landArea,
      'localityOfAddress': localityOfAddress,
      'documentShown': documentShown,
      'totalFamilyMembers': totalFamilyMembers,
      'numberOfEarners': numberOfEarners,
      'verifierComments': verifierComments,
      'applicantResidingThere': applicantResidingThere,
      'whoIsThat': whoIsThat,
      'residenceConfirmationB2': residenceConfirmationB2,
      'totalFloorsB2': totalFloorsB2,
      'addressFloorB2': addressFloorB2,
      'landAreaB2': landAreaB2,
      'localityB2': localityB2,
      'commentsB2': commentsB2,
      'generatedRemarks': generatedRemarks,
      'finalStatus': finalStatus,
    };
  }

  String get geoTagText {
    final tags = geoGroups
        .where((g) => g.latitude != null && g.longitude != null)
        .map((g) => g.geoTagText)
        .toList();
    if (tags.isNotEmpty) return tags.join(' | ');
    if (latitude == null || longitude == null) return 'Not captured';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  void syncGeoFields() {
    if (geoGroups.isEmpty && photoPaths.isNotEmpty) {
      geoGroups.add(
        GeoPhotoGroup(
          latitude: latitude,
          longitude: longitude,
          photoPaths: List<String>.from(photoPaths),
        ),
      );
    }
    photoPaths
      ..clear()
      ..addAll(geoGroups.expand((g) => g.photoPaths));
    final first = geoGroups.cast<GeoPhotoGroup?>().firstWhere(
          (g) => g?.latitude != null && g?.longitude != null,
          orElse: () => geoGroups.isEmpty ? null : geoGroups.first,
        );
    latitude = first?.latitude;
    longitude = first?.longitude;
  }

  /// Stable local identifier for a case: prefers the assigned address key so
  /// drafts and the offline sync queue can be matched back to the same case.
  String get localKey {
    if (firebaseKey.isNotEmpty) return firebaseKey;
    if (caseId.isNotEmpty) return caseId;
    return id;
  }

  String get _mediaSuffix =>
      '\n\nGeo-tag: $geoTagText. Photos attached: ${photoPaths.length}.';

  /// Human-readable Title -> Answer pairs used to render the generated
  /// remarks as labelled rows instead of one long paragraph.
  List<(String, String)> get remarksEntries {
    final items = <(String, String)>[];
    void add(String label, String value) {
      if (value.trim().isNotEmpty) items.add((label, value));
    }

    add('Address', address);
    if (traced == false) {
      add('Reason of Untraced', reasonOfUntraced);
      add('Require to Trace', requireToTrace);
      add('Calling Response', callingResponse);
      add('Last Location', lastLocation);
      add('Comments', untracedComments);
    } else {
      add('Met Person Name', metPersonName);
      if (neighborConfirmed == false) {
        add('Who is That', whoIsThat);
        add('Residence Confirmation', residenceConfirmationB2);
        add('Total Floors', totalFloorsB2);
        add('Address Floor', addressFloorB2);
        add('Land Area', landAreaB2);
        add('Locality', localityB2);
        add('Comments', commentsB2);
      } else {
        add('Relation with Applicant', relationWithApplicant);
        add('Residence Confirmation', residenceConfirmation);
        add('Tenure of Residence', tenureOfResidence);
        add('Ownership of Residence', ownershipOfResidence);
        add('Rent Amount', rentAmount);
        add('Landlord Name', landlordName);
        add('Building Description', buildingDescription);
        add('Total Floors', totalFloors);
        add('Applicant Floor', applicantFloor);
        add('Land Area', landArea);
        add('Locality of Address', localityOfAddress);
        add('Document Shown', documentShown);
        add('Total Family Members', totalFamilyMembers);
        add('Number of Earners', numberOfEarners);
        if (applicantResidingThere != null) {
          add('Applicant Residing There',
              applicantResidingThere! ? 'Yes' : 'No');
        }
        add('Verifier Comments', verifierComments);
      }
      add('1st Neighbour', neighbor1);
      add('2nd Neighbour', neighbor2);
    }
    add('Geo Tag', geoTagText);
    return items;
  }

  String buildConfirmedRemarks() {
    return 'Visited at given address ($address) we met with met person name '
        '($relationWithApplicant), who confirmed that applicant is '
        '$residenceConfirmation from last $tenureOfResidence in '
        '$ownershipOfResidence premises.'
        '${rentAmount.isNotEmpty ? ' If rented, paid rent amount $rentAmount to $landlordName.' : ''} '
        'Applicant is residing in $buildingDescription. Building is built '
        'from $totalFloors and applicant resides on $applicantFloor with an '
        'area approx. $landArea in $localityOfAddress locality. Document '
        'shown by met person: $documentShown. Total family members: '
        '$totalFamilyMembers, of which $numberOfEarners are earners.\n\n'
        'Neighbour confirmation: We met with $neighbor1 and $neighbor2, both '
        'confirmed the applicant\'s name and residence.$_mediaSuffix';
  }

  String buildNotConfirmedRemarks() {
    return 'Visited at given address ($address) we met with met person name '
        '($whoIsThat), who confirmed that applicant is '
        '$residenceConfirmationB2. Building is built from $totalFloorsB2 '
        'and premises exist at $addressFloorB2 with an area approx. '
        '$landAreaB2 in $localityB2 locality.\n\n'
        'Neighbour confirmation: We met with $neighbor1 and $neighbor2, both '
        'stated they could not confirm the applicant regarding the address.$_mediaSuffix';
  }

  String buildUntracedRemarks() {
    return 'Visited at given address ($address) but the address could not '
        'be traced. Reason: $reasonOfUntraced. Additional information '
        'required: $requireToTrace. Calling response: $callingResponse. '
        'Last known location: $lastLocation.$_mediaSuffix';
  }
}

String _asString(dynamic value) => value?.toString() ?? '';

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

class GeoPhotoGroup {
  double? latitude;
  double? longitude;
  final List<String> photoPaths;

  GeoPhotoGroup({
    this.latitude,
    this.longitude,
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? [];

  factory GeoPhotoGroup.fromMap(Map<String, dynamic> map) {
    return GeoPhotoGroup(
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      photoPaths: _asStringList(map['photoPaths']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'photoPaths': photoPaths,
    };
  }

  bool get hasGeoTag => latitude != null && longitude != null;

  String get geoTagText => hasGeoTag
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : 'Not captured';
}