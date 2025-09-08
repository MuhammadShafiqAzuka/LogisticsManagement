import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../admin /model/document.dart';
import '../../admin /model/driver.dart';
import '../../admin /model/vehicle.dart';
import '../../admin /provider/driver_notifer.dart';
import '../../../core/constants/const.dart';

class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage> {
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
  bool _initialized = false;

  bool isSaving = false;
  bool _hasChanges = false;

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController()..addListener(_markChanged);
    _phoneController = TextEditingController()..addListener(_markChanged);
    _icController = TextEditingController()..addListener(_markChanged);
    _vehicleNameController = TextEditingController()..addListener(_markChanged);
    _vehicleRegController = TextEditingController()..addListener(_markChanged);
    _vehicleTypeController = TextEditingController()..addListener(_markChanged);
  }

  Future<void> _pickImage(Function(String) onImagePicked) async {
    final granted = await checkAndRequestPermissions(isDriver: true);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery permission is required")),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        onImagePicked(pickedFile.path);
        _markChanged();
      });
    }
  }

  /// Circle image picker (Profile photo)
  Widget _buildCircleImagePicker({
    required String label,
    required String? currentPath,
    required Function(String) onPicked,
    String defaultAsset = 'assets/default_driver.png',
  }) {
    return GestureDetector(
      onTap: () => _pickImage(onPicked),
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 100,
              height: 100,
              child: currentPath != null
                  ? Image.network(
                currentPath,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(defaultAsset, fit: BoxFit.cover);
                }
              ): Image.asset(defaultAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Rectangle image picker (IC / Licence)
  Widget _buildRectImagePicker({
    required String label,
    required String? currentPath,
    required Function(String) onPicked,
    String defaultAsset = 'assets/placeholder.png',
  }) {
    return GestureDetector(
      onTap: () => _pickImage(onPicked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: currentPath != null
                ? Image.network(
              currentPath,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(defaultAsset, fit: BoxFit.cover);
              },
            )
                : Image.asset(defaultAsset, fit: BoxFit.cover),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _saveProfile(Driver? oldDriver) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final storage = StorageService();

    String? uploadedProfileUrl;
    String? uploadedIcUrl;
    String? uploadedLicenceUrl;

    if (_profilePhotoPath != null && File(_profilePhotoPath!).existsSync()) {
      uploadedProfileUrl = await storage.uploadDriverFile(
        driverId: uid,
        file: File(_profilePhotoPath!),
        fileName: "profile.jpg",
      );
    }

    if (_icPhotoPath != null && File(_icPhotoPath!).existsSync()) {
      uploadedIcUrl = await storage.uploadDriverFile(
        driverId: uid,
        file: File(_icPhotoPath!),
        fileName: "ic.jpg",
      );
    }

    if (_licencePhotoPath != null && File(_licencePhotoPath!).existsSync()) {
      uploadedLicenceUrl = await storage.uploadDriverFile(
        driverId: uid,
        file: File(_licencePhotoPath!),
        fileName: "licence.jpg",
      );
    }

    Document? document;
    if (uploadedIcUrl != null || uploadedLicenceUrl != null) {
      document = Document(
        icPhoto: uploadedIcUrl,
        licencePhoto: uploadedLicenceUrl,
      );
    }

    final newDriver = Driver(
      id: uid,
      icNumber: _icController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      profilePhoto: uploadedProfileUrl ?? oldDriver?.profilePhoto,
      vehicle: Vehicle(
        name: _vehicleNameController.text,
        registrationNumber: _vehicleRegController.text,
        type: _vehicleTypeController.text,
      ),
      document: document ?? oldDriver?.document,
      activeStocks: oldDriver?.activeStocks ?? [],
      previousStocks: oldDriver?.previousStocks ?? [],
    );

    final notifier = ref.read(driverNotifierProvider.notifier);
    await notifier.updateDriver(newDriver);

    setState(() {
      isSaving = false;
      _hasChanges = false; // reset after save
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final driverStream =
    ref.read(driverRepositoryProvider).watchCurrentDriver(uid);

    return StreamBuilder<Driver>(
      stream: driverStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text("Driver profile not found")));
        }

        final driver = snapshot.data!;

        if (!_initialized && snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _emailController.text = driver.email;
            _phoneController.text = driver.phoneNumber;
            _icController.text = driver.icNumber ?? '';
            _vehicleNameController.text = driver.vehicle?.name ?? '';
            _vehicleRegController.text = driver.vehicle?.registrationNumber ?? '';
            _vehicleTypeController.text = driver.vehicle?.type ?? '';
            _profilePhotoPath = driver.profilePhoto;
            _icPhotoPath = driver.document?.icPhoto;
            _licencePhotoPath = driver.document?.licencePhoto;

            setState(() {
              _initialized = true;
            });
          });
        }

        return Scaffold(
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// Profile photo
                  Center(
                    child: _buildCircleImagePicker(
                      label: "Profile Photo",
                      currentPath: _profilePhotoPath,
                      onPicked: (path) => _profilePhotoPath = path,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// IC & Licence
                  _buildRectImagePicker(
                    label: "IC Photo",
                    currentPath: _icPhotoPath,
                    onPicked: (path) => _icPhotoPath = path,
                    defaultAsset: 'assets/licence1.jpg',
                  ),
                  const SizedBox(height: 16),
                  _buildRectImagePicker(
                    label: "Licence Photo",
                    currentPath: _licencePhotoPath,
                    onPicked: (path) => _licencePhotoPath = path,
                    defaultAsset: 'assets/licence2.jpg',
                  ),
                  const SizedBox(height: 20),

                  /// Driver Info
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: "Email", border: OutlineInputBorder()),
                    validator: (val) =>
                    val == null || val.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: "Phone", border: OutlineInputBorder()),
                    validator: (val) =>
                    val == null || val.isEmpty ? "Enter phone" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _icController,
                    decoration: const InputDecoration(
                        labelText: "IC Number", border: OutlineInputBorder()),
                    validator: (val) =>
                    val == null || val.isEmpty ? "Enter IC number" : null,
                  ),
                  const SizedBox(height: 20),

                  /// Vehicle Info
                  TextFormField(
                    controller: _vehicleNameController,
                    decoration: const InputDecoration(
                        labelText: "Vehicle Name",
                        border: OutlineInputBorder()),
                    validator: (val) =>
                    val == null || val.isEmpty ? "Enter vehicle name" : null,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleRegController,
                    decoration: const InputDecoration(
                      labelText: "Registration Number",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                    ],
                    validator: (val) => val == null || val.isEmpty
                        ? "Enter vehicle registration number"
                        : null,
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
                        _markChanged();
                      });
                    },
                    validator: (val) => val == null || val.isEmpty
                        ? "Select vehicle type"
                        : null,
                  ),
                  const SizedBox(height: 24),

                  /// Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (!_hasChanges || isSaving)
                          ? null
                          : () => _saveProfile(driver),
                      child: isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}