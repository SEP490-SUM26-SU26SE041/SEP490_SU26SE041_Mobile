import '../shared/models/farm_model.dart';

final mockFarm = FarmModel(
  id: 'farm-001',
  farmCode: 'FARM-NVU-01',
  farmName: 'Trại Thực Nghiệm Nông Vụ',
  location: 'Bình Dương, Việt Nam',
  status: LocationStatus.inUse,
  areas: [
    AreaModel(
      id: 'area-001',
      areaCode: 'A01',
      areaName: 'Khu Nhà Lưới Alpha',
      environmentType: 'Nhà lưới kín',
      totalArea: 500.0,
      status: LocationStatus.inUse,
      zones: [
        ZoneModel(
          id: 'zone-001',
          zoneCode: 'Z01',
          zoneName: 'Khu trồng cà chua',
          areaSize: 120.0,
          soilType: 'Đất phù sa pha cát',
          status: LocationStatus.inUse,
          beds: [
            BedModel(
              id: 'bed-001',
              bedCode: 'B01',
              length: 5.0,
              width: 1.2,
              status: LocationStatus.inUse,
              experimentId: 'exp-001',
              batchId: 'batch-ctrl-01',
              sensors: const [
                SensorModel(id: 'sen-001', sensorCode: 'TEMP-Z01-B01', sensorType: SensorType.temperature, status: SensorStatusType.online, unit: '°C', latestValue: 28.4, lastUpdated: null),
                SensorModel(id: 'sen-002', sensorCode: 'HUM-Z01-B01', sensorType: SensorType.humidity, status: SensorStatusType.online, unit: '%', latestValue: 72.1, lastUpdated: null),
                SensorModel(id: 'sen-003', sensorCode: 'SOIL-Z01-B01', sensorType: SensorType.soilMoisture, status: SensorStatusType.online, unit: '%', latestValue: 45.8, lastUpdated: null),
              ],
            ),
            BedModel(
              id: 'bed-002',
              bedCode: 'B02',
              length: 5.0,
              width: 1.2,
              status: LocationStatus.inUse,
              experimentId: 'exp-001',
              batchId: 'batch-ctrl-02',
              sensors: const [
                SensorModel(id: 'sen-004', sensorCode: 'TEMP-Z01-B02', sensorType: SensorType.temperature, status: SensorStatusType.offline, unit: '°C', latestValue: null, lastUpdated: null),
              ],
            ),
            BedModel(
              id: 'bed-003',
              bedCode: 'B03',
              length: 5.0,
              width: 1.2,
              status: LocationStatus.available,
              sensors: const [],
            ),
          ],
        ),
        ZoneModel(
          id: 'zone-002',
          zoneCode: 'Z02',
          zoneName: 'Khu trồng rau muống',
          areaSize: 80.0,
          soilType: 'Đất thịt nặng',
          status: LocationStatus.available,
          beds: [
            BedModel(
              id: 'bed-004',
              bedCode: 'B01',
              length: 4.0,
              width: 1.0,
              status: LocationStatus.available,
              sensors: const [],
            ),
          ],
        ),
        ZoneModel(
          id: 'zone-003',
          zoneCode: 'Z03',
          zoneName: 'Khu trồng ớt chuông',
          areaSize: 60.0,
          soilType: 'Đất phù sa pha cát',
          status: LocationStatus.inUse,
          beds: [
            BedModel(
              id: 'bed-005',
              bedCode: 'B01',
              length: 4.0,
              width: 1.0,
              status: LocationStatus.maintenance,
              sensors: const [
                SensorModel(id: 'sen-005', sensorCode: 'TEMP-Z03-B01', sensorType: SensorType.temperature, status: SensorStatusType.warning, unit: '°C', latestValue: 35.2, lastUpdated: null),
              ],
            ),
          ],
        ),
      ],
    ),
    AreaModel(
      id: 'area-002',
      areaCode: 'A02',
      areaName: 'Khu Trồng Thủy Canh',
      environmentType: 'Nhà kính',
      totalArea: 300.0,
      status: LocationStatus.inUse,
      zones: [
        ZoneModel(
          id: 'zone-004',
          zoneCode: 'Z01',
          zoneName: 'Khu thủy canh 1',
          areaSize: 150.0,
          soilType: 'Dung dịch dinh dưỡng',
          status: LocationStatus.inUse,
          beds: [
            BedModel(
              id: 'bed-006',
              bedCode: 'B01',
              length: 6.0,
              width: 1.5,
              status: LocationStatus.inUse,
              sensors: const [
                SensorModel(id: 'sen-006', sensorCode: 'PH-Z04-B01', sensorType: SensorType.soilMoisture, status: SensorStatusType.online, unit: 'pH', latestValue: 6.5, lastUpdated: null),
                SensorModel(id: 'sen-007', sensorCode: 'EC-Z04-B01', sensorType: SensorType.soilMoisture, status: SensorStatusType.online, unit: 'mS/cm', latestValue: 2.1, lastUpdated: null),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
