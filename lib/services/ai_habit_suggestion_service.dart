import '../models/ai_habit_suggestion_model.dart';
import '../models/habit_model.dart';

class AiHabitSuggestionService {
  Future<List<AiHabitSuggestionModel>> generateSuggestions(String goal) async {
    final normalizedGoal = goal.trim().toLowerCase();
    if (normalizedGoal.isEmpty) {
      throw ArgumentError('Goal is required.');
    }

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (_containsAny(normalizedGoal, ['anh', 'english', 'toeic', 'ielts'])) {
      return const [
        AiHabitSuggestionModel(
          name: 'Học 10 từ vựng tiếng Anh',
          description: 'Ghi lại 10 từ mới, ví dụ và ôn lại vào cuối ngày.',
          category: 'Học tập',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.high,
          difficulty: HabitDifficulty.easy,
          reminderTime: '20:00',
          reason: 'Nhỏ, đều và dễ duy trì để tăng vốn từ mỗi ngày.',
        ),
        AiHabitSuggestionModel(
          name: 'Nghe tiếng Anh 15 phút',
          description: 'Nghe podcast hoặc video ngắn bằng tiếng Anh.',
          category: 'Học tập',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.easy,
          reminderTime: '21:00',
          reason: 'Tăng khả năng nghe mà không cần phiên học quá dài.',
        ),
        AiHabitSuggestionModel(
          name: 'Luyện nói 5 phút',
          description: 'Nói lại một chủ đề ngắn hoặc tự ghi âm câu trả lời.',
          category: 'Học tập',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.medium,
          reminderTime: '21:30',
          reason: 'Giúp chuyển kiến thức thụ động thành phản xạ nói.',
        ),
      ];
    }

    if (_containsAny(normalizedGoal, ['sức khỏe', 'khoe', 'fitness', 'giảm cân', 'gym', 'tập'])) {
      return const [
        AiHabitSuggestionModel(
          name: 'Đi bộ 20 phút',
          description: 'Đi bộ nhẹ hoặc nhanh tùy thể trạng trong ngày.',
          category: 'Sức khỏe',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.high,
          difficulty: HabitDifficulty.easy,
          reminderTime: '07:00',
          reason: 'Hoạt động đơn giản, ít rào cản và dễ duy trì.',
        ),
        AiHabitSuggestionModel(
          name: 'Uống đủ nước',
          description: 'Uống nước đều trong ngày, ưu tiên sau khi thức dậy.',
          category: 'Sức khỏe',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.easy,
          reminderTime: '08:00',
          reason: 'Hỗ trợ năng lượng, tập trung và phục hồi cơ thể.',
        ),
        AiHabitSuggestionModel(
          name: 'Chuẩn bị bữa ăn lành mạnh',
          description: 'Chọn trước một bữa ăn ít đồ chiên và nhiều rau.',
          category: 'Sức khỏe',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.medium,
          reminderTime: '18:00',
          reason: 'Giúp mục tiêu sức khỏe không phụ thuộc vào quyết định vội.',
        ),
      ];
    }

    if (_containsAny(normalizedGoal, ['ngủ', 'sleep', 'mệt', 'năng lượng'])) {
      return const [
        AiHabitSuggestionModel(
          name: 'Tắt màn hình trước khi ngủ',
          description: 'Dừng điện thoại và máy tính 30 phút trước giờ ngủ.',
          category: 'Sức khỏe',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.high,
          difficulty: HabitDifficulty.medium,
          reminderTime: '22:00',
          reason: 'Giảm kích thích não bộ để dễ ngủ hơn.',
        ),
        AiHabitSuggestionModel(
          name: 'Chuẩn bị giấc ngủ',
          description: 'Dọn giường, giảm ánh sáng và thư giãn vài phút.',
          category: 'Sức khỏe',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.easy,
          reminderTime: '22:15',
          reason: 'Tạo tín hiệu lặp lại để cơ thể vào nhịp nghỉ.',
        ),
        AiHabitSuggestionModel(
          name: 'Ghi nhanh việc ngày mai',
          description: 'Viết 3 việc cần làm để giảm suy nghĩ trước khi ngủ.',
          category: 'Tinh thần',
          frequency: HabitFrequency.daily,
          priority: HabitPriority.medium,
          difficulty: HabitDifficulty.easy,
          reminderTime: '21:45',
          reason: 'Giúp đầu óc nhẹ hơn và ngủ ổn định hơn.',
        ),
      ];
    }

    return [
      AiHabitSuggestionModel(
        name: 'Dành 15 phút cho mục tiêu',
        description: 'Làm một bước nhỏ liên quan đến: ${goal.trim()}.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.daily,
        priority: HabitPriority.high,
        difficulty: HabitDifficulty.easy,
        reminderTime: '20:00',
        reason: 'Biến mục tiêu lớn thành hành động hằng ngày.',
      ),
      const AiHabitSuggestionModel(
        name: 'Ghi lại tiến độ cuối ngày',
        description: 'Viết 2-3 dòng về việc đã làm và bước tiếp theo.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.daily,
        priority: HabitPriority.medium,
        difficulty: HabitDifficulty.easy,
        reminderTime: '21:30',
        reason: 'Theo dõi giúp bạn thấy tiến bộ và điều chỉnh sớm.',
      ),
      const AiHabitSuggestionModel(
        name: 'Ôn lại kế hoạch tuần',
        description: 'Mỗi tuần xem lại điều gì hiệu quả và điều gì cần đổi.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.weekly,
        priority: HabitPriority.medium,
        difficulty: HabitDifficulty.medium,
        reminderTime: '19:00',
        reason: 'Giữ mục tiêu đúng hướng thay vì chỉ làm theo quán tính.',
      ),
    ];
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
