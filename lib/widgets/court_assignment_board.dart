import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/reservation_service.dart';
import 'package:ehjez_admin/services/strike_service.dart';
import 'package:ehjez_admin/widgets/sports_court_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _Booking {
  final int id;
  final int fieldNumber;
  final String startTime;
  final int duration;
  final String size;
  final String name;
  final String phone;

  const _Booking({
    required this.id,
    required this.fieldNumber,
    required this.startTime,
    required this.duration,
    required this.size,
    required this.name,
    required this.phone,
  });

  factory _Booking.fromMap(Map<String, dynamic> r) => _Booking(
        id: r['id'] as int,
        fieldNumber: (r['field_number'] as int?) ?? 1,
        startTime: r['start_time'] as String,
        duration: (r['duration'] as num).toInt(),
        size: r['size'] as String,
        name: r['name'] as String? ?? '—',
        phone: r['phone'] as String? ?? '—',
      );

  int get startHour => int.parse(startTime.split(':')[0]);
  int get startMin => int.parse(startTime.split(':')[1]);

  String get displayTime {
    final start = DateFormat.jm().format(
      DateFormat('HH:mm').parse(
        '$startHour:${startMin.toString().padLeft(2, '0')}',
      ),
    );
    final endDt = DateTime(0, 1, 1, startHour, startMin)
        .add(Duration(hours: duration));
    return '$start – ${DateFormat.jm().format(endDt)}';
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CourtAssignmentBoard extends ConsumerStatefulWidget {
  final String courtId;
  final String courtName;
  final String courtStartTime;
  final String courtEndTime;

  const CourtAssignmentBoard({
    super.key,
    required this.courtId,
    required this.courtName,
    required this.courtStartTime,
    required this.courtEndTime,
  });

  @override
  ConsumerState<CourtAssignmentBoard> createState() =>
      _CourtAssignmentBoardState();
}

class _CourtAssignmentBoardState extends ConsumerState<CourtAssignmentBoard> {
  static const double _hourHeight = 72.0;
  static const double _timeColWidth = 64.0;
  static const double _fieldHeaderHeight = 32.0;
  static const double _fieldHeaderGap = 6.0;

  final ScrollController _vScroll = ScrollController();

  // UI-only state — no server data lives here.
  DateTime _selectedDate = DateTime.now();
  String? _selectedSize;
  _Booking? _selectedBooking;

  static const _blockColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFF57F17),
    Color(0xFF880E4F),
    Color(0xFF4527A0),
  ];
  static const _fieldHeaderColors = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFF8E1),
    Color(0xFFFCE4EC),
    Color(0xFFEDE7F6),
  ];

  int get _startHour => int.parse(widget.courtStartTime.split(':')[0]);
  int get _endHour {
    final h = int.parse(widget.courtEndTime.split(':')[0]);
    return widget.courtEndTime.startsWith('23:59') ? 24 : h;
  }

  int get _totalHours => (_endHour - _startHour).clamp(1, 24);

  @override
  void dispose() {
    _vScroll.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _selectedDateStr =>
      DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _invalidateBookings() {
    final sizes =
        ref.read(courtSizesProvider(widget.courtId)).valueOrNull ?? {};
    final effectiveSize =
        (_selectedSize != null && sizes.containsKey(_selectedSize))
            ? _selectedSize!
            : sizes.keys.firstOrNull;
    if (effectiveSize != null) {
      ref.invalidate(boardBookingsProvider((
        courtId: widget.courtId,
        size: effectiveSize,
        date: _selectedDateStr,
      )));
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddBookingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    Text(
                      S.of(ctx).addBooking,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SportsCourtCalendar(
                  name: widget.courtName,
                  courtId: widget.courtId,
                  onBookingAdded: () {
                    Navigator.of(ctx).pop();
                    _invalidateBookings();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReservation(_Booking booking) async {
    await ReservationService.deleteReservation(booking.id);
    setState(() => _selectedBooking = null);
    _invalidateBookings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).reservationDeleted)),
      );
    }
  }

  /// True when the booking's end time is already in the past.
  bool _isBookingPast(_Booking booking) {
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      booking.startHour,
      booking.startMin,
    ).add(Duration(hours: booking.duration));
    return end.isBefore(DateTime.now());
  }

  Future<void> _noShowReservation(_Booking booking) async {
    await StrikeService.addStrike(
      phone: booking.phone,
      courtId: widget.courtId,
      reservationId: booking.id,
    );
    await ReservationService.deleteReservation(booking.id);
    setState(() => _selectedBooking = null);
    _invalidateBookings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).noShowRecorded(booking.phone)),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  void _showEditDialog(_Booking booking) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _blockColors[
                    (booking.fieldNumber - 1) % _blockColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.fieldN(booking.fieldNumber),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.person_outline, s.nameField, booking.name),
              const SizedBox(height: 10),
              _detailRow(Icons.phone_outlined, s.phoneCol, booking.phone),
              const SizedBox(height: 10),
              _detailRow(Icons.access_time, s.timeCol, booking.displayTime),
              const SizedBox(height: 10),
              _detailRow(Icons.straighten, s.sizeCol, booking.size),
              const SizedBox(height: 10),
              _detailRow(
                Icons.hourglass_bottom,
                s.durationShort,
                s.durationHours(booking.duration),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.close,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          // No-show button — only visible for past bookings
          if (_isBookingPast(booking))
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.person_off_outlined, size: 16),
              label: Text(s.noShow),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(s.markAsNoShow),
                    content: Text(
                        s.noShowDialogBody(booking.name, booking.phone)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(s.cancel),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(s.noShow),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await _noShowReservation(booking);
              },
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(s.delete),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.confirmDeletion),
                  content: Text(
                    s.deleteBookingConfirm(
                        booking.name, booking.displayTime),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(s.cancel),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(s.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await _deleteReservation(booking);
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: ehjezGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatHour(int h) =>
      DateFormat.j().format(DateTime(0, 1, 1, h % 24));

  double _topOffset(int hour, int minute) =>
      (hour - _startHour + minute / 60) * _hourHeight;

  // ── Booking block ─────────────────────────────────────────────────────────

  Widget _bookingBlock(_Booking b) {
    final fieldIndex = b.fieldNumber - 1;
    final color = _blockColors[fieldIndex % _blockColors.length];
    final isSelected = _selectedBooking?.id == b.id;
    final topPx = _topOffset(b.startHour, b.startMin);
    final heightPx = b.duration * _hourHeight - 4;

    return Positioned(
      top: topPx + 2,
      left: 2,
      right: 2,
      height: heightPx,
      child: GestureDetector(
        onTap: () => setState(
          () => _selectedBooking = isSelected ? null : b,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                b.displayTime,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (heightPx > 54)
                Text(
                  b.phone,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vertical grid ─────────────────────────────────────────────────────────

  Widget _buildGrid(List<_Booking> bookings, int numFields) {
    final gridHeight = _totalHours * _hourHeight;
    final timeLabelsHeight = gridHeight + 20;
    final headerSectionHeight = _fieldHeaderHeight + _fieldHeaderGap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _timeColWidth,
          child: Column(
            children: [
              SizedBox(height: headerSectionHeight),
              SizedBox(
                height: timeLabelsHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(
                    _totalHours + 1,
                    (i) => Positioned(
                      top: i * _hourHeight,
                      left: 0,
                      right: 0,
                      child: Text(
                        _formatHour(_startHour + i),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(numFields, (fieldIndex) {
              final fieldNum = fieldIndex + 1;
              final hdrColor =
                  _fieldHeaderColors[fieldIndex % _fieldHeaderColors.length];
              final blkColor =
                  _blockColors[fieldIndex % _blockColors.length];
              final fieldBookings = bookings
                  .where((b) => b.fieldNumber == fieldNum)
                  .toList();

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: _fieldHeaderHeight,
                      margin: const EdgeInsets.only(right: 6, bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: hdrColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        S.of(context).fieldN(fieldNum),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: blkColor,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      height: gridHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ...List.generate(
                            _totalHours,
                            (i) => Positioned(
                              top: i * _hourHeight,
                              left: 0,
                              right: 0,
                              height: 0.5,
                              child: Container(
                                  color: Colors.grey.shade200),
                            ),
                          ),
                          ...fieldBookings.map(_bookingBlock),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sizesAsync = ref.watch(courtSizesProvider(widget.courtId));
    final sizeFields = sizesAsync.valueOrNull ?? {};

    // Derive the effective size: user pick if set, otherwise first available.
    // _selectedSize persists the user's tap across rebuilds.
    final effectiveSize =
        (_selectedSize != null && sizeFields.containsKey(_selectedSize))
            ? _selectedSize!
            : sizeFields.keys.firstOrNull;

    final bookingsAsync = effectiveSize != null
        ? ref.watch(boardBookingsProvider((
            courtId: widget.courtId,
            size: effectiveSize,
            date: _selectedDateStr,
          )))
        : const AsyncData(<Map<String, dynamic>>[]);

    final numFields =
        effectiveSize != null ? (sizeFields[effectiveSize] ?? 1) : 1;
    final bookings =
        bookingsAsync.valueOrNull?.map(_Booking.fromMap).toList() ?? [];

    final isToday = _selectedDateStr ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                s.courtAssignment,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showAddBookingDialog,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: Text(
                  s.addBooking,
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ehjezGreen,
                  side: BorderSide(color: ehjezGreen),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _selectedBooking != null
                      ? () => _showEditDialog(_selectedBooking!)
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: Text(s.edit,
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedBooking != null
                        ? ehjezGreen
                        : Colors.grey.shade300,
                    foregroundColor: _selectedBooking != null
                        ? Colors.white
                        : Colors.grey.shade500,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  isToday
                      ? s.today
                      : DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ehjezGreen,
                  side: BorderSide(color: ehjezGreen),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _invalidateBookings,
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: s.refresh,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),

        // ── Size selector ─────────────────────────────────────────────────
        if (sizeFields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              children: sizeFields.keys.map((size) {
                final selected = size == _selectedSize;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedSize = size;
                    _selectedBooking = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? ehjezGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? ehjezGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      s.sizeWithFields(size, sizeFields[size]!),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Grid ──────────────────────────────────────────────────────────
        if (bookingsAsync.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: Scrollbar(
              controller: _vScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _vScroll,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 24),
                  child: _buildGrid(bookings, numFields),
                ),
              ),
            ),
          ),

        if (!bookingsAsync.isLoading && bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                isToday
                    ? s.noBookingsToday(_selectedSize)
                    : s.noBookingsOnDate(
                        DateFormat('MMM d').format(_selectedDate),
                        _selectedSize),
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
