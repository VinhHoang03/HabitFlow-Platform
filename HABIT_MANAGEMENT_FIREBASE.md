# HABIT MANAGEMENT MODULE - FIREBASE VERSION

## 1. Module Overview

Habit Management Module là module cho phép người dùng tạo, quản lý và theo dõi các thói quen tích cực hằng ngày.

Vì đây là dự án môn học và sử dụng Firebase, module nên tập trung vào các chức năng chính, dễ triển khai, dễ demo và có thể mở rộng thêm AI nếu cần.

---

## 2. Main Features

### 2.1 Create Habit

Người dùng có thể tạo thói quen mới.

Thông tin thói quen gồm:

- Habit name
- Description
- Category
- Frequency
- Reminder time
- Priority
- Difficulty
- Start date
- Status
- Created at
- Updated at

Ví dụ:

- Đọc sách 30 phút mỗi ngày
- Uống 2 lít nước mỗi ngày
- Học tiếng Anh 20 phút mỗi tối
- Tập thể dục 3 lần mỗi tuần

Business Rules:

- Habit name không được để trống.
- Frequency không được để trống.
- Priority mặc định là Medium.
- Difficulty mặc định là Easy.
- Status mặc định là Active.

---

### 2.2 View Habit List

Người dùng có thể xem danh sách thói quen của mình.

Danh sách hiển thị:

- Habit name
- Category
- Frequency
- Priority
- Difficulty
- Status
- Reminder time
- Created date

Có thể lọc theo:

- Active habits
- Paused habits
- Archived habits
- Category
- Priority

Có thể tìm kiếm theo:

- Habit name

---

### 2.3 View Habit Detail

Người dùng có thể xem chi tiết một thói quen.

Thông tin hiển thị:

- Habit name
- Description
- Category
- Frequency
- Reminder time
- Priority
- Difficulty
- Status
- Start date
- Created date
- Updated date

Có thể hiển thị thêm:

- Total completed days
- Current streak
- Completion rate

---

### 2.4 Update Habit

Người dùng có thể chỉnh sửa thông tin thói quen.

Các thông tin có thể sửa:

- Habit name
- Description
- Category
- Frequency
- Reminder time
- Priority
- Difficulty
- Status

Business Rules:

- Không được để trống Habit name.
- Khi cập nhật, hệ thống tự động cập nhật updatedAt.
- Việc cập nhật habit không xóa lịch sử hoàn thành trước đó.

---

### 2.5 Delete Habit

Người dùng có thể xóa thói quen.

Khuyến nghị dùng soft delete thay vì xóa hẳn.

Cách làm:

- Đổi status thành Deleted
- Hoặc thêm field isDeleted = true

Business Rules:

- Habit đã xóa không hiển thị trong danh sách chính.
- Có thể giữ dữ liệu để phục vụ thống kê nếu cần.

---

### 2.6 Pause / Resume Habit

Người dùng có thể tạm dừng hoặc tiếp tục thói quen.

Pause Habit:

- status = Paused
- Không hiển thị trong danh sách thói quen hôm nay
- Không gửi nhắc nhở

Resume Habit:

- status = Active
- Hiển thị lại trong danh sách thói quen

---

### 2.7 Archive Habit

Người dùng có thể lưu trữ thói quen không còn muốn theo dõi.

Archive Habit:

- status = Archived
- Không hiển thị trong danh sách chính
- Vẫn có thể xem lại trong mục Archived

---

### 2.8 Habit Template

Hệ thống cung cấp một số mẫu thói quen có sẵn để người dùng chọn nhanh.

Ví dụ template:

- Drink Water
- Read Book
- Exercise
- Meditation
- Sleep Early
- Learn English
- Save Money
- Morning Routine

Khi người dùng chọn template, hệ thống tự điền sẵn:

- Habit name
- Description
- Category
- Frequency
- Difficulty

Người dùng có thể chỉnh sửa trước khi lưu.

---

### 2.9 AI Habit Suggestion

Đây là tính năng nâng cao, có thể thêm để module sáng tạo hơn.

Mục đích:

Người dùng nhập mục tiêu cá nhân, AI gợi ý các thói quen phù hợp.

Ví dụ:

User input:

Tôi muốn học tiếng Anh tốt hơn.

AI output:

- Học 10 từ vựng mỗi ngày
- Nghe podcast tiếng Anh 15 phút
- Luyện nói tiếng Anh 5 phút
- Làm 1 bài reading ngắn mỗi ngày

Workflow:

User nhập mục tiêu

AI phân tích mục tiêu

AI trả về danh sách thói quen gợi ý

User chọn thói quen muốn thêm

Hệ thống tạo habit trong Firestore

Gợi ý triển khai đơn giản:

- Frontend gửi goal text lên AI API
- AI trả về JSON list habits
- App hiển thị danh sách gợi ý
- User bấm Add để lưu vào Firestore

---

## 3. Firebase Design

### 3.1 Firebase Services Used

Nên dùng:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage nếu có upload ảnh/icon
- Firebase Cloud Functions nếu muốn gọi AI an toàn hơn

---

## 4. Firestore Collections

### 4.1 users

Collection: users

Document ID: userId

Fields:

```json
{
  "fullName": "Nguyen Van A",
  "email": "user@gmail.com",
  "avatarUrl": "",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

### 4.2 habits

Collection: habits

Document ID: auto id

Fields:

```json
{
  "userId": "firebase_user_id",
  "name": "Read Book",
  "description": "Read book every night",
  "category": "Study",
  "frequency": "Daily",
  "reminderTime": "21:00",
  "priority": "Medium",
  "difficulty": "Easy",
  "status": "Active",
  "startDate": "2026-06-28",
  "isDeleted": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Status values:

- Active
- Paused
- Archived
- Deleted

Priority values:

- Low
- Medium
- High

Difficulty values:

- Easy
- Medium
- Hard

Frequency values:

- Daily
- Weekly
- Custom

---

### 4.3 habit_templates

Collection: habit_templates

Document ID: auto id

Fields:

```json
{
  "name": "Drink Water",
  "description": "Drink enough water every day",
  "category": "Health",
  "frequency": "Daily",
  "difficulty": "Easy",
  "isActive": true,
  "createdAt": "timestamp"
}
```

---

### 4.4 habit_completions

Collection: habit_completions

Document ID: auto id

Fields:

```json
{
  "habitId": "habit_id",
  "userId": "firebase_user_id",
  "date": "2026-06-28",
  "isCompleted": true,
  "note": "Finished today",
  "createdAt": "timestamp"
}
```

Collection này dùng để tính:

- Số ngày hoàn thành
- Streak
- Tỷ lệ hoàn thành
- Lịch sử theo ngày

---

## 5. Suggested Screens

### 5.1 Habit List Screen

Hiển thị:

- Danh sách habit
- Nút Add Habit
- Search box
- Filter theo status/category

Actions:

- View detail
- Edit
- Delete
- Pause
- Archive

---

### 5.2 Create Habit Screen

Fields:

- Name
- Description
- Category
- Frequency
- Reminder Time
- Priority
- Difficulty

Button:

- Save
- Cancel

---

### 5.3 Habit Detail Screen

Hiển thị:

- Habit information
- Status
- Completion history
- Current streak
- Total completed days

Actions:

- Mark as completed
- Edit
- Pause / Resume
- Archive
- Delete

---

### 5.4 AI Suggest Habit Screen

Fields:

- Goal input

Button:

- Generate Suggestions

Result:

- AI suggested habits
- Add selected habits

---

## 6. Main Use Cases

### Use Case 1: Create Habit

Actor: User

Trigger:

User opens Habit List screen and clicks Add Habit.

Description:

This feature allows user to create a new habit.

Main Flow:

1. User clicks Add Habit.
2. System displays Create Habit screen.
3. User enters habit information.
4. User clicks Save.
5. System validates input.
6. System saves habit to Firestore.
7. System displays success message.
8. System redirects user to Habit List screen.

Exception Flow:

- If habit name is empty, display error message.
- If saving to Firestore fails, display error message.

---

### Use Case 2: View Habit List

Actor: User

Trigger:

User opens Habit Management screen.

Description:

This feature allows user to view all personal habits.

Main Flow:

1. User opens Habit List screen.
2. System gets current userId from Firebase Auth.
3. System queries habits from Firestore by userId.
4. System displays habit list.
5. User can search, filter or sort habits.

Exception Flow:

- If no habit exists, display empty state.
- If Firestore query fails, display error message.

---

### Use Case 3: View Habit Detail

Actor: User

Trigger:

User clicks a habit in the habit list.

Description:

This feature allows user to view full habit information.

Main Flow:

1. User selects a habit.
2. System gets habit detail from Firestore.
3. System gets related completion records.
4. System displays habit detail and progress.

Exception Flow:

- If habit does not exist, display not found message.

---

### Use Case 4: Update Habit

Actor: User

Trigger:

User clicks Edit in Habit Detail screen.

Description:

This feature allows user to update habit information.

Main Flow:

1. User clicks Edit.
2. System displays current habit information.
3. User updates habit fields.
4. User clicks Save.
5. System validates input.
6. System updates habit in Firestore.
7. System displays success message.

Exception Flow:

- If habit name is empty, display error message.
- If update fails, display error message.

---

### Use Case 5: Delete Habit

Actor: User

Trigger:

User clicks Delete habit.

Description:

This feature allows user to delete a habit using soft delete.

Main Flow:

1. User clicks Delete.
2. System displays confirmation dialog.
3. User confirms delete.
4. System updates isDeleted = true and status = Deleted.
5. System hides habit from main list.
6. System displays success message.

Exception Flow:

- If user cancels, no data is changed.
- If delete fails, display error message.

---

### Use Case 6: Pause Habit

Actor: User

Trigger:

User clicks Pause habit.

Description:

This feature allows user to temporarily pause a habit.

Main Flow:

1. User clicks Pause.
2. System updates status = Paused.
3. System hides habit from today task list.
4. System displays success message.

---

### Use Case 7: Resume Habit

Actor: User

Trigger:

User clicks Resume habit.

Description:

This feature allows user to continue a paused habit.

Main Flow:

1. User clicks Resume.
2. System updates status = Active.
3. System displays habit again in active list.
4. System displays success message.

---

### Use Case 8: Archive Habit

Actor: User

Trigger:

User clicks Archive habit.

Description:

This feature allows user to archive a habit that is no longer active.

Main Flow:

1. User clicks Archive.
2. System updates status = Archived.
3. System removes habit from active list.
4. System keeps habit history.

---

### Use Case 9: Create Habit From Template

Actor: User

Trigger:

User opens Habit Template screen.

Description:

This feature allows user to quickly create a habit from available templates.

Main Flow:

1. User opens template list.
2. System displays available habit templates.
3. User selects one template.
4. System fills habit form using template data.
5. User can customize the information.
6. User clicks Save.
7. System creates habit in Firestore.

---

### Use Case 10: AI Suggest Habits From Goal

Actor: User

Trigger:

User opens AI Suggest Habit screen.

Description:

This feature allows user to generate habit suggestions by entering a personal goal.

Main Flow:

1. User enters personal goal.
2. User clicks Generate Suggestions.
3. System sends goal to AI service.
4. AI returns suggested habits.
5. System displays the suggested habits.
6. User selects habits.
7. System saves selected habits to Firestore.

Exception Flow:

- If AI service fails, display error message.
- If user does not select any habit, disable Add button.

---

## 7. Simple API / Firebase Service Functions

Because this project uses Firebase, REST API is optional.

Recommended frontend service functions:

```ts
createHabit(userId, habitData)
getHabitsByUser(userId)
getHabitById(habitId)
updateHabit(habitId, habitData)
deleteHabit(habitId)
pauseHabit(habitId)
resumeHabit(habitId)
archiveHabit(habitId)
getHabitTemplates()
createHabitFromTemplate(userId, templateId)
generateHabitSuggestions(goalText)
markHabitCompleted(userId, habitId, date, note)
getHabitCompletions(habitId)
```

---

## 8. Firestore Security Rules Suggestion

Basic rule:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /habits/{habitId} {
      allow read, create: if request.auth != null;
      allow update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }

    match /habit_completions/{completionId} {
      allow read, create: if request.auth != null;
      allow update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
    }

    match /habit_templates/{templateId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

Note:

For better security, create rule should check request.resource.data.userId == request.auth.uid.

---

## 9. Recommended Implementation Scope For School Project

Must have:

- Create Habit
- View Habit List
- View Habit Detail
- Update Habit
- Delete Habit
- Mark Habit Completed

Should have:

- Pause / Resume Habit
- Archive Habit
- Habit Template
- Search / Filter

Nice to have:

- AI Habit Suggestion
- AI Habit Coach
- Completion Statistics

Do not overcomplicate:

- Group habit
- Leaderboard
- Payment
- Marketplace
- Complex gamification

---

## 10. Prompt For Codex

Implement Habit Management Module for a school project using Firebase.

Tech stack:

- Firebase Authentication
- Cloud Firestore
- Frontend framework of current project

Requirements:

- Create habit
- View habit list
- View habit detail
- Update habit
- Soft delete habit
- Pause habit
- Resume habit
- Archive habit
- Create habit from template
- Mark habit as completed
- View completion history
- AI habit suggestion from user goal if possible

Firestore collections:

- users
- habits
- habit_templates
- habit_completions

Please create clean, simple and maintainable code.

Use Firebase Auth current user uid as userId.

Do not create unnecessary backend REST API unless needed.

Use soft delete instead of hard delete.

Validate required fields before saving.

Add loading, success and error states.

Make the UI suitable for a habit tracking app.
