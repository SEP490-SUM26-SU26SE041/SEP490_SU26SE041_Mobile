import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ai_scan_repository.dart';
import '../../data/mock_ai_scan.dart';

/// ─── Providers ────────────────────────────────────────────────────────────────

final aiScanRepositoryProvider = Provider<AiScanRepository>((ref) {
  return AiScanRepository();
});

/// Trạng thái scan hiện tại (per plantType).
sealed class AiScanState {}

class AiScanInitial extends AiScanState {}

class AiScanLoading extends AiScanState {}

class AiScanSuccess extends AiScanState {
  AiScanSuccess({required this.result});
  final DiseaseResult result;
}

class AiScanError extends AiScanState {
  AiScanError({required this.message});
  final String message;
}

/// Notifier quản lý trạng thái AI scan **riêng biệt cho từng plantType**.
///
/// Mỗi plantType ('tomato' / 'pest') có state độc lập, tránh tình trạng:
///   • Scan tomato bị 500 → state lỗi ảnh hưởng sang tab pest
///   • Scan pest xong → tab tomato hiển thị nhầm kết quả pest
class AiScanNotifier extends StateNotifier<Map<String, AiScanState>> {
  AiScanNotifier(this._ref)
      : super({'tomato': AiScanInitial(), 'pest': AiScanInitial()});

  final Ref _ref;

  /// Thực hiện scan với ảnh từ device.
  Future<void> scanImage(File imageFile, {required String plantType}) async {
    state = {...state, plantType: AiScanLoading()};

    try {
      final repo = _ref.read(aiScanRepositoryProvider);
      final scanResult =
          await repo.scanImage(imageFile, plantType: plantType);

      if (scanResult.result != null) {
        state = {
          ...state,
          plantType: AiScanSuccess(result: scanResult.result!),
        };
      } else {
        state = {
          ...state,
          plantType: AiScanError(
            message: scanResult.errorMessage ?? 'Không thể phân tích ảnh.',
          ),
        };
      }
    } catch (e) {
      state = {
        ...state,
        plantType: AiScanError(message: 'Lỗi: ${e.toString()}'),
      };
    }
  }

  /// Reset state cho một plantType cụ thể (hoặc cả hai nếu null).
  void reset([String? plantType]) {
    if (plantType == null) {
      state = {'tomato': AiScanInitial(), 'pest': AiScanInitial()};
    } else {
      state = {...state, plantType: AiScanInitial()};
    }
  }
}

final aiScanProvider =
    StateNotifierProvider<AiScanNotifier, Map<String, AiScanState>>((ref) {
  return AiScanNotifier(ref);
});

/// Provider helper: lấy state cho một plantType cụ thể.
final aiScanStateProvider = Provider.family<AiScanState, String>((ref, plantType) {
  final map = ref.watch(aiScanProvider);
  return map[plantType] ?? AiScanInitial();
});

/// Provider trả về result hiện tại (cho một plantType).
final aiScanResultProvider = Provider.family<DiseaseResult?, String>((ref, plantType) {
  final state = ref.watch(aiScanStateProvider(plantType));
  return switch (state) {
    AiScanSuccess(result: final r) => r,
    _ => null,
  };
});
