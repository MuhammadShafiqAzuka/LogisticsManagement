import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/admin /model/stock.dart';
import '../../../core/constants/const.dart';

class StockFormPage extends StatefulWidget {
  final Stock? stock;
  const StockFormPage({super.key, this.stock});

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  //String? _photoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.stock?.name ?? '');
    //_photoPath = widget.stock?.photo;
  }

  Future<void> _pickImage() async {
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
      //setState(() => _photoPath = pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.stock != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Stock' : 'Add Stock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image picker
              // GestureDetector(
              //   onTap: _pickImage,
              //   child: Container(
              //     height: 150,
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.grey.shade400),
              //       borderRadius: BorderRadius.circular(8),
              //       image: _photoPath != null
              //           ? DecorationImage(
              //         image: _photoPath!.startsWith('assets/')
              //             ? AssetImage(_photoPath!) as ImageProvider
              //             : FileImage(File(_photoPath!)),
              //         fit: BoxFit.cover,
              //       )
              //           : null,
              //     ),
              //     child: _photoPath == null
              //         ? const Center(
              //       child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
              //     )
              //         : null,
              //   ),
              // ),
              // const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Stock Name'),
                validator: (val) => val!.isEmpty ? "Enter stock name" : null,
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newStock = Stock(
                      id: widget.stock?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                    );
                    Navigator.pop(context, newStock);
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Stock'),
              )
            ],
          ),
        ),
      ),
    );
  }
}