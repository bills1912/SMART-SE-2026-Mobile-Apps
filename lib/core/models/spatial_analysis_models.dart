import 'dart:math';

/// Represents a single business/usaha location point
class BusinessLocation {
  final String id;
  final String name;
  final String province;
  final String sector;     // KBLI sector code (A-U)
  final String sectorName; // Human-readable sector name
  final double latitude;
  final double longitude;
  final int totalUsaha;
  final Map<String, dynamic>? metadata;

  BusinessLocation({
    required this.id,
    required this.name,
    required this.province,
    required this.sector,
    required this.sectorName,
    required this.latitude,
    required this.longitude,
    required this.totalUsaha,
    this.metadata,
  });

  factory BusinessLocation.fromJson(Map<String, dynamic> json) {
    return BusinessLocation(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? json['provinsi'] ?? '',
      province: json['province'] ?? json['provinsi'] ?? '',
      sector: json['sector'] ?? json['kbli_code'] ?? 'G',
      sectorName: json['sector_name'] ?? json['kbli_name'] ?? 'Perdagangan',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0) is String
          ? double.tryParse(json['latitude'] ?? '0') ?? 0.0
          : (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0) is String
          ? double.tryParse(json['longitude'] ?? '0') ?? 0.0
          : (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      totalUsaha: (json['total_usaha'] ?? json['total'] ?? 0) is String
          ? int.tryParse(json['total_usaha']?.toString() ?? '0') ?? 0
          : (json['total_usaha'] ?? json['total'] ?? 0).toInt(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'province': province,
    'sector': sector,
    'sector_name': sectorName,
    'latitude': latitude,
    'longitude': longitude,
    'total_usaha': totalUsaha,
  };
}

/// Cluster of nearby business locations
class LocationCluster {
  final String id;
  final double centerLatitude;
  final double centerLongitude;
  final List<BusinessLocation> locations;
  final int totalUsaha;
  final String dominantSector;
  final String dominantSectorName;

  LocationCluster({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.locations,
    required this.totalUsaha,
    required this.dominantSector,
    required this.dominantSectorName,
  });

  int get count => locations.length;
}

/// Economic center / hub analysis result
class EconomicCenter {
  final String name;
  final String province;
  final double latitude;
  final double longitude;
  final double score; // 0-100 centrality score
  final int totalUsaha;
  final String dominantSector;
  final String description;
  final String centerType; // 'primary', 'secondary', 'tertiary'

  EconomicCenter({
    required this.name,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.totalUsaha,
    required this.dominantSector,
    required this.description,
    required this.centerType,
  });

  factory EconomicCenter.fromJson(Map<String, dynamic> json) {
    return EconomicCenter(
      name: json['name'] ?? '',
      province: json['province'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      score: (json['score'] ?? 0.0).toDouble(),
      totalUsaha: (json['total_usaha'] ?? 0).toInt(),
      dominantSector: json['dominant_sector'] ?? '',
      description: json['description'] ?? '',
      centerType: json['center_type'] ?? 'secondary',
    );
  }
}

/// Full spatial analysis result
class SpatialAnalysisResult {
  final String query;
  final String analysisType;       // 'distribution', 'centers', 'corridor', 'density', 'sector_map'
  final List<BusinessLocation> locations;
  final List<EconomicCenter> economicCenters;
  final List<SpatialInsight> insights;
  final SpatialStatistics statistics;
  final String narrativeAnalysis;
  final BoundingBox? boundingBox;
  final DateTime generatedAt;

  SpatialAnalysisResult({
    required this.query,
    required this.analysisType,
    required this.locations,
    required this.economicCenters,
    required this.insights,
    required this.statistics,
    required this.narrativeAnalysis,
    this.boundingBox,
    required this.generatedAt,
  });

  bool get hasLocations => locations.isNotEmpty;
  bool get hasEconomicCenters => economicCenters.isNotEmpty;
}

/// Individual spatial insight
class SpatialInsight {
  final String type;        // 'concentration', 'gap', 'corridor', 'cluster', 'anomaly'
  final String title;
  final String description;
  final double magnitude;   // 0-1 significance level
  final List<String> relatedProvinces;

  SpatialInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.magnitude,
    required this.relatedProvinces,
  });

  factory SpatialInsight.fromJson(Map<String, dynamic> json) {
    return SpatialInsight(
      type: json['type'] ?? 'cluster',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      magnitude: (json['magnitude'] ?? 0.5).toDouble(),
      relatedProvinces: json['related_provinces'] != null
          ? List<String>.from(json['related_provinces'])
          : [],
    );
  }
}

/// Aggregate statistics for a spatial query
class SpatialStatistics {
  final int totalLocations;
  final int totalUsaha;
  final double averageUsahaPerLocation;
  final double spatialConcentrationIndex; // Gini-like, 0-1
  final String highestDensityRegion;
  final String lowestDensityRegion;
  final Map<String, int> usahaByProvince;
  final Map<String, int> usahaBySector;

  SpatialStatistics({
    required this.totalLocations,
    required this.totalUsaha,
    required this.averageUsahaPerLocation,
    required this.spatialConcentrationIndex,
    required this.highestDensityRegion,
    required this.lowestDensityRegion,
    required this.usahaByProvince,
    required this.usahaBySector,
  });

  factory SpatialStatistics.empty() {
    return SpatialStatistics(
      totalLocations: 0,
      totalUsaha: 0,
      averageUsahaPerLocation: 0,
      spatialConcentrationIndex: 0,
      highestDensityRegion: '-',
      lowestDensityRegion: '-',
      usahaByProvince: {},
      usahaBySector: {},
    );
  }
}

/// Geographic bounding box
class BoundingBox {
  final double northEastLat;
  final double northEastLng;
  final double southWestLat;
  final double southWestLng;

  BoundingBox({
    required this.northEastLat,
    required this.northEastLng,
    required this.southWestLat,
    required this.southWestLng,
  });

  double get centerLat => (northEastLat + southWestLat) / 2;
  double get centerLng => (northEastLng + southWestLng) / 2;
}

// ─── Province coordinate registry ─────────────────────────────────────────
// Used to synthesize lat/lng from province names from economic data
const Map<String, Map<String, double>> kProvinceCoordinates = {
  'ACEH': {'lat': 4.6951, 'lng': 96.7494},
  'SUMATERA UTARA': {'lat': 2.1154, 'lng': 99.5451},
  'SUMATERA BARAT': {'lat': -0.7399, 'lng': 100.8000},
  'RIAU': {'lat': 0.2933, 'lng': 101.7068},
  'KEPULAUAN RIAU': {'lat': 3.9457, 'lng': 108.1429},
  'JAMBI': {'lat': -1.6101, 'lng': 103.6131},
  'SUMATERA SELATAN': {'lat': -3.3194, 'lng': 103.9144},
  'BENGKULU': {'lat': -3.5778, 'lng': 102.3464},
  'LAMPUNG': {'lat': -4.5585, 'lng': 105.4068},
  'KEP. BANGKA BELITUNG': {'lat': -2.7411, 'lng': 106.4406},
  'DKI JAKARTA': {'lat': -6.2088, 'lng': 106.8456},
  'JAWA BARAT': {'lat': -6.9147, 'lng': 107.6098},
  'JAWA TENGAH': {'lat': -7.1510, 'lng': 110.1403},
  'DI YOGYAKARTA': {'lat': -7.8753, 'lng': 110.4262},
  'JAWA TIMUR': {'lat': -7.5360, 'lng': 112.2384},
  'BANTEN': {'lat': -6.4058, 'lng': 106.0640},
  'BALI': {'lat': -8.3405, 'lng': 115.0920},
  'NUSA TENGGARA BARAT': {'lat': -8.6529, 'lng': 117.3616},
  'NUSA TENGGARA TIMUR': {'lat': -8.6574, 'lng': 121.0794},
  'KALIMANTAN BARAT': {'lat': -0.2787, 'lng': 111.4753},
  'KALIMANTAN TENGAH': {'lat': -1.6815, 'lng': 113.3824},
  'KALIMANTAN SELATAN': {'lat': -3.0926, 'lng': 115.2838},
  'KALIMANTAN TIMUR': {'lat': 0.5387, 'lng': 116.4194},
  'KALIMANTAN UTARA': {'lat': 3.0731, 'lng': 116.0413},
  'SULAWESI UTARA': {'lat': 0.6247, 'lng': 123.9750},
  'SULAWESI TENGAH': {'lat': -1.4300, 'lng': 121.4456},
  'SULAWESI SELATAN': {'lat': -3.6687, 'lng': 119.9740},
  'SULAWESI TENGGARA': {'lat': -4.1449, 'lng': 122.1746},
  'GORONTALO': {'lat': 0.6999, 'lng': 122.4467},
  'SULAWESI BARAT': {'lat': -2.8441, 'lng': 119.2321},
  'MALUKU': {'lat': -3.2385, 'lng': 130.1453},
  'MALUKU UTARA': {'lat': 1.5709, 'lng': 127.8088},
  'PAPUA': {'lat': -4.2699, 'lng': 138.0804},
  'PAPUA BARAT': {'lat': -1.3361, 'lng': 133.1747},
};