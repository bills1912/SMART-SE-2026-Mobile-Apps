import 'dart:math';
import '../models/chat_models.dart' as chat;
import '../models/spatial_analysis_models.dart';
import '../models/data/spatial_mock_data.dart';

/// SpatialAnalysisService
/// Converts chat responses into spatial analysis results.
/// Uses SpatialMockData when live data has no coordinates.
class SpatialAnalysisService {

  /// Detect whether a user message requests spatial/map analysis
  static bool isSpatialQuery(String message) {
    final lower = message.toLowerCase();
    final keywords = [
      'peta', 'map', 'lokasi', 'location', 'wilayah', 'daerah', 'titik',
      'persebaran', 'sebaran', 'distribusi spasial', 'spatial',
      'pusat ekonomi', 'economic center', 'pusat perekonomian', 'sentra',
      'koridor', 'corridor', 'klaster', 'cluster', 'konsentrasi',
      'tampilkan di peta', 'show on map', 'visualisasi lokasi', 'plot',
      'sebaran usaha', 'pola spasial', 'spatial pattern',
      'mana yang paling', 'daerah mana', 'provinsi mana', 'pulau',
      'jawa', 'sumatera', 'kalimantan', 'sulawesi', 'papua', 'bali',
      // Also trigger on general queries so the map always shows
      'gambaran', 'overview', 'nasional', 'indonesia', 'seluruh',
    ];
    return keywords.any((kw) => lower.contains(kw));
  }

  /// Detect analysis type from the user query
  static String detectAnalysisType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('pusat') || lower.contains('center') || lower.contains('sentra')) {
      return 'centers';
    }
    if (lower.contains('koridor') || lower.contains('corridor')) {
      return 'corridor';
    }
    if (lower.contains('kepadatan') || lower.contains('density')) {
      return 'density';
    }
    if (lower.contains('sektor') || lower.contains('sector') || lower.contains('kbli')) {
      return 'sector_map';
    }
    return 'distribution';
  }

  /// Build a full SpatialAnalysisResult from a ChatResponse.
  /// Prioritises mock data for guaranteed rendering.
  SpatialAnalysisResult buildSpatialAnalysis({
    required String query,
    required chat.ChatResponse response,
    required Map<String, dynamic> analysisData,
  }) {
    // Always use mock data as the primary source for consistent rendering.
    // The mock data is based on real SE 2016 figures.
    final mockResult = SpatialMockData.generateForQuery(query);

    // If the backend response contained real province data, try to
    // overlay it onto the mock locations.
    final enriched = _tryEnrichWithBackendData(mockResult, analysisData);

    return enriched;
  }

  /// Attempt to replace mock totals with real totals from backend response.
  SpatialAnalysisResult _tryEnrichWithBackendData(
      SpatialAnalysisResult base,
      Map<String, dynamic> analysisData,
      ) {
    final topProvinces = analysisData['top_provinces'] as List?;
    if (topProvinces == null || topProvinces.isEmpty) return base;

    // Build a lookup: province name (normalised) → total
    final realTotals = <String, int>{};
    for (final p in topProvinces) {
      if (p is Map<String, dynamic>) {
        final name = (p['provinsi'] ?? '').toString().toUpperCase();
        final total = (p['total'] ?? 0) is num
            ? (p['total'] as num).toInt()
            : 0;
        if (name.isNotEmpty && total > 0) {
          realTotals[name] = total;
        }
      }
    }

    if (realTotals.isEmpty) return base;

    // Update locations with real totals where available
    final updated = base.locations.map((loc) {
      final key = loc.province.toUpperCase();
      final realTotal = realTotals[key];
      if (realTotal != null && realTotal > 0) {
        return BusinessLocation(
          id: loc.id,
          name: loc.name,
          province: loc.province,
          sector: loc.sector,
          sectorName: loc.sectorName,
          latitude: loc.latitude,
          longitude: loc.longitude,
          totalUsaha: realTotal,
          metadata: loc.metadata,
        );
      }
      return loc;
    }).toList();

    // Recompute stats and centers from updated locations
    final stats = _computeStats(updated);
    final centers = _computeCenters(updated);

    return SpatialAnalysisResult(
      query: base.query,
      analysisType: base.analysisType,
      locations: updated,
      economicCenters: centers,
      insights: base.insights,
      statistics: stats,
      narrativeAnalysis: base.narrativeAnalysis,
      boundingBox: base.boundingBox,
      generatedAt: base.generatedAt,
    );
  }

  SpatialStatistics _computeStats(List<BusinessLocation> locations) {
    if (locations.isEmpty) return SpatialStatistics.empty();

    final total = locations.fold(0, (s, l) => s + l.totalUsaha);
    final avg = total / locations.length;

    final sorted = [...locations]
      ..sort((a, b) => a.totalUsaha.compareTo(b.totalUsaha));
    double gini = 0;
    for (int i = 0; i < sorted.length; i++) {
      gini += (2 * (i + 1) - sorted.length - 1) * sorted[i].totalUsaha;
    }
    final concentration =
    total > 0 ? gini.abs() / (sorted.length * total) : 0.0;

    final highest =
    locations.reduce((a, b) => a.totalUsaha > b.totalUsaha ? a : b);
    final lowestList =
    locations.where((l) => l.totalUsaha > 0).toList()
      ..sort((a, b) => a.totalUsaha.compareTo(b.totalUsaha));
    final lowest = lowestList.isNotEmpty ? lowestList.first : locations.last;

    final byProv = <String, int>{};
    final bySect = <String, int>{};
    for (final l in locations) {
      byProv[l.province] = (byProv[l.province] ?? 0) + l.totalUsaha;
      bySect[l.sectorName] = (bySect[l.sectorName] ?? 0) + l.totalUsaha;
    }

    return SpatialStatistics(
      totalLocations: locations.length,
      totalUsaha: total,
      averageUsahaPerLocation: avg,
      spatialConcentrationIndex: concentration,
      highestDensityRegion: highest.province,
      lowestDensityRegion: lowest.province,
      usahaByProvince: byProv,
      usahaBySector: bySect,
    );
  }

  List<EconomicCenter> _computeCenters(List<BusinessLocation> locations) {
    if (locations.isEmpty) return [];
    final sorted = [...locations]
      ..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha));
    final maxU = sorted.first.totalUsaha;

    return sorted.take(5).toList().asMap().entries.map((e) {
      final loc = e.value;
      final idx = e.key;
      final score = maxU > 0 ? (loc.totalUsaha / maxU) * 100 : 0.0;
      final type =
      idx == 0 ? 'primary' : idx < 3 ? 'secondary' : 'tertiary';
      return EconomicCenter(
        name: loc.province,
        province: loc.province,
        latitude: loc.latitude,
        longitude: loc.longitude,
        score: score,
        totalUsaha: loc.totalUsaha,
        dominantSector: loc.sectorName,
        description: idx == 0
            ? '${loc.province} adalah pusat ekonomi utama dengan dominasi sektor ${loc.sectorName}.'
            : '${loc.province} berperan sebagai pusat regional dengan ${_fmt(loc.totalUsaha)} unit usaha aktif.',
        centerType: type,
      );
    }).toList();
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.');
}