# TaskReport & MeasurementRecord - Luồng Logic Front-end

> Tài liệu mô tả chi tiết logic xử lý **báo cáo tác vụ** (TaskReport) và **bản ghi đo lường** (MeasurementRecord) cho 2 vai trò **Student** & **Technician**, dùng làm reference để implement bên **mobile** với logic tương đương.

**Phiên bản:** MeasurementStatistics v1.0
**Áp dụng:** `src/components/tasks/TaskReportForm.jsx`, `src/utils/measurementBridge.js`, `src/utils/measurement.js`, `src/pages/technician/TechnicianDashboard.jsx`, `src/pages/student/StudentDashboard.jsx`, `src/pages/PersonalTaskList.jsx`

---

## 1. Tổng quan

### 1.1 Bối cảnh

Hệ thống có 3 thực thể chính:

| Entity | Mục đích | Người tạo |
|--------|----------|-----------|
| **Task** (`/api/tasks`) | Đơn vị công việc (trồng cây, tưới nước, đo lường...) được giao cho Student/Tech | Researcher (sinh tự động theo stage) |
| **TaskReport** (`/api/task-reports`) | Báo cáo kết quả thực hiện Task kèm `resultData` dạng key/value | Student / Technician |
| **MeasurementRecord** (`/api/measurement-records`) | Bản ghi đo lường chuẩn hoá gắn vào batch/stage (cùng `measuredAt`) — dùng cho thống kê của Researcher | Auto-bridge từ TaskReport |

### 1.2 Hai đường tạo Measurement

Khi Student/Tech gửi báo cáo, hệ thống **TỰ ĐỘNG tạo** MeasurementRecord tương ứng:

1. **Bulk path** (`POST /measurement-records/bulk`) — dùng cho:
   - `Measurement` task
   - `Observation` task
   - Form động theo `MeasurementDefinition`

2. **Legacy path** (`POST /measurement-records` từng cái) — dùng cho:
   - `Planting` / `Watering` / `Fertilizing` / `Inspection` / `Harvest` / `Other`
   - Mapping qua bảng `MEASUREMENT_FIELD_MAP`

### 1.3 Ba flow chính

```
┌─────────────────────────────────────────────────────────────────────┐
│ FLOW 1: Mở Task Detail Modal                                        │
│   GET /tasks/{taskId}                                               │
│   GET /experiments/{expId}/measurements   (lấy definitions)          │
│   GET /batches/{batchId}                  (lấy groupId của batch)   │
│   GET /task-reports/task/{taskId}         (lấy reports lịch sử)     │
└─────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│ FLOW 2: Gửi Báo cáo (không complete)                                │
│   POST /task-reports           ← tạo TaskReport                     │
│   POST /measurement-records/bulk  HOẶC  POST /measurement-records   │
│   POST /task-images/upload        ← upload ảnh (multipart)         │
└─────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│ FLOW 3: Hoàn thành Tác vụ                                          │
│   (Flow 2)                                                          │
│   PATCH /tasks/{taskId}/complete  ← đánh dấu hoàn thành             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. API Endpoints

### 2.1 Tasks

```
GET    /api/tasks/my                       ← danh sách task của tôi
GET    /api/tasks/today                    ← task hôm nay
GET    /api/tasks/upcoming?days=7          ← task sắp tới
GET    /api/tasks/overdue                  ← task trễ hạn
GET    /api/tasks/{id}                     ← chi tiết task
GET    /api/tasks/batch/{batchId}          ← task theo batch
GET    /api/tasks/assignments/my           ← task được giao
PATCH  /api/tasks/{id}/start               ← bắt đầu task
PATCH  /api/tasks/{id}/complete            ← hoàn thành task
PATCH  /api/tasks/{id}/cancel              ← huỷ task
```

### 2.2 Task Reports

```
POST   /api/task-reports                   ← tạo report
GET    /api/task-reports/task/{taskId}     ← lịch sử report của task
GET    /api/task-reports/batch/{batchId}   ← report theo batch
PUT    /api/task-reports/{id}              ← cập nhật report
```

**Request body `POST /task-reports`:**
```json
{
  "taskId": "uuid",
  "reportText": "Mô tả chi tiết kết quả thực hiện",
  "resultData": {
    "plantCount": "120",
    "plantSpacing": "30",
    "def_<uuid-của-definition-1>": "18",
    "def_<uuid-của-definition-2>": "85",
    "custom_key_1": "giá trị tự do"
  }
}
```

**Response:** `{ success, message, data: { id, taskId, reporterId, reportText, resultData, createdAt } }`

### 2.3 Measurement Records

```
POST   /api/measurement-records                                  ← tạo đơn lẻ (legacy)
POST   /api/measurement-records/bulk                             ← tạo nhiều cùng lúc
GET    /api/measurement-records/batch/{batchId}                  ← tra cứu
GET    /api/measurement-records/experiment/{expId}               ← theo experiment
PUT    /api/measurement-records/{id}                             ← cập nhật
DELETE /api/measurement-records/{id}                             ← xoá
```

**Schema MeasurementRecord (BE trả về):**
```typescript
interface MeasurementRecord {
  id: string;
  experimentId: string;
  experimentStageId: string | null;
  batchId: string | null;
  taskId: string | null;
  measurementDefinitionId: string | null;
  metricName: string;           // BE tự populate từ definition
  unit: string;                 // BE tự populate từ definition
  targetValue: number | null;   // BE tự populate từ definition
  value: number;                // ← giá trị đo được do FE gửi lên
  measuredBy: string;
  measuredAt: string;           // ISO 8601, cùng timestamp cho cả batch trong 1 lần đo
  notes?: string;
  extraData?: { note: string; sourceKey?: string };
}
```

**Request `POST /measurement-records` (legacy - từng cái):**
```json
{
  "experimentId": "uuid",
  "experimentStageId": "uuid",
  "batchId": "uuid",
  "taskId": "uuid",
  "measurementDefinitionId": "uuid",
  "value": 18.5,
  "measuredAt": "2026-08-14T09:30:00.000Z"
}
```

**Request `POST /measurement-records/bulk`:**
```json
{
  "experimentId": "uuid",
  "experimentStageId": "uuid",
  "batchId": "uuid",
  "measuredAt": "2026-08-14T09:30:00.000Z",
  "extraData": { "note": "..." },
  "items": [
    {
      "measurementDefinitionId": "uuid-1",
      "value": 18.5,
      "metricName": "Chiều cao cây",
      "unit": "cm",
      "targetValue": 25
    },
    {
      "measurementDefinitionId": "uuid-2",
      "value": 85.0,
      "metricName": "Độ ẩm đất",
      "unit": "%",
      "targetValue": 80
    }
  ]
}
```

**Response bulk:** `{ success, message, data: { created, skipped, warnings, records } }`

### 2.4 Measurement Definitions (định nghĩa metric - Researcher tạo)

```
GET    /api/experiments/{experimentId}/measurements
GET    /api/measurement-definitions?experimentId={id}        ← legacy
GET    /api/measurement-definitions/{id}
POST   /api/measurement-definitions                         ← tạo
PUT    /api/measurement-definitions/{id}                    ← cập nhật
DELETE /api/measurement-definitions/{id}                    ← xoá
POST   /api/measurement-definitions/{id}/validate?value=18.5
```

**Schema MeasurementDefinition:**
```typescript
interface MeasurementDefinition {
  id: string;
  experimentId: string;
  groupId: string;          // ⭐ QUAN TRỌNG - mỗi nhóm có bộ metric riêng
  groupName: string;       // "Phân NPK", "Phân hữu cơ", "Đối chứng", ...
  metricName: string;       // "Chiều cao cây", "Số lá trung bình", ...
  unit: string;            // "cm", "lá", "%", ...
  targetValue: number;     // mục tiêu cần đạt
  description?: string;
}
```

### 2.5 Batches

```
GET    /api/batches/{id}                       ← lấy groupId của batch (⭐ dùng để filter)
GET    /api/batches/experiments/{experimentId}
```

**Response schema:**
```typescript
{
  id: string;
  batchCode: string;
  experimentId: string;
  groupId: string;        // ⭐ field quan trọng nhất
  groupName: string;
  ...
}
```

### 2.6 Task Images

```
POST   /api/task-images/upload     ← multipart (File + metadata)
POST   /api/task-images            ← JSON (chỉ URL)
GET    /api/task-images/task/{reportId}
GET    /api/task-images/batch/{batchId}
DELETE /api/task-images/{id}
```

**Request `POST /task-images/upload` (multipart/form-data):**
```
File          binary ← file ảnh
experimentId  text
batchId       text
taskReportId  text
taskId        text
imageUrl      text    (optional, nếu đã có Cloudinary URL)
caption       text    (optional)
capturedAt    text    (ISO 8601)
tags          text    (optional)
exif          text    (JSON string, optional)
```

---

## 3. Form Rendering - 2 dạng

### 3.1 Quick Form (Form cố định theo taskType)

Áp dụng cho 6 loại task. Schema được hardcode trong `QUICK_FORM_SCHEMA`:

```javascript
const QUICK_FORM_SCHEMA = {
  Planting:      { icon: '🌱', fields: [...] },
  Watering:      { icon: '💧', fields: [...] },
  Fertilizing:   { icon: '🧪', fields: [...] },
  Inspection:    { icon: '🔍', fields: [...] },
  Harvest:       { icon: '🌾', fields: [...] },
  Other:         { icon: '📋', fields: [] },
  Observation:   { icon: '👁️', fields: [], isDynamic: true },
  Measurement:   { icon: '📏', fields: [], isDynamic: true }
};
```

**Chi tiết schema 6 loại hardcode:**

```javascript
Planting = {
  fields: [
    { key: 'plantCount',     label: 'Số cây đã trồng',    type: 'number', unit: 'cây' },
    { key: 'plantSpacing',   label: 'Khoảng cách cây',    type: 'number', unit: 'cm' },
    { key: 'soilCondition',  label: 'Tình trạng đất',     type: 'select',
      options: ['Tốt', 'Trung bình', 'Khô', 'Ẩm ướt'] },
    { key: 'seedlingSource', label: 'Nguồn giống',        type: 'text' }
  ]
}

Watering = {
  fields: [
    { key: 'waterAmount',         label: 'Lượng nước tưới',    type: 'number', unit: 'L/m²' },
    { key: 'irrigationMethod',    label: 'Phương pháp tưới',   type: 'select',
      options: ['Phun mưa', 'Nhỏ giọt', 'Thủ công', 'Ngập'] },
    { key: 'duration',            label: 'Thời gian tưới',     type: 'number', unit: 'phút' },
    { key: 'soilMoistureBefore',  label: 'Độ ẩm đất trước',   type: 'number', unit: '%' },
    { key: 'soilMoistureAfter',   label: 'Độ ẩm đất sau',     type: 'number', unit: '%' }
  ]
}

Fertilizing = {
  fields: [
    { key: 'fertilizerType',     label: 'Loại phân',         type: 'select',
      options: ['NPK', 'Hữu cơ', 'Vi sinh', 'Ure', 'Phân chuồng', 'Phân xanh', 'Khác'] },
    { key: 'fertilizerAmount',   label: 'Liều lượng',        type: 'number', unit: 'g/cây' },
    { key: 'fertilizerBrand',    label: 'Thương hiệu',       type: 'text' },
    { key: 'applicationMethod',  label: 'Cách bón',          type: 'select',
      options: ['Rải gốc', 'Pha nước', 'Bón lá', 'Bón theo hàng'] }
  ]
}

Inspection = {
  fields: [
    { key: 'overallHealth',        label: 'Tình trạng tổng thể',    type: 'select',
      options: ['Tốt', 'Trung bình', 'Yếu', 'Có vấn đề'] },
    { key: 'pestDiseaseLevel',     label: 'Mức độ sâu bệnh',       type: 'select',
      options: ['Không có', 'Nhẹ', 'Trung bình', 'Nặng'] },
    { key: 'affectedPlantCount',   label: 'Số cây bị ảnh hưởng',    type: 'number', unit: 'cây' },
    { key: 'inspectionChecklist',  label: 'Checklist tuân thủ',    type: 'select',
      options: ['Đạt', 'Cần cải thiện', 'Không đạt'] }
  ]
}

Harvest = {
  fields: [
    { key: 'harvestWeight',    label: 'Khối lượng thu hoạch',  type: 'number', unit: 'kg' },
    { key: 'qualityGrade',     label: 'Phân loại chất lượng',  type: 'select',
      options: ['Loại A', 'Loại B', 'Loại C', 'Không phân loại'] },
    { key: 'plantCount',       label: 'Số cây thu hoạch',      type: 'number', unit: 'cây' },
    { key: 'averagePerPlant',  label: 'Trung bình/cây',        type: 'number', unit: 'kg' },
    { key: 'moistureContent',  label: 'Độ ẩm',                type: 'number', unit: '%' }
  ]
}

Other = { fields: [] }
```

### 3.2 Dynamic Form (Form đo lường - Observation/Measurement)

**Cơ chế:**
1. Khi mở task loại `Observation` / `Measurement`, fetch:
   - `GET /api/experiments/{expId}/measurements` → trả về definitions của **TẤT CẢ nhóm**
   - `GET /api/batches/{batchId}` → lấy `groupId` của batch đang làm task
2. Lọc definitions chỉ giữ `d.groupId === batchGroupId`
3. Mỗi definition → 1 field trong form, key là `def_<definitionId>`

**Render field:**
```
┌────────────────────────────────────────────────┐
│ 📏 Chiều cao cây  📦 Phân NPK  🎯 25 cm       │ ← header
│ Mô tả: Chiều cao trung bình cây sau 30 ngày    │
│ ┌─────────────────────┐    ✅ (đạt target)      │
│ │ 18              cm  │                        │
│ └─────────────────────┘                        │
└────────────────────────────────────────────────┘
```

- Hiển thị `targetValue` (mục tiêu) cùng `unit` để user biết cần đo tới đâu
- Icon trạng thái realtime:
  - ✅ đạt target (`num >= target`)
  - ⚡ gần target (`num >= target * 0.8 && num < target`)
  - ⚠️ chưa đạt (`num < target * 0.8`)
- Validate local realtime (xem mục 6)

### 3.3 Custom Fields (User tự thêm)

User (Student/Tech) có thể bấm **"+ Thêm cột"** để tự thêm key-value bất kỳ (vd: `tenCongCu = "Cào"`). Các key custom có prefix `custom_N` và không qua bridge → không tạo MeasurementRecord.

---

## 4. Bridge Logic - Tự động tạo MeasurementRecord

### 4.1 Phân loại branch

```javascript
const isMeasurementTask = task?.taskType === 'Measurement' || task?.taskType === 'Observation';

if (isMeasurementTask) {
  // ⭐ Bulk path: 1 request tạo nhiều record
  bulkItems = extractBulkItemsFromResultData(resultData, effectiveDefinitions);
  result   = await createMeasurementsBulk(task, bulkItems, meta, bulkApi);
} else {
  // Legacy path: gọi POST /measurement-records từng cái
  defByName = new Map(effectiveDefinitions.map(d => [d.metricName, d]));
  payloads  = buildMeasurementPayloads(task, extractMeasurementsFromReport(dataObj), meta, defByName);
  result    = await createMeasurementsFromTaskReport(payloads, measurementRecordsApi);
}
```

### 4.2 `extractBulkItemsFromResultData(resultData, definitions)`

Chuyển `resultData` dạng `[{ key: "def_<uuid>", value: "18" }, ...]` thành `items[]` cho bulk API:

```javascript
function extractBulkItemsFromResultData(resultData, definitions) {
  const defsById = Object.fromEntries(definitions.map(d => [d.id, d]));
  const items = [];
  for (const r of resultData) {
    if (!r.key?.startsWith('def_')) continue;
    const definitionId = r.key.slice(4);
    if (!definitionId) continue;
    if (r.value === '' || r.value == null) continue;

    const def = defsById[definitionId];
    const item = { definitionId, value: r.value };
    if (def) {
      item.metricName = def.metricName;
      item.unit       = def.unit;
      if (def.targetValue != null) item.targetValue = def.targetValue;
    }
    items.push(item);
  }
  return items;
}
```

**Output:**
```javascript
[
  { definitionId: 'uuid-1', value: '18',   metricName: 'Chiều cao cây',  unit: 'cm', targetValue: 25 },
  { definitionId: 'uuid-2', value: '85',   metricName: 'Độ ẩm đất',     unit: '%',  targetValue: 80 }
]
```

### 4.3 `createMeasurementsBulk(task, items, extraMeta, bulkApi)`

```javascript
async function createMeasurementsBulk(task, items, extraMeta, bulkApi) {
  const experimentId = task?.experimentId || task?.experiment?.id;
  const stageId      = task?.stageId || task?.experimentStageId || task?.stage?.id;
  const batchId      = task?.batchId || task?.batch?.id;

  if (!experimentId || !batchId) {
    return { created: 0, skipped: items.length, warnings: ['Thiếu exp/batchId'], records: [] };
  }

  const payload = {
    experimentId,
    experimentStageId: stageId || null,
    batchId,
    measuredAt: extraMeta?.measuredAt || new Date().toISOString(),
    extraData: extraMeta?.notes ? { note: extraMeta.notes } : null,
    items: items
      .filter(i => i.definitionId && i.value !== '' && i.value != null)
      .map(i => {
        const v = typeof i.value === 'string' ? parseFloat(i.value) : i.value;
        const item = { measurementDefinitionId: i.definitionId, value: isNaN(v) ? 0 : v };
        if (i.metricName)   item.metricName   = i.metricName;
        if (i.unit)         item.unit         = i.unit;
        if (i.targetValue != null) item.targetValue = i.targetValue;
        return item;
      })
  };

  if (payload.items.length === 0) return { created: 0, skipped: 0, warnings: [], records: [] };

  try {
    const res   = await bulkApi(payload);
    const data  = res?.data || res;
    return {
      created:  data?.created ?? payload.items.length,
      skipped:  data?.skipped ?? 0,
      warnings: data?.warnings || [],
      records:  data?.records  || []
    };
  } catch (err) {
    return { created: 0, skipped: payload.items.length, warnings: [err.message], records: [] };
  }
}
```

### 4.4 `MEASUREMENT_FIELD_MAP` - Bảng mapping cho legacy path

```javascript
export const MEASUREMENT_FIELD_MAP = {
  // Plant metrics
  plantHeight:       { targetName: 'height',         targetUnit: 'cm',     description: 'Chiều cao cây' },
  chieuCaoCm:        { targetName: 'height',         targetUnit: 'cm',     description: 'Chiều cao cây' },
  leafCount:         { targetName: 'leafCount',      targetUnit: 'lá',     description: 'Số lá trung bình' },
  soLaTrungBinh:     { targetName: 'leafCount',      targetUnit: 'lá',     description: 'Số lá trung bình' },
  tocDoSinhTruong:   { targetName: 'growthRate',     targetUnit: 'cm/ngày',description: 'Tốc độ sinh trưởng' },
  tiLeSong:          { targetName: 'survivalRate',   targetUnit: '%',      description: 'Tỷ lệ sống' },
  tiLeDauQua:        { targetName: 'fruitingRate',   targetUnit: '%',      description: 'Tỷ lệ đậu quả' },

  // Watering
  waterAmount:          { targetName: 'waterAmount',       targetUnit: 'L/m²', description: 'Lượng nước tưới' },
  luongNuocTong:        { targetName: 'totalWater',        targetUnit: 'lít',  description: 'Tổng lượng nước' },
  soLanTuoi:            { targetName: 'wateringCount',     targetUnit: 'lần',  description: 'Số lần tưới' },
  duration:             { targetName: 'wateringDuration',  targetUnit: 'phút', description: 'Thời gian tưới' },
  soilMoistureBefore:   { targetName: 'soilMoistureBefore',targetUnit: '%',    description: 'Độ ẩm đất trước tưới' },
  soilMoistureAfter:    { targetName: 'soilMoistureAfter', targetUnit: '%',    description: 'Độ ẩm đất sau tưới' },

  // Fertilizing
  fertilizerAmount:  { targetName: 'fertilizerAmount',  targetUnit: 'g/cây', description: 'Liều lượng phân bón' },
  soLanBonPhan:      { targetName: 'fertilizingCount', targetUnit: 'lần',    description: 'Số lần bón phân' },
  soLanPhunThuoc:    { targetName: 'pesticideCount',   targetUnit: 'lần',    description: 'Số lần phun thuốc BVTV' },

  // Planting
  plantCount:    { targetName: 'plantCount',   targetUnit: 'cây', description: 'Số cây trồng/thu hoạch' },
  plantSpacing:  { targetName: 'plantSpacing', targetUnit: 'cm',  description: 'Khoảng cách cây' },
  soLuong:       { targetName: 'plantCount',   targetUnit: 'cây', description: 'Số lượng' },

  // Inspection
  affectedPlantCount: { targetName: 'affectedPlantCount', targetUnit: 'cây', description: 'Số cây bị ảnh hưởng' },
  tyLeHaoHut:         { targetName: 'lossRate',           targetUnit: '%',   description: 'Tỷ lệ hao hụt' },

  // Harvest
  harvestWeight:  { targetName: 'weight',         targetUnit: 'kg',     description: 'Khối lượng thu hoạch' },
  sanLuongKg:     { targetName: 'weight',         targetUnit: 'kg',     description: 'Sản lượng (kg)' },
  sanLuongTan:    { targetName: 'weightTon',      targetUnit: 'tấn',    description: 'Sản lượng (tấn)' },
  averagePerPlant:{ targetName: 'yieldPerPlant',  targetUnit: 'kg/cây', description: 'Trung bình/cây' },
  moistureContent:{ targetName: 'moistureContent',targetUnit: '%',      description: 'Độ ẩm sản phẩm' },

  // PostHarvest
  khoiLuongBaoQuan: { targetName: 'storageWeight', targetUnit: 'kg',  description: 'Khối lượng bảo quản' },
  nhietDoBaoQuan:   { targetName: 'storageTemp',   targetUnit: '°C',  description: 'Nhiệt độ bảo quản' }
};
```

### 4.5 `extractMeasurementsFromReport(resultData)`

Lấy tất cả key trong `resultData` có trong `MEASUREMENT_FIELD_MAP`:

```javascript
function extractMeasurementsFromReport(resultData = {}) {
  const measurements = [];
  for (const [key, value] of Object.entries(resultData)) {
    const mapping = MEASUREMENT_FIELD_MAP[key];
    if (!mapping) continue;
    if (value === '' || value == null) continue;

    let numericValue = value;
    if (typeof value === 'string') {
      const parsed = parseFloat(value);
      if (!isNaN(parsed)) numericValue = parsed;
    }
    measurements.push({
      name: mapping.targetName,
      value: numericValue,
      unit: mapping.targetUnit,
      description: mapping.description,
      sourceKey: key
    });
  }
  return measurements;
}
```

### 4.6 `buildMeasurementPayloads(task, measurements, extraMeta, definitionLookup)`

Build payload cho legacy POST từng cái:

```javascript
function buildMeasurementPayloads(task, measurements, extraMeta = {}, definitionLookup = null) {
  if (!measurements?.length) return [];
  const experimentId = task?.experimentId || task?.experiment?.id;
  const stageId      = task?.stageId || task?.experimentStageId || task?.stage?.id;
  const batchId      = task?.batchId || task?.batch?.id;
  if (!experimentId) {
    console.warn('[bridge] thiếu experimentId');
    return [];
  }

  const measuredAt = extraMeta.measuredAt || extraMeta.performedAt || new Date().toISOString();

  return measurements.map(m => {
    let measurementDefinitionId = null;
    if (definitionLookup instanceof Map) {
      const def = definitionLookup.get(m.name) || definitionLookup.get(m.metricName);
      if (def?.id) measurementDefinitionId = def.id;
    }

    const payload = {
      experimentId,
      experimentStageId: stageId || null,
      batchId: batchId || null,
      taskId: task.id || task?.taskId || null,
      value: typeof m.value === 'number' ? m.value : parseFloat(m.value) || 0,
      measuredAt
    };

    if (measurementDefinitionId) {
      payload.measurementDefinitionId = measurementDefinitionId;
    } else {
      payload.metricName = m.name; // fallback cho BE lookup
    }

    if (extraMeta.notes) payload.extraData = { note: extraMeta.notes, sourceKey: m.sourceKey };
    return payload;
  });
}
```

### 4.7 `createMeasurementsFromTaskReport(payloads, api)` - Gọi song song

```javascript
async function createMeasurementsFromTaskReport(payloads, measurementApi) {
  if (!payloads?.length) return { success: 0, failed: 0, errors: [], measurements: [] };

  const results = await Promise.allSettled(
    payloads.map(p => measurementApi.create(p))
  );

  const success = [], errors = [];
  results.forEach((r, idx) => {
    if (r.status === 'fulfilled') success.push(r.value);
    else errors.push({ payload: payloads[idx], error: r.reason?.message || String(r.reason) });
  });

  return { success: success.length, failed: errors.length, errors, measurements: success };
}
```

**Lưu ý:** Dùng `Promise.allSettled` để **không fail cả batch** nếu 1 record lỗi.

---

## 5. Filter MeasurementDefinition theo Group (⭐ Logic lõi)

### 5.1 Vấn đề

API `/api/experiments/{expId}/measurements` trả về definitions của **TẤT CẢ các nhóm** trong experiment (Control, Phân hữu cơ, Phân NPK...). Mỗi nhóm có **cùng tập metricName** nhưng `groupId` và `targetValue` khác nhau.

Ví dụ:
```json
[
  { id: 'd1', groupId: 'g-control',  groupName: 'Đối chứng',   metricName: 'Chiều cao', unit: 'cm', targetValue: 15 },
  { id: 'd2', groupId: 'g-organic',  groupName: 'Phân hữu cơ', metricName: 'Chiều cao', unit: 'cm', targetValue: 20 },
  { id: 'd3', groupId: 'g-npk',      groupName: 'Phân NPK',    metricName: 'Chiều cao', unit: 'cm', targetValue: 25 },
  { id: 'd4', groupId: 'g-control',  groupName: 'Đối chứng',   metricName: 'Số lá',     unit: 'lá', targetValue: 5 },
  { id: 'd5', groupId: 'g-organic',  groupName: 'Phân hữu cơ', metricName: 'Số lá',     unit: 'lá', targetValue: 6 },
  { id: 'd6', groupId: 'g-npk',      groupName: 'Phân NPK',    metricName: 'Số lá',     unit: 'lá', targetValue: 8 }
]
```

Nếu task thuộc batch nhóm `Phân NPK`, form phải chỉ hiển thị `d3` + `d6` (kèm target 25cm & 8 lá) — KHÔNG phải `d1+d2+d3+d4+d5+d6`.

### 5.2 `filterDefinitionsByTaskGroup(definitions, task, explicitGroupId)`

```javascript
function filterDefinitionsByTaskGroup(definitions, task, explicitGroupId) {
  if (!Array.isArray(definitions) || definitions.length === 0) return [];

  // Ưu tiên groupId theo thứ tự
  const taskGroupId =
    explicitGroupId ||                            // 1. fetch trực tiếp từ batch API ⭐
    task?.batch?.groupId ||                       // 2. BE populate batch vào task
    task?.batchGroupId ||                         // 3. fallback flat field
    task?.groupId;

  if (taskGroupId) {
    const sameGroup = definitions.filter(d => d.groupId === taskGroupId);
    if (sameGroup.length > 0) return sameGroup;
  }

  // Fallback: dedupe theo metricName (giữ bản ghi đầu tiên)
  const seen = new Set();
  const deduped = [];
  for (const d of definitions) {
    const key = (d.metricName || '').trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    deduped.push(d);
  }
  return deduped;
}
```

### 5.3 `fetchBatchGroupInfo(batchId)`

```javascript
async function fetchBatchGroupInfo(batchId) {
  if (!batchId) return null;
  try {
    const b = await batchesApi.getById(batchId);
    if (!b) return null;
    return {
      groupId:    b.groupId || null,
      groupName:  b.groupName || '',
      batchCode:  b.batchCode || '',
      ...b
    };
  } catch {
    return null;
  }
}
```

### 5.4 Luồng áp dụng trong TaskDetailModal

```
1. task = getById(taskId)         → task.batch có thể không populate groupId
2. definitions = getByExperiment(expId)  → tất cả definitions
3. batch = getById(batchId)       → ⭐ chắc chắn có groupId
4. effectiveDefinitions = filterDefinitionsByTaskGroup(definitions, task, batch.groupId)
5. Render form với effectiveDefinitions
6. Khi submit:
   - Bulk path: extractBulkItemsFromResultData(resultData, effectiveDefinitions)
   - Legacy path: buildMeasurementPayloads(task, extract, ..., Map<name,def>)
```

---

## 6. Local Validation cho Dynamic Field

### 6.1 `localValidateValue(definition, value)`

```javascript
function localValidateValue(definition, value) {
  if (value === '' || value == null) return null; // trống OK ở step này
  const num   = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num))  return 'Giá trị phải là số';
  if (num < 0)     return 'Giá trị không được âm';

  const unit   = (definition?.unit || '').trim();
  const name   = (definition?.metricName || '').toLowerCase();
  const target = parseFloat(definition?.targetValue);

  // Phần trăm 0–100
  if (unit === '%' && num > 100) {
    return `Giá trị ${definition.metricName} là phần trăm nên phải nằm trong [0, 100].`;
  }
  // Thang điểm màu sắc 1–5
  if (name.includes('màu sắc') && (num < 1 || num > 5)) {
    return `${definition.metricName} theo thang điểm 1–5, giá trị ${num} không hợp lệ.`;
  }
  // Sanity target * 5
  if (!isNaN(target) && target > 0 && num > target * 5) {
    return `Giá trị ${definition.metricName} vượt quá 5 lần target ${target}.`;
  }
  return null;
}
```

### 6.2 `getValueStatus(definition, value)` - Phân loại

```javascript
function getValueStatus(definition, value) {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num) || value === '' || value == null) return 'unknown';
  const target = parseFloat(definition?.targetValue);
  if (isNaN(target)) return 'ok';
  if (num >= target)         return 'exceeded';  // ✅
  if (num >= target * 0.8)   return 'close';     // ⚡
  return 'below';                                    // ⚠️
}
```

---

## 7. Luồng Submit Báo Cáo (Chi tiết)

### 7.1 Sequence Diagram

```
┌────────┐    ┌──────────┐    ┌──────────────┐    ┌──────────────┐
│ Client │    │ BE Tasks │    │ BE Reports   │    │ BE Measure  │
└───┬────┘    └────┬─────┘    └──────┬───────┘    └──────┬───────┘
    │              │                │                   │
    │ POST /task-reports                                 │
    │ {taskId, reportText, resultData}                   │
    ├──────────────┼─────────────────►                   │
    │              │                │                    │
    │              │   ◄───── {id} ──┤                    │
    │ reportId     │                │                    │
    │              │                │                    │
    │ (Nếu Measurement/Observation)                      │
    │ POST /measurement-records/bulk                     │
    │ {experimentId, batchId, measuredAt, items[]}       │
    ├──────────────┼─────────────────┼──────────────────►
    │              │                │                    │
    │              │   ◄── {created, skipped, records} ──┤
    │              │                │                    │
    │ (Nếu có ảnh) │                │                    │
    │ POST /task-images/upload (multipart)               │
    │ {File, experimentId, batchId, taskReportId}        │
    ├──────────────┼─────────────────┼──────────────────►
    │              │                │                    │
    │              │   ◄── {id, imageUrl} ────────────────┤
    │              │                │                    │
    │ (Nếu bấm "Hoàn thành")                             │
    │ PATCH /tasks/{id}/complete                         │
    ├──────────────►                │                    │
    │              │                │                    │
```

### 7.2 Code mẫu (mobil-style)

```javascript
async function handleSubmitReport(task, payload) {
  // payload = { reportText, resultData: [{key, value}], images: [...] }

  // STEP 1: Tạo TaskReport
  const dataObj = {};
  payload.resultData.forEach(r => {
    if (r.key?.trim()) dataObj[r.key.trim()] = r.value;
  });

  const reportRes = await api.post('/task-reports', {
    taskId: task.id,
    reportText: payload.reportText,
    resultData: dataObj
  });
  const reportId = reportRes.data.id;

  // STEP 2: Lấy groupId từ batch
  let batchGroupId = null;
  const batchId = task.batchId || task.batch?.id;
  if (batchId) {
    try {
      const b = await api.get(`/batches/${batchId}`);
      batchGroupId = b.data.groupId;
    } catch {}
  }

  // STEP 3: Lấy definitions & filter theo group
  let definitions = [];
  if (task.experimentId) {
    try {
      const d = await api.get(`/experiments/${task.experimentId}/measurements`);
      definitions = Array.isArray(d.data) ? d.data : [];
    } catch {}
  }

  const effectiveDefinitions = filterDefinitionsByTaskGroup(definitions, task, batchGroupId);

  // STEP 4: Tạo MeasurementRecord
  const isMeasurementTask = task.taskType === 'Measurement' || task.taskType === 'Observation';

  if (isMeasurementTask) {
    const bulkItems = extractBulkItemsFromResultData(payload.resultData, effectiveDefinitions);
    const bulkResult = await createMeasurementsBulk(task, bulkItems, {
      measuredAt: new Date().toISOString(),
      notes: `Tự động từ TaskReport #${reportId}`
    }, (p) => api.post('/measurement-records/bulk', p).then(r => r.data));
  } else {
    const defByName = new Map(effectiveDefinitions.map(d => [d.metricName, d]));
    const measurements = extractMeasurementsFromReport(dataObj);
    const payloads = buildMeasurementPayloads(task, measurements, {
      measuredAt: new Date().toISOString(),
      notes: `Tự động từ TaskReport #${reportId}`
    }, defByName);
    const result = await createMeasurementsFromTaskReport(payloads, {
      create: (p) => api.post('/measurement-records', p).then(r => r.data)
    });
  }

  // STEP 5: Upload ảnh (nếu có)
  if (payload.images?.length) {
    await Promise.allSettled(
      payload.images.map(img => {
        const formData = new FormData();
        formData.append('File', img.file);
        formData.append('experimentId', task.experimentId || task.experiment?.id);
        formData.append('batchId', task.batchId || task.batch?.id);
        formData.append('taskReportId', reportId);
        formData.append('taskId', task.id);
        if (img.caption)    formData.append('caption', img.caption);
        formData.append('capturedAt', img.uploadedAt || new Date().toISOString());
        return api.post('/task-images/upload', formData, { headers: { 'Content-Type': 'multipart/form-data' } });
      })
    );
  }

  return { reportId };
}
```

---

## 8. Luồng Hoàn Thành Task

### 8.1 Business Rule

- **Bắt buộc:** Phải có ít nhất 1 trong 3:
  - Có nội dung báo cáo mới (`reportText.trim().length > 0`)
  - Có ảnh mới (`reportImages.length > 0`)
  - Có lịch sử báo cáo (`reports.length > 0`)
- Sau khi submit đủ 1 trong 3 → gọi `PATCH /tasks/{id}/complete`

### 8.2 Flow chi tiết

```
┌─────────────────────────────────────────────┐
│ Step 1: Submit Report (giống mục 7)         │
│ - Chỉ chạy nếu có nội dung mới             │
├─────────────────────────────────────────────┤
│ Step 2: Bridge tạo Measurement             │
│ - Chỉ chạy nếu có dataObj có nội dung      │
├─────────────────────────────────────────────┤
│ Step 3: Upload ảnh                          │
│ - Anchor với reportId mới hoặc report cũ   │
│ - Nếu không có report mới → dùng report cuối│
├─────────────────────────────────────────────┤
│ Step 4: PATCH /tasks/{id}/complete          │
└─────────────────────────────────────────────┘
```

### 8.3 Code mẫu

```javascript
async function handleCompleteTask(task, payload) {
  const hasNewContent  = payload.reportText?.trim().length > 0;
  const hasNewImages   = payload.images?.length > 0;

  // Lấy lịch sử report (cần thiết nếu không có content mới)
  let reports = [];
  try {
    const res = await api.get(`/task-reports/task/${task.id}`);
    reports = Array.isArray(res.data) ? res.data : [];
  } catch {}
  const hasReportHistory = reports.length > 0;

  if (!hasNewContent && !hasNewImages && !hasReportHistory) {
    throw new Error('Vui lòng nhập nội dung báo cáo hoặc đính kèm ảnh trước.');
  }

  let reportId;
  let dataObj = {};

  if (hasNewContent) {
    dataObj = {};
    payload.resultData.forEach(r => {
      if (r.key?.trim()) dataObj[r.key.trim()] = r.value;
    });
    const reportRes = await api.post('/task-reports', {
      taskId: task.id,
      reportText: payload.reportText,
      resultData: dataObj
    });
    reportId = reportRes.data.id;
  } else if (hasReportHistory) {
    reportId = reports[reports.length - 1].id; // anchor ảnh mới vào report cũ
  }

  if (hasNewContent && Object.keys(dataObj).length > 0) {
    // ... bridge tạo Measurement (giống mục 7.2 STEP 2-4)
  }

  if (hasNewImages && reportId) {
    await Promise.allSettled(
      payload.images.map(img => uploadImage(img, { reportId, task }))
    );
  }

  await api.patch(`/tasks/${task.id}/complete`);
}
```

---

## 9. Toast Notification

Sau khi submit thành công, thông báo dạng:

```
✅ Đã hoàn thành tác vụ (báo cáo mới)! 📊 5 chỉ số · 📷 3 ảnh
✅ Đã hoàn thành tác vụ (bổ sung ảnh)! 📷 2 ảnh
✅ Đã hoàn thành tác vụ dựa trên lịch sử!
✅ Đã gửi báo cáo! 📊 4 chỉ số · 📷 2 ảnh
```

Thành phần:
- **Mode label:** `báo cáo mới` / `bổ sung ảnh` / `lịch sử`
- **Measurement counts:** `📊 N chỉ số` (cho legacy) hoặc `📊 N chỉ số · ⚠️ M bỏ qua` (cho bulk)
- **Image counts:** `📷 N ảnh`

---

## 10. Upload ảnh - ImageUploader

### 10.1 Props

```javascript
<ImageUploader
  value={images}                  // controlled: [{file, previewUrl, caption, fileName, fileSize, imageId?, url?}]
  onChange={setImages}
  experimentId={task?.experimentId}
  batchId={task?.batchId}
  taskId={task?.id}
  disabled={false}
/>
```

### 10.2 Mỗi item trong `images[]`

```typescript
interface ImageItem {
  file?: File;            // File binary mới chọn (multipart)
  previewUrl?: string;    // preview local (URL.createObjectURL)
  caption?: string;
  fileName?: string;
  fileSize?: number;
  imageId?: string;       // Cloudinary URL nếu đã upload trước
  url?: string;           // ⭐ Cloudinary URL (nếu đã upload thành công)
  uploadedAt?: string;    // ISO 8601 (nếu đã upload)
}
```

### 10.3 Logic submit

```javascript
images.map(img => {
  if (img.file) {
    // Có file local → multipart
    return taskImagesApi.upload({
      file: img.file,
      imageUrl: img.url,                          // optional
      caption: img.caption || '',
      capturedAt: img.uploadedAt || new Date().toISOString(),
      experimentId, batchId, taskReportId, taskId
    });
  }
  // Không có file → JSON với imageUrl
  return taskImagesApi.create({
    taskReportId: reportId,
    taskId, experimentId, batchId,
    imageUrl: img.url,
    caption: img.caption || '',
    capturedAt: img.uploadedAt || new Date().toISOString()
  });
});
```

---

## 11. Edge Cases & Business Rules

### 11.1 Xử lý khi task không có `batchId`

- Vẫn cho phép tạo TaskReport (vì report chỉ cần `taskId + reportText + resultData`)
- Bridge `MeasurementRecord` sẽ skip nếu thiếu `batchId`/`experimentId`
- UI form: ẩn phần "đang lấy nhóm" / dedupe theo metricName

### 11.2 Network error khi fetch batch

- `batchesApi.getById()` fail → `batchGroupId = null`
- Fallback thứ tự ưu tiên:
  1. `batchGroupId` (fetch)
  2. `task.batch.groupId` (BE populate)
  3. `task.batchGroupId` (flat)
  4. `task.groupId` (flat)
  5. Dedupe theo metricName

### 11.3 Definitions rỗng cho measurement task

```javascript
if (definitions.length === 0) {
  // Hiện: "⚠️ Experiment này chưa có MeasurementDefinition. Liên hệ Researcher để tạo trước."
}
```

### 11.4 Definitions có nhiều nhóm, không trùng groupId

```javascript
if (filteredDefinitions.length === 0 && definitions.length > 0) {
  // Hiện: "⚠️ Không tìm thấy MeasurementDefinition phù hợp với nhóm của task này."
}
```

### 11.5 Concurrent submit

- Disable nút submit trong khi đang gửi (`saving=true`)
- Dùng `Promise.allSettled` cho measurement + image (không fail cả batch)

### 11.6 Custom field trùng key

- Bắt đầu từ `custom_1`, tăng dần `custom_2`... cho tới khi không trùng
- Không xung đột với key schema

### 11.7 Submit report rỗng

```javascript
if (!reportText.trim()) {
  showToast('Vui lòng nhập nội dung báo cáo', 'error');
  return;
}
```

---

## 12. State Management cho Mobile

### 12.1 Đề xuất structure

```
mobile_app/
├── api/
│   ├── client.ts             ← base apiClient + interceptor
│   ├── tasksApi.ts
│   ├── taskReportsApi.ts
│   ├── measurementRecordsApi.ts
│   ├── measurementDefinitionsApi.ts
│   ├── batchesApi.ts
│   └── taskImagesApi.ts
├── utils/
│   ├── measurementBridge.ts  ← port y hệt JS version
│   ├── measurement.ts        ← port y hệt
│   └── types.ts              ← TypeScript interfaces
├── screens/                  (React Native / Flutter)
│   ├── TaskListScreen.tsx
│   ├── TaskDetailScreen.tsx
│   ├── TaskReportScreen.tsx
│   └── CompleteTaskScreen.tsx
├── components/
│   ├── QuickFormField.tsx
│   ├── DynamicField.tsx
│   ├── CustomColumn.tsx
│   └── ImagePicker.tsx
└── hooks/
    ├── useTaskReport.ts      ← state + submit logic
    ├── useBatchGroupId.ts    ← hook fetch batch
    └── useTaskDefinitions.ts ← hook fetch definitions
```

### 12.2 Hook `useBatchGroupId(task)`

```typescript
function useBatchGroupId(task: Task): { groupId: string | null, groupName: string, loading: boolean } {
  const [groupId, setGroupId] = useState<string | null>(null);
  const [groupName, setGroupName] = useState('');
  const [loading, setLoading] = useState(false);

  const batchId = task?.batchId || task?.batch?.id;

  useEffect(() => {
    if (!batchId) { setGroupId(null); setGroupName(''); return; }
    let cancelled = false;
    setLoading(true);
    batchesApi.getById(batchId)
      .then(b => {
        if (!cancelled) {
          setGroupId(b?.groupId || null);
          setGroupName(b?.groupName || '');
        }
      })
      .catch(() => { if (!cancelled) { setGroupId(null); setGroupName(''); } })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [batchId]);

  return { groupId, groupName, loading };
}
```

### 12.3 Hook `useTaskDefinitions(experimentId)`

```typescript
function useTaskDefinitions(experimentId: string | undefined) {
  const [definitions, setDefinitions] = useState<MeasurementDefinition[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!experimentId) return;
    let cancelled = false;
    setLoading(true);
    measurementDefinitionsApi.getByExperiment(experimentId)
      .then(d => { if (!cancelled) setDefinitions(Array.isArray(d) ? d : []); })
      .catch(() => { if (!cancelled) setDefinitions([]); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [experimentId]);

  return { definitions, loading };
}
```

---

## 13. TypeScript Interfaces

```typescript
// Types cần cho mobile
interface Task {
  id: string;
  taskType: 'Planting' | 'Watering' | 'Fertilizing' | 'Inspection'
            | 'Harvest' | 'Observation' | 'Measurement' | 'Other';
  status: 'Pending' | 'InProgress' | 'Completed' | 'Cancelled' | 'Overdue';
  experimentId: string;
  experimentStageId?: string;
  batchId?: string;
  batch?: {
    id: string;
    batchCode: string;
    groupId?: string;
    groupName?: string;
  };
  title?: string;
  dueDate?: string;
}

interface Batch {
  id: string;
  batchCode: string;
  experimentId: string;
  groupId: string;
  groupName: string;
}

interface MeasurementDefinition {
  id: string;
  experimentId: string;
  groupId: string;
  groupName: string;
  metricName: string;
  unit: string;
  targetValue: number;
  description?: string;
}

interface ResultEntry { key: string; value: string | number; }
interface ImageItem {
  file?: any;
  previewUrl?: string;
  caption?: string;
  fileName?: string;
  fileSize?: number;
  url?: string;
  uploadedAt?: string;
}

interface SubmitPayload {
  reportText: string;
  resultData: ResultEntry[];
  images: ImageItem[];
}
```

---

## 14. Checklist Implement cho Mobile

### Core
- [ ] `filterDefinitionsByTaskGroup(definitions, task, explicitGroupId)`
- [ ] `fetchBatchGroupInfo(batchId)` → batch.groupId
- [ ] `extractBulkItemsFromResultData(resultData, definitions)`
- [ ] `extractMeasurementsFromReport(resultData)` (theo `MEASUREMENT_FIELD_MAP`)
- [ ] `buildMeasurementPayloads(task, measurements, meta, lookup)`
- [ ] `createMeasurementsBulk(task, items, meta, api)`
- [ ] `createMeasurementsFromTaskReport(payloads, api)`
- [ ] `localValidateValue(definition, value)`
- [ ] `getValueStatus(definition, value)`

### UI (Render)
- [ ] QUICK_FORM_SCHEMA cho 6 loại hardcode
- [ ] Dynamic form cho Measurement/Observation (lấy `def_<uuid>` keys)
- [ ] Hiển thị `targetValue` + `unit` + status icon (✅⚡⚠️)
- [ ] Custom columns (+ Thêm cột)
- [ ] ImagePicker đa ảnh

### API calls
- [ ] `POST /task-reports`
- [ ] `POST /measurement-records/bulk`
- [ ] `POST /measurement-records` (legacy, từng cái)
- [ ] `POST /task-images/upload` (multipart)
- [ ] `POST /task-images` (JSON)
- [ ] `PATCH /tasks/{id}/complete`
- [ ] `GET /batches/{batchId}` (⭐ filter group)
- [ ] `GET /experiments/{expId}/measurements`

### States
- [ ] `resultData: [{key, value}]`
- [ ] `reportText: string`
- [ ] `images: ImageItem[]`
- [ ] `saving: boolean`
- [ ] `batchGroupId` (từ hook)
- [ ] `definitions` (từ hook)
- [ ] `taskGroupId` (computed: ưu tiên `batchGroupId` > `task.batch.groupId` > ...)

### Flow
- [ ] handleSubmitReport() - mục 7.2
- [ ] handleCompleteTask() - mục 8.3
- [ ] Toast notifications
- [ ] Validation (client + server)

### Business rules
- [ ] Phải có `reportText.trim()` hoặc ảnh hoặc lịch sử report
- [ ] Bulk path chỉ dùng cho Measurement/Observation
- [ ] Legacy path cho các task khác
- [ ] Dedupe metricName nếu không có groupId
- [ ] `Promise.allSettled` cho batch operations
- [ ] Hiện toast count: `📊 N chỉ số · 📷 M ảnh`

---

## 15. Lưu ý quan trọng

1. **LUÔN fetch `GET /batches/{batchId}` trước khi render form đo lường** — để có groupId chính xác. Không chỉ dựa vào `task.batch.groupId` vì BE có thể không populate.

2. **Cùng `measuredAt` cho tất cả records trong 1 bulk request** — đây là design để thống kê theo thời gian chính xác (1 lần đo của batch tạo N records, không phải N lần đo).

3. **Bulk payload có `metricName`/`unit`/`targetValue` inline** — tránh BE phải lookup lại qua DB (tiết kiệm query, giảm latency).

4. **Custom fields (`custom_N`) KHÔNG qua bridge** — chỉ lưu trong `resultData` của TaskReport, không tạo MeasurementRecord.

5. **Khi `definitions` không có item nào trùng `groupId`**: ưu tiên hiển thị cảnh báo cho user. Không tự ý dedupe vì có thể gây nhầm với nhóm khác.

6. **Khi `measuredAt` không truyền vào**: BE sẽ dùng `now()` (server time). Nên FE nên truyền ISO string để đồng bộ.

7. **Khi `experimentStageId` không có** (task không thuộc stage nào): vẫn gửi `null`, BE sẽ tự xử lý.

8. **Field key `def_<uuid>` chỉ dành cho Measurement task** — Planting/Watering/... dùng key flat (`plantCount`, `waterAmount`...).

---

## 16. Tham khảo

| File | Vai trò |
|------|---------|
| `src/components/tasks/TaskReportForm.jsx` | Form rendering + QUICK_FORM_SCHEMA + dynamic field |
| `src/utils/measurementBridge.js` | `extractMeasurementsFromReport`, `buildMeasurementPayloads`, `createMeasurementsBulk`, `extractBulkItemsFromResultData`, `filterDefinitionsByTaskGroup`, `fetchBatchGroupInfo`, `MEASUREMENT_FIELD_MAP` |
| `src/utils/measurement.js` | `localValidateValue`, `getValueStatus`, `buildBulkItems`, format helpers |
| `src/api/sharedTaskApi.js` | `tasksApi`, `taskReportsApi`, `measurementRecordsApi`, `taskImagesApi` |
| `src/api/experimentApi.js` | `batchesApi`, `measurementDefinitionsApi`, `tasksApi` (alt) |
| `src/pages/technician/TechnicianDashboard.jsx` | `handleSubmitReport`, `handleCompleteTask` (Tech) |
| `src/pages/student/StudentDashboard.jsx` | `handleSubmitReport` (Student) |
| `src/pages/PersonalTaskList.jsx` | `handleSubmitComplete` (cả Student/Tech — luồng mobile-like đơn giản nhất) |

Phiên bản: MeasurementStatistics v1.0
Cập nhật: Aug 14, 2026
