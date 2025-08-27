import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/const.dart';
import '../../../core/widgets/import_job_page.dart';
import '../../../core/widgets/job_map_page.dart';
import '../model/driver.dart';
import '../model/job.dart';
import '../provider/driver_notifer.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../provider/job2_notifer.dart';

class AllJobPage extends ConsumerStatefulWidget {
  const AllJobPage({super.key});

  @override
  ConsumerState<AllJobPage> createState() => _AllJobPageState();
}

class _AllJobPageState extends ConsumerState<AllJobPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedDriverId;
  late ScrollController _scrollController;
  bool _showFab = true;
  double lastOffset = 0;

  String? selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset > lastOffset && _showFab) {
        setState(() => _showFab = false);
      } else if (offset < lastOffset && !_showFab) {
        setState(() => _showFab = true);
      }
      lastOffset = offset;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(job2NotifierProvider);
    final driversAsync = ref.watch(driverNotifierProvider);

    return Scaffold(
      body: driversAsync.when(
        data: (drivers) {
          final vehicleTypes = drivers.map((d) => d.vehicle!.type).toSet().toList();

          final activeJobs = jobs.where((j) => j.status == 'active').length;
          final pendingJobs = jobs.where((j) => j.status == 'pending').length;
          final returnedJobs = jobs.where((j) => j.status == 'returned').length;
          final finishedJobs = jobs.where((j) => j.status == 'finished').length;

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  _buildTab("Active", Icons.local_shipping, activeJobs, Colors.orange),
                  _buildTab("Pending", Icons.schedule, pendingJobs, Colors.blue),
                  _buildTab("Returned", Icons.undo, returnedJobs, Colors.red),
                  _buildTab("Finished", Icons.check_circle_outline, finishedJobs, Colors.green),
                ],
              ),

              _buildFilters(vehicleTypes),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    JobsTab(status: 'active', driverId: selectedDriverId, scrollController: _scrollController, vehicleFilter: selectedVehicleType),
                    JobsTab(status: 'pending', driverId: selectedDriverId, scrollController: _scrollController, vehicleFilter: selectedVehicleType),
                    JobsTab(status: 'returned', driverId: selectedDriverId, scrollController: _scrollController, vehicleFilter: selectedVehicleType),
                    JobsTab(status: 'finished', driverId: selectedDriverId, scrollController: _scrollController, vehicleFilter: selectedVehicleType),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading drivers: $err')),
      ),
      floatingActionButton: _showFab
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_job_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportJobPage()),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text("Import Jobs"),
          )
        ],
      )
          : null,
    );
  }

  Widget _buildTab(String title, IconData icon, int count, Color badgeColor) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(title),
          if (count > 0)
            Positioned(
              right: -10,
              top: -5,
              child: badges.Badge(
                badgeContent: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: badgeColor,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<String> vehicleTypes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: selectedVehicleType,
            hint: const Text("Vehicle Type"),
            items: ['All', ...vehicleTypes].map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (val) {
              setState(() => selectedVehicleType = val);
            },
          ),
        ],
      ),
    );
  }
}

class JobsTab extends ConsumerWidget {
  final String status;
  final String? driverId;
  final ScrollController scrollController;
  final String? vehicleFilter;

  const JobsTab({
    super.key,
    required this.status,
    required this.driverId,
    required this.scrollController,
    this.vehicleFilter,
  });



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(job2NotifierProvider); // ✅ use job2
    final driversAsync = ref.watch(driverNotifierProvider);

    // Filter jobs
    final filteredJobs = jobs.where((job) {
      if (job.status != status) return false;
      if (driverId != null && job.driverId != driverId) return false;

      // Vehicle filter
      if (vehicleFilter != null && vehicleFilter != 'All') {
        final driver = ref.read(driverNotifierProvider).maybeWhen(
          data: (drivers) => drivers.firstWhere(
                (d) => d.id == job.driverId,
            orElse: () => Driver.empty(),
          ),
          orElse: () => Driver.empty(),
        );
        if (driver.vehicle!.type != vehicleFilter) return false;
      }

      return true;
    }).toList();

    if (filteredJobs.isEmpty) {
      return const Center(child: Text("No jobs found"));
    }

    // Sort by date
    filteredJobs.sort((a, b) => b.date.compareTo(a.date));

    // Group jobs by time
    final Map<String, List<Job2>> groupedJobs = {};
    final now = DateTime.now();
    for (var job in filteredJobs) {
      final difference = now.difference(job.date).inDays;
      String group;
      if (difference == 0) {
        group = "Today";
      } else if (difference == 1) {
        group = "Yesterday";
      } else if (difference < 7) {
        group = "$difference days ago";
      } else if (difference < 30) {
        group = "A week ago";
      } else {
        group = DateFormat("MMMM dd, yyyy").format(job.date);
      }
      groupedJobs.putIfAbsent(group, () => []).add(job);
    }

    return driversAsync.when(
      data: (drivers) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: groupedJobs.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...entry.value.map((job) {
                  final driver = drivers.firstWhere(
                        (d) => d.id == job.driverId,
                    orElse: () => Driver.empty(),
                  );
                  final style = statusStyle(status);

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
                                "Order #${job.id}",
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
                                backgroundColor: style['bg'],
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

                          const Divider(height: 20),

                          Row(
                            children: [
                              /// Profile photo
                              CircleAvatar(
                                backgroundImage: driver.profilePhoto!.startsWith('assets')
                                    ? AssetImage(driver.profilePhoto!) as ImageProvider
                                    : FileImage(File(driver.profilePhoto!)),
                              ),
                              const SizedBox(width: 12),

                              /// Driver details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.email, // or a `driver.name` if you have one
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${driver.vehicle!.name} (${driver.vehicle!.registrationNumber})",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Type: ${driver.vehicle!.type}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // View Map
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobMapPage(
                                        job: job,
                                        showNavigation: false,
                                        isAdmin: true,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('View Delivery'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading drivers: $err')),
    );
  }
}
