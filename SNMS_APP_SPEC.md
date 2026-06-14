# SNMS Flutter App — Full Specification
# Smart Nursery Management System
# Version: 1.0 | Mock Data Phase

---

## 1. TỔNG QUAN NGHIỆP VỤ

### Flow chính theo DB

```
ExperimentRequests (Researcher tạo)
    → RequestReviews (Farm Manager duyệt)
    → Experiments (được tạo sau khi approve)
        → ExperimentDesigns (thiết kế thí nghiệm)
        → ExperimentGroups (Control vs Treatment)
        → CultivationMethods (phương pháp canh tác mỗi group)
        → ExperimentStages (các giai đoạn: Nursery→Care→Growth→Harvest→Evaluation)
        → ExperimentBedAssignments (gán luống)
        → Batches (lô cây, mỗi batch = 1 group × 1 bed)
        → CareSchedules (lịch chăm sóc)
        → Tasks (công việc cụ thể, gán cho Student/Technician)
            → AITaskAssignmentSuggestions (AI gợi ý người phù hợp)
            → TaskAssignments (record gán việc)
            → TaskReports (báo cáo từ Student/Technician)
        → GrowthRecords (Student ghi tăng trưởng hàng ngày)
        → PlantObservations (Student ghi quan sát)
        → MeasurementRecords (đo theo MeasurementDefinitions)
        → StageResults (kết quả mỗi giai đoạn)
        → ExperimentResults (kết quả final + so sánh group)
        → StatisticalAnalyses (phân tích thống kê)
        → ExperimentReports (báo cáo xuất)
```

---

## 2. SCREEN MAP THEO ROLE

### RESEARCHER (5 màn hình chính)

```
Bottom Nav: Dashboard | Experiments | Tasks | Notifications | Chat
```

#### R1. Dashboard
- Greeting + role badge "Researcher"
- Alert banner nếu có sensor anomaly
- KPI tiles: Active Experiments | Pending Tasks | Students assigned | Stages on track
- Quick action: [+ New Experiment Request]
- Active experiments list (ExperimentCard với progress per stage)
- Recent notifications

#### R2. Experiment List
- Filter tabs: All | Draft | Pending | Active | Completed
- Search bar
- ExperimentCard mỗi item (title, status, progress, group count)
- FAB: + Create Request

#### R3. Experiment Request — Create (Multi-step Form)
**Step 1 — Basic Info**
- Title*
- Objective* (textarea)
- CropVariety (dropdown: Crops → CropVarieties)
- Expected Start Date / End Date (date picker)
- Plant Quantity, Group Count
- Required Area (m²)

**Step 2 — Location Requirements**
- Required Zone Count
- Required Bed Count
- Plant Spacing (cm)
- Required Soil Type (dropdown từ SoilTypes)
- Monitoring checklist: Temperature | Humidity | Soil Moisture | Light

**Step 3 — Review & Submit**
- Summary tất cả thông tin
- [Submit Request] button

#### R4. Experiment Detail (sau khi được Approved → Active)
**Tab 1: Overview**
- Status chip, dates, objective
- ExperimentDesign info: DesignType, SampleSize, ReplicationCount
- Groups section: danh sách ExperimentGroups (Control vs Treatment)
  - Mỗi group: GroupName | GroupType | CultivationMethod
  - CultivationMethod detail: WateringRules, FertilizingRules

**Tab 2: Stages**
- Timeline view các ExperimentStages (Nursery → Care → Growth → Harvest → Evaluation)
- Mỗi stage: StageType chip | Date range | Status | StageResults (nếu có)
- Active stage highlighted
- [View Stage Detail] → StageResults, Tasks thuộc stage này

**Tab 3: Groups Comparison** ⭐ NGHIỆP VỤ CHÍNH
- Dropdown chọn Stage để so sánh
- Side-by-side card: Control Group vs Treatment Group
- Metrics so sánh theo MeasurementDefinitions:
  - PlantHeight average (từ GrowthRecords)
  - LeafCount average
  - Survival Rate
  - MeasurementRecords theo MetricName (e.g. chlorophyll, root length...)
- Chart: Line chart tăng trưởng chiều cao theo ngày (2 lines = 2 groups)
- Chart: Bar chart so sánh metrics cuối stage
- Final comparison (nếu stage = Evaluation):
  - ExperimentResults: BestGroupId, BestMethodId, SurvivalRate, AverageHeight, Conclusion
  - StatisticalAnalyses: AnalysisMethod, PValue, ResultSummary

**Tab 4: Batches**
- Danh sách Batches theo GroupId
- BatchCard: BatchCode | Group | Bed | Quantity | Status | HealthScore (từ PlantHealthAssessments)
- Tap → Batch Detail: GrowthRecords chart, PlantObservations list, PlantImages

**Tab 5: Tasks** ⭐
- Filter: All | Pending | InProgress | Completed
- TaskCard: TaskName | Type | Assignee | DueDate | Status
- [+ Create Task] button
  
#### R5. Create Task + AI Assignment ⭐ NGHIỆP VỤ CHÍNH
**Form tạo task:**
- TaskName*, TaskType (dropdown: Planting/Watering/Fertilizing/Observation/Inspection)
- Description*, RequiredSkillDescription
- StartAt, DueDate (datetime picker)
- BatchId (chọn batch liên quan)
- ExperimentStageId (chọn stage)
- Skill Requirements: thêm Skills với RequiredLevel (1-5), IsMandatory toggle

**AI Assignment panel** (sau khi fill form):
- [🤖 Get AI Suggestion] button
- AI gọi API → trả về AITaskAssignmentSuggestions:
  - Danh sách candidates được rank theo MatchScore
  - Mỗi candidate: Avatar | FullName | MatchScore bar | Reason text | Current task count
  - Skills match visualization (required vs candidate's ProficiencyLevel)
  - Chip: "Best skill match" | "Least workload"
- Researcher có thể:
  - Accept suggestion (→ tạo TaskAssignment)
  - Adjust (chọn người khác từ danh sách)
  - Reject (assign thủ công)

#### R6. Notifications
- List NotificationCard: icon | message | time | unread dot
- Filter: All | Alerts | Task updates | System
- Tap → navigate đến màn hình liên quan

#### R7. Chatbot
- Conversation list (ChatbotConversations)
- Chat UI: bubble messages (user/assistant)
- Context: CropVariety selector (optional, để AI biết context)
- KnowledgeDocument RAG: AI trả lời dựa trên docs đã index
- Input bar + send button

---

### STUDENT (4 màn hình chính)

```
Bottom Nav: Dashboard | My Tasks | Growth Log | Chat
```

#### S1. Dashboard
- Greeting + "Student" badge
- KPI tiles: Tasks today | Completed this week | Observations logged | Experiments assigned
- Today's tasks list (Tasks filter by AssignedTo = currentUser, DueDate = today)
- Assigned experiments (read-only)

#### S2. My Tasks
- Filter tabs: Today | This Week | All | Completed
- TaskCard: TaskName | Experiment | Stage | DueDate | Status
- Tap → Task Detail:
  - Thông tin task, description, skill requirements
  - CareActivities (nếu Watering/Fertilizing): input WaterAmount, FertilizerAmount, Note
  - [Submit Task Report] → TaskReport form:
    - ReportData (các fields tùy TaskType)
    - Summary textarea
    - ImageUrl (upload ảnh)
    - [Submit] → tạo TaskReport + update Task status

#### S3. Growth Log ⭐ NGHIỆP VỤ CHÍNH
- Dropdown chọn Batch (batches assigned to student's experiments)
- Nếu chưa có record hôm nay → hiện form nhanh:
  - PlantHeight (cm)*, LeafCount*, LeafColor (dropdown), PlantStatus
  - Note (PlantObservation)
  - [+ Upload Photo] → PlantImage
  - [Save Growth Record]
- History list: GrowthRecords sorted by date (newest first)
- GrowthRecord card: date | height | leafCount | status badge
- Mini chart: line chart PlantHeight theo ngày (last 14 days)
- [View Full Chart] → expand với leafCount overlay

#### S4. Chat
- Giống Researcher chatbot nhưng role = student context

---

### TECHNICIAN (4 màn hình chính)

```
Bottom Nav: Dashboard | My Tasks | Report | Chat
```

#### T1. Dashboard
- KPI tiles: Tasks today | Overdue | Sensors to check | Completed this week
- Alert banner: Sensor anomalies cần kiểm tra (từ Alerts table)
- Today's schedule (CareSchedules + Tasks assigned)
- Sensor status summary (SensorAllocations + SensorData latest)

#### T2. My Tasks
- Giống Student nhưng TaskType chủ yếu: Watering, Fertilizing, Inspection
- Task Detail → CareActivity form:
  - WaterAmount, FertilizerAmount, Note, PerformedAt
  - [Submit] → tạo CareActivity + TaskReport

#### T3. Technician Report ⭐ NGHIỆP VỤ CHÍNH
- Báo cáo gửi lên Researcher (TaskReport với ReportData phong phú):
  - Chọn Task liên quan
  - Work Done summary
  - Issues Found (textarea)
  - Sensor readings ghi nhận (manual nếu MQTT không có)
  - Severity dropdown nếu có vấn đề: Low | Medium | High | Critical
  - ImageUrl
  - [Submit Report to Researcher]
- History: danh sách TaskReports đã submit
- Tap report → full detail

#### T4. Chat
- Chatbot với context kỹ thuật chăm sóc cây

---

### FARM MANAGER (4 màn hình chính)

```
Bottom Nav: Dashboard | Farm Map | Experiments | Notifications
```

#### FM1. Dashboard
- KPI tiles: Active experiments | Available beds | Sensors online | Pending requests
- Alert banner: ExperimentRequests cần review (Pending status)
- Quick action: [Review Requests]
- Active batches overview

#### FM2. Farm Map ⭐ NGHIỆP VỤ CHÍNH
**Hierarchical view:**

**Level 1 — Farm overview**
- Card: FarmName | FarmCode | Location | Status badge
- Areas list → tap để drill down

**Level 2 — Area detail**
- AreaName, EnvironmentType, TotalArea
- Zones grid (ZoneCode | Status badge | AreaSize)
- Tap Zone → Zone detail

**Level 3 — Zone detail**
- ZoneCode, ZoneName, SoilType name
- Beds grid (BedCode | Status | dimensions L×W)
- Tap Bed → Bed detail

**Level 4 — Bed detail**
- BedCode, SoilType, Status
- Current experiment assignment (ExperimentBedAssignments)
- Active batch (Batches với status Growing)
- Sensors allocated (SensorAllocations → Sensors):
  - SensorCard: SensorCode | SensorType | Status badge | Latest value | Timestamp
  - Chart: sensor readings last 24h (SensorData)
- Alerts for this bed (nếu có SensorAnomalyEvents)

#### FM3. Experiment Requests Review
- List ExperimentRequests với Status = Pending
- RequestCard: Title | Researcher name | CropVariety | Expected dates | Required resources
- Tap → Request Detail:
  - Full request info (tất cả fields ExperimentRequests)
  - Monitoring requirements checklist
  - [Approve] → tạo RequestReview với Result=Approved + trigger tạo Experiment
  - [Reject] → dialog nhập Comment, tạo RequestReview Result=Rejected

#### FM4. Notifications
- Giống Researcher notifications

---

## 3. MOCK DATA

### Users

```dart
// lib/mock/mock_users.dart
final mockUsers = [
  UserModel(
    id: 'usr-researcher-001',
    fullName: 'TS. Nguyễn Minh Khoa',
    email: 'khoa.researcher@snms.vn',
    role: UserRole.researcher,
    skills: [],
  ),
  UserModel(
    id: 'usr-farmmanager-001',
    fullName: 'Trần Văn Đức',
    email: 'duc.manager@snms.vn',
    role: UserRole.farmManager,
    skills: [],
  ),
  UserModel(
    id: 'usr-technician-001',
    fullName: 'Lê Thị Hương',
    email: 'huong.tech@snms.vn',
    role: UserRole.technician,
    skills: [
      UserSkill(skillName: 'Tưới tiêu tự động', proficiencyLevel: 5),
      UserSkill(skillName: 'Vận hành cảm biến', proficiencyLevel: 4),
      UserSkill(skillName: 'Bón phân', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-technician-002',
    fullName: 'Phạm Hoàng Nam',
    email: 'nam.tech@snms.vn',
    role: UserRole.technician,
    skills: [
      UserSkill(skillName: 'Kiểm tra sâu bệnh', proficiencyLevel: 5),
      UserSkill(skillName: 'Vận hành cảm biến', proficiencyLevel: 3),
      UserSkill(skillName: 'Chụp ảnh cây', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-student-001',
    fullName: 'Võ Thị Lan',
    email: 'lan.student@snms.vn',
    role: UserRole.student,
    skills: [
      UserSkill(skillName: 'Quan sát tăng trưởng', proficiencyLevel: 3),
      UserSkill(skillName: 'Ghi chép dữ liệu', proficiencyLevel: 4),
    ],
  ),
  UserModel(
    id: 'usr-student-002',
    fullName: 'Đỗ Văn Bình',
    email: 'binh.student@snms.vn',
    role: UserRole.student,
    skills: [
      UserSkill(skillName: 'Quan sát tăng trưởng', proficiencyLevel: 4),
      UserSkill(skillName: 'Phân tích mẫu đất', proficiencyLevel: 3),
    ],
  ),
];
```

### Farm Hierarchy

```dart
// lib/mock/mock_farm.dart
final mockFarm = FarmModel(
  id: 'farm-001',
  farmCode: 'FARM-NVU-01',
  farmName: 'Trại Thực Nghiệm Nông Vụ',
  location: 'Bình Dương, Việt Nam',
  status: LocationStatus.available,
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
            BedModel(id: 'bed-001', bedCode: 'B01', length: 5.0, width: 1.2,
              status: LocationStatus.inUse,
              sensors: [
                SensorModel(id: 'sen-001', sensorCode: 'TEMP-Z01-B01',
                  sensorType: SensorType.temperature,
                  status: SensorStatus.allocated,
                  latestValue: 28.4, unit: '°C'),
                SensorModel(id: 'sen-002', sensorCode: 'HUM-Z01-B01',
                  sensorType: SensorType.humidity,
                  status: SensorStatus.allocated,
                  latestValue: 72.1, unit: '%'),
                SensorModel(id: 'sen-003', sensorCode: 'SOIL-Z01-B01',
                  sensorType: SensorType.soilMoisture,
                  status: SensorStatus.allocated,
                  latestValue: 45.8, unit: '%'),
              ],
            ),
            BedModel(id: 'bed-002', bedCode: 'B02', length: 5.0, width: 1.2,
              status: LocationStatus.inUse,
              sensors: [
                SensorModel(id: 'sen-004', sensorCode: 'TEMP-Z01-B02',
                  sensorType: SensorType.temperature,
                  status: SensorStatus.offline,
                  latestValue: null, unit: '°C'),
              ],
            ),
            BedModel(id: 'bed-003', bedCode: 'B03', length: 5.0, width: 1.2,
              status: LocationStatus.available, sensors: []),
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
            BedModel(id: 'bed-004', bedCode: 'B01', length: 4.0, width: 1.0,
              status: LocationStatus.available, sensors: []),
          ],
        ),
      ],
    ),
  ],
);
```

### Experiments

```dart
// lib/mock/mock_experiments.dart
final mockExperiments = [
  ExperimentModel(
    id: 'exp-001',
    experimentCode: 'EXP-2024-001',
    title: 'So sánh phương pháp tưới nhỏ giọt và tưới phun sương trên cà chua bi',
    objective: 'Xác định phương pháp tưới tối ưu nhằm tăng tỷ lệ sống và chiều cao cây cà chua bi trong giai đoạn vườn ươm 45 ngày đầu.',
    status: ExperimentStatus.active,
    researcherId: 'usr-researcher-001',
    startDate: DateTime(2024, 3, 1),
    endDate: DateTime(2024, 5, 15),
    cropVariety: 'Cà chua bi Cherry 101',

    design: ExperimentDesign(
      designType: DesignType.completelyRandomized,
      sampleSize: 60,
      replicationCount: 3,
      treatmentCount: 2,
      observationFrequencyDays: 2,
      measurementFrequencyDays: 7,
      evaluationCriteria: 'Chiều cao cây, số lá, tỷ lệ sống, chỉ số SPAD chlorophyll',
      analysisPlan: 'ANOVA một nhân tố, so sánh Tukey HSD, p < 0.05',
    ),

    groups: [
      ExperimentGroup(
        id: 'grp-control-001',
        groupName: 'Nhóm Đối Chứng',
        groupType: GroupType.control,
        description: 'Tưới phun sương 2 lần/ngày, 200ml/lần',
        cultivationMethod: CultivationMethod(
          methodName: 'Tưới phun sương truyền thống',
          wateringRule: WateringRule(amount: 200, frequencyDays: 1),
          fertilizingRule: FertilizingRule(
            fertilizerName: 'NPK 20-20-20',
            amount: 5.0,
            frequencyDays: 7,
          ),
        ),
      ),
      ExperimentGroup(
        id: 'grp-treatment-001',
        groupName: 'Nhóm Thực Nghiệm',
        groupType: GroupType.treatment,
        description: 'Tưới nhỏ giọt liên tục 4h/ngày, sensor-controlled',
        cultivationMethod: CultivationMethod(
          methodName: 'Tưới nhỏ giọt IoT',
          wateringRule: WateringRule(amount: 150, frequencyDays: 1),
          fertilizingRule: FertilizingRule(
            fertilizerName: 'Fert-Plus Hữu Cơ',
            amount: 4.0,
            frequencyDays: 7,
          ),
        ),
      ),
    ],

    stages: [
      ExperimentStage(
        id: 'stage-001', stageOrder: 1, stageName: 'Giai Đoạn Vườn Ươm',
        stageType: ExperimentStageType.nursery,
        startDate: DateTime(2024, 3, 1), endDate: DateTime(2024, 3, 21),
        status: StageStatus.completed,
        result: StageResult(
          summary: 'Tỷ lệ nảy mầm: Đối chứng 82%, Thực nghiệm 88%. Nhóm thực nghiệm cho tỷ lệ cao hơn 6%.',
        ),
      ),
      ExperimentStage(
        id: 'stage-002', stageOrder: 2, stageName: 'Giai Đoạn Chăm Sóc',
        stageType: ExperimentStageType.care,
        startDate: DateTime(2024, 3, 22), endDate: DateTime(2024, 4, 15),
        status: StageStatus.completed,
        result: StageResult(
          summary: 'Nhóm thực nghiệm cao hơn trung bình 1.4cm sau 3 tuần chăm sóc.',
        ),
      ),
      ExperimentStage(
        id: 'stage-003', stageOrder: 3, stageName: 'Giai Đoạn Tăng Trưởng',
        stageType: ExperimentStageType.growth,
        startDate: DateTime(2024, 4, 16), endDate: DateTime(2024, 5, 5),
        status: StageStatus.active,  // ← ĐANG CHẠY
      ),
      ExperimentStage(
        id: 'stage-004', stageOrder: 4, stageName: 'Thu Hoạch',
        stageType: ExperimentStageType.harvest,
        startDate: DateTime(2024, 5, 6), endDate: DateTime(2024, 5, 10),
        status: StageStatus.upcoming,
      ),
      ExperimentStage(
        id: 'stage-005', stageOrder: 5, stageName: 'Đánh Giá Tổng Kết',
        stageType: ExperimentStageType.evaluation,
        startDate: DateTime(2024, 5, 11), endDate: DateTime(2024, 5, 15),
        status: StageStatus.upcoming,
      ),
    ],
  ),
];
```

### Growth Records (cho biểu đồ so sánh)

```dart
// lib/mock/mock_growth_records.dart

// Group Control — Batch B01
final mockGrowthControl = [
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,16), plantHeight: 12.3, leafCount: 6, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,18), plantHeight: 13.1, leafCount: 7, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,20), plantHeight: 14.0, leafCount: 7, leafColor: 'Xanh nhạt', plantStatus: 'Trung bình'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,22), plantHeight: 14.9, leafCount: 8, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,24), plantHeight: 15.6, leafCount: 9, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,26), plantHeight: 16.2, leafCount: 9, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-ctrl-01', recordDate: DateTime(2024,4,28), plantHeight: 17.0, leafCount: 10, leafColor: 'Xanh đậm', plantStatus: 'Rất tốt'),
];

// Group Treatment — Batch B02
final mockGrowthTreatment = [
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,16), plantHeight: 13.8, leafCount: 7, leafColor: 'Xanh đậm', plantStatus: 'Tốt'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,18), plantHeight: 15.2, leafCount: 8, leafColor: 'Xanh đậm', plantStatus: 'Rất tốt'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,20), plantHeight: 16.6, leafCount: 9, leafColor: 'Xanh đậm', plantStatus: 'Rất tốt'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,22), plantHeight: 17.9, leafCount: 10, leafColor: 'Xanh đậm', plantStatus: 'Rất tốt'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,24), plantHeight: 19.1, leafCount: 11, leafColor: 'Xanh bóng', plantStatus: 'Xuất sắc'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,26), plantHeight: 20.3, leafCount: 12, leafColor: 'Xanh bóng', plantStatus: 'Xuất sắc'),
  GrowthRecord(batchId: 'batch-trt-01', recordDate: DateTime(2024,4,28), plantHeight: 21.4, leafCount: 13, leafColor: 'Xanh bóng', plantStatus: 'Xuất sắc'),
];
```

### Tasks + AI Suggestions

```dart
// lib/mock/mock_tasks.dart
final mockTasks = [
  TaskModel(
    id: 'task-001',
    taskName: 'Quan sát tăng trưởng Nhóm Đối Chứng - Tuần 4',
    taskType: TaskType.observation,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-student-001',
    dueDate: DateTime(2024, 4, 30),
    requiredSkills: [
      TaskSkillRequirement(skillName: 'Quan sát tăng trưởng', requiredLevel: 2, isMandatory: true),
      TaskSkillRequirement(skillName: 'Ghi chép dữ liệu', requiredLevel: 2, isMandatory: true),
    ],
    aiSuggestion: AITaskSuggestion(
      suggestedAssigneeId: 'usr-student-001',
      matchScore: 87.5,
      reason: 'Võ Thị Lan có kỹ năng "Quan sát tăng trưởng" level 3 (yêu cầu 2) và "Ghi chép dữ liệu" level 4 (yêu cầu 2). Hiện có 1 task đang chạy — ít nhất trong nhóm student.',
      reviewStatus: AIReviewStatus.accepted,
    ),
  ),
  TaskModel(
    id: 'task-002',
    taskName: 'Tưới nhỏ giọt Nhóm Thực Nghiệm - Ngày 15/4→28/4',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.pending,
    assignedTo: null,  // Chưa assign
    dueDate: DateTime(2024, 4, 28),
    requiredSkills: [
      TaskSkillRequirement(skillName: 'Tưới tiêu tự động', requiredLevel: 3, isMandatory: true),
      TaskSkillRequirement(skillName: 'Vận hành cảm biến', requiredLevel: 2, isMandatory: false),
    ],
    aiSuggestion: AITaskSuggestion(
      suggestedAssigneeId: 'usr-technician-001',
      matchScore: 94.2,
      reason: 'Lê Thị Hương có kỹ năng "Tưới tiêu tự động" level 5 (yêu cầu 3) và "Vận hành cảm biến" level 4. Hiện có 2 tasks — ít hơn Phạm Hoàng Nam (3 tasks).',
      reviewStatus: AIReviewStatus.suggested,
      alternativeCandidates: [
        AICandidateSuggestion(
          userId: 'usr-technician-002',
          fullName: 'Phạm Hoàng Nam',
          matchScore: 71.0,
          currentTaskCount: 3,
          reason: '"Vận hành cảm biến" level 3 (đủ) nhưng không có kỹ năng "Tưới tiêu tự động". Đang bận hơn.',
        ),
      ],
    ),
  ),
];
```

### Notifications

```dart
// lib/mock/mock_notifications.dart
final mockNotifications = [
  NotificationModel(
    id: 'notif-001',
    type: NotificationType.alert,
    title: 'Cảm biến ngoại tuyến',
    message: 'Cảm biến TEMP-Z01-B02 đã offline hơn 2 giờ. Cần kiểm tra ngay.',
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    linkedRoute: '/farm/zones/zone-001/beds/bed-002',
  ),
  NotificationModel(
    id: 'notif-002',
    type: NotificationType.taskUpdate,
    title: 'Báo cáo task từ Võ Thị Lan',
    message: 'Sinh viên Võ Thị Lan đã hoàn thành "Quan sát tăng trưởng - Ngày 26/4". Xem báo cáo.',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    linkedRoute: '/tasks/task-001',
  ),
  NotificationModel(
    id: 'notif-003',
    type: NotificationType.system,
    title: 'Yêu cầu thực nghiệm được duyệt',
    message: 'Yêu cầu EXP-REQ-003 đã được Farm Manager duyệt. Thực nghiệm mới đã được tạo.',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    linkedRoute: '/experiments/exp-002',
  ),
  NotificationModel(
    id: 'notif-004',
    type: NotificationType.alert,
    title: 'Nhiệt độ vượt ngưỡng',
    message: 'Luống B01-Z01: Nhiệt độ 34.2°C vượt ngưỡng tối đa (32°C). Mức độ: Cao.',
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    linkedRoute: '/farm',
  ),
];
```

### Chatbot Conversations

```dart
// lib/mock/mock_chatbot.dart
final mockConversations = [
  ChatConversation(
    id: 'conv-001',
    title: 'Cà chua bi - Bệnh héo xanh',
    cropVariety: 'Cà chua bi Cherry 101',
    createdAt: DateTime(2024, 4, 20),
    messages: [
      ChatMessage(sender: 'user', text: 'Cây cà chua trong nhóm đối chứng xuất hiện lá vàng, héo từ dưới lên. Nguyên nhân có thể là gì?', createdAt: DateTime(2024, 4, 20, 9, 0)),
      ChatMessage(sender: 'assistant', text: 'Dựa trên tài liệu kỹ thuật canh tác cà chua, triệu chứng lá vàng và héo từ dưới lên có thể do:\n\n1. **Bệnh héo xanh vi khuẩn** (Ralstonia solanacearum) — phổ biến khi độ ẩm đất cao.\n2. **Thiếu Magie (Mg)** — gây vàng gân lá ở lá già.\n3. **Tưới quá nhiều** — rễ thiếu oxy, héo sinh lý.\n\nBạn có thể kiểm tra bằng cách cắt thân và nhúng vào nước — nếu có dòng chảy trắng đục là vi khuẩn. Tôi có thể gợi ý phác đồ xử lý.', createdAt: DateTime(2024, 4, 20, 9, 1)),
      ChatMessage(sender: 'user', text: 'Cảm ơn! Tôi thấy có dòng trắng đục. Xử lý thế nào?', createdAt: DateTime(2024, 4, 20, 9, 5)),
      ChatMessage(sender: 'assistant', text: 'Đối với bệnh héo xanh vi khuẩn:\n\n**Ngắn hạn:**\n- Loại bỏ ngay cây bệnh, không để lại gốc trong đất\n- Khử trùng dụng cụ bằng cồn 70° hoặc Javel 1%\n- Hạn chế tưới vào gốc cây khỏe xung quanh\n\n**Phòng ngừa lan rộng:**\n- Phun Copper Oxychloride 0.2% cho cây lân cận\n- Tăng cường thông gió khu vực nhà lưới\n\nNên báo cáo ngay cho Researcher để ghi nhận vào kết quả thí nghiệm.', createdAt: DateTime(2024, 4, 20, 9, 6)),
    ],
  ),
];
```

---

## 4. AI TASK ASSIGNMENT — LOGIC MOCK

### Thuật toán (mock bằng Anthropic API)

```
Input:
- Task: TaskName, TaskType, RequiredSkills [{ skillName, requiredLevel, isMandatory }]
- Candidates: Users với role = Student hoặc Technician
  - Mỗi user: UserSkills [{ skillName, proficiencyLevel }], currentTaskCount

Scoring logic:
1. Skill Match Score (60%):
   - Mandatory skill missing → candidate bị loại
   - Mandatory skill match: proficiency >= required → +20% mỗi skill
   - Optional skill match: +10% mỗi skill

2. Workload Score (40%):
   - currentTaskCount = 0 → 100 điểm
   - currentTaskCount = 1 → 80 điểm
   - currentTaskCount = 2 → 60 điểm
   - currentTaskCount = 3+ → 30 điểm

MatchScore = (skillMatchScore * 0.6) + (workloadScore * 0.4)

Output:
- Ranked list: [{ userId, fullName, matchScore, reason, skillMatchDetails, currentTaskCount }]
```

### Prompt gửi lên Claude API (trong artifact AI Assignment):

```
System: Bạn là hệ thống gợi ý phân công task thông minh của SNMS.
Trả về JSON thuần túy, không markdown.

User: Hãy đánh giá và xếp hạng các ứng viên sau cho task:
Task: {taskName}
Loại task: {taskType}
Kỹ năng yêu cầu: {requiredSkills}

Ứng viên:
{candidates}

Trả về JSON:
{
  "suggestions": [
    {
      "userId": "...",
      "fullName": "...",
      "matchScore": 87.5,
      "reason": "Giải thích ngắn gọn bằng tiếng Việt tại sao phù hợp",
      "skillMatchDetails": [
        { "skillName": "...", "required": 2, "candidate": 4, "match": true }
      ],
      "currentTaskCount": 1,
      "recommendation": "best" | "alternative" | "not_recommended"
    }
  ]
}
```

---

## 5. NAVIGATION FLOW

### Researcher flow — Tạo Experiment đến giao việc

```
Login → Dashboard
  → [+ New Experiment] → CreateRequestScreen (3 steps)
    → Submit → ExperimentListScreen (status: Pending)
    → (Farm Manager approve) → status: Active
  → ExperimentDetailScreen
    → Tab: Stages → active stage
    → Tab: Groups Comparison → chọn stage → view charts
    → Tab: Tasks → [+ Create Task]
      → CreateTaskScreen → fill form → [🤖 AI Suggest]
        → AIAssignmentPanel → view candidates
        → [Accept] → task assigned → TaskAssignmentScreen
```

### Student flow — Nhận task và báo cáo

```
Login → Dashboard (today's tasks)
  → MyTasksScreen → TaskDetailScreen
    → [Start Task] → update status InProgress
    → [Submit Report] → TaskReportForm → submit
  → GrowthLogScreen
    → chọn Batch → GrowthRecordForm → save
    → view GrowthChart (14 ngày)
```

### Technician flow — Nhận task và báo cáo

```
Login → Dashboard (alerts + today schedule)
  → Alert banner → FarmMapScreen → BedDetail (sensor issue)
  → MyTasksScreen → TaskDetail → CareActivityForm → submit
  → ReportScreen → [New Report] → TechnicianReportForm → gửi Researcher
```

---

## 6. WIDGET MAPPING — NGHIỆP VỤ → COMPONENT

| Nghiệp vụ | Widget chính | Data source |
|-----------|-------------|-------------|
| So sánh 2 nhóm | `GroupComparisonChart` (fl_chart LineChart) | GrowthRecords x2 groups |
| Per-stage comparison | `StageComparisonCard` (side-by-side) | StageResults + MeasurementRecords |
| Final result | `ExperimentResultCard` | ExperimentResults + StatisticalAnalyses |
| AI suggestion panel | `AIAssignmentPanel` | AITaskAssignmentSuggestions |
| Skill match viz | `SkillMatchRow` (progress bars) | UserSkills vs TaskSkillRequirements |
| Student growth form | `GrowthRecordForm` | → GrowthRecords |
| Student growth chart | `GrowthLineChart` | GrowthRecords (BatchId) |
| Tech report form | `TechnicianReportForm` | → TaskReports |
| Sensor card | `SensorDataCard` (realtime-like) | SensorData mock |
| Farm hierarchy | `FarmHierarchyView` (expandable) | Farm→Area→Zone→Bed |
| Notification item | `NotificationCard` | Alerts + system events |
| Chatbot bubble | `ChatBubble` (user/assistant) | ChatbotMessages |
| Stage timeline | `StageTimeline` (horizontal scroll) | ExperimentStages |

---

## 7. THÔNG BÁO (NOTIFICATION) — PHÂN LOẠI

| Trigger | Target roles | Type | Severity |
|---------|-------------|------|----------|
| Sensor offline > 30min | FarmManager, Researcher | Alert | High |
| SensorData vượt threshold | Researcher, FarmManager | Alert | per rule |
| Task report submitted | Researcher (người tạo task) | TaskUpdate | Info |
| Task overdue | Researcher + Assignee | TaskUpdate | Warning |
| ExperimentRequest approved | Researcher | System | Info |
| ExperimentRequest rejected | Researcher | System | Warning |
| AI suggestion ready | Researcher | System | Info |
| Stage kết thúc | Researcher | System | Info |
| New task assigned | Student/Technician | TaskUpdate | Info |

---

## 8. CHATBOT — SCOPE PER ROLE

| Role | Context | Có thể hỏi về |
|------|---------|--------------|
| Researcher | CropVariety của experiment | Kỹ thuật canh tác, bệnh cây, phân tích số liệu |
| Student | Batch đang theo dõi | Cách quan sát, ghi chép, bệnh lá |
| Technician | Farm + Batch đang chăm | Kỹ thuật tưới, phân bón, vận hành cảm biến |
| FarmManager | Farm tổng thể | Quản lý tài nguyên, lịch luân canh |

KnowledgeDocuments là RAG source. Mock: hardcode 2-3 responses thuyết phục thay vì gọi vector DB.

---

## 9. CÁC MÀN HÌNH ƯU TIÊN BUILD TRƯỚC

**Sprint 1 — Core Researcher flow:**
1. Login Screen
2. Researcher Dashboard
3. Experiment List
4. Create Experiment Request (3 steps)
5. Experiment Detail (Tab Overview + Tab Stages)

**Sprint 2 — So sánh nhóm:**
6. Experiment Detail Tab: Groups Comparison (chart + side-by-side)
7. Create Task + AI Assignment Panel
8. Task Detail (Researcher view)

**Sprint 3 — Student + Technician:**
9. Student Dashboard + My Tasks
10. Growth Log Screen + Chart
11. Technician Dashboard + Tasks
12. Technician Report Screen

**Sprint 4 — Farm + Notification + Chat:**
13. Farm Map Hierarchy (Farm→Zone→Bed→Sensor)
14. Notification Screen
15. Chatbot Screen (4 roles)
