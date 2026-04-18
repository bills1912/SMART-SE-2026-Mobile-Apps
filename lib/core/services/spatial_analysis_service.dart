import 'dart:math';
import '../models/chat_models.dart' as chat;
import '../models/spatial_analysis_models.dart';
import '../models/data/spatial_mock_data.dart';

/// SpatialAnalysisService
///
/// PERBAIKAN: isSpatialQuery() sekarang hanya return true jika user
/// SECARA EKSPLISIT meminta analisis berbasis peta/lokasi/spasial.
///
/// Sebelumnya hampir semua query (termasuk yang hanya menyebut nama provinsi
/// atau kata "gambaran") dianggap spasial, sehingga peta selalu muncul.
/// Sekarang hanya query yang memang meminta visualisasi geografis yang
/// memunculkan peta.
class SpatialAnalysisService {

  // ── Keyword Tiers ──────────────────────────────────────────────────────────
  //
  // TIER 1 — Eksplisit spasial: langsung return true jika ada salah satu.
  // Ini kata kunci yang JELAS meminta peta / analisis berbasis lokasi.
  static const _kExplicitSpatial = [
    // Peta & map
    'peta', 'map', 'petakan', 'tampilkan peta', 'show map', 'plot peta',
    'visualisasi peta', 'geographic', 'geografis', 'geografi',

    // Spasial eksplisit
    'spasial', 'spatial', 'analisis spasial', 'spatial analysis',
    'pola spasial', 'spatial pattern', 'distribusi spasial',
    'distribusi geografis', 'sebaran geografis',

    // Persebaran / distribusi dengan konteks lokasi
    'persebaran wilayah', 'sebaran wilayah', 'sebaran daerah',
    'persebaran daerah', 'sebaran antar provinsi', 'persebaran antar provinsi',
    'persebaran di indonesia', 'sebaran di indonesia',
    'sebaran usaha di', 'persebaran usaha di',

    // Pusat ekonomi / klaster geografis
    'pusat ekonomi', 'pusat perekonomian', 'economic center',
    'economic hub', 'sentra ekonomi', 'klaster ekonomi',
    'klaster wilayah', 'koridor ekonomi', 'economic corridor',

    // Titik lokasi
    'titik lokasi', 'lokasi usaha', 'sebaran titik', 'plot lokasi',
    'visualisasi lokasi', 'tampilkan di peta', 'show on map',

    // Ketimpangan spasial / wilayah
    'ketimpangan wilayah', 'disparitas wilayah', 'kesenjangan geografis',
    'kesenjangan wilayah', 'ketimpangan spasial',
  ];

  // TIER 2 — Memerlukan kombinasi: kata ini hanya memicu spatial jika
  // JUGA ada kata dari _kSpatialModifier di query yang sama.
  static const _kSpatialTrigger = [
    'sebaran', 'persebaran', 'distribusi', 'penyebaran',
  ];

  // Modifier yang mengubah "sebaran/distribusi" menjadi query spasial
  static const _kSpatialModifier = [
    'peta', 'map', 'wilayah', 'geografis', 'spasial', 'spatial',
    'lokasi', 'daerah', 'antar pulau', 'antar wilayah',
  ];

  // Kata-kata ini TIDAK cukup sendiri untuk memicu spatial —
  // meskipun sebelumnya termasuk. Hanya nama wilayah / kata umum.
  // (Daftar ini dokumentasi saja, tidak digunakan dalam kode)
  // ignore: unused_field
  static const _kNonSpatialAlone = [
    'indonesia', 'nasional', 'gambaran', 'overview',
    'jawa', 'sumatera', 'kalimantan', 'sulawesi', 'papua', 'bali',
    'provinsi', 'daerah', 'wilayah', 'sebaran', 'distribusi',
  ];

  /// Deteksi apakah query meminta analisis SPASIAL / PETA.
  ///
  /// Return true HANYA jika:
  ///   (a) Ada kata kunci eksplisit spasial (Tier 1), ATAU
  ///   (b) Ada kata trigger (sebaran/distribusi) + modifier spasial (Tier 2)
  ///
  /// Kata-kata umum seperti nama provinsi, "gambaran", "overview",
  /// "nasional" TIDAK cukup untuk memicu spatial map.
  static bool isSpatialQuery(String message) {
    final lower = message.toLowerCase();

    // Tier 1: kata kunci eksplisit spasial
    for (final kw in _kExplicitSpatial) {
      if (lower.contains(kw)) return true;
    }

    // Tier 2: kombinasi trigger + modifier
    final hasTrigger = _kSpatialTrigger.any((t) => lower.contains(t));
    if (hasTrigger) {
      final hasModifier = _kSpatialModifier.any((m) => lower.contains(m));
      if (hasModifier) return true;
    }

    return false;
  }

  /// Deteksi tipe analisis spasial dari query
  static String detectAnalysisType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('pusat') || lower.contains('center') ||
        lower.contains('sentra') || lower.contains('hub')) {
      return 'centers';
    }
    if (lower.contains('koridor') || lower.contains('corridor')) {
      return 'corridor';
    }
    if (lower.contains('kepadatan') || lower.contains('density')) {
      return 'density';
    }
    if (lower.contains('sektor') || lower.contains('sector') ||
        lower.contains('kbli')) {
      return 'sector_map';
    }
    if (lower.contains('ketimpangan') || lower.contains('disparitas') ||
        lower.contains('kesenjangan')) {
      return 'gap';
    }
    return 'distribution';
  }

  /// Build SpatialAnalysisResult dari ChatResponse.
  SpatialAnalysisResult buildSpatialAnalysis({
    required String query,
    required chat.ChatResponse response,
    required Map<String, dynamic> analysisData,
  }) {
    final mockResult = SpatialMockData.generateForQuery(query);
    return _tryEnrichWithBackendData(mockResult, analysisData);
  }

  SpatialAnalysisResult _tryEnrichWithBackendData(
      SpatialAnalysisResult base,
      Map<String, dynamic> analysisData,
      ) {
    final topProvinces = analysisData['top_provinces'] as List?;
    if (topProvinces == null || topProvinces.isEmpty) return base;

    final realTotals = <String, int>{};
    for (final p in topProvinces) {
      if (p is Map<String, dynamic>) {
        final name = (p['provinsi'] ?? '').toString().toUpperCase();
        final total =
        (p['total'] ?? 0) is num ? (p['total'] as num).toInt() : 0;
        if (name.isNotEmpty && total > 0) realTotals[name] = total;
      }
    }

    if (realTotals.isEmpty) return base;

    final updated = base.locations.map((loc) {
      final realTotal = realTotals[loc.province.toUpperCase()];
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
      gini +=
          (2 * (i + 1) - sorted.length - 1) * sorted[i].totalUsaha;
    }
    final concentration =
    total > 0 ? gini.abs() / (sorted.length * total) : 0.0;

    final highest =
    locations.reduce((a, b) => a.totalUsaha > b.totalUsaha ? a : b);
    final lowestList = locations.where((l) => l.totalUsaha > 0).toList()
      ..sort((a, b) => a.totalUsaha.compareTo(b.totalUsaha));
    final lowest =
    lowestList.isNotEmpty ? lowestList.first : locations.last;

    final byProv = <String, int>{};
    final bySect = <String, int>{};
    for (final l in locations) {
      byProv[l.province] = (byProv[l.province] ?? 0) + l.totalUsaha;
      bySect[l.sectorName] =
          (bySect[l.sectorName] ?? 0) + l.totalUsaha;
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
      .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}