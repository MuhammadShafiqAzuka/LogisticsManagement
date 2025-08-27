import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../core/constants/const.dart';
import '../../../core/widgets/job_map_page.dart';
import '../../admin /model/job.dart';
import '../providers/driver_job_provider.dart';
import '../providers/driver_job_status_notifer.dart';
import 'package:badges/badges.dart' as badges;

import '../providers/tracking_enable_provider.dart';

class MyJobsPage extends ConsumerWidget {
  final String driverId;
  const MyJobsPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Jobs"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Consumer(
              builder: (context, ref, _) {
                final activeCount   = ref.watch(activeJobsProvider(driverId)).length;
                final finishedCount = ref.watch(finishedJobsProvider(driverId)).length;
                final pendingCount  = ref.watch(pendingJobsProvider(driverId)).length;
                final returnedCount = ref.watch(returnedJobsProvider(driverId)).length;

                return TabBar(
                  isScrollable: true,
                  tabs: [
                    _buildTabWithBadge("Active", activeCount, Colors.orange),
                    _buildTabWithBadge("Finished", finishedCount, Colors.green),
                    _buildTabWithBadge("Pending", pendingCount, Colors.blue),
                    _buildTabWithBadge("Returned", returnedCount, Colors.red),
                  ],
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobList(context, ref.watch(activeJobsProvider(driverId)), ref),
            _buildJobList(context, ref.watch(finishedJobsProvider(driverId)), ref),
            _buildJobList(context, ref.watch(pendingJobsProvider(driverId)), ref),
            _buildJobList(context, ref.watch(returnedJobsProvider(driverId)), ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(String title, int count, Color color) {
    return badges.Badge(
      showBadge: count > 0,
      position: badges.BadgePosition.topEnd(top: -10, end: -20),
      badgeStyle: badges.BadgeStyle(
        badgeColor: color,
        padding: const EdgeInsets.all(6),
      ),
      badgeContent: Text(
        count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      child: Tab(text: title),
    );
  }

  Widget _buildJobList(BuildContext context, List<Job2> jobs, WidgetRef ref) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No jobs.'));
    }

    // ✅ Sort by date (most recent first)
    jobs.sort((a, b) => b.date.compareTo(a.date));

    // ✅ Group by time difference
    final Map<String, List<Job2>> groupedJobs = {};
    final now = DateTime.now();

    for (var job in jobs) {
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
        group = DateFormat("MMMM dd, yyyy").format(job.date); // fallback
      }

      groupedJobs.putIfAbsent(group, () => []).add(job);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: groupedJobs.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map((job) => _buildJobCard(context, ref, job)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildJobCard(BuildContext context, WidgetRef ref, Job2 job) {
    final jobUpdate = job.status == 'active'
        ? ref.watch(jobStatusProvider.select((map) => map[job.id]))
        : null;

    final trackingEnabled = ref.watch(trackingEnabledProvider).value ?? false;
    final currentStatus = jobUpdate?.status ?? job.status;
    final style = statusStyle(currentStatus);
    final formattedDate = DateFormat('EEEE, dd/MM/yyyy, HH:mm').format(job.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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

            // ORDER DETAILS
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
            // TIME & DRIVER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Due: ${job.dueDate.toLocal().toString().split(' ')[0]}"),
                Text("Window: ${job.timeWindow}"),
              ],
            ),
            const SizedBox(height: 6),

            const Divider(height: 20),

            // 🔹 Action Buttons (logic preserved)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStatus == 'active') ...[
                  OutlinedButton.icon(
                    onPressed: trackingEnabled
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobMapPage(job: job),
                        ),
                      );
                    }
                        : null, // disabled if tracking off
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Map'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showUpdateDeliveryDialog(context, ref, job.id);
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('Update Delivery'),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      _showStatusDetailsDialog(
                        context,
                        job,
                        currentStatus,
                        jobUpdate?.proofPath ?? job.proof?.proofPhoto,
                        jobUpdate?.signatureBytes,
                        job.proof?.proofSignature,
                        jobUpdate?.reason ?? job.proof?.proofReason,
                        formattedDate,
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                  ),
                  OutlinedButton.icon(
                    onPressed: trackingEnabled
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobMapPage(
                            job: job,
                            showNavigation: false,
                          ),
                        ),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Delivery'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImage(String? proofPath, {bool isLocal = false}) {
    if (proofPath == null) return const SizedBox();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.maxFinite,
        child: isLocal
            ? Image.file(
          File(proofPath),
          height: 150,
          fit: BoxFit.cover,
        )
            : Image.asset(
          proofPath,
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _openFinishOrPendingSheet({required BuildContext context, required WidgetRef ref, required String jobId,  required CompleteMode mode}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FinishOrPendingSheet(
        jobId: jobId,
        mode: mode,
        onSubmit: (proofPath, signatureBytes, reason) {
          String status;
          switch (mode) {
            case CompleteMode.finished:
              status = 'finished';
              break;
            case CompleteMode.pending:
              status = 'pending';
              break;
            case CompleteMode.returned:
              status = 'returned';
              break;
          }

          ref.read(jobStatusProvider.notifier).updateStatus(
            jobId,
            status,
            proofPath: proofPath,
            signatureBytes: signatureBytes,
            reason: reason?.isNotEmpty == true ? reason : null,
          );
        },
      ),
    );
  }

  void _showUpdateDeliveryDialog(BuildContext context, WidgetRef ref, String jobId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Delivery"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFinishOrPendingSheet(
                context: context,
                ref: ref,
                jobId: jobId,
                mode: CompleteMode.finished,
              );
            },
            child: const Text("Success"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFinishOrPendingSheet(
                context: context,
                ref: ref,
                jobId: jobId,
                mode: CompleteMode.pending,
              );
            },
            child: const Text("Pending"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFinishOrPendingSheet(
                context: context,
                ref: ref,
                jobId: jobId,
                mode: CompleteMode.returned,
              );
            },
            child: const Text("Returned"),
          ),
        ],
      ),
    );
  }

  void _showStatusDetailsDialog(BuildContext context, Job2 job, String status, String? proofPath, Uint8List? signatureBytes, String? signatureProof, String? reason, String formattedDate) {
    IconData icon;
    Color color;
    String title;

    switch (status) {
      case 'finished':
        icon = Icons.check_circle;
        color = Colors.green;
        title = "Finished Job";
        break;
      case 'pending':
        icon = Icons.pending_actions;
        color = Colors.blue;
        title = "Pending Job";
        break;
      case 'returned':
        icon = Icons.undo;
        color = Colors.red;
        title = "Returned Job";
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blueGrey;
        title = "Job Details";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status == 'finished') ...[
                Text("Completed on: $formattedDate"),
                const SizedBox(height: 12),
                if (proofPath != null)
                  _buildProofImage(proofPath, isLocal: job.proof?.proofPhoto == null),
                const SizedBox(height: 12),
                if (signatureBytes != null)
                  Image.memory(signatureBytes, height: 150, fit: BoxFit.cover),
                if (signatureProof != null)
                  Image.asset(signatureProof, height: 150, fit: BoxFit.cover),
              ],
              if (status == 'pending' || status == 'returned') ...[
                Text("Reason: ${reason ?? 'No reason provided'}"),
                const SizedBox(height: 12),
                if (proofPath != null)
                  _buildProofImage(proofPath, isLocal: job.proof?.proofPhoto == null),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FinishOrPendingSheet extends StatefulWidget {
  final String jobId;
  final CompleteMode mode;
  final void Function(String? proofPath, Uint8List? signatureBytes, String? reason) onSubmit;

  const _FinishOrPendingSheet({
    required this.jobId,
    required this.mode,
    required this.onSubmit,
  });

  @override
  State<_FinishOrPendingSheet> createState() => _FinishOrPendingSheetState();
}

class _FinishOrPendingSheetState extends State<_FinishOrPendingSheet> {
  final GlobalKey<SfSignaturePadState> _sigKey = GlobalKey<SfSignaturePadState>();
  final TextEditingController _reasonCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _proofPath;
  bool _submitting = false;
  bool _hasSignature = false;

  bool get _isReadyToSubmit {
    switch (widget.mode) {
      case CompleteMode.finished:
        return _proofPath != null && _hasSignature;
      case CompleteMode.pending:
      case CompleteMode.returned:
        return _reasonCtrl.text.isNotEmpty;
      }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _proofPath = picked.path);
    }
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      Uint8List? signatureBytes;

      if (widget.mode == CompleteMode.finished) {
        final ui.Image? sigImage = await _sigKey.currentState?.toImage(pixelRatio: 3.0);
        final byteData = await sigImage?.toByteData(format: ui.ImageByteFormat.png);
        signatureBytes = byteData?.buffer.asUint8List();
      }

      widget.onSubmit(
        _proofPath,
        signatureBytes,
        (widget.mode == CompleteMode.pending || widget.mode == CompleteMode.returned)
            ? _reasonCtrl.text
            : null,
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.mode == CompleteMode.pending;
    final isReturned = widget.mode == CompleteMode.returned;
    final isFinished = widget.mode == CompleteMode.finished;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPending
                    ? 'Mark as Pending'
                    : isReturned
                    ? 'Mark as Returned'
                    : isFinished
                    ? 'Mark as Finished'
                    : 'Complete Delivery',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              if (isPending || isReturned) ...[
                const Text('Reason'),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],


              if (isFinished) ...[
                const Text('Proof of Delivery (Photo)'),
                const SizedBox(height: 8),
                if (_proofPath != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_proofPath!), height: 160, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _proofPath = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture / Upload Photo'),
                  ),

                const SizedBox(height: 16),

                const Text('Recipient Signature'),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Listener(
                    onPointerDown: (_) => setState(() => _hasSignature = true), // detect start of signature
                    child: SfSignaturePad(
                      key: _sigKey,
                      backgroundColor: Colors.white,
                      strokeColor: Colors.black,
                      minimumStrokeWidth: 1.5,
                      maximumStrokeWidth: 4.0,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _sigKey.currentState?.clear();
                      setState(() => _hasSignature = false);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting || !_isReadyToSubmit ? null : _handleSubmit,
                  icon: _submitting
                      ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_alt),
                  label: Text(_submitting
                      ? 'Submitting...'
                      : (isPending ? 'Mark Pending' : isReturned ? 'Mark Returned' : 'Mark Finished')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}