import 'package:equatable/equatable.dart';

class MultipostingChannelDefinition extends Equatable {
  const MultipostingChannelDefinition({
    required this.id,
    required this.label,
    required this.defaultCostEur,
  });

  final String id;
  final String label;
  final double defaultCostEur;

  @override
  List<Object?> get props => [id, label, defaultCostEur];
}

const List<MultipostingChannelDefinition> companyMultipostingChannelCatalog = [
  MultipostingChannelDefinition(
    id: 'linkedin',
    label: 'LinkedIn',
    defaultCostEur: 249,
  ),
  MultipostingChannelDefinition(
    id: 'indeed',
    label: 'Indeed',
    defaultCostEur: 199,
  ),
  MultipostingChannelDefinition(
    id: 'university_portal',
    label: 'Portal universitario',
    defaultCostEur: 89,
  ),
  MultipostingChannelDefinition(
    id: 'infojobs',
    label: 'InfoJobs',
    defaultCostEur: 149,
  ),
  MultipostingChannelDefinition(
    id: 'glassdoor',
    label: 'Glassdoor',
    defaultCostEur: 129,
  ),
  MultipostingChannelDefinition(
    id: 'github_jobs',
    label: 'GitHub Jobs',
    defaultCostEur: 179,
  ),
];

const List<String> companyDefaultMultipostingChannels = [
  'linkedin',
  'indeed',
  'university_portal',
];

class CompanyMultipostingSettings extends Equatable {
  const CompanyMultipostingSettings({
    this.enabledChannels = companyDefaultMultipostingChannels,
    this.costOverridesEur = const <String, double>{},
  });

  final List<String> enabledChannels;
  final Map<String, double> costOverridesEur;

  factory CompanyMultipostingSettings.fromJson(
    Object? raw, {
    Object? fallbackEnabledChannels,
  }) {
    final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final hasExplicitEnabledChannels =
        map?.containsKey('enabledChannels') ?? false;
    final hasExplicitChannelsConfig = map?.containsKey('channels') ?? false;
    final hasExplicitFallbackChannels = fallbackEnabledChannels is List;

    final enabledFromMap = _parseEnabledChannels(map?['enabledChannels']);
    final channelsMap = map?['channels'] is Map
        ? Map<String, dynamic>.from(map!['channels'] as Map)
        : const <String, dynamic>{};

    final enabledFromChannels = <String>{};
    final costOverrides = <String, double>{};

    for (final entry in channelsMap.entries) {
      final channelId = _normalizeChannelId(entry.key);
      if (channelId == null) continue;

      final channelData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : const <String, dynamic>{};

      final enabledValue = channelData['enabled'];
      final isEnabled = enabledValue != false;
      if (isEnabled) {
        enabledFromChannels.add(channelId);
      }

      final overrideRaw = channelData['costEur'] ?? channelData['cost'];
      final overrideParsed = _parseNonNegativeDouble(overrideRaw);
      if (overrideParsed != null) {
        costOverrides[channelId] = overrideParsed;
      }
    }

    final enabledFromFallback = _parseEnabledChannels(fallbackEnabledChannels);

    final mergedEnabled = <String>{
      ...enabledFromMap,
      ...enabledFromChannels,
      ...enabledFromFallback,
    };
    final hasExplicitConfig =
        hasExplicitEnabledChannels ||
        hasExplicitChannelsConfig ||
        hasExplicitFallbackChannels;

    final resolvedEnabled = mergedEnabled.isEmpty
        ? (hasExplicitConfig
              ? const <String>[]
              : companyDefaultMultipostingChannels)
        : _sortChannels(mergedEnabled.toList(growable: false));

    return CompanyMultipostingSettings(
      enabledChannels: resolvedEnabled,
      costOverridesEur: costOverrides,
    );
  }

  CompanyMultipostingSettings copyWith({
    List<String>? enabledChannels,
    Map<String, double>? costOverridesEur,
  }) {
    return CompanyMultipostingSettings(
      enabledChannels: enabledChannels ?? this.enabledChannels,
      costOverridesEur: costOverridesEur ?? this.costOverridesEur,
    );
  }

  Map<String, dynamic> toJson() {
    final normalizedEnabled = _sortChannels(enabledChannels);
    final channels = <String, Map<String, dynamic>>{};

    for (final definition in companyMultipostingChannelCatalog) {
      final id = definition.id;
      final isEnabled = normalizedEnabled.contains(id);
      final override = costOverridesEur[id];
      if (!isEnabled && override == null) continue;

      final channelConfig = <String, dynamic>{'enabled': isEnabled};
      if (override != null) {
        channelConfig['costEur'] = override;
      }
      channels[id] = channelConfig;
    }

    return {'enabledChannels': normalizedEnabled, 'channels': channels};
  }

  double resolvedCostEur(String channelId) {
    final normalizedChannel = _normalizeChannelId(channelId);
    if (normalizedChannel == null) return 0;

    final override = costOverridesEur[normalizedChannel];
    if (override != null) return override;

    for (final definition in companyMultipostingChannelCatalog) {
      if (definition.id == normalizedChannel) {
        return definition.defaultCostEur;
      }
    }
    return 0;
  }

  @override
  List<Object?> get props => [enabledChannels, costOverridesEur];
}

List<String> _parseEnabledChannels(Object? raw) {
  if (raw is! List) return const [];

  final normalized = <String>{};
  for (final value in raw) {
    final channelId = _normalizeChannelId(value);
    if (channelId != null) {
      normalized.add(channelId);
    }
  }

  return _sortChannels(normalized.toList(growable: false));
}

String? _normalizeChannelId(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.isEmpty) return null;

  if (value == 'linkedin') return 'linkedin';
  if (value == 'indeed') return 'indeed';
  if (value == 'university_portal' ||
      value == 'university' ||
      value == 'universities') {
    return 'university_portal';
  }
  if (value == 'infojobs') return 'infojobs';
  if (value == 'glassdoor') return 'glassdoor';
  if (value == 'github_jobs' || value == 'github-jobs' || value == 'github') {
    return 'github_jobs';
  }

  return null;
}

double? _parseNonNegativeDouble(Object? raw) {
  if (raw == null) return null;

  if (raw is num) {
    final value = raw.toDouble();
    if (value >= 0) return value;
    return null;
  }

  final parsed = double.tryParse(raw.toString().trim());
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

List<String> _sortChannels(List<String> channels) {
  final idsInOrder = companyMultipostingChannelCatalog
      .map((channel) => channel.id)
      .toList(growable: false);

  final deduped = <String>{...channels};
  final ordered = <String>[];

  for (final id in idsInOrder) {
    if (deduped.remove(id)) {
      ordered.add(id);
    }
  }

  if (deduped.isNotEmpty) {
    final extra = deduped.toList(growable: false)..sort();
    ordered.addAll(extra);
  }

  return ordered;
}
