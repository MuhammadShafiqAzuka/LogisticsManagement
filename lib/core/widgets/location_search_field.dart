import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logistic_management/core/constants/const.dart';

class LocationSearchField extends StatefulWidget {
  final String label;
  final Function(String address, double lat, double lng) onSelected;

  const LocationSearchField({
    Key? key,
    required this.label,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  String? _sessionToken;
  final String _apiKey = apiKey;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      setState(() => _suggestions.clear());
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$input"
        "&key=$_apiKey"
        "&components=country:my"
        "&types=geocode";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final predictions = (data['predictions'] as List)
          .take(5) // limit to 5 results
          .map((p) => {
        "description": p['description'],
        "place_id": p['place_id'],
      })
          .toList();
      setState(() => _suggestions = predictions);
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    final detailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=${place['place_id']}"
        "&key=$_apiKey";

    final res = await http.get(Uri.parse(detailsUrl));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final location = data['result']['geometry']['location'];

      // Call the callback
      widget.onSelected(
        place['description'],
        location['lat'],
        location['lng'],
      );

      // Stop listening before setting text
      _controller.removeListener(_onChanged);
      _controller.text = place['description'];
      _controller.addListener(_onChanged);

      // Clear suggestions
      setState(() => _suggestions.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) =>
          value == null || value.isEmpty ? 'Please select location' : null,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  title: Text(place['description']),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
      ],
    );
  }
}