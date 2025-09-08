import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../features/admin /model/driver.dart';
import '../../features/admin /model/job.dart';
import '../../features/admin /provider/driver_notifer.dart';
import '../../features/admin /provider/job2_notifer.dart';
import '../constants/const.dart';
import 'package:timeline_tile/timeline_tile.dart';

class ImportJobPage extends ConsumerStatefulWidget {
  const ImportJobPage({super.key});

  @override
  ConsumerState<ImportJobPage> createState() => _ImportJobPageState();
}

class _ImportJobPageState extends ConsumerState<ImportJobPage> {
  List<Job2> importedJobs = [];
  bool isSaving = false;

  // ✅ Round-robin index tracker per vehicle type
  final Map<String, int> assignmentIndexByType = {};

  Driver _selectDriverForJob(Map<String, dynamic> jobData, List<Driver> drivers) {
    final storageCondition =
    (jobData["Storage Condition"]?.toString().trim() ?? "");

    final Map<String, String> conditionToVehicle = {
      "Chilled": "Cold",
      "Frozen": "Freezer",
      "Dry": "Dry",
    };

    final requiredType = conditionToVehicle[storageCondition];

    // Filter drivers by vehicle type
    final matchingDrivers = requiredType == null
        ? drivers
        : drivers
        .where((d) =>
    d.vehicle?.type.toLowerCase() == requiredType.toLowerCase())
        .toList();

    if (matchingDrivers.isEmpty) {
      // fallback → just return first driver if available
      return drivers.isNotEmpty ? drivers.first : Driver.empty();
    }

    if (requiredType == null) {
      // If no mapping, still do round robin on all drivers
      final index = assignmentIndexByType["any"] ?? 0;
      final driver = matchingDrivers[index % matchingDrivers.length];
      assignmentIndexByType["any"] = index + 1;
      return driver;
    }

    // Round robin within matching type
    final index = assignmentIndexByType[requiredType] ?? 0;
    final driver = matchingDrivers[index % matchingDrivers.length];
    assignmentIndexByType[requiredType] = index + 1;

    return driver;
  }

  Future<void> pickAndImportFile() async {
     await checkAndRequestPermissions(isDriver: false);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);

    // 👇 get drivers from provider (unwrap AsyncValue)
    final driverState = ref.read(driverNotifierProvider);
    final drivers = driverState.value ?? [];

    if (file.path.endsWith('.csv')) {
      await _importCsv(file, drivers);
    } else {
      await _importExcel(file, drivers);
    }

    setState(() {});
  }

  Future<void> _importExcel(File file, List<Driver> drivers) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables[excel.tables.keys.first]!;
    final headers =
    sheet.rows.first.map((cell) => cell?.value.toString().trim() ?? "").toList();

    final jobsFromExcel = <Map<String, dynamic>>[];

    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      final rowMap = <String, dynamic>{};
      for (int c = 0; c < headers.length; c++) {
        rowMap[headers[c]] = row[c]?.value;
      }
      jobsFromExcel.add(rowMap);
    }

    for (int i = 0; i < jobsFromExcel.length; i++) {
      final driver = _selectDriverForJob(jobsFromExcel[i], drivers);

      final job = Job2.fromExcelRow(jobsFromExcel[i], driver.id).copyWith(
        status: "active",
        date: DateTime.now(),
        proof: null,
      );

      importedJobs.add(job);
    }
  }

  Future<void> _importCsv(File file, List<Driver> drivers) async {
    final csvContent = await file.readAsString();
    final rows = const CsvToListConverter().convert(csvContent);

    final headers = rows.first.map((h) => h.toString().trim()).toList();

    final jobsFromCsv = <Map<String, dynamic>>[];

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;

      final rowMap = <String, dynamic>{};
      for (int c = 0; c < headers.length; c++) {
        rowMap[headers[c]] = row[c];
      }
      jobsFromCsv.add(rowMap);
    }

    for (int i = 0; i < jobsFromCsv.length; i++) {
      final driver = _selectDriverForJob(jobsFromCsv[i], drivers);

      final job = Job2.fromExcelRow(jobsFromCsv[i], driver.id).copyWith(
        status: "active",
        date: DateTime.now(),
        proof: null,
      );

      importedJobs.add(job);
    }
  }

  Future<void> _saveAll() async {
    if (importedJobs.isEmpty) return;
    setState(() => isSaving = true);
    await ref.read(job2NotifierProvider.notifier).addJobs(importedJobs);
    setState(() => isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bulk Import Jobs"),
        actions: [
          IconButton(
            onPressed: pickAndImportFile,
            icon: const Icon(Icons.upload),
          ),
        ],
      ),
      body: importedJobs.isEmpty
          ? const Center(child: Text("No jobs imported yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: importedJobs.length,
        itemBuilder: (context, index) {
          final job = importedJobs[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${job.id}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Chip(
                        label: Text(
                          job.status.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: job.status == "active"
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// PICKUP & DROPOFF (TIMELINE)
                  Column(
                    children: [
                      TimelineTile(
                        isFirst: true,
                        alignment: TimelineAlign.start,
                        lineXY: 0.1,
                        indicatorStyle: IndicatorStyle(
                          color: Colors.green,
                          width: 20,
                          iconStyle: IconStyle(
                            iconData: Icons.store,
                            color: Colors.white,
                          ),
                        ),
                        endChild: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Pickup: ${job.pickupLocation}\n(${job.pickupLatLng.latitude}, ${job.pickupLatLng.longitude})",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        beforeLineStyle: LineStyle(
                          color: Colors.grey.shade400,
                          thickness: 2,
                        ),
                      ),
                      TimelineTile(
                        isLast: true,
                        alignment: TimelineAlign.start,
                        lineXY: 0.1,
                        indicatorStyle: IndicatorStyle(
                          color: Colors.red,
                          width: 20,
                          iconStyle: IconStyle(
                            iconData: Icons.location_on,
                            color: Colors.white,
                          ),
                        ),
                        endChild: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Dropoff: ${job.dropoffLocation}\n(${job.dropoffLatLng.latitude}, ${job.dropoffLatLng.longitude})",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        beforeLineStyle: LineStyle(
                          color: Colors.grey.shade400,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  /// CUSTOMER INFO
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Customer Ref: ${job.customerRef}\nAddress: ${job.address}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  /// ORDER DETAILS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Type: ${job.orderType}"),
                      Text("Amount: ${job.orderAmount}"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Price: RM${job.price}"),
                      Text("Weight: ${job.weight} kg"),
                    ],
                  ),

                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Storage Condition: ${job.stocks}"),
                    ],
                  ),

                  /// TIME & DRIVER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Due: ${job.dueDate.toLocal().toString().split(' ')[0]}",
                      ),
                      Text("Window: ${job.timeWindow}"),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Assigned Driver: ${job.driverId}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: importedJobs.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: isSaving ? null : _saveAll,
        icon: isSaving
            ? const CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2)
            : const Icon(Icons.save),
        label: Text(isSaving ? "Saving..." : "Save All"),
      )
          : null,
    );
  }
}