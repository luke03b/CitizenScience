import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../providers/app_state_provider.dart';
import '../utils/location_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/error_handler.dart';
import '../l10n/app_locale.dart';

/// Screen for creating a new sighting with photos and location.
/// 
/// Allows users to capture or select photos, set location via GPS or map,
/// add notes, and submit the sighting to the backend.
class CreateSightingScreen extends StatefulWidget {
  const CreateSightingScreen({super.key});

  @override
  State<CreateSightingScreen> createState() => _CreateSightingScreenState();
}

class _CreateSightingScreenState extends State<CreateSightingScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  List<XFile> _selectedImages = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  /// Fetches the current GPS location and updates the text fields.
  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    
    try {
      final result = await LocationUtils.getCurrentLocation();
      
      if (mounted) {
        if (result.success && result.position != null) {
          _latitudeController.text = result.position!.latitude.toStringAsFixed(6);
          _longitudeController.text = result.position!.longitude.toStringAsFixed(6);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? AppLocale.unknownError.getString(context))),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  /// Opens a map dialog for manual location selection.
  Future<void> _pickLocationOnMap() async {
    // Get initial position from text fields or use default
    double initialLat = 45.4642; // Milano default
    double initialLng = 9.1900;
    
    if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
      final lat = double.tryParse(_latitudeController.text);
      final lng = double.tryParse(_longitudeController.text);
      if (lat != null && lng != null) {
        initialLat = lat;
        initialLng = lng;
      }
    }

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapPickerDialog(
        initialPosition: LatLng(initialLat, initialLng),
      ),
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
      });
    }
  }

  /// Captures a photo using the device camera.
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.cameraError.getString(context)),
        ),
      );
    }
  }

  /// Selects one or more photos from the device gallery.
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.galleryError.getString(context)),
        ),
      );
    }
  }

  /// Opens date and time pickers for sighting observation time.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// Validates inputs and submits the sighting to the API.
  Future<void> _submitSighting() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.photoRequired.getString(context))),
      );
      return;
    }

    final validation = ValidationUtils.validateCoordinates(
      _latitudeController.text,
      _longitudeController.text,
    );
    
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.errorMessage!)),
      );
      return;
    }

    final lat = double.parse(_latitudeController.text);
    final lng = double.parse(_longitudeController.text);

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      await appState.createSighting(
        photos: _selectedImages,
        date: _selectedDate,
        latitude: lat,
        longitude: lng,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      final message = appState.isOnline 
          ? AppLocale.creationSuccess.getString(context)
          : AppLocale.savedOffline.getString(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: appState.isOnline ? Colors.green : Colors.orange,
        ),
      );

      // Return true to indicate successful creation
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(context, e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Removes an image from the selected images list.
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.newSighting.getString(context)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _selectedImages.isEmpty
                ? _buildSelectionView()
                : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 100,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 32),
        Text(
          AppLocale.addPhoto.getString(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocale.addPhotoDescription.getString(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: AppLocale.takePhoto.getString(context),
          icon: Icons.camera_alt,
          onPressed: _pickImageFromCamera,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: AppLocale.chooseFromGallery.getString(context),
          icon: Icons.photo_library,
          onPressed: _pickImageFromGallery,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _selectedImages[index].path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocale.addPhoto.getString(context)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocale.fromGallery.getString(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Date picker
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.calendar_today),
            title: Text(AppLocale.dateAndTime.getString(context)),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: _selectDate,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(height: 16),
          
          // Location picker
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.location_on),
            title: Text(AppLocale.location.getString(context)),
            subtitle: Text(
              _latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty
                  ? '${_latitudeController.text}, ${_longitudeController.text}'
                  : AppLocale.selectLocation.getString(context),
            ),
            trailing: const Icon(Icons.edit),
            onTap: _pickLocationOnMap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _locationLoading ? null : _getCurrentLocation,
            icon: _locationLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_locationLoading ? AppLocale.loading.getString(context) : AppLocale.useCurrentLocation.getString(context)),
          ),
          const SizedBox(height: 16),
          
          // Notes field
          CustomTextField(
            controller: _notesController,
            label: AppLocale.notesOptional.getString(context),
            hint: AppLocale.addNotes.getString(context),
            prefixIcon: Icons.notes,
          ),
          const SizedBox(height: 32),
          
          CustomButton(
            text: AppLocale.createSighting.getString(context),
            onPressed: _submitSighting,
            isLoading: _isLoading,
            icon: Icons.check,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: AppLocale.cancel.getString(context),
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}

/// Dialog widget for selecting a location on an interactive map.
class _MapPickerDialog extends StatefulWidget {
  final LatLng initialPosition;

  const _MapPickerDialog({required this.initialPosition});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late MapController _mapController;
  late LatLng _selectedPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Moves map to current GPS location.
  Future<void> _goToCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      final result = await LocationUtils.getCurrentLocation();
      
      if (mounted) {
        if (result.success && result.position != null) {
          final currentLocation = LatLng(
            result.position!.latitude,
            result.position!.longitude,
          );
          setState(() {
            _selectedPosition = currentLocation;
          });
          _mapController.move(currentLocation, 15);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? AppLocale.unknownError.getString(context))),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text(
                    AppLocale.selectLocation.getString(context),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: widget.initialPosition,
                      initialZoom: 13,
                      onTap: (tapPosition, latLng) {
                        setState(() {
                          _selectedPosition = latLng;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.citizen_science',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Current location button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
                      backgroundColor: Colors.white,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
            // Coordinates display and actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${AppLocale.coordinates.getString(context)}: ${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocale.cancel.getString(context)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_selectedPosition),
                        child: Text(AppLocale.confirm.getString(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
