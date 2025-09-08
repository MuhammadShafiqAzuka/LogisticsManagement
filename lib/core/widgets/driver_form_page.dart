import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/admin /model/driver.dart';
import '../../features/admin /model/vehicle.dart';
import '../../features/admin /provider/driver_notifer.dart';

class DriverFormPage extends ConsumerStatefulWidget {
  final Driver driver;
  const DriverFormPage({super.key, required this.driver});

  @override
  ConsumerState<DriverFormPage> createState() => _DriverFormPageState();
}

class _DriverFormPageState extends ConsumerState<DriverFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vehicleNameController;
  late TextEditingController _vehicleRegController;
  late TextEditingController _vehicleTypeController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _vehicleNameController =
        TextEditingController(text: widget.driver.vehicle?.name ?? '');
    _vehicleRegController =
        TextEditingController(text: widget.driver.vehicle?.registrationNumber ?? '');
    _vehicleTypeController =
        TextEditingController(text: widget.driver.vehicle?.type ?? '');
  }

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleRegController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  Widget _readOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      readOnly: true,
    );
  }

  Widget _buildCircularImage(String? imageUrl, {double size = 100, String fallbackAsset = 'assets/licence1.jpg'}) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(fallbackAsset, fit: BoxFit.cover);
          },
        )
            : Image.asset(fallbackAsset, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildRectangularImage(String? imageUrl, {double height = 120, String fallbackAsset = 'assets/licence2.jpg'}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallbackAsset, fit: BoxFit.cover);
        },
      )
          : Image.asset(fallbackAsset, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Info")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ==== Profile Photo ====
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Profile Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildCircularImage(
                    widget.driver.profilePhoto,
                    fallbackAsset: 'assets/default_driver.png',
                  ),
                  const SizedBox(height: 12),
                ],
              ),

              // ==== Document Photos ====
              Text("IC Photo", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildRectangularImage(
                widget.driver.document?.icPhoto,
                fallbackAsset: 'assets/licence1.jpg',
              ),
              const SizedBox(height: 12),

              Text("Licence Photo", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildRectangularImage(
                widget.driver.document?.licencePhoto,
                fallbackAsset: 'assets/licence2.jpg',
              ),
              const SizedBox(height: 12),
              // ==== Driver Info (Read-only) ====
              _readOnlyField("Email", widget.driver.email),
              const SizedBox(height: 12),
              _readOnlyField("Phone", widget.driver.phoneNumber),
              const SizedBox(height: 12),
              _readOnlyField("IC Number", widget.driver.icNumber),
              const SizedBox(height: 20),

              // ==== Vehicle Info (Editable) ====
              TextFormField(
                controller: _vehicleNameController,
                decoration: const InputDecoration(
                    labelText: "Vehicle Name", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter vehicle name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleRegController,
                decoration: const InputDecoration(
                    labelText: "Registration Number", border: OutlineInputBorder()),
                validator: (val) =>
                val!.isEmpty ? "Enter vehicle registration number" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _vehicleTypeController.text.isNotEmpty
                    ? _vehicleTypeController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: "Vehicle Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Frozen", child: Text("Frozen")),
                  DropdownMenuItem(value: "Chilled", child: Text("Chilled")),
                  DropdownMenuItem(value: "Dry", child: Text("Dry")),
                ],
                onChanged: (val) {
                  setState(() {
                    _vehicleTypeController.text = val!;
                  });
                },
                validator: (val) =>
                val == null || val.isEmpty ? "Select vehicle type" : null,
              ),
              const SizedBox(height: 24),

              // ==== Save Button ====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isSaving = true);

                      // Update only vehicle info
                      final updatedDriver = widget.driver.copyWith(
                        vehicle: Vehicle(
                          name: _vehicleNameController.text,
                          registrationNumber: _vehicleRegController.text,
                          type: _vehicleTypeController.text,
                        ),
                      );

                      final notifier =
                      ref.read(driverNotifierProvider.notifier);
                      await notifier.updateDriver(updatedDriver);

                      setState(() => isSaving = false);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text("Save Vehicle Info"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
