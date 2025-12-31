import 'dart:convert';

/// Enum for data sources - matches backend DataSource
enum DataSource {
  government,
  economic,
  news,
  academic,
  socialMedia;

  String get value {
    switch (this) {
      case DataSource.government:
        return 'government';
      case DataSource.economic:
        return 'economic';
      case DataSource.news:
        return 'news';
      case DataSource.academic:
        return 'academic';
      case DataSource.socialMedia:
        return 'social_media';
    }
  }

  static DataSource fromString(String? value) {
    switch (value) {
      case 'government':
        return DataSource.government;
      case 'economic':
        return DataSource.economic;
      case 'news':
        return DataSource.news;
      case 'academic':
        return DataSource.academic;
      case 'social_media':
        return DataSource.socialMedia;
      default:
        return DataSource.economic;
    }
  }
}

/// Enum for policy categories - matches backend PolicyCategory
enum PolicyCategory {
  economic,
  social,
  environmental,
  healthcare,
  education,
  security,
  technology;

  String get value {
    switch (this) {
      case PolicyCategory.economic:
        return 'economic';
      case PolicyCategory.social:
        return 'social';
      case PolicyCategory.environmental:
        return 'environmental';
      case PolicyCategory.healthcare:
        return 'healthcare';
      case PolicyCategory.education:
        return 'education';
      case PolicyCategory.security:
        return 'security';
      case PolicyCategory.technology:
        return 'technology';
    }
  }

  String get displayName {
    switch (this) {
      case PolicyCategory.economic:
        return 'Ekonomi';
      case PolicyCategory.social:
        return 'Sosial';
      case PolicyCategory.environmental:
        return 'Lingkungan';
      case PolicyCategory.healthcare:
        return 'Kesehatan';
      case PolicyCategory.education:
        return 'Pendidikan';
      case PolicyCategory.security:
        return 'Keamanan';
      case PolicyCategory.technology:
        return 'Teknologi';
    }
  }

  static PolicyCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'economic':
        return PolicyCategory.economic;
      case 'social':
        return PolicyCategory.social;
      case 'environmental':
        return PolicyCategory.environmental;
      case 'healthcare':
        return PolicyCategory.healthcare;
      case 'education':
        return PolicyCategory.education;
      case 'security':
        return PolicyCategory.security;
      case 'technology':
        return PolicyCategory.technology;
      default:
        return PolicyCategory.economic;
    }
  }
}

/// VisualizationConfig - matches backend VisualizationConfig model
class VisualizationConfig {
  final String id;
  final String type; // 'chart', 'graph', 'map', 'table'
  final String title;
  final Map<String, dynamic> config; // ECharts configuration
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  VisualizationConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.config,
    required this.data,
    this.createdAt,
  });

  factory VisualizationConfig.fromJson(Map<String, dynamic> json) {
    return VisualizationConfig(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] ?? 'chart',
      title: json['title'] ?? 'Visualization',
      config: json['config'] is Map ? Map<String, dynamic>.from(json['config']) : {},
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'config': config,
      'data': data,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get chart type from ECharts config
  String get chartType {
    final series = config['series'];
    if (series is List && series.isNotEmpty) {
      return series[0]['type']?.toString() ?? 'bar';
    }
    return 'bar';
  }

  /// Get data for Flutter charts
  List<Map<String, dynamic>> get chartData {
    final series = config['series'];
    if (series is List && series.isNotEmpty) {
      final seriesData = series[0]['data'];
      if (seriesData is List) {
        // For pie charts
        if (chartType == 'pie') {
          return seriesData.map((item) {
            if (item is Map) {
              return {
                'name': item['name']?.toString() ?? '',
                'value': (item['value'] is num) ? item['value'] : 0,
              };
            }
            return {'name': '', 'value': 0};
          }).toList().cast<Map<String, dynamic>>();
        }
        // For bar/line charts
        final xAxis = config['xAxis'];
        final categories = xAxis is Map ? (xAxis['data'] as List?)?.cast<String>() ?? [] : <String>[];

        return List.generate(seriesData.length, (index) {
          final value = seriesData[index];
          return {
            'label': index < categories.length ? categories[index] : 'Item $index',
            'value': value is num ? value : (value is Map ? value['value'] ?? 0 : 0),
          };
        });
      }
    }
    return [];
  }
}

/// PolicyInsight - matches backend PolicyInsight model
class PolicyInsight {
  final String id;
  final String text;
  final double confidenceScore;
  final List<String> supportingDataIds;
  final PolicyCategory category;
  final DateTime? createdAt;

  PolicyInsight({
    required this.id,
    required this.text,
    this.confidenceScore = 0.0,
    this.supportingDataIds = const [],
    required this.category,
    this.createdAt,
  });

  factory PolicyInsight.fromJson(Map<String, dynamic> json) {
    return PolicyInsight(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      supportingDataIds: json['supporting_data_ids'] != null
          ? List<String>.from(json['supporting_data_ids'])
          : [],
      category: PolicyCategory.fromString(json['category']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'confidence_score': confidenceScore,
      'supporting_data_ids': supportingDataIds,
      'category': category.value,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// PolicyRecommendation - matches backend PolicyRecommendation model
class PolicyRecommendation {
  final String id;
  final String title;
  final String description;
  final String priority; // 'high', 'medium', 'low'
  final PolicyCategory category;
  final String impact;
  final List<String> implementationSteps;
  final List<String> supportingInsights;
  final List<String> supportingDataIds;
  final DateTime? createdAt;

  PolicyRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.impact,
    required this.implementationSteps,
    this.supportingInsights = const [],
    this.supportingDataIds = const [],
    this.createdAt,
  });

  factory PolicyRecommendation.fromJson(Map<String, dynamic> json) {
    return PolicyRecommendation(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      category: PolicyCategory.fromString(json['category']),
      impact: json['impact'] ?? '',
      implementationSteps: json['implementation_steps'] != null
          ? List<String>.from(json['implementation_steps'])
          : [],
      supportingInsights: json['supporting_insights'] != null
          ? List<String>.from(json['supporting_insights'])
          : [],
      supportingDataIds: json['supporting_data_ids'] != null
          ? List<String>.from(json['supporting_data_ids'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category.value,
      'impact': impact,
      'implementation_steps': implementationSteps,
      'supporting_insights': supportingInsights,
      'supporting_data_ids': supportingDataIds,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get priority color
  String get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return '#e74c3c';
      case 'medium':
        return '#f39c12';
      case 'low':
        return '#2ecc71';
      default:
        return '#f39c12';
    }
  }
}

/// ChatMessage - matches backend ChatMessage model
class ChatMessage {
  final String id;
  final String sessionId;
  final String sender; // 'user' or 'ai'
  final String content;
  final List<VisualizationConfig>? visualizations;
  final List<String>? insights;
  final List<PolicyRecommendation>? policies;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    this.visualizations,
    this.insights,
    this.policies,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: json['session_id']?.toString() ?? '',
      sender: json['sender'] ?? 'user',
      content: json['content'] ?? '',
      visualizations: json['visualizations'] != null && json['visualizations'] is List
          ? (json['visualizations'] as List)
          .map((v) => VisualizationConfig.fromJson(v))
          .toList()
          : null,
      insights: json['insights'] != null && json['insights'] is List
          ? List<String>.from(json['insights'])
          : null,
      policies: json['policies'] != null && json['policies'] is List
          ? (json['policies'] as List)
          .map((p) => PolicyRecommendation.fromJson(p))
          .toList()
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender': sender,
      'content': content,
      'visualizations': visualizations?.map((v) => v.toJson()).toList(),
      'insights': insights,
      'policies': policies?.map((p) => p.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isAI => sender == 'ai';
  bool get isUser => sender == 'user';

  bool get hasVisualizations => visualizations != null && visualizations!.isNotEmpty;
  bool get hasInsights => insights != null && insights!.isNotEmpty;
  bool get hasPolicies => policies != null && policies!.isNotEmpty;
  bool get hasAnalysis => hasVisualizations || hasInsights || hasPolicies;

  int get visualizationCount => visualizations?.length ?? 0;
  int get insightCount => insights?.length ?? 0;
  int get policyCount => policies?.length ?? 0;
}

/// ChatSession - matches backend ChatSession model
class ChatSession {
  final String id;
  final String? userId; // NEW: Link session to user
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final int? messageCount;

  ChatSession({
    required this.id,
    this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // Safe parsing for messages list
    List<ChatMessage> parsedMessages = [];
    if (json['messages'] != null && json['messages'] is List) {
      for (var m in json['messages']) {
        try {
          if (m is Map<String, dynamic>) {
            parsedMessages.add(ChatMessage.fromJson(m));
          } else if (m is Map) {
            parsedMessages.add(ChatMessage.fromJson(Map<String, dynamic>.from(m)));
          }
        } catch (e) {
          print('[ChatSession] Error parsing message: $e');
        }
      }
    }

    // Safe int parsing helper
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ChatSession(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? 'Policy Analysis Session',
      messages: parsedMessages,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      messageCount: parseIntSafe(json['message_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  int get realMessageCount {
    if (messageCount != null) return messageCount!;
    return messages.where((m) => !m.id.startsWith('welcome_')).length;
  }

  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// PolicyAnalysisRequest - matches backend PolicyAnalysisRequest model
class PolicyAnalysisRequest {
  final String message;
  final String? sessionId;
  final bool includeVisualizations;
  final bool includeInsights;
  final bool includePolicies;

  PolicyAnalysisRequest({
    required this.message,
    this.sessionId,
    this.includeVisualizations = true,
    this.includeInsights = true,
    this.includePolicies = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'session_id': sessionId,
      'include_visualizations': includeVisualizations,
      'include_insights': includeInsights,
      'include_policies': includePolicies,
    };
  }
}

/// PolicyAnalysisResponse - matches backend PolicyAnalysisResponse model
class ChatResponse {
  final String message;
  final String sessionId;
  final List<VisualizationConfig>? visualizations;
  final List<String>? insights;
  final List<PolicyRecommendation>? policies;
  final int supportingDataCount;

  ChatResponse({
    required this.message,
    required this.sessionId,
    this.visualizations,
    this.insights,
    this.policies,
    required this.supportingDataCount,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    // Safe int parsing helper
    int parseIntSafe(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return ChatResponse(
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      visualizations: json['visualizations'] != null && json['visualizations'] is List
          ? (json['visualizations'] as List)
          .map((v) => VisualizationConfig.fromJson(v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v)))
          .toList()
          : null,
      insights: json['insights'] != null && json['insights'] is List
          ? List<String>.from(json['insights'].map((e) => e.toString()))
          : null,
      policies: json['policies'] != null && json['policies'] is List
          ? (json['policies'] as List)
          .map((p) => PolicyRecommendation.fromJson(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p)))
          .toList()
          : null,
      supportingDataCount: parseIntSafe(json['supporting_data_count']),
    );
  }
}

/// Health status response
class HealthStatus {
  final String status;
  final String database;
  final String aiAnalyzer;
  final String scrapingStatus;
  final DateTime? lastScraping;
  final Map<String, dynamic>? dataStats;

  HealthStatus({
    required this.status,
    required this.database,
    required this.aiAnalyzer,
    required this.scrapingStatus,
    this.lastScraping,
    this.dataStats,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] ?? 'unknown',
      database: json['database'] ?? 'unknown',
      aiAnalyzer: json['ai_analyzer'] ?? 'unknown',
      scrapingStatus: json['scraping_status'] ?? 'idle',
      lastScraping: json['last_scraping'] != null
          ? DateTime.tryParse(json['last_scraping'].toString())
          : null,
      dataStats: json['data_stats'] is Map
          ? Map<String, dynamic>.from(json['data_stats'])
          : null,
    );
  }

  bool get isHealthy => status == 'healthy';
  bool get isDatabaseConnected => database == 'connected';
  bool get isAIReady => aiAnalyzer == 'ready';
}