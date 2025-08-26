import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/widgets/stock_form_page.dart';
import '../model/stock.dart';
import '../provider/stock_notifier.dart';

class AllStockPage extends ConsumerWidget {
  const AllStockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stockNotifierProvider);
    final notifier = ref.read(stockNotifierProvider.notifier);

    return Scaffold(
      body: stocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stocks) {
          if (stocks.isEmpty) {
            return const Center(
              child: Text(
                'No stocks found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: stocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return Card(
                child: ListTile(
                  title: Text(stock.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockFormPage(stock: stock),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          notifier.deleteStock(stock.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newStock = await Navigator.push<Stock>(
            context,
            MaterialPageRoute(builder: (_) => const StockFormPage()),
          );
          if (newStock != null) {
            notifier.addStock(newStock);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Stock"),
      )
    );
  }
}