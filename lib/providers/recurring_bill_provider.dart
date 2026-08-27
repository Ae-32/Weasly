import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_bill_model.dart';
import '../services/notification_service.dart';
import '../services/recurring_bill_service.dart';
import 'auth_provider.dart';

final recurringBillServiceProvider = Provider<RecurringBillService>((ref) {
  return RecurringBillService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Live stream provider of all recurring bills for the signed-in user.
final recurringBillsStreamProvider = StreamProvider.autoDispose<List<RecurringBillModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final service = ref.watch(recurringBillServiceProvider);
  return service.getRecurringBillsStream(user.uid);
});

/// Computed provider returning bills due within the next 30 days.
final upcomingBillsProvider = Provider.autoDispose<List<RecurringBillModel>>((ref) {
  final bills = ref.watch(recurringBillsStreamProvider).value ?? [];
  final now = DateTime.now();
  final thirtyDaysFromNow = now.add(const Duration(days: 30));

  return bills.where((b) {
    return b.nextDueDate.isBefore(thirtyDaysFromNow);
  }).toList();
});

class RecurringBillState {
  final bool isLoading;
  final String? error;

  const RecurringBillState({this.isLoading = false, this.error});
}

class RecurringBillController extends StateNotifier<RecurringBillState> {
  final RecurringBillService _service;
  final NotificationService _notificationService;
  final Ref _ref;

  RecurringBillController(this._service, this._notificationService, this._ref)
      : super(const RecurringBillState());

  String? get _userId => _ref.read(authStateProvider).value?.uid;

  Future<bool> addBill(RecurringBillModel bill) async {
    final uid = _userId;
    if (uid == null) {
      state = const RecurringBillState(error: 'User not signed in');
      return false;
    }

    state = const RecurringBillState(isLoading: true);
    try {
      final savedBill = await _service.addRecurringBill(uid, bill);
      await _notificationService.scheduleBillReminder(
        billId: savedBill.id,
        billName: savedBill.name,
        amount: savedBill.amount,
        dueDate: savedBill.nextDueDate,
        reminderDaysBefore: savedBill.reminderDaysBefore,
        isReminderEnabled: savedBill.isReminderEnabled,
      );
      state = const RecurringBillState(isLoading: false);
      return true;
    } catch (e) {
      state = RecurringBillState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateBill(RecurringBillModel bill) async {
    final uid = _userId;
    if (uid == null) {
      state = const RecurringBillState(error: 'User not signed in');
      return false;
    }

    state = const RecurringBillState(isLoading: true);
    try {
      await _service.updateRecurringBill(uid, bill);
      await _notificationService.scheduleBillReminder(
        billId: bill.id,
        billName: bill.name,
        amount: bill.amount,
        dueDate: bill.nextDueDate,
        reminderDaysBefore: bill.reminderDaysBefore,
        isReminderEnabled: bill.isReminderEnabled,
      );
      state = const RecurringBillState(isLoading: false);
      return true;
    } catch (e) {
      state = RecurringBillState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteBill(String billId) async {
    final uid = _userId;
    if (uid == null) {
      state = const RecurringBillState(error: 'User not signed in');
      return false;
    }

    state = const RecurringBillState(isLoading: true);
    try {
      await _service.deleteRecurringBill(uid, billId);
      await _notificationService.cancelBillReminder(billId);
      state = const RecurringBillState(isLoading: false);
      return true;
    } catch (e) {
      state = RecurringBillState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markPaidAndAdvance(RecurringBillModel bill) async {
    final uid = _userId;
    if (uid == null) {
      state = const RecurringBillState(error: 'User not signed in');
      return false;
    }

    state = const RecurringBillState(isLoading: true);
    try {
      final updatedBill = await _service.advanceBillDueDate(uid, bill);
      await _notificationService.scheduleBillReminder(
        billId: updatedBill.id,
        billName: updatedBill.name,
        amount: updatedBill.amount,
        dueDate: updatedBill.nextDueDate,
        reminderDaysBefore: updatedBill.reminderDaysBefore,
        isReminderEnabled: updatedBill.isReminderEnabled,
      );
      state = const RecurringBillState(isLoading: false);
      return true;
    } catch (e) {
      state = RecurringBillState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final recurringBillControllerProvider =
    StateNotifierProvider<RecurringBillController, RecurringBillState>((ref) {
  final service = ref.watch(recurringBillServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return RecurringBillController(service, notificationService, ref);
});
