import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/admin /model/driver.dart';
import '../../features/admin /model/job.dart';
import '../../features/admin /model/stock.dart';
import '../../features/admin /provider/driver_notifer.dart';
import '../../features/admin /provider/stock_notifier.dart';
import 'location_search_field.dart';

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  double? pickupLat;
  double? pickupLng;
  double? dropoffLat;
  double? dropoffLng;

  String title = '';
  String description = '';
  Driver? selectedDriver;
  List<Stock> selectedStocks = [];
  Map<String, String> othersDetails = {};

  // Error flags
  bool driverError = false;
  bool stockError = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _selectDriver() async {
    final driver = await showDialog<Driver>(
      context: context,
      builder: (context) {
        String searchQuery = '';

        return Consumer(
          builder: (context, ref, _) {
            final driversAsync = ref.watch(driverNotifierProvider);

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 450,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Search driver',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => setStateDialog(() => searchQuery = val),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: driversAsync.when(
                            data: (driversList) {
                              final filteredDrivers = driversList
                                  .where((d) => d.email.toLowerCase().contains(searchQuery.toLowerCase()))
                                  .toList();
                              if (filteredDrivers.isEmpty) {
                                return const Center(child: Text('No drivers found'));
                              }
                              return ListView.separated(
                                itemCount: filteredDrivers.length,
                                itemBuilder: (context, index) {
                                  final driver = filteredDrivers[index];
                                  return ListTile(
                                    title: Text(driver.email),
                                    subtitle: Text(driver.vehicle!.registrationNumber),
                                    onTap: () => Navigator.pop(context, driver),
                                  );
                                },
                                separatorBuilder: (context, index) => const Divider(), // <-- separator
                              );

                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (driver != null) {
      setState(() {
        selectedDriver = driver;
        driverError = false;
      });
    }
  }

  Future<void> _selectStocks() async {
    final stocks = await showDialog<List<Stock>>(
      context: context,
      builder: (context) {
        List<String> tempSelectedIds = selectedStocks.map((s) => s.id).toList();
        String searchQuery = '';

        return Consumer( // <-- This is the fix
          builder: (context, ref, _) {
            final stocksAsync = ref.watch(stockNotifierProvider);

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 450,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (tempSelectedIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${tempSelectedIds.length} selected',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Search stocks',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => setStateDialog(() => searchQuery = val),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: stocksAsync.when(
                            data: (stocksList) {
                              final filteredStocks = stocksList
                                  .where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()))
                                  .toList();
                              if (filteredStocks.isEmpty) return const Center(child: Text('No stocks found'));
                              return ListView(
                                children: filteredStocks.map((stock) {
                                  final isSelected = tempSelectedIds.contains(stock.id);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        value: isSelected,
                                        title: Text(stock.name),
                                        tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                                        onChanged: (selected) {
                                          setStateDialog(() {
                                            if (selected == true) {
                                              tempSelectedIds.add(stock.id);
                                              if (stock.name.toLowerCase() == 'others') {
                                                othersDetails[stock.id] = ''; // initialize
                                              }
                                            } else {
                                              tempSelectedIds.remove(stock.id);
                                              othersDetails.remove(stock.id); // remove if unselected
                                            }
                                          });
                                        },
                                      ),
                                      if (isSelected && stock.name.toLowerCase() == 'others')
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Please enter details',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (val) {
                                              setStateDialog(() {
                                                othersDetails[stock.id] = val;
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                final selected = stocksAsync.maybeWhen(
                                  data: (s) => s.where((st) => tempSelectedIds.contains(st.id)).toList(),
                                  orElse: () => <Stock>[],
                                );
                                Navigator.pop(context, selected);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (stocks != null) {
      setState(() {
        selectedStocks = stocks;
        stockError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Job')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
                onSaved: (v) => title = v!,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
                onSaved: (v) => description = v!,
              ),
              const SizedBox(height: 16),

              // Driver selection card
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: GestureDetector(
                  onTap: _selectDriver,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: driverError ? Colors.red : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              selectedDriver?.email ?? 'Select Driver',
                              key: ValueKey(selectedDriver?.id ?? 'no_driver'),
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedDriver != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (driverError)
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Text('Please select a driver', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),

              // Stocks selection card
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: GestureDetector(
                  onTap: _selectStocks,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: stockError ? Colors.red : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              selectedStocks.isEmpty
                                  ? 'Select Stocks'
                                  : '${selectedStocks.length} Stocks selected',
                              key: ValueKey(selectedStocks.length),
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedStocks.isNotEmpty ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: selectedStocks.map((s) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Chip(
                                  key: ValueKey(s.id), // Important for AnimatedSwitcher to track
                                  label: Text(s.name),
                                  onDeleted: () {
                                    setState(() {
                                      selectedStocks.remove(s);
                                      if (selectedStocks.isNotEmpty) stockError = false;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (stockError)
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Text('Please select at least one stock', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 32),

              // Pickup
              LocationSearchField(
                label: "Pickup Location",
                onSelected: (address, lat, lng) {
                  setState(() {
                    _pickupController.text = address;
                    pickupLat = lat;
                    pickupLng = lng;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Drop-off
              LocationSearchField(
                label: "Drop-off Location",
                onSelected: (address, lat, lng) {
                  setState(() {
                    _dropoffController.text = address;
                    dropoffLat = lat;
                    dropoffLng = lng;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Create Job button
              ElevatedButton(
                onPressed: () {
                  final formValid = _formKey.currentState!.validate();
                  final driverValid = selectedDriver != null;
                  final stocksValid = selectedStocks.isNotEmpty;

                  setState(() {
                    driverError = !driverValid;
                    stockError = !stocksValid;
                  });

                  if (formValid && driverValid && stocksValid) {
                    _formKey.currentState!.save();
                    final job = Job(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      driverId: selectedDriver!.id,
                      pickupLocation: _pickupController.text,
                      pickupLatLng: LatLngPoint(latitude: pickupLat ?? 0, longitude: pickupLng ?? 0),
                      dropoffLocation: _dropoffController.text,
                      dropoffLatLng: LatLngPoint(latitude: dropoffLat ?? 0, longitude: dropoffLng ?? 0),
                      status: 'active',
                      date: DateTime.now(),
                      stocks: selectedStocks.map((s) {
                        if (s.name.toLowerCase() == 'others') {
                          return Stock(
                            id: s.id,
                            name: s.name,
                            details: othersDetails[s.id] ?? '',
                          );
                        }
                        return s;
                      }).toList(),
                    );
                    Navigator.pop(context, job);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Job', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}