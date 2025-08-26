import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/stock_repository.dart';
import '../model/stock.dart';

class StockNotifier extends StateNotifier<AsyncValue<List<Stock>>> {
  final StockRepository repository;

  StockNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadStocks();
  }

  Future<void> loadStocks() async {
    state = const AsyncValue.loading();
    try {
      final stocks = await repository.getAllStock();
      state = AsyncValue.data(stocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addStock(Stock stock) {
    state.whenData((stocks) => state = AsyncValue.data([...stocks, stock]));
  }

  void updateStock(Stock updated) {
    state.whenData((stocks) {
      final newList = [
        for (final stock in stocks)
          if (stock.id == updated.id) updated else stock
      ];
      state = AsyncValue.data(newList);
    });
  }

  void deleteStock(String id) {
    state.whenData((stocks) => state = AsyncValue.data(stocks.where((s) => s.id != id).toList()));
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});

final stockNotifierProvider = StateNotifierProvider<StockNotifier, AsyncValue<List<Stock>>>((ref) {
  final repo = ref.read(stockRepositoryProvider);
  return StockNotifier(repo);
});
