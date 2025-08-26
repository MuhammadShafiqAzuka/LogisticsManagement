import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logistic_management/features/admin%20/model/driver.dart';
import '../../../core/widgets/driver_form_page.dart';
import '../provider/driver_notifer.dart';

class AllDriversPage extends ConsumerStatefulWidget {
  const AllDriversPage({super.key});

  @override
  ConsumerState<AllDriversPage> createState() => _AllDriversPageState();
}

class _AllDriversPageState extends ConsumerState<AllDriversPage> {
  late ScrollController _scrollController;
  bool _showFab = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > lastOffset && _showFab) {
        setState(() => _showFab = false); // scrolling down
      } else if (offset < lastOffset && !_showFab) {
        setState(() => _showFab = true); // scrolling up
      }
      lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(driverNotifierProvider);
    final notifier = ref.read(driverNotifierProvider.notifier);

    return Scaffold(
      body: driversState.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return const Center(child: Text('No drivers found.'));
          }
          return ListView.separated(
            controller: _scrollController, // attach controller
            padding: const EdgeInsets.all(12),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: driver.profilePhoto.startsWith('assets')
                        ? AssetImage(driver.profilePhoto) as ImageProvider
                        : FileImage(File(driver.profilePhoto)),
                  ),
                  title: Text(driver.email),
                  subtitle: Text(
                      '${driver.vehicle.name} • ${driver.vehicle.registrationNumber}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverFormPage(driver: driver),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          notifier.deleteDriver(driver.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
        const Center(child: CircularProgressIndicator()), // Loading state
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/*
floatingActionButton: _showFab
          ? FloatingActionButton.extended(
        onPressed: () async {
          final newDriver = await Navigator.push<Driver>(
            context,
            MaterialPageRoute(builder: (_) => const DriverFormPage()),
          );
          if (newDriver != null) {
            notifier.addDriver(newDriver);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Driver"),
      )
          : null,
 */