class RainfallHistoryModel {
  final RainfallSummary summary;
  final List<DailyRainfall> dailyData;

  RainfallHistoryModel({required this.summary, required this.dailyData});

  factory RainfallHistoryModel.fromJson(Map<String, dynamic> json) {
    return RainfallHistoryModel(
      summary: RainfallSummary.fromJson(json['summary']),
      dailyData: (json['daily_data'] as List)
          .map((e) => DailyRainfall.fromJson(e))
          .toList(),
    );
  }
}

class RainfallSummary {
  final double totalRainfall;
  final double averageDaily;
  final String maxRainfallDate;
  final double maxRainfallAmount;

  RainfallSummary({
    required this.totalRainfall,
    required this.averageDaily,
    required this.maxRainfallDate,
    required this.maxRainfallAmount,
  });

  factory RainfallSummary.fromJson(Map<String, dynamic> json) {
    return RainfallSummary(
      totalRainfall: (json['total_rainfall'] ?? 0).toDouble(),
      averageDaily: (json['average_daily'] ?? 0).toDouble(),
      maxRainfallDate: json['max_rainfall_day']['date'] ?? '',
      maxRainfallAmount: (json['max_rainfall_day']['amount'] ?? 0).toDouble(),
    );
  }
}

class DailyRainfall {
  final String date;
  final double precipitation;

  DailyRainfall({required this.date, required this.precipitation});

  factory DailyRainfall.fromJson(Map<String, dynamic> json) {
    return DailyRainfall(
      date: json['date'] ?? '',
      precipitation: (json['precipitation'] ?? 0).toDouble(),
    );
  }
}