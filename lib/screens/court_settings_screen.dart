// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ehjez_admin/models/admin_court.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourtSettingsScreen extends ConsumerWidget {
  final String courtId;
  const CourtSettingsScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(courtSettingsProvider(courtId));

    return Scaffold(
      appBar: AppBar(title: const Text('Court Settings')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (data) => _SettingsForm(
          courtId: courtId,
          initialCourt: data.court,
          initialSizePrices: data.sizePrices,
          onSaved: () {
            // Refresh home screen court name + settings data
            ref.invalidate(currentCourtProvider);
            ref.invalidate(courtSettingsProvider(courtId));
          },
        ),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _SettingsForm extends StatefulWidget {
  final String courtId;
  final AdminCourt initialCourt;
  final List<Map<String, dynamic>> initialSizePrices;
  final VoidCallback onSaved;

  const _SettingsForm({
    required this.courtId,
    required this.initialCourt,
    required this.initialSizePrices,
    required this.onSaved,
  });

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  // ── Basic info ──────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _locationCtrl;

  // ── Hours ───────────────────────────────────────────────────────────────────
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  // ── Working days (ISO: 1=Mon … 7=Sun) ──────────────────────────────────────
  late Set<int> _workingDays;

  // ── Pricing rows ────────────────────────────────────────────────────────────
  // Each entry: { 'id' (int|null), 'size', 'sizeCtrl'(new rows only),
  //               'price1Ctrl', 'price2Ctrl', 'fieldsCtrl', 'isNew' (bool) }
  // id == null  →  row not yet persisted (added locally, save will INSERT)
  // isNew       →  shows size name as editable text field
  late final List<Map<String, dynamic>> _priceRows;

  // ── Images ──────────────────────────────────────────────────────────────────
  late List<String?> _imageUrls; // index 0-2 → image_url, image2_url, image3_url
  final List<bool> _imageUploading = [false, false, false];

  bool _saving = false;

  static const _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    final c = widget.initialCourt;

    _nameCtrl = TextEditingController(text: c.name);
    _categoryCtrl = TextEditingController(text: c.category ?? '');
    _locationCtrl = TextEditingController(text: c.location ?? '');

    _startTime = _parseTime(c.startTime) ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = _parseTime(c.endTime) ?? const TimeOfDay(hour: 22, minute: 0);

    _workingDays = Set<int>.from(c.workingDays);

    _priceRows = widget.initialSizePrices.map((row) {
      return <String, dynamic>{
        'id': row['id'] as int,
        'size': row['size'] as String,
        'sizeCtrl': TextEditingController(text: row['size'] as String),
        'price1Ctrl': TextEditingController(
          text: (row['price1'] as num?)?.toString() ?? '',
        ),
        'price2Ctrl': TextEditingController(
          text: (row['price2'] as num?)?.toString() ?? '',
        ),
        'fieldsCtrl': TextEditingController(
          text: (row['number_of_fields'] as num?)?.toString() ?? '1',
        ),
        'isNew': false,
      };
    }).toList();

    _imageUrls = [c.imageUrl, c.image2Url, c.image3Url];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _locationCtrl.dispose();
    for (final row in _priceRows) {
      (row['sizeCtrl'] as TextEditingController).dispose();
      (row['price1Ctrl'] as TextEditingController).dispose();
      (row['price2Ctrl'] as TextEditingController).dispose();
      (row['fieldsCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  // ── Time picker ─────────────────────────────────────────────────────────────

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  // ── Image upload ─────────────────────────────────────────────────────────────
  //
  // Uses dart:html directly instead of image_picker — more reliable on Flutter
  // web since we control the file input lifecycle ourselves.

  Future<void> _pickAndUploadImage(int slot) async {
    // 1. Open a native file-input dialog and wait for the user's selection.
    final picked = await _pickFileWeb();
    if (picked == null || !mounted) return;

    // 2. Show uploading indicator only after a file is actually chosen.
    setState(() => _imageUploading[slot] = true);
    try {
      final url = await CourtService.uploadCourtImage(
        widget.courtId,
        slot + 1,
        picked.bytes,
        picked.ext,
      );
      // Persist the URL immediately.
      await CourtService.updateCourt(
        widget.courtId,
        imageUrl: slot == 0 ? url : null,
        image2Url: slot == 1 ? url : null,
        image3Url: slot == 2 ? url : null,
      );
      if (mounted) {
        setState(() => _imageUrls[slot] = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _imageUploading[slot] = false);
    }
  }

  /// Opens a browser file-input restricted to images and returns the selected
  /// file's bytes + extension. Returns null if the user cancels.
  Future<({Uint8List bytes, String ext})?> _pickFileWeb() {
    final completer = Completer<({Uint8List bytes, String ext})?>();

    final input = html.FileUploadInputElement()..accept = 'image/*';

    // Listen before clicking so the event is always captured.
    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();

      reader.onLoad.listen((_) {
        final result = reader.result;
        final Uint8List bytes;
        if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }
        final ext =
            file.name.contains('.') ? file.name.split('.').last : 'jpg';
        if (!completer.isCompleted) {
          completer.complete((bytes: bytes, ext: ext));
        }
      });

      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });

      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }

  // ── Size management ──────────────────────────────────────────────────────────

  void _addSize() {
    setState(() {
      _priceRows.add(<String, dynamic>{
        'id': null, // not yet in DB
        'size': '',
        'sizeCtrl': TextEditingController(),
        'price1Ctrl': TextEditingController(),
        'price2Ctrl': TextEditingController(),
        'fieldsCtrl': TextEditingController(text: '1'),
        'isNew': true,
      });
    });
  }

  Future<void> _removeSize(int index) async {
    final row = _priceRows[index];
    final size = (row['isNew'] as bool)
        ? (row['sizeCtrl'] as TextEditingController).text.trim()
        : row['size'] as String;
    final isNew = row['isNew'] as bool;

    // New rows (never saved) can be removed without any DB check
    if (isNew) {
      _disposeRow(row);
      setState(() => _priceRows.removeAt(index));
      return;
    }

    // Existing rows: confirm, then check for upcoming reservations
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove size?'),
        content: Text(
          'Are you sure you want to remove the "$size" size?\n\n'
          'This cannot be undone. Any upcoming reservations for this size '
          'must be cleared first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Check upcoming reservations via RPC
    setState(() => _saving = true);
    try {
      final count = await CourtService.getUpcomingReservationCountForSize(
        widget.courtId,
        size,
      );
      if (count > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot remove "$size" — it has $count upcoming '
              '${count == 1 ? 'reservation' : 'reservations'}. '
              'Cancel them first.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      await CourtService.deleteSizePrice(row['id'] as int);
      _disposeRow(row);
      setState(() => _priceRows.removeAt(index));
      widget.onSaved(); // refresh parent providers
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$size" removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove size: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _disposeRow(Map<String, dynamic> row) {
    (row['sizeCtrl'] as TextEditingController).dispose();
    (row['price1Ctrl'] as TextEditingController).dispose();
    (row['price2Ctrl'] as TextEditingController).dispose();
    (row['fieldsCtrl'] as TextEditingController).dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  /// Returns a human-readable error string, or null if everything is valid.
  String? _validate() {
    // Court name is required
    if (_nameCtrl.text.trim().isEmpty) {
      return 'Court name cannot be empty.';
    }

    // End time must be after start time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      return 'Closing time must be after opening time.';
    }

    // At least one working day
    if (_workingDays.isEmpty) {
      return 'Select at least one working day.';
    }

    // No duplicate size names
    final allSizeNames = _priceRows.map((row) {
      final isNew = row['isNew'] as bool;
      return isNew
          ? (row['sizeCtrl'] as TextEditingController).text.trim().toLowerCase()
          : (row['size'] as String).toLowerCase();
    }).toList();
    if (allSizeNames.length != allSizeNames.toSet().length) {
      return 'Each size must have a unique name.';
    }

    // Per-size row validations
    for (final row in _priceRows) {
      final isNew = row['isNew'] as bool;
      final size = isNew
          ? (row['sizeCtrl'] as TextEditingController).text.trim()
          : row['size'] as String;

      if (isNew && size.isEmpty) {
        return 'Size name cannot be empty.';
      }

      final p1Text = (row['price1Ctrl'] as TextEditingController).text.trim();
      final p2Text = (row['price2Ctrl'] as TextEditingController).text.trim();
      final fText = (row['fieldsCtrl'] as TextEditingController).text.trim();

      // Prices — must be a non-negative number if provided
      for (final entry in [('Weekday price', p1Text), ('Weekend price', p2Text)]) {
        final label = entry.$1;
        final val = entry.$2;
        if (val.isNotEmpty) {
          final d = double.tryParse(val);
          if (d == null) return '$label for "$size" must be a valid number.';
          if (d < 0) return '$label for "$size" cannot be negative.';
        }
      }

      // Number of fields — required, integer, minimum 1
      if (fText.isEmpty) {
        return 'Number of fields for "$size" is required.';
      }
      final fields = int.tryParse(fText);
      if (fields == null) {
        return 'Number of fields for "$size" must be a whole number.';
      }
      if (fields < 1) {
        return 'Number of fields for "$size" must be at least 1.';
      }
    }

    return null;
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1. Update main court row
      await CourtService.updateCourt(
        widget.courtId,
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        workingDays: _workingDays.toList()..sort(),
      );

      // 2. Insert new rows / update existing rows
      for (var i = 0; i < _priceRows.length; i++) {
        final row = _priceRows[i];
        final isNew = row['isNew'] as bool;
        final p1 = double.tryParse(
          (row['price1Ctrl'] as TextEditingController).text,
        );
        final p2 = double.tryParse(
          (row['price2Ctrl'] as TextEditingController).text,
        );
        final fields = int.tryParse(
          (row['fieldsCtrl'] as TextEditingController).text,
        );

        if (isNew) {
          final sizeName =
              (row['sizeCtrl'] as TextEditingController).text.trim();
          await CourtService.addSizePrice(
            widget.courtId,
            size: sizeName,
            price1: p1,
            price2: p2,
            numberOfFields: fields ?? 1,
          );
          // Mark as persisted so re-saves update instead of inserting again.
          // We don't have the new id here, so we reload via onSaved below.
        } else {
          await CourtService.updateSizePrice(
            row['id'] as int,
            price1: p1,
            price2: p2,
            numberOfFields: fields,
          );
        }
      }

      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  _basicInfoCard(),
                  const SizedBox(height: 16),
                  _hoursCard(),
                  const SizedBox(height: 16),
                  _workingDaysCard(),
                  const SizedBox(height: 16),
                  _pricingCard(),
                  const SizedBox(height: 16),
                  _photosCard(),
                  const SizedBox(height: 16),
                  _vacationDaysButton(),
                ],
              ),
            ),
          ),
        ),
        // Floating save bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF068631),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vacationDaysButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () =>
            context.push('/vacation-days/${widget.courtId}'),
        icon: const Icon(Icons.beach_access_outlined, size: 16),
        label: const Text('Manage Vacation Days'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade300),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  // ── Section cards ─────────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF068631),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _basicInfoCard() => _sectionCard(
        title: 'Basic Information',
        child: Column(
          children: [
            _labeledField('Court Name', _nameCtrl),
            const SizedBox(height: 12),
            _labeledField('Category', _categoryCtrl,
                hint: 'e.g. Football, Basketball'),
            const SizedBox(height: 12),
            _labeledField('Location', _locationCtrl,
                hint: 'Address or area'),
          ],
        ),
      );

  Widget _hoursCard() => _sectionCard(
        title: 'Opening Hours',
        child: Row(
          children: [
            Expanded(
              child: _timeTile(
                label: 'Opening time',
                time: _startTime,
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _timeTile(
                label: 'Closing time',
                time: _endTime,
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
      );

  Widget _workingDaysCard() => _sectionCard(
        title: 'Working Days',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dayLabels.entries.map((entry) {
            final selected = _workingDays.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _workingDays.add(entry.key);
                  } else {
                    _workingDays.remove(entry.key);
                  }
                });
              },
              selectedColor: const Color(0xFF068631).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF068631),
            );
          }).toList(),
        ),
      );

  Widget _pricingCard() => _sectionCard(
        title: 'Sizes & Pricing',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._priceRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isNew = row['isNew'] as bool;
              final sizeName = isNew
                  ? null
                  : row['size'] as String;
              final sizeCtrl = row['sizeCtrl'] as TextEditingController;
              final p1c = row['price1Ctrl'] as TextEditingController;
              final p2c = row['price2Ctrl'] as TextEditingController;
              final fc = row['fieldsCtrl'] as TextEditingController;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isNew
                        ? const Color(0xFF068631)
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isNew
                      ? const Color(0xFF068631).withValues(alpha: 0.03)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNew)
                          Expanded(
                            child: TextFormField(
                              controller: sizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Size name (e.g. 5v5)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              sizeName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Remove this size',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: _saving
                              ? null
                              : () => _removeSize(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _numField(
                            label: 'Price (1 hr)',
                            ctrl: p1c,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _numField(
                            label: 'Price (2 hr)',
                            ctrl: p2c,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: _numField(
                            label: 'Fields',
                            ctrl: fc,
                            isInt: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _saving ? null : _addSize,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Size'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF068631),
                side: const BorderSide(color: Color(0xFF068631)),
              ),
            ),
          ],
        ),
      );

  Widget _photosCard() => _sectionCard(
        title: 'Court Photos',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (i) => _imageSlot(i))
              .expand((w) => [w, const SizedBox(width: 12)])
              .take(5)
              .toList(),
        ),
      );

  // ── Small helpers ─────────────────────────────────────────────────────────

  Widget _labeledField(
    String label,
    TextEditingController ctrl, {
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController ctrl,
    String? prefix,
    bool isInt = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF068631)),
                const SizedBox(width: 6),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSlot(int slot) {
    final url = _imageUrls[slot];
    final uploading = _imageUploading[slot];
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(slot),
                    )
                  : _imagePlaceholder(slot),
            ),
            // Uploading overlay
            if (uploading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            // Change button
            if (!uploading)
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _pickAndUploadImage(slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(int slot) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 32, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text(
            'Photo ${slot + 1}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
