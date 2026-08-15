# 📱 Tổng Hợp Logic Mobile — Luồng Student / Technician

**Phạm vi:** Frontend (React + Vite) — dành cho 2 portal **Student Portal** và **Technician Portal**.
**Các tính năng chính:** `Task` · `Task Report` · `Measurement Record` · `Notification realtime`.
**Mục tiêu tài liệu:** mô tả chi tiết logic đã xử lý trên FE để team BE/QA/BA tham chiếu, đồng thời là tài liệu bàn giao nội bộ.

---

## 1. Tổng quan kiến trúc

```
┌──────────────────────────────────────────────────────────┐
│  Student / Technician Portal (React SPA)                 │
│                                                          │
│  ┌──────────────────┐    ┌──────────────────────────┐     │
│  │ NotificationBell │◄──►│  notificationSocket.js   │◄────┼── WebSocket: wss://…/ws?token=JWT
│  └──────────────────┘    │  (singleton, reconnect)  │     │
│         │                └──────────────────────────┘     │
│         │ toast / badge / unread-count                   │
│         ▼                                                │
│  ┌────────────────────────────────────────────────┐      │
│  │ Dashboard (sidebar) → Tab Tasks / Reports /    │      │
│  │ Measurements                                     │      │
│  │   ├─ PersonalTaskList (shared)                   │      │
│  │   ├─ StudentDashboard / TechnicianDashboard     │      │
│  │   └─ TaskReportForm  → bulk Measurement bridge   │      │
│  └────────────────────────────────────────────────┘      │
│         │ REST (apiClient + JWT bearer)                  │
└─────────┼────────────────────────────────────────────────┘
          ▼
   Backend API + SignalR/WS Hub
```

### 1.1. Stack & quy ước
- **Routing:** dùng custom event `window.dispatchEvent(new Event('navigate'))` + `history.pushState` (không dùng React Router).
- **HTTP client:** `src/api/apiClient.js` — tự gắn `Authorization: Bearer <token>`, unwrap envelope (`{ success, data }`).
- **Token:** lưu `localStorage.token` (JWT) và `localStorage.user`.
- **Portal mount:** `<div class="fixed inset-0 z-[1000]">` — sidebar z-50, content z-1000, modal dùng `createPortal(..., document.body)`.

### 1.2. Hai portal chia sẻ logic
| File | Vai trò |
|---|---|
| `src/pages/PersonalTaskList.jsx` | Trang Task list độc lập (mobile-first), tự phát hiện role theo URL (`/student` hoặc `/technician`). |
| `src/pages/student/StudentDashboard.jsx` | Dashboard Student với 4 tab: Overview / Tasks / Reports / Morphology. |
| `src/pages/technician/TechnicianDashboard.jsx` | Dashboard Technician với 4 tab: Overview / Tasks / Reports / Measurements. |
| `src/components/tasks/TaskReportForm.jsx` | Form báo cáo dùng chung cho cả 2 role, render schema động theo `taskType`. |
| `src/components/tasks/ImageUploader.jsx` | Upload ảnh đính kèm (multipart, có preview, xoay, xoá). |
| `src/components/notifications/NotificationBell.jsx` | Chuông thông báo realtime + dropdown + toast. |
| `src/services/notificationSocket.js` | Singleton WebSocket client, tự reconnect. |
| `src/api/sharedTaskApi.js` | Tasks / TaskReports / MeasurementRecords / TaskImages (REST). |
| `src/utils/measurementBridge.js` | Cầu nối TaskReport ↔ MeasurementRecord + filter theo nhóm. |
| `src/utils/measurement.js` | Helper validate + format cho Measurement form. |

---

## 2. Luồng Task

### 2.1. Danh sách & bộ lọc
- 4 tab FE: **Tất cả** / **Hôm nay** / **Sắp tới (7 ngày)** / **Quá hạn**.
- Gọi REST tương ứng:

| Tab FE | API | Hàm |
|---|---|---|
| Tất cả | `GET /api/tasks/my` | `tasksApi.getMy()` |
| Hôm nay | `GET /api/tasks/today` | `tasksApi.getToday()` |
| Sắp tới | `GET /api/tasks/upcoming?days=7` | `tasksApi.getUpcoming(7)` |
| Quá hạn | `GET /api/tasks/overdue` | `tasksApi.getOverdue()` |
| Chi tiết | `GET /api/tasks/{id}` | `tasksApi.getById(id)` |
| Theo lô | `GET /api/tasks/batch/{batchId}` | `tasksApi.getByBatch(batchId)` |
| Theo stage | `GET /api/tasks/stage/{stageId}` | `tasksApi.getByStage(stageId)` |
| Theo experiment | `GET /api/tasks/experiment/{experimentId}` | `tasksApi.getByExperiment(experimentId)` |

### 2.2. Trạng thái & icon
| Status | Màu badge | Nhãn VI |
|---|---|---|
| `Pending` | blue-100 / blue-700 | "Chờ" |
| `InProgress` | amber-100 / amber-700 | "Đang làm" |
| `Completed` | emerald-100 / emerald-700 | "Hoàn thành" |
| `Overdue` | rose-100 / rose-700 | "Quá hạn" |
| `Cancelled` | slate-100 / slate-600 | "Đã huỷ" |

Icon theo `taskType`:
- 🌱 Planting · 💧 Watering · 🧪 Fertilizing · 👁️ Observation · 🔍 Inspection · 🌾 Harvest · 📋 Other · 📏 Measurement.

### 2.3. Vòng đời Task (state machine FE)

```text
        ┌──────────┐   start   ┌─────────────┐  submit report  ┌────────────┐
        │ Pending  │──────────►│ InProgress  │────────────────►│ Completed  │
        └──────────┘           └─────────────┘                 └────────────┘
            │                       │
            │ cancel                │ cancel
            ▼                       ▼
        ┌──────────────────────────────────────┐
        │              Cancelled               │
        └──────────────────────────────────────┘
            ▲
            │ server set (cronjob quét dueDate < now && !Completed)
       Overdue (chỉ hiển thị, do BE đặt)
```

### 2.4. Hành động Task
- **Bắt đầu:** `PATCH /api/tasks/{id}/start` → state chuyển `InProgress`. FE gọi lại `fetchTasks()` để đồng bộ badge.
- **Hoàn thành:** `PATCH /api/tasks/{id}/complete` — **BẮT BUỘC** sau khi đã POST task-report thành công (xem mục 3).
- **Huỷ:** `PATCH /api/tasks/{id}/cancel`.

### 2.5. Stats Overview (Student)
Song song gọi 4 API (`Promise.allSettled`) để hiển thị 4 ô KPI:
- Công việc của tôi / Hôm nay / Sắp tới (7 ngày) / Quá hạn.
- Lỗi từng API được nuốt (`catch`), không chặn các ô còn lại.

---

## 3. Luồng Task Report

### 3.1. Form `TaskReportForm` — schema động theo `taskType`

| taskType | Icon | Schema |
|---|---|---|
| `Planting` | 🌱 | plantCount, plantSpacing, soilCondition, seedlingSource |
| `Watering` | 💧 | waterAmount, irrigationMethod, duration, soilMoistureBefore/After |
| `Fertilizing` | 🧪 | fertilizerType, fertilizerAmount, fertilizerBrand, applicationMethod |
| `Inspection` | 🔍 | overallHealth, pestDiseaseLevel, affectedPlantCount, inspectionChecklist |
| `Harvest` | 🌾 | harvestWeight, qualityGrade, plantCount, averagePerPlant, moistureContent |
| `Observation` | 👁️ | **Dynamic** — load `MeasurementDefinition` của experiment, lọc theo group của batch |
| `Measurement` | 📏 | **Dynamic** — giống Observation, dành riêng cho luồng ghi nhận tăng trưởng |
| `Other` | 📋 | Free-form + nút "＋ Thêm cột" |

### 3.2. Custom fields
- Người dùng có thể bấm **"＋ Thêm cột"** để thêm cặp `{key, value}` tự do.
- Hệ thống tự sinh key `custom_1`, `custom_2`, … đảm bảo không trùng.
- Các custom field sẽ được giữ nguyên khi đổi task (không tự reset).

### 3.3. Validate số trước khi submit
Hàm `localValidateValue(definition, value)` ở `src/utils/measurement.js`:
- Số không âm.
- Đơn vị `%` ⇒ `0–100`.
- Tên chứa "màu sắc" ⇒ thang 1–5.
- `value > targetValue × 5` ⇒ cảnh báo "vượt quá 5 lần target".

### 3.4. Quy trình nộp báo cáo (5 bước tuần tự trong `handleSubmitComplete`)

```text
[1] Tạo TaskReport
    POST /api/task-reports
    body: { taskId, reportText, resultData: { key: value, ... } }

        ↓
[2] Bridge → tạo MeasurementRecord (xem mục 4)

        ↓
[3] Upload TaskImage đính kèm (xem mục 5)

        ↓
[4] Mark complete
    PATCH /api/tasks/{id}/complete

        ↓
[5] Toast tổng kết: "Đã hoàn thành! 📊 N chỉ số (...) · 📷 M ảnh"
```

> ⚠️ **Business rule:** Báo cáo **bắt buộc** phải tạo **trước** khi complete. Nếu `[1]` fail thì dừng, không gọi tiếp `[2]/[3]/[4]`.

### 3.5. Payload schema

```json
POST /api/task-reports
{
  "taskId": "uuid",
  "reportText": "Đã tưới đủ ẩm, đất đạt độ ẩm 78%",
  "resultData": {
    "waterAmount": 12.5,
    "soilMoistureBefore": 45,
    "soilMoistureAfter": 78,
    "custom_1": "Ghi chú tự do"
  }
}
```

`buildReportPayload(resultArray)` flatten mảng `[{key, value}]` thành object (chỉ giữ key có `.trim()` khác rỗng).

### 3.6. Cập nhật TaskReport
- `PUT /api/task-reports/{id}` — dùng khi user muốn sửa báo cáo trước khi complete (ít dùng trên mobile, chủ yếu desktop).

---

## 4. Luồng Measurement Record (Bridge từ TaskReport)

### 4.1. Vấn đề
TaskReport là dữ liệu tự do (key/value). MeasurementRecord là dữ liệu chuẩn hoá theo `MeasurementDefinition` (do Researcher tạo). FE phải **tự động rút trích** các trường đo lường có trong báo cáo → map sang definition → POST lên BE.

### 4.2. Pipeline (trong `handleSubmitComplete`)

```
resultData (key/value)
   │
   ▼
filterDefinitionsByTaskGroup(definitions, task, explicitGroupId)
   │     - Lấy groupId chắc chắn qua GET /batches/{batchId}
   │     - Lọc definitions chỉ của 1 nhóm duy nhất (tránh trùng metricName)
   ▼
[1] Nếu taskType === 'Measurement' / 'Observation':
       extractBulkItemsFromResultData(resultData, definitions)
         → items[] = { definitionId, value, metricName, unit, targetValue }
       createMeasurementsBulk(task, items, meta, measurementRecordsApi.bulk)
         → POST /api/measurement-records/bulk (1 request duy nhất)

[2] Ngược lại (Planting/Watering/Fertilizing/Harvest/Inspection/Other):
       extractMeasurementsFromReport(dataObj)
         → lọc theo MEASUREMENT_FIELD_MAP (vd: plantHeight → 'height'/cm)
       buildMeasurementPayloads(task, [...], meta, defByName)
         → map name → measurementDefinitionId
       createMeasurementsFromTaskReport(payloads, measurementRecordsApi)
         → POST /api/measurement-records n lần (Promise.allSettled)
```

### 4.3. `MEASUREMENT_FIELD_MAP` (Vi → En + Unit)
| Key trong TaskReport | `metricName` (chuẩn) | Unit | Mô tả |
|---|---|---|---|
| `plantHeight`, `chieuCaoCm` | `height` | cm | Chiều cao cây |
| `leafCount`, `soLaTrungBinh` | `leafCount` | lá | Số lá trung bình |
| `tocDoSinhTruong` | `growthRate` | cm/ngày | Tốc độ sinh trưởng |
| `tiLeSong` | `survivalRate` | % | Tỷ lệ sống |
| `tiLeDauQua` | `fruitingRate` | % | Tỷ lệ đậu quả |
| `waterAmount` | `waterAmount` | L/m² | Lượng nước tưới |
| `luongNuocTong` | `totalWater` | lít | Tổng lượng nước |
| `duration` | `wateringDuration` | phút | Thời gian tưới |
| `soilMoistureBefore/After` | `soilMoistureBefore/After` | % | Độ ẩm đất trước/sau |
| `fertilizerAmount` | `fertilizerAmount` | g/cây | Liều lượng phân bón |
| `plantCount` | `plantCount` | cây | Số cây |
| `harvestWeight`, `sanLuongKg`, `sanLuongTon` | `weight` | kg/tấn | Sản lượng |
| `moistureContent` | `moistureContent` | % | Độ ẩm sản phẩm |
| … | … | … | (xem file đầy đủ) |

### 4.4. Schema payload MeasurementRecord

```jsonc
// Single
POST /api/measurement-records
{
  "experimentId": "uuid",
  "experimentStageId": "uuid|null",
  "batchId": "uuid",
  "measurementDefinitionId": "uuid",   // BE tự fill metricName/unit/targetValue
  "value": 78,
  "measuredAt": "2026-08-15T10:30:00Z",
  "extraData": { "note": "Auto from TaskReport #xxx", "sourceKey": "soilMoistureAfter" }
}

// Bulk (cho taskType Measurement/Observation)
POST /api/measurement-records/bulk
{
  "experimentId": "uuid",
  "experimentStageId": "uuid",
  "batchId": "uuid",
  "measuredAt": "2026-08-15T10:30:00Z",
  "extraData": { "note": "..." },
  "items": [
    { "measurementDefinitionId": "uuid", "value": 18.4, "metricName": "Height", "unit": "cm", "targetValue": 20 },
    { "measurementDefinitionId": "uuid", "value": 7,    "metricName": "LeafCount", "unit": "lá", "targetValue": 8 }
  ]
}
```

### 4.5. Lấy `groupId` chắc chắn đúng

Vì `GET /api/experiments/{id}/measurements` trả về definitions của **tất cả các nhóm** (Control, NPK, Hữu cơ, …) và mỗi nhóm có cùng `metricName` → FE **bắt buộc** lọc theo nhóm của batch đang thực hiện.

Thứ tự ưu tiên:
1. `batchGroupId` từ `GET /api/batches/{batchId}` (chắc chắn đúng).
2. `task.batch.groupId` (nếu BE populate sẵn).
3. `task.batchGroupId` / `task.groupId` (fallback field flat).
4. Nếu không có gì → dedupe theo `metricName` (giữ bản đầu).

### 4.6. Lịch sử đo lường (Measurements tab — Technician)
- Gọi `GET /api/measurement-records/batch/{batchId}` hoặc `…/experiment/{experimentId}`.
- Hiển thị bảng theo `metricName`, có filter theo batch / stage / khoảng thời gian.
- Có thể xem chi tiết từng record, so sánh giữa các lần đo (line chart).

---

## 5. Luồng TaskImage (Upload ảnh đính kèm)

### 5.1. Hai cách upload trong `ImageUploader`

| Cách | API | Khi nào |
|---|---|---|
| Multipart | `POST /api/task-images/upload` | Ảnh mới chọn từ máy (có `File`) |
| JSON | `POST /api/task-images` | Ảnh đã upload Cloudinary trước đó, chỉ reference bằng URL |

### 5.2. Multipart payload (FE → BE)
```
form-data:
  File: <binary>
  imageUrl?: "https://res.cloudinary.com/..."
  caption: "Cây số 3 có dấu hiệu vàng lá"
  capturedAt: "2026-08-15T10:00:00Z"
  experimentId: "uuid"
  batchId: "uuid"
  taskId: "uuid"
  taskReportId: "uuid"   // gắn SAU khi report được tạo ở bước [1]
  tags?: "pest,leaf"
  exif?: JSON string
```

### 5.3. Upload song song
- Trong `handleSubmitComplete`, danh sách ảnh được upload bằng `Promise.allSettled` để **một ảnh lỗi không chặn ảnh khác**.
- Đếm `imageOk = fulfilled && success !== false` để hiện trên toast.

### 5.4. UI
- Chọn ảnh → preview base64 → cho phép xoá, xoay, sắp xếp lại.
- Mỗi ảnh có ô caption riêng, lưu kèm khi upload.
- Giới hạn dung lượng & định dạng ở client (PNG/JPG/WebP, ≤ 10MB).

---

## 6. Luồng Notification Realtime

### 6.1. WebSocket — `src/services/notificationSocket.js`

| Thuộc tính | Giá trị |
|---|---|
| Protocol | Raw WebSocket (RFC 6455) |
| URL | `wss://<host>/ws?token=<JWT>` (BE tự parse token từ query) |
| Auth | JWT trong query string `?token=…` |
| Keep-alive | Server ping mỗi 30s, FE không cần gửi gì thêm |
| Events | `Connected` (heartbeat), `ReceiveNotification` |
| Envelope | `{ event: string, data: T, ts: ISO, tsVietnam: ISO+07:00 }` |
| Reconnect | Exponential `[1000, 2000, 5000, 10000, 30000]` ms |
| Singleton | 1 instance cho cả app |
| Token hết hạn | Server close (401) → FE reconnect với token mới sau refresh |

### 6.2. Lifecycle của singleton

```text
constructor()
   ↓
mount NotificationBell → notificationSocket.start()
   │
   ├─ Lấy token từ localStorage
   ├─ Nếu socket đang OPEN với cùng token → skip
   ├─ new WebSocket(`${wsBase}/ws?token=${token}`)
   │
   ▼
onopen
   ├─ reset reconnectAttempt = 0
   ├─ status: connected = true → listeners được gọi
   │
onmessage (JSON.parse)
   ├─ env.event = "Connected"        → bỏ qua (heartbeat)
   ├─ env.event = "ReceiveNotification"
   │      ├─ prepend vào items[] (dedupe theo id, giữ tối đa 50)
   │      ├─ unreadCount++ nếu !isRead
   │      └─ showToast() theo priority
   │
onclose
   ├─ connected = false
   └─ _scheduleReconnect() nếu shouldRun
```

### 6.3. REST companion

| Action | API |
|---|---|
| Lấy danh sách (phân trang) | `GET /api/notifications?pageNumber=1&pageSize=20` |
| Số chưa đọc | `GET /api/notifications/unread-count` |
| Đánh dấu 1 đã đọc | `PUT /api/notifications/{id}/read` |
| Đánh dấu tất cả đã đọc | `PUT /api/notifications/read-all` |
| Test push (dev) | `POST /api/notifications/test-push` |

> Sau khi WS reconnect, **server KHÔNG push lại** notification cũ → FE phải gọi lại `GET /api/notifications/unread-count` để đồng bộ badge.

### 6.4. NotificationBell component

State chính:
- `items[]` — danh sách thông báo (tối đa 50 hiển thị).
- `unreadCount` — số badge đỏ.
- `connected` — trạng thái WS (chấm xanh lá / xám).
- `pos` — vị trí portal khi mở dropdown.
- `open` — dropdown đang mở hay không.

Mount effect:
```js
notificationSocket.start();              // bắt đầu WS
fetchInitial();                          // REST lần đầu
const unsubStatus = notificationSocket.onStatusChange(setConnected);
const unsubMsg = notificationSocket.subscribe(env => {
  if (env.event === 'Connected') return;
  if (env.event === 'ReceiveNotification' && env.data) {
    // prepend, dedupe, tăng unread, showToast
  }
});
return () => { unsubStatus(); unsubMsg(); };
```

Reconnect effect:
```js
useEffect(() => {
  if (connected) {
    notificationsApi.getUnreadCount()
      .then(c => setUnreadCount(Number(c?.count ?? c ?? 0)))
      .catch(() => {});
  }
}, [connected]);
```

### 6.5. Phân loại hiển thị

| Type | Icon | Màu | Nhãn VI |
|---|---|---|---|
| Task | 📋 | blue-100/700 | "Tác vụ" |
| Experiment | 🧪 | indigo-100/700 | "Thí nghiệm" |
| Alert | ⚠️ | rose-100/700 | "Cảnh báo" |
| System | 🔔 | slate-100/700 | "Hệ thống" |

Priority:
- **Critical** → toast `error` (đỏ), badge "Khẩn cấp".
- **High** → toast `warning` (cam), badge "Cao".
- **Medium / Low** → toast `info`, badge tương ứng.

### 6.6. Click điều hướng

`referenceTable` + `referenceId` được ánh xạ sang route FE:

| referenceTable | Route |
|---|---|
| `Tasks` | `/personal-tasks?taskId={refId}` |
| `Experiments` | `/experiments/{refId}` |
| `Alerts` | `/alerts/{refId}` |
| Khác | (không click được) |

Helper `appNavigate(path)`:
```js
window.history.pushState(null, '', path);
window.dispatchEvent(new Event('navigate'));
```

### 6.7. Toast pipeline

`useToast()` từ `src/context/ToastContext.jsx` được gọi NGAY khi nhận `ReceiveNotification` (kể cả khi dropdown đóng) → user thấy popup góc phải mà không cần mở chuông.

---

## 7. Ma trận hành vi giữa Student và Technician

| Tính năng | Student | Technician |
|---|---|---|
| Dashboard | StudentPortal (blue) | TechnicianPortal (blue, label khác) |
| Tab Tổng quan | ✅ | ✅ |
| Tab Công việc | ✅ (cá nhân) | ✅ (phân công) |
| Tab Báo cáo | ✅ | ✅ |
| Tab Đo lường | — | ✅ |
| Tab Hình thái (Morphology) | ✅ | — |
| Nhận TaskReport | ✅ | ✅ |
| Upload ảnh | ✅ | ✅ |
| Bridge Measurement | ✅ | ✅ |
| Bulk Measurement | — | ✅ (`BulkMeasurementForm`) |
| Đánh dấu khẩn (EmergencyReport) | — | ✅ (`/technician/emergency`) |
| Notification realtime | ✅ | ✅ |

---

## 8. Edge case & quy tắc đã xử lý trên FE

| Case | Cách FE xử lý |
|---|---|
| Token hết hạn trong WS | `onclose` → reconnect → khi reconnect fail 401 → `apiClient` tự `localStorage.clear()` + redirect `/login`. |
| WS server không push lại khi reconnect | `useEffect` theo `connected` → gọi lại `getUnreadCount()` và `fetchInitial()` của từng page. |
| Definition trùng `metricName` giữa các nhóm | Filter theo `groupId` của batch (ưu tiên fetch qua `GET /batches/{id}`). |
| Batch không có `groupId` | Fallback dedupe theo `metricName` (giữ bản đầu). |
| Ảnh upload fail | `Promise.allSettled` — tiếp tục ảnh khác, đếm `imageOk`, log lỗi. |
| Measurement fail | `Promise.allSettled` — đếm `success`/`failed`, vẫn tiếp tục hoàn thành task (không rollback). |
| User mở nhiều tab | NotificationSocket là singleton → nhiều tab tạo nhiều instance (mỗi tab có singleton riêng). Trong tương lai có thể dùng `BroadcastChannel` để đồng bộ. |
| Mobile offline | Toast "Không thể tải tác vụ", badge WS chuyển xám, không crash app. |
| Form đo lường chưa có definition | Hiển thị banner "Experiment này chưa có MeasurementDefinition. Liên hệ Researcher để tạo trước." |
| Custom field trùng schema key | Hiện cả 2 dòng (không tự xoá) — user tự xử lý. |
| `start()` khi socket đã OPEN với cùng token | Skip, không reconnect. |
| `start()` khi chưa có token | Trả về `true`, không throw — chờ lần mount sau khi đăng nhập. |

---

## 9. State persistence & rehydration

| State | Lưu ở đâu | Rehydrate khi nào |
|---|---|---|
| JWT token | `localStorage.token` | Mỗi request qua `apiClient` |
| User info | `localStorage.user` (JSON) | Hiển thị tên trên sidebar |
| Tasks list | React state | `useEffect [activeTab]` |
| Notifications | React state + refetch on WS reconnect | Sau khi WS connect / reconnect |
| Measurement defs | React state (per form mount) | Khi mở `TaskReportForm` |
| Batch group info | React state (per form mount) | Khi mở `TaskReportForm` |

---

## 10. Diagram tổng hợp (textual)

```
   ┌───────────────────────────────────────────────────────────────┐
   │ User mở app → Login → Token lưu localStorage                  │
   └───────────────────────────────────────────────────────────────┘
                                  ↓
   ┌───────────────────────────────────────────────────────────────┐
   │ Mount Dashboard (Student / Technician)                         │
   │   • Mount NotificationBell → start WS                         │
   │   • Fetch initial notifications + unread-count                │
   │   • Active tab = "overview" → fetch stats                     │
   └───────────────────────────────────────────────────────────────┘
                                  ↓
   ┌───────────────────────────────────────────────────────────────┐
   │ User vào tab "Công việc"                                       │
   │   • Chọn sub-tab: all/today/upcoming/overdue                  │
   │   • tasksApi.getXxx() → render list                           │
   │   • Mỗi task có nút: Bắt đầu | Hoàn thành | Huỷ              │
   └───────────────────────────────────────────────────────────────┘
                                  ↓
   ┌───────────────────────────────────────────────────────────────┐
   │ Bấm "Hoàn thành" → mở TaskReportModal                        │
   │   1. TaskReportForm render schema theo task.taskType          │
   │   2. Nếu Measurement/Observation → fetch MeasurementDefinition│
   │      + fetch batch (lấy groupId)                              │
   │   3. User nhập: reportText + resultData + upload ảnh          │
   │   4. Bấm "Gửi Báo Cáo":                                       │
   │      a) POST /task-reports                                     │
   │      b) bridge → createMeasurements (single hoặc bulk)        │
   │      c) upload TaskImages (multipart hoặc json)               │
   │      d) PATCH /tasks/{id}/complete                            │
   │      e) Toast tổng kết                                         │
   └───────────────────────────────────────────────────────────────┘
                                  ↓
   ┌───────────────────────────────────────────────────────────────┐
   │ Realtime phía user:                                            │
   │   • Nhận notification mới (qua WS) → toast + badge + list     │
   │   • Click notification → navigate tới task/experiment/alert    │
   │   • Đánh dấu đã đọc (PUT)                                     │
   └───────────────────────────────────────────────────────────────┘
```

---

## 11. Checklist test thủ công (Mobile-first)

### 11.1. Notification
- [ ] Mở app → badge đếm số unread đúng với DB.
- [ ] Trigger notification mới (qua backend) → toast hiện, badge +1.
- [ ] Tắt mạng → badge xám. Bật lại mạng → badge xanh, count fetch lại.
- [ ] Click notification `Tasks` → mở đúng trang Task detail.
- [ ] Bấm "Đọc hết" → badge = 0, list cập nhật.

### 11.2. Task
- [ ] Filter 4 tab đều load đúng.
- [ ] Bấm "Bắt đầu" → state `InProgress`, badge đổi màu.
- [ ] Bấm "Hoàn thành" mà chưa gửi report → bị chặn (modal yêu cầu nhập).

### 11.3. TaskReport + Measurement Bridge
- [ ] `Watering` → nhập `waterAmount = 12` → sau khi gửi, kiểm tra DB có `MeasurementRecord` với `metricName = 'waterAmount'`, `value = 12`.
- [ ] `Measurement` task → form tự load danh sách chỉ số của nhóm đúng → submit bulk → 1 request duy nhất tạo N record.
- [ ] `Harvest` → nhập `harvestWeight = 5.2` → record `weight` được tạo.
- [ ] Nhập giá trị vượt 5× target → cảnh báo đỏ dưới input.
- [ ] Thêm custom field `ghiChuThem = "abc"` → trong `resultData` có key này.
- [ ] Upload 3 ảnh, một ảnh fail network → 2 ảnh OK, toast báo "📷 2 ảnh".

### 11.4. Đo lường (Technician)
- [ ] Tab "Đo Lường" → bảng lịch sử theo batch đang chọn.
- [ ] Lọc theo stage / khoảng ngày → kết quả đúng.
- [ ] Click 1 record → xem chi tiết (line chart các lần đo cùng metric).

### 11.5. Mobile UX
- [ ] Trên viewport ≤ 768px: sidebar collapse, content full-width.
- [ ] Modal mở từ mobile → backdrop full màn hình, đóng khi kéo xuống.
- [ ] Toast không che input quan trọng (góc phải trên cùng).
- [ ] Input số trong form đo lường mở bàn phím số trên iOS/Android.

---

## 12. Tài liệu tham chiếu trong repo

| File | Vai trò |
|---|---|
| `src/api/sharedTaskApi.js` | Tất cả REST liên quan Task / Report / Measurement / Image |
| `src/api/notificationsApi.js` | REST thông báo |
| `src/services/notificationSocket.js` | WebSocket singleton (reconnect, status) |
| `src/components/notifications/NotificationBell.jsx` | UI chuông + dropdown + toast pipeline |
| `src/components/tasks/TaskReportForm.jsx` | Form báo cáo + schema động |
| `src/components/tasks/ImageUploader.jsx` | Upload ảnh (multipart/JSON) |
| `src/utils/measurementBridge.js` | Cầu nối TaskReport ↔ MeasurementRecord + filter group |
| `src/utils/measurement.js` | Helper validate + format |
| `src/pages/PersonalTaskList.jsx` | Trang task list mobile-first (chia sẻ role) |
| `src/pages/student/StudentDashboard.jsx` | Dashboard Student |
| `src/pages/technician/TechnicianDashboard.jsx` | Dashboard Technician |
| `src/context/ToastContext.jsx` | Global toast notification |

---

## 13. Roadmap / Cải tiến đề xuất

1. **Đồng bộ WS giữa nhiều tab** bằng `BroadcastChannel` — chỉ 1 tab giữ socket, các tab khác nhận broadcast.
2. **Offline queue** cho TaskReport + Measurement khi mất mạng, retry khi online.
3. **Optimistic UI** cho `start/complete/cancel` — đổi badge ngay, rollback nếu fail.
4. **Skeleton loading** + lazy load ảnh (lazy `<img loading="lazy">`) cho list Task.
5. **Virtual scroll** cho list > 200 task.
6. **Telemetry** — log các event `task_completed`, `measurement_created`, `notification_received` để đo funnel.
7. **Push notification** (Web Push API) khi user không mở app.
8. **Service Worker** cache `/api/tasks/my` để hiển thị offline.

---

*Tài liệu này được sinh tự động từ mã nguồn FE, dựa trên cấu trúc repo tại commit hiện tại. Cập nhật khi có thay đổi về schema, API hoặc state machine.*
