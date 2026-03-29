import '../spatial_analysis_models.dart';

/// Mock data provider for the spatial analysis feature.
/// Provides realistic Sensus Ekonomi 2016 data with province-level
/// aggregates and sector breakdowns.
class SpatialMockData {
  /// Returns a full SpatialAnalysisResult for a given query type.
  static SpatialAnalysisResult generateForQuery(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('jawa') || lower.contains('java')) {
      return _javaFocused();
    }
    if (lower.contains('sumatera') || lower.contains('sumatra')) {
      return _sumateraFocused();
    }
    if (lower.contains('pusat') || lower.contains('center') || lower.contains('sentra')) {
      return _economicCenters();
    }
    if (lower.contains('perdagangan') || lower.contains('dagang') || lower.contains('trade')) {
      return _sectorFocused('G', 'Perdagangan');
    }
    if (lower.contains('industri') || lower.contains('manufaktur')) {
      return _sectorFocused('C', 'Industri Pengolahan');
    }
    // Default: full national overview
    return _nationalOverview();
  }

  // ─── National Overview ─────────────────────────────────────────────────
  static SpatialAnalysisResult _nationalOverview() {
    final locations = _allProvinceLocations();
    final stats = _computeStats(locations);
    final centers = _computeCenters(locations);

    return SpatialAnalysisResult(
      query: 'Gambaran umum persebaran usaha di Indonesia',
      analysisType: 'distribution',
      locations: locations,
      economicCenters: centers,
      insights: _nationalInsights(locations, stats),
      statistics: stats,
      narrativeAnalysis: _nationalNarrative(stats, centers),
      boundingBox: BoundingBox(
        northEastLat: 7, northEastLng: 142,
        southWestLat: -12, southWestLng: 94,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ─── Java focused ──────────────────────────────────────────────────────
  static SpatialAnalysisResult _javaFocused() {
    final all = _allProvinceLocations();
    final javaProvs = {
      'DKI JAKARTA', 'JAWA BARAT', 'JAWA TENGAH',
      'DI YOGYAKARTA', 'JAWA TIMUR', 'BANTEN'
    };
    final locations = all.where((l) => javaProvs.contains(l.province.toUpperCase())).toList();
    final stats = _computeStats(locations);
    final centers = _computeCenters(locations);

    return SpatialAnalysisResult(
      query: 'Persebaran usaha di Jawa',
      analysisType: 'density',
      locations: locations,
      economicCenters: centers,
      insights: [
        SpatialInsight(
          type: 'concentration',
          title: 'Konsentrasi Jawa Timur–Barat',
          description:
          'Jawa Timur dan Jawa Barat bersama-sama menyumbang lebih dari 35% total usaha di Pulau Jawa. '
              'Kepadatan usaha tertinggi terpusat di koridor Jakarta–Surabaya.',
          magnitude: 0.87,
          relatedProvinces: ['Jawa Timur', 'Jawa Barat', 'DKI Jakarta'],
        ),
        SpatialInsight(
          type: 'cluster',
          title: 'Klaster Industri Jawa Tengah',
          description:
          'Jawa Tengah membentuk klaster industri pengolahan yang signifikan, '
              'khususnya di koridor Semarang–Solo–Yogyakarta.',
          magnitude: 0.72,
          relatedProvinces: ['Jawa Tengah', 'DI Yogyakarta'],
        ),
        SpatialInsight(
          type: 'corridor',
          title: 'Koridor Ekonomi Pantura',
          description:
          'Jalur pantai utara Jawa menghubungkan pusat-pusat ekonomi dari Banten hingga Jawa Timur, '
              'membentuk koridor ekonomi terpanjang di Indonesia.',
          magnitude: 0.91,
          relatedProvinces: ['Banten', 'DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur'],
        ),
      ],
      statistics: stats,
      narrativeAnalysis:
      '**Analisis Spasial Pulau Jawa**\n\n'
          'Pulau Jawa merupakan episentrum ekonomi Indonesia dengan ${_formatNumber(stats.totalUsaha)} '
          'unit usaha tersebar di 6 provinsi. DKI Jakarta memimpin sebagai pusat keuangan dan perdagangan, '
          'sementara Jawa Timur dan Jawa Barat menjadi basis industri pengolahan terbesar.\n\n'
          '**Pola Distribusi:** Terdapat ketimpangan yang jelas antara provinsi pesisir utara '
          '(kepadatan tinggi) vs. provinsi pedalaman. Koridor Pantura menjadi tulang punggung ekonomi.\n\n'
          '**Implikasi Kebijakan:**\n'
          '• Investasi infrastruktur pendukung di Selatan Jawa untuk pemerataan\n'
          '• Penguatan kawasan industri di DI Yogyakarta sebagai penyeimbang\n'
          '• Digitalisasi UMKM di Jawa Tengah untuk peningkatan produktivitas',
      boundingBox: BoundingBox(
        northEastLat: -5.5, northEastLng: 115,
        southWestLat: -9, southWestLng: 105,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ─── Sumatera focused ──────────────────────────────────────────────────
  static SpatialAnalysisResult _sumateraFocused() {
    final all = _allProvinceLocations();
    final provs = {
      'ACEH', 'SUMATERA UTARA', 'SUMATERA BARAT', 'RIAU',
      'KEPULAUAN RIAU', 'JAMBI', 'SUMATERA SELATAN', 'BENGKULU', 'LAMPUNG',
      'KEP. BANGKA BELITUNG'
    };
    final locations = all.where((l) => provs.contains(l.province.toUpperCase())).toList();
    final stats = _computeStats(locations);
    final centers = _computeCenters(locations);

    return SpatialAnalysisResult(
      query: 'Persebaran usaha di Sumatera',
      analysisType: 'corridor',
      locations: locations,
      economicCenters: centers,
      insights: [
        SpatialInsight(
          type: 'corridor',
          title: 'Koridor Trans-Sumatera',
          description:
          'Sumut–Riau–Lampung membentuk koridor ekonomi utama Sumatera '
              'dengan total lebih dari 60% usaha di pulau ini.',
          magnitude: 0.78,
          relatedProvinces: ['Sumatera Utara', 'Riau', 'Sumatera Selatan', 'Lampung'],
        ),
        SpatialInsight(
          type: 'cluster',
          title: 'Klaster Perdagangan Sumut',
          description:
          'Sumatera Utara (Medan) menjadi pusat perdagangan dan distribusi barang '
              'untuk seluruh kawasan barat Indonesia.',
          magnitude: 0.83,
          relatedProvinces: ['Sumatera Utara'],
        ),
      ],
      statistics: stats,
      narrativeAnalysis:
      '**Analisis Spasial Sumatera**\n\n'
          'Sumatera adalah basis ekonomi kedua terbesar Indonesia dengan kekuatan '
          'di sektor perdagangan, perkebunan, dan pertambangan. Medan (Sumut) '
          'mendominasi sebagai hub distribusi regional.\n\n'
          '**Implikasi Kebijakan:**\n'
          '• Percepatan pembangunan Tol Trans-Sumatera untuk konektivitas\n'
          '• Diversifikasi ekonomi dari komoditas ke manufaktur\n'
          '• Pengembangan kawasan ekonomi khusus di Kepri dan Riau',
      boundingBox: BoundingBox(
        northEastLat: 6, northEastLng: 109,
        southWestLat: -6, southWestLng: 95,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ─── Economic centers ──────────────────────────────────────────────────
  static SpatialAnalysisResult _economicCenters() {
    final locations = _allProvinceLocations();
    final stats = _computeStats(locations);
    final centers = _computeCenters(locations);

    return SpatialAnalysisResult(
      query: 'Pusat-pusat perekonomian Indonesia',
      analysisType: 'centers',
      locations: locations,
      economicCenters: centers,
      insights: [
        SpatialInsight(
          type: 'concentration',
          title: 'Dominasi Tiga Kota Besar',
          description:
          'Jakarta, Surabaya, dan Medan membentuk segitiga ekonomi yang '
              'menguasai lebih dari 45% aktivitas usaha nasional.',
          magnitude: 0.92,
          relatedProvinces: ['DKI Jakarta', 'Jawa Timur', 'Sumatera Utara'],
        ),
        SpatialInsight(
          type: 'gap',
          title: 'Kesenjangan Timur-Barat',
          description:
          'Kawasan Timur Indonesia (Maluku, Papua, NTT) hanya menyumbang '
              '5.2% dari total usaha nasional meski mencakup 40% wilayah.',
          magnitude: 0.88,
          relatedProvinces: ['Papua', 'Maluku', 'Nusa Tenggara Timur'],
        ),
        SpatialInsight(
          type: 'cluster',
          title: 'Emerging Hub Sulawesi',
          description:
          'Makassar (Sulsel) berkembang menjadi pusat ekonomi baru '
              'untuk kawasan timur Indonesia dengan pertumbuhan usaha yang pesat.',
          magnitude: 0.61,
          relatedProvinces: ['Sulawesi Selatan', 'Sulawesi Utara'],
        ),
      ],
      statistics: stats,
      narrativeAnalysis:
      '**Peta Pusat-Pusat Perekonomian Indonesia**\n\n'
          'Indonesia memiliki hierarki pusat ekonomi yang jelas dengan 3 simpul primer, '
          '7 simpul sekunder, dan 24 simpul tersier. Polanya sangat Jawa-sentris.\n\n'
          '**Pusat Primer:** Jakarta, Surabaya, Medan\n'
          '**Pusat Sekunder:** Bandung, Semarang, Makassar, Balikpapan\n\n'
          '**Implikasi Kebijakan:**\n'
          '• Pengembangan pusat ekonomi baru di luar Jawa\n'
          '• Konektivitas maritim antar-pulau untuk redistribusi ekonomi\n'
          '• Program insentif fiskal untuk daerah tertinggal di Timur Indonesia',
      boundingBox: BoundingBox(
        northEastLat: 7, northEastLng: 142,
        southWestLat: -12, southWestLng: 94,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ─── Sector focused ────────────────────────────────────────────────────
  static SpatialAnalysisResult _sectorFocused(String sectorCode, String sectorName) {
    final all = _allProvinceLocations();
    // Recalculate totals using only the target sector
    final locations = all.map((loc) {
      final sectorTotal = (loc.metadata?['sectors']?[sectorCode] ?? 0) as int;
      return BusinessLocation(
        id: loc.id,
        name: loc.name,
        province: loc.province,
        sector: sectorCode,
        sectorName: sectorName,
        latitude: loc.latitude,
        longitude: loc.longitude,
        totalUsaha: sectorTotal > 0 ? sectorTotal : (loc.totalUsaha * 0.3).toInt(),
        metadata: loc.metadata,
      );
    }).toList();

    final stats = _computeStats(locations);
    final centers = _computeCenters(locations);

    return SpatialAnalysisResult(
      query: 'Persebaran sektor $sectorName',
      analysisType: 'sector_map',
      locations: locations,
      economicCenters: centers,
      insights: [
        SpatialInsight(
          type: 'concentration',
          title: 'Konsentrasi Sektor $sectorName',
          description:
          'Sektor $sectorName terkonsentrasi di provinsi-provinsi padat penduduk di Jawa, '
              'dengan Jawa Timur dan Jawa Barat sebagai pemimpin.',
          magnitude: 0.75,
          relatedProvinces: ['Jawa Timur', 'Jawa Barat', 'Jawa Tengah'],
        ),
      ],
      statistics: stats,
      narrativeAnalysis:
      '**Peta Sektor $sectorName**\n\n'
          'Sektor $sectorName tersebar di seluruh Indonesia dengan konsentrasi '
          'tertinggi di Pulau Jawa. ${_formatNumber(stats.totalUsaha)} unit usaha '
          'aktif di sektor ini pada Sensus Ekonomi 2016.',
      boundingBox: BoundingBox(
        northEastLat: 7, northEastLng: 142,
        southWestLat: -12, southWestLng: 94,
      ),
      generatedAt: DateTime.now(),
    );
  }

  // ─── Province location data (ground truth) ─────────────────────────────
  static List<BusinessLocation> _allProvinceLocations() {
    return _rawData.map((d) => BusinessLocation(
      id: 'mock_${d['province']}',
      name: d['province'] as String,
      province: d['province'] as String,
      sector: d['dominant_sector'] as String,
      sectorName: d['dominant_sector_name'] as String,
      latitude: d['lat'] as double,
      longitude: d['lng'] as double,
      totalUsaha: d['total_usaha'] as int,
      metadata: {
        'sectors': d['sectors'],
        'percentage': d['percentage'],
      },
    )).toList();
  }

  static SpatialStatistics _computeStats(List<BusinessLocation> locations) {
    if (locations.isEmpty) return SpatialStatistics.empty();

    final total = locations.fold(0, (s, l) => s + l.totalUsaha);
    final avg = total / locations.length;

    final sorted = [...locations]..sort((a, b) => a.totalUsaha.compareTo(b.totalUsaha));
    double giniNum = 0;
    for (int i = 0; i < sorted.length; i++) {
      giniNum += (2 * (i + 1) - sorted.length - 1) * sorted[i].totalUsaha;
    }
    final gini = total > 0 ? giniNum.abs() / (sorted.length * total) : 0.0;

    final highest = locations.reduce((a, b) => a.totalUsaha > b.totalUsaha ? a : b);
    final lowestList = locations.where((l) => l.totalUsaha > 0).toList();
    lowestList.sort((a, b) => a.totalUsaha.compareTo(b.totalUsaha));
    final lowest = lowestList.isNotEmpty ? lowestList.first : locations.first;

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
      spatialConcentrationIndex: gini,
      highestDensityRegion: highest.province,
      lowestDensityRegion: lowest.province,
      usahaByProvince: byProv,
      usahaBySector: bySect,
    );
  }

  static List<EconomicCenter> _computeCenters(List<BusinessLocation> locations) {
    if (locations.isEmpty) return [];
    final sorted = [...locations]..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha));
    final maxUsaha = sorted.first.totalUsaha;

    return sorted.take(5).toList().asMap().entries.map((e) {
      final loc = e.value;
      final idx = e.key;
      final score = maxUsaha > 0 ? (loc.totalUsaha / maxUsaha) * 100 : 0.0;
      final type = idx == 0 ? 'primary' : idx < 3 ? 'secondary' : 'tertiary';
      return EconomicCenter(
        name: loc.province,
        province: loc.province,
        latitude: loc.latitude,
        longitude: loc.longitude,
        score: score,
        totalUsaha: loc.totalUsaha,
        dominantSector: loc.sectorName,
        description: _centerDesc(loc, idx),
        centerType: type,
      );
    }).toList();
  }

  static String _centerDesc(BusinessLocation loc, int rank) {
    if (rank == 0) {
      return '${loc.province} adalah pusat ekonomi utama Indonesia dengan dominasi '
          'sektor ${loc.sectorName}. Sentralitas tinggi mencerminkan peran sebagai '
          'hub distribusi nasional.';
    }
    if (rank < 3) {
      return '${loc.province} berperan sebagai pusat regional dengan ${_formatNumber(loc.totalUsaha)} '
          'unit usaha aktif dan pengaruh ekonomi signifikan di wilayahnya.';
    }
    return '${loc.province} menjadi simpul ekonomi tersier yang melengkapi jaringan '
        'distribusi kawasan.';
  }

  static List<SpatialInsight> _nationalInsights(
      List<BusinessLocation> locations, SpatialStatistics stats) {
    final total = stats.totalUsaha;
    final sorted = [...locations]..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha));
    final top3Total = sorted.take(3).fold(0, (s, l) => s + l.totalUsaha);
    final top3Names = sorted.take(3).map((l) => l.province).join(', ');
    final top3Pct = total > 0 ? (top3Total / total * 100).toStringAsFixed(1) : '0';

    final javaProvs = {'DKI JAKARTA','JAWA BARAT','JAWA TENGAH','DI YOGYAKARTA','JAWA TIMUR','BANTEN'};
    final javaTotal = locations.where((l) => javaProvs.contains(l.province.toUpperCase())).fold(0, (s,l)=>s+l.totalUsaha);
    final javaPct = total > 0 ? (javaTotal / total * 100).toStringAsFixed(1) : '0';

    final eastProvs = {'MALUKU','MALUKU UTARA','PAPUA','PAPUA BARAT'};
    final eastTotal = locations.where((l) => eastProvs.contains(l.province.toUpperCase())).fold(0,(s,l)=>s+l.totalUsaha);
    final eastPct = total > 0 ? (eastTotal / total * 100).toStringAsFixed(1) : '0';

    return [
      SpatialInsight(
        type: 'concentration',
        title: 'Konsentrasi Spasial Nasional',
        description:
        '3 provinsi teratas ($top3Names) menguasai $top3Pct% dari total usaha nasional. '
            'Indeks Gini spasial: ${(stats.spatialConcentrationIndex * 100).toStringAsFixed(0)}% — '
            'mengindikasikan ketimpangan distribusi yang tinggi.',
        magnitude: stats.spatialConcentrationIndex,
        relatedProvinces: sorted.take(3).map((l) => l.province).toList(),
      ),
      SpatialInsight(
        type: 'cluster',
        title: 'Dominasi Pulau Jawa',
        description:
        'Pulau Jawa menyumbang $javaPct% dari total usaha nasional meski hanya '
            'mencakup 7% wilayah daratan Indonesia. Ketimpangan ini mencerminkan '
            'sentralisasi pembangunan yang perlu dikoreksi.',
        magnitude: javaTotal / (total > 0 ? total : 1),
        relatedProvinces: ['DKI Jakarta', 'Jawa Timur', 'Jawa Barat', 'Jawa Tengah'],
      ),
      SpatialInsight(
        type: 'gap',
        title: 'Kesenjangan Kawasan Timur Indonesia',
        description:
        'Maluku dan Papua hanya berkontribusi $eastPct% dari total usaha nasional. '
            'Ketimpangan ini mengindikasikan potensi ekonomi yang belum teroptimalkan '
            'di kawasan kaya sumber daya alam ini.',
        magnitude: 1.0 - (eastTotal / (total > 0 ? total : 1)),
        relatedProvinces: ['Papua', 'Papua Barat', 'Maluku', 'Maluku Utara'],
      ),
      SpatialInsight(
        type: 'corridor',
        title: 'Koridor Ekonomi Trans-Sumatera',
        description:
        'Sumatera Utara–Riau–Sumatera Selatan–Lampung membentuk koridor ekonomi '
            'terpanjang kedua di Indonesia, menjadi penghubung antara kawasan barat '
            'dan pusat konsumsi di Jawa.',
        magnitude: 0.68,
        relatedProvinces: ['Sumatera Utara', 'Riau', 'Sumatera Selatan', 'Lampung'],
      ),
    ];
  }

  static String _nationalNarrative(
      SpatialStatistics stats, List<EconomicCenter> centers) {
    final top = centers.isNotEmpty ? centers.first.name : '-';
    return '**Analisis Spasial Persebaran Usaha Indonesia (SE 2016)**\n\n'
        'Peta menampilkan ${stats.totalLocations} provinsi dengan total '
        '${_formatNumber(stats.totalUsaha)} unit usaha. $top mendominasi '
        'sebagai pusat ekonomi utama nasional.\n\n'
        '**Temuan Utama:** Distribusi usaha sangat tidak merata — '
        '${(stats.spatialConcentrationIndex * 100).toStringAsFixed(0)}% indeks konsentrasi '
        'menunjukkan ketimpangan signifikan antara Jawa dan luar Jawa.\n\n'
        '**Rekomendasi Kebijakan:**\n'
        '• Program desentralisasi ekonomi dan kemudahan investasi di luar Jawa\n'
        '• Penguatan infrastruktur konektivitas antar-pulau\n'
        '• Insentif fiskal untuk pengembangan usaha di kawasan timur Indonesia';
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  // ─── Raw data (Sensus Ekonomi 2016 approximated) ──────────────────────
  static final List<Map<String, dynamic>> _rawData = [
    {
      'province': 'Jawa Timur', 'lat': -7.5360, 'lng': 112.2384,
      'total_usaha': 4678754, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 17.2,
      'sectors': {'G': 1983211, 'C': 812345, 'I': 654321, 'A': 498765, 'P': 312456},
    },
    {
      'province': 'Jawa Barat', 'lat': -6.9147, 'lng': 107.6098,
      'total_usaha': 4198432, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 15.4,
      'sectors': {'G': 1765432, 'C': 932154, 'I': 598765, 'A': 412345, 'P': 287654},
    },
    {
      'province': 'Jawa Tengah', 'lat': -7.1510, 'lng': 110.1403,
      'total_usaha': 3987654, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 14.7,
      'sectors': {'G': 1654321, 'C': 798765, 'I': 534321, 'A': 487654, 'P': 276543},
    },
    {
      'province': 'Sumatera Utara', 'lat': 2.1154, 'lng': 99.5451,
      'total_usaha': 1654321, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 6.1,
      'sectors': {'G': 698765, 'A': 312345, 'I': 243210, 'C': 198765, 'P': 134567},
    },
    {
      'province': 'DKI Jakarta', 'lat': -6.2088, 'lng': 106.8456,
      'total_usaha': 1432198, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 5.3,
      'sectors': {'G': 512345, 'K': 287654, 'J': 198765, 'M': 156789, 'I': 134567},
    },
    {
      'province': 'Banten', 'lat': -6.4058, 'lng': 106.0640,
      'total_usaha': 1298765, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 4.8,
      'sectors': {'G': 534321, 'C': 287654, 'I': 198765, 'A': 143210, 'P': 112345},
    },
    {
      'province': 'Sulawesi Selatan', 'lat': -3.6687, 'lng': 119.9740,
      'total_usaha': 954321, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 3.5,
      'sectors': {'G': 412345, 'A': 198765, 'I': 154321, 'C': 98765, 'P': 76543},
    },
    {
      'province': 'DI Yogyakarta', 'lat': -7.8753, 'lng': 110.4262,
      'total_usaha': 876543, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 3.2,
      'sectors': {'G': 356789, 'I': 198765, 'P': 132456, 'C': 98765, 'S': 54321},
    },
    {
      'province': 'Riau', 'lat': 0.2933, 'lng': 101.7068,
      'total_usaha': 812345, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 3.0,
      'sectors': {'G': 345678, 'A': 198765, 'B': 112345, 'I': 98765, 'C': 67890},
    },
    {
      'province': 'Sumatera Selatan', 'lat': -3.3194, 'lng': 103.9144,
      'total_usaha': 798765, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 2.9,
      'sectors': {'A': 312345, 'G': 298765, 'I': 112345, 'C': 87654, 'B': 43210},
    },
    {
      'province': 'Lampung', 'lat': -4.5585, 'lng': 105.4068,
      'total_usaha': 765432, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 2.8,
      'sectors': {'A': 298765, 'G': 243210, 'I': 112345, 'C': 76543, 'H': 34567},
    },
    {
      'province': 'Kalimantan Timur', 'lat': 0.5387, 'lng': 116.4194,
      'total_usaha': 654321, 'dominant_sector': 'B', 'dominant_sector_name': 'Pertambangan',
      'percentage': 2.4,
      'sectors': {'B': 198765, 'G': 187654, 'C': 98765, 'I': 87654, 'H': 54321},
    },
    {
      'province': 'Sumatera Barat', 'lat': -0.7399, 'lng': 100.8000,
      'total_usaha': 632198, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 2.3,
      'sectors': {'G': 256789, 'A': 143210, 'I': 112345, 'P': 67890, 'C': 54321},
    },
    {
      'province': 'Bali', 'lat': -8.3405, 'lng': 115.0920,
      'total_usaha': 612345, 'dominant_sector': 'I', 'dominant_sector_name': 'Akomodasi & Kuliner',
      'percentage': 2.3,
      'sectors': {'I': 256789, 'G': 156789, 'R': 87654, 'A': 54321, 'L': 43210},
    },
    {
      'province': 'Aceh', 'lat': 4.6951, 'lng': 96.7494,
      'total_usaha': 598765, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 2.2,
      'sectors': {'G': 243210, 'A': 156789, 'I': 98765, 'C': 56789, 'P': 43210},
    },
    {
      'province': 'Kalimantan Barat', 'lat': -0.2787, 'lng': 111.4753,
      'total_usaha': 567890, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 2.1,
      'sectors': {'A': 198765, 'G': 187654, 'B': 76543, 'I': 54321, 'C': 43210},
    },
    {
      'province': 'Sulawesi Tengah', 'lat': -1.4300, 'lng': 121.4456,
      'total_usaha': 456789, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 1.7,
      'sectors': {'A': 198765, 'G': 134567, 'B': 54321, 'I': 43210, 'C': 23456},
    },
    {
      'province': 'Sulawesi Utara', 'lat': 0.6247, 'lng': 123.9750,
      'total_usaha': 398765, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 1.5,
      'sectors': {'G': 156789, 'A': 98765, 'I': 67890, 'P': 43210, 'C': 23456},
    },
    {
      'province': 'Nusa Tenggara Barat', 'lat': -8.6529, 'lng': 117.3616,
      'total_usaha': 387654, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 1.4,
      'sectors': {'A': 156789, 'G': 123456, 'I': 54321, 'B': 32109, 'P': 21098},
    },
    {
      'province': 'Jambi', 'lat': -1.6101, 'lng': 103.6131,
      'total_usaha': 365432, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 1.3,
      'sectors': {'A': 143210, 'G': 112345, 'B': 54321, 'I': 34567, 'C': 21456},
    },
    {
      'province': 'Kalimantan Selatan', 'lat': -3.0926, 'lng': 115.2838,
      'total_usaha': 354321, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 1.3,
      'sectors': {'G': 143210, 'B': 87654, 'A': 67890, 'I': 34567, 'C': 21098},
    },
    {
      'province': 'Kepulauan Riau', 'lat': 3.9457, 'lng': 108.1429,
      'total_usaha': 312345, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 1.1,
      'sectors': {'G': 123456, 'C': 67890, 'I': 54321, 'J': 34567, 'K': 21098},
    },
    {
      'province': 'Sulawesi Tenggara', 'lat': -4.1449, 'lng': 122.1746,
      'total_usaha': 287654, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 1.1,
      'sectors': {'A': 112345, 'G': 98765, 'B': 32109, 'I': 23456, 'C': 12345},
    },
    {
      'province': 'Nusa Tenggara Timur', 'lat': -8.6574, 'lng': 121.0794,
      'total_usaha': 265432, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 1.0,
      'sectors': {'A': 112345, 'G': 87654, 'P': 34567, 'I': 21098, 'C': 9876},
    },
    {
      'province': 'Bengkulu', 'lat': -3.5778, 'lng': 102.3464,
      'total_usaha': 243210, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.9,
      'sectors': {'A': 98765, 'G': 87654, 'I': 32109, 'C': 14567, 'P': 9876},
    },
    {
      'province': 'Gorontalo', 'lat': 0.6999, 'lng': 122.4467,
      'total_usaha': 198765, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.7,
      'sectors': {'A': 87654, 'G': 67890, 'I': 23456, 'P': 12345, 'C': 7654},
    },
    {
      'province': 'Maluku', 'lat': -3.2385, 'lng': 130.1453,
      'total_usaha': 187654, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.7,
      'sectors': {'A': 76543, 'G': 65432, 'I': 21098, 'P': 12345, 'C': 7654},
    },
    {
      'province': 'Sulawesi Barat', 'lat': -2.8441, 'lng': 119.2321,
      'total_usaha': 176543, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.6,
      'sectors': {'A': 76543, 'G': 54321, 'I': 21098, 'C': 12345, 'P': 9876},
    },
    {
      'province': 'Kalimantan Tengah', 'lat': -1.6815, 'lng': 113.3824,
      'total_usaha': 165432, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.6,
      'sectors': {'A': 65432, 'G': 54321, 'B': 23456, 'I': 12345, 'C': 9876},
    },
    {
      'province': 'Kep. Bangka Belitung', 'lat': -2.7411, 'lng': 106.4406,
      'total_usaha': 154321, 'dominant_sector': 'B', 'dominant_sector_name': 'Pertambangan',
      'percentage': 0.6,
      'sectors': {'B': 56789, 'G': 45678, 'A': 23456, 'I': 14567, 'C': 9876},
    },
    {
      'province': 'Maluku Utara', 'lat': 1.5709, 'lng': 127.8088,
      'total_usaha': 143210, 'dominant_sector': 'A', 'dominant_sector_name': 'Pertanian',
      'percentage': 0.5,
      'sectors': {'A': 56789, 'G': 45678, 'B': 19876, 'I': 12345, 'C': 7654},
    },
    {
      'province': 'Kalimantan Utara', 'lat': 3.0731, 'lng': 116.0413,
      'total_usaha': 98765, 'dominant_sector': 'B', 'dominant_sector_name': 'Pertambangan',
      'percentage': 0.4,
      'sectors': {'B': 34567, 'G': 32109, 'A': 14567, 'I': 9876, 'C': 6789},
    },
    {
      'province': 'Papua', 'lat': -4.2699, 'lng': 138.0804,
      'total_usaha': 187654, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 0.7,
      'sectors': {'G': 67890, 'A': 54321, 'B': 32109, 'I': 19876, 'P': 9876},
    },
    {
      'province': 'Papua Barat', 'lat': -1.3361, 'lng': 133.1747,
      'total_usaha': 132456, 'dominant_sector': 'G', 'dominant_sector_name': 'Perdagangan',
      'percentage': 0.5,
      'sectors': {'G': 45678, 'A': 36789, 'B': 23456, 'I': 14567, 'C': 8765},
    },
  ];
}