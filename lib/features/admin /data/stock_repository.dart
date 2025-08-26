import '../model/stock.dart';

class StockRepository {
  final List<Stock> _mockStocks = [
    Stock(id: '1', name: 'Freezer Temperature'),
    Stock(id: '2', name: 'Cold Temperature'),
    Stock(id: '3', name: 'Room Temperature'),
    Stock(id: '4', name: 'Others'),
  ];

  /// Get all stocks for admin
  Future<List<Stock>> getAllStock() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockStocks);
  }

  /// add stock for admin
  void addStock(Stock stock) {
    _mockStocks.add(stock);
  }

  /// update stock for admin
  void updateStock(Stock updated) {
    final index = _mockStocks.indexWhere((s) => s.id == updated.id);
    if (index != -1) _mockStocks[index] = updated;
  }

  /// delete stock for admin
  void deleteStock(String id) {
    _mockStocks.removeWhere((s) => s.id == id);
  }
}