import 'dart:math' as math;

String money(double value) {
  final fixed = value.toStringAsFixed(value >= 100 ? 0 : 2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  if (parts.length == 1 || parts.last == '00') {
    return '\$$buffer';
  }

  return '\$$buffer.${parts.last}';
}

String compactNumber(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String formatBytes(num bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unitIndex]}';
}

String titleCase(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

double clampDouble(double value, double min, double max) {
  return math.max(min, math.min(max, value));
}

String riskScoreLabel(double score) {
  if (score >= 8) return 'Critical';
  if (score >= 6) return 'High';
  if (score >= 4) return 'Medium';
  if (score >= 2) return 'Low';
  return 'Info';
}

String formatRiskScore(double score) {
  return '${score.toStringAsFixed(1)} / 10';
}

String latencyLabel(double ms) {
  if (ms >= 1000) {
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
  return '${ms.toStringAsFixed(0)}ms';
}

String rpsLabel(double rps) {
  if (rps >= 1000000) {
    return '${(rps / 1000000).toStringAsFixed(1)}M req/s';
  }
  if (rps >= 1000) {
    return '${(rps / 1000).toStringAsFixed(1)}K req/s';
  }
  return '${rps.toStringAsFixed(0)} req/s';
}
