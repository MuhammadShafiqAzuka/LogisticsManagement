import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logistic_management/core/constants/const.dart';
import '../../features/admin /model/document.dart';
import '../../features/admin /model/driver.dart';
import '../../features/admin /model/vehicle.dart';
import '../../features/admin /provider/driver_notifer.dart';

class DriverFormPage extends ConsumerStatefulWidget {
  final Driver? driver;
  const DriverFormPage({super.key, this.driver});

  @override
  ConsumerState<DriverFormPage> createState() => _DriverFormPageState();
}

class _DriverFormPageState extends ConsumerState<DriverFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _icController;
  late TextEditingController _vehicleNameController;
  late TextEditingController _vehicleRegController;
  late TextEditingController _vehicleTypeController;

  String? _profilePhotoPath;
  String? _icPhotoPath;
  String? _licencePhotoPath;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.driver?.email ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phoneNumber ?? '');
    _icController = TextEditingController(text: widget.driver?.icNumber ?? '');
    _vehicleNameController = TextEditingController(text: widget.driver?.vehicle?.name ?? '');
    _vehicleRegController = TextEditingController(text: widget.driver?.vehicle?.registrationNumber ?? '');
    _vehicleTypeController = TextEditingController(text: widget.driver?.vehicle?.type ?? '');

    _profilePhotoPath = widget.driver?.profilePhoto;
    _icPhotoPath = widget.driver?.document?.icPhoto;
    _licencePhotoPath = widget.driver?.document?.licencePhoto;
  }

  /// Helper function: safely load image from path or default asset
  ImageProvider<Object> safeImageProvider(String? path, {String defaultAsset = 'assets/default_driver.png'}) {
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return FileImage(File(path));
    } else {
      return AssetImage(defaultAsset);
    }
  }

  Future<void> _pickImage(Function(String) onImagePicked) async {
    final granted = await checkAndRequestPermissions(isDriver: false);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery permission is required")),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => onImagePicked(pickedFile.path));
    }
  }

  Widget _buildImagePicker({
    required String label,
    required String? currentPath,
    required Function(String) onPicked,
    bool isCircle = false,
    String defaultAsset = 'assets/default_driver.png',
  }) {
    return GestureDetector(
      onTap: () => _pickImage(onPicked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          isCircle
              ? CircleAvatar(
            radius: 50,
            backgroundImage: safeImageProvider(currentPath, defaultAsset: defaultAsset),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          )
              : Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: safeImageProvider(currentPath, defaultAsset: defaultAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: currentPath == null
                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.driver != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Driver" : "Add Driver"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// Profile Photo
              Center(
                child: _buildImagePicker(
                  label: "Profile Photo",
                  currentPath: _profilePhotoPath,
                  onPicked: (path) => _profilePhotoPath = path,
                  isCircle: true,
                  defaultAsset: 'assets/default_driver.png',
                ),
              ),
              const SizedBox(height: 20),

              /// Document Photos Section
              Column(
                children: [
                  _buildImagePicker(
                    label: "IC Photo",
                    currentPath: _icPhotoPath,
                    onPicked: (path) => _icPhotoPath = path,
                    defaultAsset: 'assets/ic_default.png',
                  ),
                  const SizedBox(height: 16),
                  _buildImagePicker(
                    label: "Licence Photo",
                    currentPath: _licencePhotoPath,
                    onPicked: (path) => _licencePhotoPath = path,
                    defaultAsset: 'assets/licence_default.png',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Driver Info
              Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter phone" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _icController,
                    decoration: const InputDecoration(labelText: "IC Number", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter IC number" : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Vehicle Info
              Column(
                children: [
                  TextFormField(
                    controller: _vehicleNameController,
                    decoration: const InputDecoration(labelText: "Vehicle Name", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter vehicle name" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleRegController,
                    decoration: const InputDecoration(labelText: "Registration Number", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Enter vehicle registration number" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _vehicleTypeController.text.isNotEmpty ? _vehicleTypeController.text : null,
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
                    validator: (val) => val == null || val.isEmpty ? "Select vehicle type" : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 24),

              /// Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isSaving = true);

                      // Only create Document if at least one photo is picked
                      Document? document;
                      if (_licencePhotoPath != null || _icPhotoPath != null) {
                        document = Document(
                          licencePhoto: _licencePhotoPath,
                          icPhoto: _icPhotoPath,
                        );
                      }

                      final newDriver = Driver(
                        id: widget.driver?.id ?? '-1',
                        icNumber: _icController.text,
                        email: _emailController.text,
                        passwordHash: widget.driver?.passwordHash ?? 'hashed_pw',
                        phoneNumber: _phoneController.text,
                        // Only save profilePhoto if user picked one
                        profilePhoto: _profilePhotoPath,
                        vehicle: Vehicle(
                          name: _vehicleNameController.text,
                          registrationNumber: _vehicleRegController.text,
                          type: _vehicleTypeController.text,
                        ),
                        document: document,
                        activeStocks: widget.driver?.activeStocks ?? [],
                        previousStocks: widget.driver?.previousStocks ?? [],
                      );

                      final notifier = ref.read(driverNotifierProvider.notifier);
                      if (widget.driver == null) {
                        await notifier.addDriver(newDriver);
                      } else {
                        await notifier.updateDriver(newDriver);
                      }

                      setState(() => isSaving = false);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(isEdit ? "Save Changes" : "Add Driver"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
