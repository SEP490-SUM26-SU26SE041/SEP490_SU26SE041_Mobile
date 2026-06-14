enum LocationStatus { available, inUse, maintenance }

enum SensorType { temperature, humidity, soilMoisture, light, co2 }

enum SensorStatusType { online, offline, warning, idle }

class SensorModel {
  const SensorModel({
    required this.id,
    required this.sensorCode,
    required this.sensorType,
    required this.status,
    required this.unit,
    this.latestValue,
    this.lastUpdated,
    this.locationId,
  });

  final String id;
  final String sensorCode;
  final SensorType sensorType;
  final SensorStatusType status;
  final String unit;
  final double? latestValue;
  final DateTime? lastUpdated;
  final String? locationId;

  String get sensorTypeLabel => switch (sensorType) {
    SensorType.temperature => 'Temperature',
    SensorType.humidity    => 'Humidity',
    SensorType.soilMoisture => 'Soil Moisture',
    SensorType.light       => 'Light',
    SensorType.co2        => 'CO2',
  };

  String get sensorTypeUnit => switch (sensorType) {
    SensorType.temperature => '°C',
    SensorType.humidity    => '%',
    SensorType.soilMoisture => '%',
    SensorType.light       => 'lux',
    SensorType.co2        => 'ppm',
  };

  SensorStatusType get statusType => status;
}

class BedSensorReading {
  const BedSensorReading({
    required this.sensorId,
    required this.value,
    required this.timestamp,
  });
  final String sensorId;
  final double value;
  final DateTime timestamp;
}

class BedModel {
  const BedModel({
    required this.id,
    required this.bedCode,
    required this.length,
    required this.width,
    required this.status,
    this.experimentId,
    this.batchId,
    this.sensors = const [],
    this.readings = const [],
  });

  final String id;
  final String bedCode;
  final double length;
  final double width;
  final LocationStatus status;
  final String? experimentId;
  final String? batchId;
  final List<SensorModel> sensors;
  final List<BedSensorReading> readings;

  double get area => length * width;

  String get statusLabel => switch (status) {
    LocationStatus.available  => 'Available',
    LocationStatus.inUse    => 'In Use',
    LocationStatus.maintenance => 'Maintenance',
  };
}

class ZoneModel {
  const ZoneModel({
    required this.id,
    required this.zoneCode,
    required this.zoneName,
    required this.areaSize,
    required this.soilType,
    required this.status,
    this.beds = const [],
  });

  final String id;
  final String zoneCode;
  final String zoneName;
  final double areaSize;
  final String soilType;
  final LocationStatus status;
  final List<BedModel> beds;

  String get statusLabel => switch (status) {
    LocationStatus.available  => 'Available',
    LocationStatus.inUse    => 'In Use',
    LocationStatus.maintenance => 'Maintenance',
  };

  int get totalBeds => beds.length;
  int get availableBeds => beds.where((b) => b.status == LocationStatus.available).length;
}

class AreaModel {
  const AreaModel({
    required this.id,
    required this.areaCode,
    required this.areaName,
    required this.environmentType,
    required this.totalArea,
    required this.status,
    this.zones = const [],
  });

  final String id;
  final String areaCode;
  final String areaName;
  final String environmentType;
  final double totalArea;
  final LocationStatus status;
  final List<ZoneModel> zones;

  String get statusLabel => switch (status) {
    LocationStatus.available  => 'Available',
    LocationStatus.inUse    => 'In Use',
    LocationStatus.maintenance => 'Maintenance',
  };

  int get totalZones => zones.length;
  int get totalBeds => zones.fold(0, (sum, z) => sum + z.totalBeds);
  int get availableBeds => zones.fold(0, (sum, z) => sum + z.availableBeds);
}

class FarmModel {
  const FarmModel({
    required this.id,
    required this.farmCode,
    required this.farmName,
    required this.location,
    required this.status,
    this.areas = const [],
  });

  final String id;
  final String farmCode;
  final String farmName;
  final String location;
  final LocationStatus status;
  final List<AreaModel> areas;

  int get totalAreas => areas.length;
  int get totalZones => areas.fold(0, (sum, a) => sum + a.totalZones);
  int get totalBeds => areas.fold(0, (sum, a) => sum + a.totalBeds);
  int get availableBeds => areas.fold(0, (sum, a) => sum + a.availableBeds);

  String get statusLabel => switch (status) {
    LocationStatus.available  => 'Active',
    LocationStatus.inUse    => 'In Use',
    LocationStatus.maintenance => 'Maintenance',
  };
}
