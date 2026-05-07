import 'package:flutter/material.dart';

/// Privacy levels for location sharing
enum LocationPrivacyLevel { full, neighborhood, statusOnly }

/// Transport mode inferred from speed
enum TransportMode { stationary, walking, cycling, driving, publicTransit, unknown }

/// Type of safe zone (geofence)
enum SafeZoneType { home, work, school, danger, custom }

/// Alert severity levels
enum AlertSeverity { info, warning, critical }

/// Alert types
enum AlertType {
  geofenceEnter,
  geofenceExit,
  offline,
  lowBattery,
  panic,
  speedLimit,
  safeArrival,
}

/// A geofenced safe zone for a family member
class SafeZone {
  final String id;
  final String name;
  final SafeZoneType type;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? address;
  final TimeOfDay? activeStart;
  final TimeOfDay? activeEnd;

  const SafeZone({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    this.address,
    this.activeStart,
    this.activeEnd,
  });

  bool get isDangerZone => type == SafeZoneType.danger;
}

/// Real-time location update for a member
class LocationUpdate {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double speedKmh;
  final double heading;
  final int batteryPercent;
  final String signalStrength; // "Güçlü", "Orta", "Zayıf"
  final TransportMode transportMode;
  final DateTime timestamp;
  final String? address;

  const LocationUpdate({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    this.altitude,
    this.speedKmh = 0,
    this.heading = 0,
    this.batteryPercent = 100,
    this.signalStrength = 'Güçlü',
    this.transportMode = TransportMode.unknown,
    required this.timestamp,
    this.address,
  });

  TransportMode get inferredTransportMode {
    if (speedKmh < 1) return TransportMode.stationary;
    if (speedKmh < 10) return TransportMode.walking;
    if (speedKmh < 25) return TransportMode.cycling;
    if (speedKmh < 80) return TransportMode.driving;
    return TransportMode.publicTransit;
  }
}

/// Rich safety status for a family member
class MemberSafetyStatus {
  final String memberId;
  final String name;
  final String initial;
  final Color color;
  final String statusText; // "Evde", "Yolda (Araba)", etc.
  final Color statusColor;
  final bool isOnline;
  final DateTime? lastSeen;
  final LocationUpdate? lastLocation;
  final int batteryPercent;
  final String signalStrength;
  final String? currentPlace;
  final String? destination;
  final String? eta;
  final List<SafeZone> safeZones;
  final LocationPrivacyLevel privacyLevel;
  final bool panicActive;

  const MemberSafetyStatus({
    required this.memberId,
    required this.name,
    required this.initial,
    required this.color,
    required this.statusText,
    required this.statusColor,
    this.isOnline = true,
    this.lastSeen,
    this.lastLocation,
    this.batteryPercent = 100,
    this.signalStrength = 'Güçlü',
    this.currentPlace,
    this.destination,
    this.eta,
    this.safeZones = const [],
    this.privacyLevel = LocationPrivacyLevel.full,
    this.panicActive = false,
  });

  /// Determines status color based on online state and battery
  static Color computeStatusColor({
    required bool isOnline,
    required int batteryPercent,
    required DateTime? lastSeen,
    required bool panicActive,
  }) {
    if (panicActive) return const Color(0xFFDC2626); // Red
    if (!isOnline) {
      if (lastSeen == null) return const Color(0xFFEF4444); // Red
      final mins = DateTime.now().difference(lastSeen).inMinutes;
      if (mins > 60) return const Color(0xFFEF4444); // Red
      if (mins > 15) return const Color(0xFFF59E0B); // Amber
      return const Color(0xFF22C55E); // Green
    }
    if (batteryPercent < 10) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF22C55E); // Green
  }
}

/// Safety alert record
class SafetyAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String memberId;
  final String memberName;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final bool isRead;
  final List<AlertAction> actions;

  const SafetyAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.memberId,
    required this.memberName,
    required this.message,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.isRead = false,
    this.actions = const [],
  });
}

/// Action that can be taken on an alert
class AlertAction {
  final String type; // "call", "navigate", "dismiss"
  final String label;
  final String? payload;

  const AlertAction({
    required this.type,
    required this.label,
    this.payload,
  });
}

/// Daily safety report summary
class SafetyReport {
  final DateTime date;
  final List<MemberReport> memberReports;
  final List<String> aiSuggestions;

  const SafetyReport({
    required this.date,
    required this.memberReports,
    this.aiSuggestions = const [],
  });
}

class MemberReport {
  final String memberId;
  final String name;
  final String statusSummary;
  final Duration timeAtHome;
  final Duration timeAtWork;
  final Duration timeCommuting;
  final Duration timeOutside;
  final int geofenceEvents;
  final int alerts;

  const MemberReport({
    required this.memberId,
    required this.name,
    required this.statusSummary,
    this.timeAtHome = Duration.zero,
    this.timeAtWork = Duration.zero,
    this.timeCommuting = Duration.zero,
    this.timeOutside = Duration.zero,
    this.geofenceEvents = 0,
    this.alerts = 0,
  });
}
