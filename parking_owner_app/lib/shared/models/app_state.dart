import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Theme ──────────────────────────────────────────────
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// ── Auth ───────────────────────────────────────────────
enum UserRole { appAdmin, complexManager, attendant, resident }

class UserInfo {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? currentComplexId;
  final String complexName;
  final String? profileImageUrl;

  const UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.currentComplexId,
    required this.complexName,
    this.profileImageUrl,
  });

  UserInfo copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? currentComplexId,
    String? complexName,
    String? profileImageUrl,
  }) {
    return UserInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      currentComplexId: currentComplexId ?? this.currentComplexId,
      complexName: complexName ?? this.complexName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

final currentUserProvider = StateProvider<UserInfo?>((ref) => null);

// ── Navigation ─────────────────────────────────────────
final navIndexProvider = StateProvider<int>((ref) => 0);

// ── Mock data ──────────────────────────────────────────
enum VehicleType { registered, visitor, unregistered }

class Vehicle {
  final String id;
  final String plateNumber;
  final VehicleType type;
  final String ownerName;
  final String unit;
  final DateTime? expiresAt;
  final DateTime lastSeen;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.ownerName,
    required this.unit,
    this.expiresAt,
    required this.lastSeen,
  });
}

class EntryLog {
  final String vehiclePlate;
  final VehicleType type;
  final DateTime timestamp;
  final bool isEntry;

  const EntryLog({
    required this.vehiclePlate,
    required this.type,
    required this.timestamp,
    required this.isEntry,
  });
}

final mockVehiclesProvider = Provider<List<Vehicle>>(
  (ref) => [
    Vehicle(
      id: '1',
      plateNumber: '123가4567',
      type: VehicleType.registered,
      ownerName: '김민준',
      unit: '101동 302호',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    Vehicle(
      id: '2',
      plateNumber: '456나8910',
      type: VehicleType.registered,
      ownerName: '이서연',
      unit: '102동 504호',
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Vehicle(
      id: '3',
      plateNumber: '789다1234',
      type: VehicleType.visitor,
      ownerName: '방문객',
      unit: '103동 201호',
      expiresAt: DateTime.now().add(const Duration(hours: 3)),
      lastSeen: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    Vehicle(
      id: '4',
      plateNumber: '321라5678',
      type: VehicleType.visitor,
      ownerName: '방문객',
      unit: '101동 402호',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Vehicle(
      id: '5',
      plateNumber: '654마9012',
      type: VehicleType.unregistered,
      ownerName: '미확인',
      unit: '-',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Vehicle(
      id: '6',
      plateNumber: '987바3456',
      type: VehicleType.registered,
      ownerName: '박지훈',
      unit: '104동 105호',
      lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ],
);

final mockEntryLogsProvider = Provider<List<EntryLog>>(
  (ref) => [
    EntryLog(
      vehiclePlate: '654마9012',
      type: VehicleType.unregistered,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isEntry: true,
    ),
    EntryLog(
      vehiclePlate: '123가4567',
      type: VehicleType.registered,
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      isEntry: true,
    ),
    EntryLog(
      vehiclePlate: '789다1234',
      type: VehicleType.visitor,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isEntry: true,
    ),
    EntryLog(
      vehiclePlate: '456나8910',
      type: VehicleType.registered,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isEntry: false,
    ),
    EntryLog(
      vehiclePlate: '321라5678',
      type: VehicleType.visitor,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isEntry: true,
    ),
    EntryLog(
      vehiclePlate: '987바3456',
      type: VehicleType.registered,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isEntry: false,
    ),
  ],
);
