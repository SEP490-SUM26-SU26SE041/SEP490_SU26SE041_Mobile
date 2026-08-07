# SmartFarm API - Curl Commands for Task Flow

> Dùng cho Mobile App và kiểm thử API

## Base URL
```bash
BASE_URL=https://localhost:7048/api
```

---

## 1. Authentication

### Login
```bash
curl -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "researcher@example.com",
    "password": "Password123!"
  }'
```

> Response: `{ "token": "eyJ...", "userId": "guid", "role": "Researcher" }`

---

## 2. Researcher: Tạo & Quản lý Task

### 2.1. Tạo Task thủ công
```bash
curl -X POST $BASE_URL/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentId": "EXPERIMENT_ID",
    "experimentStageId": "STAGE_ID",
    "batchId": "BATCH_ID",
    "title": "Tưới nước cho batch 1",
    "description": "Tưới nước 500ml cho mỗi cây",
    "taskType": "Watering",
    "requiredSkillDescription": "Kỹ năng tưới nước cơ bản",
    "dueDate": "2026-08-05T08:00:00Z"
  }'
```

### 2.2. Sinh Task tự động từ CareSchedule (theo Stage)
```bash
curl -X POST $BASE_URL/api/tasks/generate-by-stage/{stageId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.3. Sinh Task tự động từ CareSchedule (toàn bộ Experiment)
```bash
curl -X POST $BASE_URL/api/tasks/generate-by-experiment/{experimentId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.4. Xem tất cả Task đã tạo
```bash
# Tất cả
curl -X GET "$BASE_URL/api/tasks/researcher/created?scope=all" \
  -H "Authorization: Bearer {researcher_token}"

# Quá hạn
curl -X GET "$BASE_URL/api/tasks/researcher/created?scope=overdue" \
  -H "Authorization: Bearer {researcher_token}"

# Sắp tới (mặc định 7 ngày)
curl -X GET "$BASE_URL/api/tasks/researcher/created?scope=upcoming&upcomingDays=14" \
  -H "Authorization: Bearer {researcher_token}"

# Hôm nay
curl -X GET "$BASE_URL/api/tasks/researcher/created?scope=today" \
  -H "Authorization: Bearer {researcher_token}"

# Theo Experiment cụ thể
curl -X GET "$BASE_URL/api/tasks/researcher/created?experimentId=EXPERIMENT_ID" \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.5. Xem Task theo Experiment
```bash
curl -X GET $BASE_URL/api/tasks/experiment/{experimentId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.6. Tìm người phù hợp theo kỹ năng
```bash
curl -X GET $BASE_URL/api/tasks/{taskId}/skill-matches \
  -H "Authorization: Bearer {researcher_token}"
```

---

## 3. Researcher: Giao Task cho Technician/Student

### 3.1. Giao Task cho Technician
```bash
curl -X POST $BASE_URL/api/tasks/assign \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "taskId": "TASK_ID",
    "assigneeId": "TECHNICIAN_USER_ID",
    "reason": "Cần người có kỹ năng tưới nước"
  }'
```

### 3.2. Giao Task cho Student
```bash
curl -X POST $BASE_URL/api/tasks/assign \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "taskId": "TASK_ID",
    "assigneeId": "STUDENT_USER_ID",
    "reason": "Sinh viên thực tập - cần training"
  }'
```

### 3.3. Giao lại Task (Reassign)
```bash
curl -X POST $BASE_URL/api/tasks/reassign \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "taskId": "TASK_ID",
    "newAssigneeId": "NEW_ASSIGNEE_ID",
    "reason": "Người trước bận việc"
  }'
```

### 3.4. Xem Assignments của Task
```bash
curl -X GET $BASE_URL/api/tasks/{taskId}/assignments \
  -H "Authorization: Bearer {researcher_token}"
```

### 3.5. Hủy Task
```bash
curl -X PATCH $BASE_URL/api/tasks/{taskId}/cancel \
  -H "Authorization: Bearer {researcher_token}"
```

---

## 4. Technician/Student (Mobile): Xem Task được giao

### 4.1. Xem Task hôm nay (MOBILE - hay dùng nhất)
```bash
curl -X GET $BASE_URL/api/tasks/today \
  -H "Authorization: Bearer {user_token}"
```

### 4.2. Xem Task sắp tới
```bash
curl -X GET "$BASE_URL/api/tasks/upcoming?days=7" \
  -H "Authorization: Bearer {user_token}"
```

### 4.3. Xem Task quá hạn
```bash
curl -X GET $BASE_URL/api/tasks/overdue \
  -H "Authorization: Bearer {user_token}"
```

### 4.4. Xem tất cả Task được giao (với filter)
```bash
# Tất cả
curl -X GET $BASE_URL/api/tasks/my \
  -H "Authorization: Bearer {user_token}"

# Chỉ Pending
curl -X GET "$BASE_URL/api/tasks/my?status=Pending" \
  -H "Authorization: Bearer {user_token}"

# Pending hoặc InProgress
curl -X GET "$BASE_URL/api/tasks/my?status=Pending&status=InProgress" \
  -H "Authorization: Bearer {user_token}"

# Theo Batch
curl -X GET "$BASE_URL/api/tasks/my?batchId=BATCH_ID" \
  -H "Authorization: Bearer {user_token}"

# Theo Experiment
curl -X GET "$BASE_URL/api/tasks/my?experimentId=EXPERIMENT_ID" \
  -H "Authorization: Bearer {user_token}"

# Kết hợp nhiều filter
curl -X GET "$BASE_URL/api/tasks/my?batchId=BATCH_ID&status=Pending&status=InProgress" \
  -H "Authorization: Bearer {user_token}"
```

### 4.5. Xem chi tiết Task
```bash
curl -X GET $BASE_URL/api/tasks/{taskId} \
  -H "Authorization: Bearer {user_token}"
```

---

## 5. Technician/Student: Thực hiện & Báo cáo Task

### 5.1. Bắt đầu thực hiện Task (Pending -> InProgress)
```bash
curl -X PATCH $BASE_URL/api/tasks/{taskId}/start \
  -H "Authorization: Bearer {user_token}"
```

### 5.2. Hoàn thành Task (InProgress -> Completed)
```bash
curl -X PATCH $BASE_URL/api/tasks/{taskId}/complete \
  -H "Authorization: Bearer {user_token}"
```

### 5.3. Tạo Báo cáo Task (Submit Report)
```bash
curl -X POST $BASE_URL/api/task-reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {user_token}" \
  -d '{
    "taskId": "TASK_ID",
    "reportText": "Đã tưới nước đầy đủ cho 50 cây. Tình trạng cây tốt.",
    "resultData": {
      "plantsWatered": 50,
      "waterAmount": "500ml/cây",
      "condition": "Tốt"
    }
  }'
```

### 5.4. Xem Báo cáo của Task
```bash
curl -X GET $BASE_URL/api/task-reports/task/{taskId} \
  -H "Authorization: Bearer {user_token}"
```

### 5.5. Xem Báo cáo theo Batch
```bash
curl -X GET $BASE_URL/api/task-reports/batch/{batchId} \
  -H "Authorization: Bearer {user_token}"
```

### 5.6. Cập nhật Báo cáo
```bash
curl -X PUT $BASE_URL/api/task-reports/{reportId} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {user_token}" \
  -d '{
    "reportText": "Cập nhật: Tưới xong, một số cây có lá héo nhẹ",
    "resultData": {
      "plantsWatered": 50,
      "plantsWilting": 3,
      "action": "Đã báo lại với Researcher"
    }
  }'
```

---

## 6. Upload Ảnh cho Báo cáo (Ghi nhận tăng trưởng)

### 6.1. Upload Ảnh cho Task Report
```bash
curl -X POST $BASE_URL/api/task-images \
  -H "Authorization: Bearer {user_token}" \
  -F "experimentId=EXPERIMENT_ID" \
  -F "batchId=BATCH_ID" \
  -F "taskReportId=REPORT_ID" \
  -F "imageUrl=https://storage.example.com/growth-001.jpg" \
  -F "caption=Ghi nhận tăng trưởng ngày 03/08/2026" \
  -F "capturedAt=2026-08-03T10:30:00Z"
```

### 6.2. Xem Ảnh của một Report
```bash
curl -X GET $BASE_URL/api/task-images/report/{reportId} \
  -H "Authorization: Bearer {user_token}"
```

### 6.3. Xem Ảnh theo Batch
```bash
curl -X GET $BASE_URL/api/task-images/batch/{batchId} \
  -H "Authorization: Bearer {user_token}"
```

---

## 7. Ghi nhận Tăng trưởng (Measurement Records)

### 7.1. Tạo Measurement Record
```bash
curl -X POST $BASE_URL/api/measurement-records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {user_token}" \
  -d '{
    "experimentId": "EXPERIMENT_ID",
    "experimentStageId": "STAGE_ID",
    "batchId": "BATCH_ID",
    "measurementDefinitionId": "MEASUREMENT_DEF_ID",
    "value": 15.5,
    "textValue": "Chiều cao trung bình",
    "measuredAt": "2026-08-03T10:00:00Z"
  }'
```

### 7.2. Xem Measurement Records theo Batch
```bash
curl -X GET $BASE_URL/api/measurement-records/batch/{batchId} \
  -H "Authorization: Bearer {user_token}"
```

---

## 8. Debug/Admin

### 8.1. Manual Sweep Overdue Tasks
```bash
curl -X POST $BASE_URL/api/tasks/admin/sweep-overdue \
  -H "Authorization: Bearer {researcher_token}"
```

### 8.2. Xem Assignments của mình
```bash
curl -X GET $BASE_URL/api/tasks/assignments/my \
  -H "Authorization: Bearer {user_token}"
```

---

## Response Examples

### Task Response
```json
{
  "id": "guid",
  "title": "Tưới nước cho batch 1",
  "description": "Tưới nước 500ml cho mỗi cây",
  "taskType": "Watering",
  "requiredSkillDescription": "Kỹ năng tưới nước cơ bản",
  "dueDate": "2026-08-05T08:00:00Z",
  "status": "Pending",
  "createdAt": "2026-08-01T10:00:00Z",
  "updatedAt": "2026-08-01T10:00:00Z",
  "experimentId": "guid",
  "experimentTitle": "Thí nghiệm A",
  "experimentCode": "EXP001",
  "experimentStageId": "guid",
  "experimentStageName": "Giai đoạn 1",
  "batchId": "guid",
  "batchCode": "BATCH001",
  "careScheduleId": "guid",
  "careScheduleTitle": "Lịch tưới nước",
  "createdBy": "guid",
  "createdByName": "Nguyễn Văn Researcher",
  "assignedTo": "guid",
  "assignedToName": "Trần Văn Student",
  "skillRequirements": [
    { "skillId": "guid", "skillName": "Tưới nước", "requiredLevel": 2 }
  ],
  "assignments": [
    {
      "id": "guid",
      "taskId": "guid",
      "taskTitle": "Tưới nước cho batch 1",
      "assigneeId": "guid",
      "assigneeName": "Trần Văn Student",
      "assigneeEmail": "student@example.com",
      "assigneeRole": "Student",
      "assigneeSkills": [
        { "skillId": "guid", "skillName": "Tưới nước", "proficiencyLevel": 3 }
      ],
      "assignedBy": "guid",
      "assignedByName": "Nguyễn Văn Researcher",
      "reason": "Cần người có kỹ năng tưới nước",
      "status": "Assigned",
      "assignedAt": "2026-08-01T11:00:00Z",
      "endedAt": null
    }
  ]
}
```

### TaskReport Response
```json
{
  "id": "guid",
  "taskId": "guid",
  "taskTitle": "Tưới nước cho batch 1",
  "reporterId": "guid",
  "reporterName": "Trần Văn Student",
  "reportText": "Đã tưới nước đầy đủ cho 50 cây. Tình trạng cây tốt.",
  "resultData": {
    "plantsWatered": 50,
    "waterAmount": "500ml/cây",
    "condition": "Tốt"
  },
  "reportedAt": "2026-08-03T10:30:00Z",
  "images": [
    {
      "id": "guid",
      "experimentId": "guid",
      "batchId": "guid",
      "batchCode": "BATCH001",
      "taskReportId": "guid",
      "imageUrl": "https://storage.example.com/growth-001.jpg",
      "caption": "Ghi nhận tăng trưởng ngày 03/08/2026",
      "uploadedBy": "guid",
      "uploadedByName": "Trần Văn Student",
      "capturedAt": "2026-08-03T10:30:00Z",
      "createdAt": "2026-08-03T10:35:00Z"
    }
  ]
}
```

---

## Task Status Flow

```
                    ┌──────────────────────────────────────┐
                    │           RESEARCHER                 │
                    │  1. Tạo Task (Pending)               │
                    │  2. Giao cho Technician/Student      │
                    └──────────────┬───────────────────────┘
                                   │ assign
                                   ▼
┌────────────────────────────────────────────────────────────┐
│  TECHNCIAN/STUDENT (MOBILE)                                │
│                                                            │
│  Pending ──► Assigned ──► InProgress ──► Completed        │
│     │              │              │           │            │
│     │              │              │           ▼            │
│     │              │              │        Approved       │
│     │              │              │           │            │
│     │              │              │           ▼            │
│     │              │              │        Submitted ──► Rejected (sửa lại)
│     │              │              │
│     │              │              └──► Resigned (từ chối)
│     │              │
│     │              └──► Reassigned
│     │
│     └──► Cancelled (bởi Researcher)
│
└────────────────────────────────────────────────────────────┘
```

## Task Type Values
- `Planting` - Trồng cây
- `Watering` - Tưới nước
- `Fertilizing` - Bón phân
- `Observation` - Quan sát
- `Inspection` - Kiểm tra
- `Harvest` - Thu hoạch
- `Other` - Khác


## 2. Experiments (Xem & Quản lý)

### 2.1. Xem danh sách Experiments của Researcher
```bash
# Researcher: Xem experiments của mình
curl -X GET $BASE_URL/api/experiments \
  -H "Authorization: Bearer {researcher_token}"

# Researcher: Xem experiments theo Farm
curl -X GET "$BASE_URL/api/experiments?farmId=FARM_ID" \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.2. Xem chi tiết Experiment (Full - bao gồm Stages, Groups, Measurements, Design)
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.3. Xem Experiment Summary (Mobile - để hiển thị dashboard)
```bash
# Lấy thông tin cơ bản: code, title, status, dates, researcher, farm
curl -X GET $BASE_URL/api/experiments/{experimentId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 2.4. Tạo Experiment
```bash
curl -X POST $BASE_URL/api/experiments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "farmId": "FARM_ID",
    "cropVarietyId": "CROP_VARIETY_ID",
    "procedureTemplateId": "TEMPLATE_ID",
    "experimentCode": "EXP001",
    "title": "Thí nghiệm tưới nước thông minh",
    "objective": "Đánh giá hiệu quả tưới tự động",
    "hypothesis": "Tưới tự động giúp tiết kiệm 30% nước",
    "startDate": "2026-08-01",
    "endDate": "2026-12-31"
  }'
```

### 2.5. Cập nhật Experiment
```bash
curl -X PUT $BASE_URL/api/experiments/{experimentId} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "title": "Thí nghiệm tưới nước thông minh - Phiên bản 2",
    "objective": "Cập nhật mục tiêu",
    "endDate": "2027-01-31"
  }'
```

### 2.6. Cập nhật trạng thái Experiment
```bash
curl -X PATCH $BASE_URL/api/experiments/{experimentId}/status \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "status": "InProgress"
  }'
```

---

## 3. Experiment Stages (Giai đoạn thực nghiệm)

### 3.1. Xem danh sách Stages của Experiment
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/stages \
  -H "Authorization: Bearer {researcher_token}"
```

### 3.2. Xem chi tiết Stage
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/stages/{stageId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 3.3. Tạo Stage
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/stages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "stageName": "Giai đoạn 1 - Chuẩn bị",
    "stageOrder": 1,
    "objective": "Chuẩn bị đất và hạt giống",
    "startDate": "2026-08-01",
    "endDate": "2026-08-15",
    "stageType": "Preparation"
  }'
```

### 3.4. Cập nhật Stage
```bash
curl -X PUT $BASE_URL/api/experiments/stages/{stageId} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "stageName": "Giai đoạn 1 - Chuẩn bị (Đã cập nhật)",
    "objective": "Cập nhật mục tiêu giai đoạn",
    "resultSummary": "Hoàn thành chuẩn bị đất"
  }'
```

---

## 4. Experiment Groups (Nhóm thực nghiệm)

### 4.1. Xem danh sách Groups của Experiment
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/groups \
  -H "Authorization: Bearer {researcher_token}"
```

### 4.2. Tạo Group (Control / Treatment)
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "groupName": "Nhóm đối chứng",
    "treatmentDescription": "Tưới nước thủ công 2 lần/ngày",
    "groupType": "Control"
  }'
```

### 4.3. Tạo Treatment Group
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "groupName": "Nhóm thí nghiệm A",
    "treatmentDescription": "Tưới nước tự động với cảm biến độ ẩm",
    "groupType": "Treatment"
  }'
```

---

## 5. Experiment Design (Thiết kế thực nghiệm)

### 5.1. Xem Design của Experiment
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/design \
  -H "Authorization: Bearer {researcher_token}"
```

### 5.2. Tạo/Cập nhật Design
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/design \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "designType": "RCBD",
    "replicationCount": 3,
    "randomizationMethod": "CompletelyRandomized",
    "designParameters": "{\"blockSize\": 10, \"plotSize\": \"2m x 3m\"}"
  }'
```

---

## 6. Measurement Definitions (Chỉ số đo lường)

### 6.1. Xem Measurement Definitions của Experiment
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/measurements \
  -H "Authorization: Bearer {researcher_token}"
```

### 6.2. Tạo Measurement Definition
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/measurements \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "groupId": "GROUP_ID",
    "metricName": "Chiều cao cây",
    "unit": "cm",
    "targetValue": 50.0,
    "description": "Đo chiều cao từ gốc đến ngọn"
  }'
```

### 6.3. Tạo nhiều Measurement Definitions
```bash
# Metric 1: Chiều cao
curl -X POST $BASE_URL/api/experiments/{experimentId}/measurements \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "metricName": "Chiều cao cây",
    "unit": "cm",
    "targetValue": 50.0,
    "description": "Đo chiều cao từ gốc đến ngọn"
  }'

# Metric 2: Số lá
curl -X POST $BASE_URL/api/experiments/{experimentId}/measurements \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "metricName": "Số lá",
    "unit": "lá",
    "targetValue": 20.0,
    "description": "Đếm số lá trên cây"
  }'

# Metric 3: Độ ẩm đất
curl -X POST $BASE_URL/api/experiments/{experimentId}/measurements \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "metricName": "Độ ẩm đất",
    "unit": "%",
    "targetValue": 60.0,
    "description": "Đo độ ẩm đất bằng cảm biến"
  }'
```

---

## 7. Care Schedules (Lịch chăm sóc)

### 7.1. Xem Care Schedules của Experiment
```bash
curl -X GET $BASE_URL/api/experiments/{experimentId}/schedules \
  -H "Authorization: Bearer {researcher_token}"
```

### 7.2. Tạo Care Schedule
```bash
curl -X POST $BASE_URL/api/experiments/{experimentId}/schedules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentStageId": "STAGE_ID",
    "batchId": "BATCH_ID",
    "title": "Tưới nước buổi sáng",
    "instruction": "Tưới 500ml nước cho mỗi cây",
    "taskType": "Watering",
    "frequencyDays": 1,
    "startDate": "2026-08-15",
    "endDate": "2026-10-15"
  }'
```

### 7.3. Tạo nhiều Care Schedules (cho các task type khác nhau)
```bash
# Schedule: Tưới nước hàng ngày
curl -X POST $BASE_URL/api/experiments/{experimentId}/schedules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentStageId": "STAGE_ID",
    "title": "Tưới nước hàng ngày",
    "instruction": "Tưới 500ml nước cho mỗi cây vào buổi sáng",
    "taskType": "Watering",
    "frequencyDays": 1,
    "startDate": "2026-08-15",
    "endDate": "2026-10-15"
  }'

# Schedule: Bón phân hàng tuần
curl -X POST $BASE_URL/api/experiments/{experimentId}/schedules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentStageId": "STAGE_ID",
    "title": "Bón phân NPK",
    "instruction": "Bón 10g NPK cho mỗi gốc cây",
    "taskType": "Fertilizing",
    "frequencyDays": 7,
    "startDate": "2026-08-20",
    "endDate": "2026-10-15"
  }'

# Schedule: Quan sát hàng tuần
curl -X POST $BASE_URL/api/experiments/{experimentId}/schedules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentStageId": "STAGE_ID",
    "title": "Quan sát sinh trưởng",
    "instruction": "Quan sát và ghi nhận tình trạng cây, chụp ảnh",
    "taskType": "Observation",
    "frequencyDays": 7,
    "startDate": "2026-08-15",
    "endDate": "2026-10-15"
  }'
```

---

## 8. Batches (Lô cây)

### 8.1. Xem Batches của Experiment
```bash
curl -X GET $BASE_URL/api/batches/experiments/{experimentId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 8.2. Xem chi tiết Batch
```bash
curl -X GET $BASE_URL/api/batches/{batchId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 8.3. Tạo Batch
```bash
curl -X POST $BASE_URL/api/batches \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "experimentId": "EXPERIMENT_ID",
    "experimentGroupId": "GROUP_ID",
    "batchCode": "BATCH001",
    "quantity": 50,
    "plantingDate": "2026-08-15",
    "seedVariety": "Giống A",
    "source": "Nhập khẩu Hà Lan"
  }'
```

### 8.4. Cập nhật Batch
```bash
curl -X PUT $BASE_URL/api/batches/{batchId} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "quantity": 48,
    "notes": "2 cây chết trong tuần đầu"
  }'
```

---

## 9. Procedure Templates (Mẫu quy trình)

### 9.1. Xem danh sách Procedure Templates
```bash
# Tất cả templates
curl -X GET $BASE_URL/api/experiments/procedure-templates \
  -H "Authorization: Bearer {researcher_token}"

# Templates theo CropVariety
curl -X GET "$BASE_URL/api/experiments/procedure-templates?cropVarietyId=CROP_VARIETY_ID" \
  -H "Authorization: Bearer {researcher_token}"
```

### 9.2. Xem chi tiết Template
```bash
curl -X GET $BASE_URL/api/experiments/procedure-templates/{templateId} \
  -H "Authorization: Bearer {researcher_token}"
```

### 9.3. Tạo Procedure Template
```bash
curl -X POST $BASE_URL/api/experiments/procedure-templates \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {researcher_token}" \
  -d '{
    "cropVarietyId": "CROP_VARIETY_ID",
    "templateName": "Quy trình trồng cà chua",
    "objective": "Hướng dẫn quy trình trồng và chăm sóc cà chua",
    "description": "Quy trình chuẩn cho thí nghiệm cà chua",
    "steps": [
      {
        "stepOrder": 1,
        "title": "Chuẩn bị đất",
        "instruction": "Làm đất tơi xốp, bón lót phân chuồng",
        "expectedDurationDays": 7,
        "requiredSkillDescription": "Kỹ năng làm đất",
        "stageType": "Preparation"
      },
      {
        "stepOrder": 2,
        "title": "Gieo hạt",
        "instruction": "Gieo hạt với khoảng cách 50cm",
        "expectedDurationDays": 1,
        "requiredSkillDescription": "Kỹ năng gieo trồng",
        "stageType": "Planting"
      },
      {
        "stepOrder": 3,
        "title": "Chăm sóc",
        "instruction": "Tưới nước, bón phân theo lịch",
        "expectedDurationDays": 60,
        "requiredSkillDescription": "Kỹ năng tưới nước, bón phân",
        "stageType": "Growing"
      }
    ]
  }'
```

---

## 10. Measurement Records (Ghi nhận tăng trưởng)

### 10.1. Tạo Measurement Record
```bash
curl -X POST $BASE_URL/api/measurement-records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {user_token}" \
  -d '{
    "experimentId": "EXPERIMENT_ID",
    "experimentStageId": "STAGE_ID",
    "batchId": "BATCH_ID",
    "measurementDefinitionId": "MEASUREMENT_DEF_ID",
    "value": 25.5,
    "textValue": "Chiều cao trung bình 5 cây đo được",
    "measuredAt": "2026-08-10T09:00:00Z"
  }'
```

### 10.2. Xem Measurement Records theo Batch
```bash
curl -X GET $BASE_URL/api/measurement-records/batch/{batchId} \
  -H "Authorization: Bearer {user_token}"
```

---

## Response Examples

### Experiment Response (Full)
```json
{
  "data": {
    "id": "guid",
    "experimentCode": "EXP001",
    "title": "Thí nghiệm tưới nước thông minh",
    "objective": "Đánh giá hiệu quả tưới tự động",
    "hypothesis": "Tưới tự động giúp tiết kiệm 30% nước",
    "status": "InProgress",
    "startDate": "2026-08-01",
    "endDate": "2026-12-31",
    "createdAt": "2026-07-01T10:00:00Z",
    "farmId": "guid",
    "farmName": "Trang trại ABC",
    "researcherId": "guid",
    "researcherName": "Nguyễn Văn Researcher",
    "cropVarietyId": "guid",
    "cropVarietyName": "Cà chua",
    "stages": [
      {
        "id": "guid",
        "stageName": "Giai đoạn 1 - Chuẩn bị",
        "stageOrder": 1,
        "objective": "Chuẩn bị đất và hạt giống",
        "startDate": "2026-08-01",
        "endDate": "2026-08-15",
        "stageType": "Preparation"
      },
      {
        "id": "guid",
        "stageName": "Giai đoạn 2 - Gieo trồng",
        "stageOrder": 2,
        "objective": "Gieo hạt và theo dõi nảy mầm",
        "startDate": "2026-08-15",
        "endDate": "2026-08-30",
        "stageType": "Planting"
      }
    ],
    "groups": [
      {
        "id": "guid",
        "groupName": "Nhóm đối chứng",
        "treatmentDescription": "Tưới nước thủ công",
        "groupType": "Control"
      },
      {
        "id": "guid",
        "groupName": "Nhóm thí nghiệm",
        "treatmentDescription": "Tưới nước tự động",
        "groupType": "Treatment"
      }
    ],
    "measurementDefinitions": [
      {
        "id": "guid",
        "metricName": "Chiều cao cây",
        "unit": "cm",
        "targetValue": 50.0,
        "description": "Đo chiều cao từ gốc đến ngọn"
      }
    ],
    "design": {
      "designType": "RCBD",
      "replicationCount": 3,
      "randomizationMethod": "CompletelyRandomized"
    }
  }
}
```

### Stage Response
```json
{
  "data": {
    "id": "guid",
    "stageName": "Giai đoạn 1 - Chuẩn bị",
    "stageOrder": 1,
    "objective": "Chuẩn bị đất và hạt giống",
    "startDate": "2026-08-01",
    "endDate": "2026-08-15",
    "stageType": "Preparation",
    "resultSummary": "Hoàn thành",
    "createdAt": "2026-07-01T10:00:00Z"
  }
}
```

### Batch Response
```json
{
  "id": "guid",
  "batchCode": "BATCH001",
  "experimentId": "guid",
  "experimentGroupId": "guid",
  "experimentGroupName": "Nhóm đối chứng",
  "quantity": 50,
  "plantingDate": "2026-08-15",
  "seedVariety": "Giống A",
  "status": "Active",
  "createdAt": "2026-08-15T08:00:00Z"
}
```

---

## Enums Reference

### Experiment Status
- `Draft` - Bản nháp
- `PendingApproval` - Chờ phê duyệt
- `Approved` - Đã phê duyệt
- `InProgress` - Đang tiến hành
- `Completed` - Hoàn thành
- `Cancelled` - Đã hủy

### Stage Type
- `Preparation` - Chuẩn bị
- `Planting` - Gieo trồng
- `Growing` - Sinh trưởng
- `Harvesting` - Thu hoạch
- `PostHarvest` - Sau thu hoạch
- `Other` - Khác

### Group Type
- `Control` - Nhóm đối chứng
- `Treatment` - Nhóm thí nghiệm

### Design Type
- `CRD` - Completely Randomized Design
- `RCBD` - Randomized Complete Block Design
- `LSD` - Latin Square Design
- `Factorial` - Factorial Design
- `SplitPlot` - Split Plot Design
- `Other` - Khác

### Task Type
- `Planting` - Trồng cây
- `Watering` - Tưới nước
- `Fertilizing` - Bón phân
- `Observation` - Quan sát
- `Inspection` - Kiểm tra
- `Harvest` - Thu hoạch
- `Other` - Khác