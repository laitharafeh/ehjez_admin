import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:ehjez_admin/services/reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SportsCourtCalendar extends StatefulWidget {
  final String courtId;
  final String name;
  final void Function(DateTime, int, String)? onTimeSlotSelected;
  final VoidCallback? onSelectionReset;
  // Called after a booking is successfully inserted — lets the parent
  // (e.g. the board dialog) react, e.g. close itself and refresh.
  final VoidCallback? onBookingAdded;

  const SportsCourtCalendar({
    required this.name,
    required this.courtId,
    this.onTimeSlotSelected,
    this.onSelectionReset,
    this.onBookingAdded,
    super.key,
  });

  @override
  State<SportsCourtCalendar> createState() => _SportsCourtCalendarState();
}

class _SportsCourtCalendarState extends State<SportsCourtCalendar> {
  DateTime? _selectedSlotTime;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> _reservations = {};
  bool _isLoading = false;
  int _selectedDuration = 2;
  DateTime? _courtStartTime;
  DateTime? _courtEndTime;
  bool _isEndTimeSpecial = false;
  final Map<String, int> _courtSizes = {};
  final Map<String, Map<int, int>> _courtPrices = {};
  String? _selectedSize;
  int? _numberOfFields;

  // Vacation days — specific dates the court is closed
  Set<DateTime> _vacationDays = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchCourtData();
  }

  DateTime _normaliseDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isVacationDay(DateTime day) =>
      _vacationDays.contains(_normaliseDate(day));

  Future<void> _showConfirmationDialog(
    BuildContext context,
    DateTime date,
    TimeOfDay startTime,
  ) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Reservation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Date: ${DateFormat.yMMMd().format(date)}'),
                  Text('Time: ${startTime.format(context)}'),
                  Text('Duration: $_selectedDuration hour(s)'),
                  Text('Size: $_selectedSize'),
                  Text(
                    'Price: ${_courtPrices[_selectedSize!]?[_selectedDuration] ?? 0} JOD',
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      try {
        final result = await ReservationService.bookSlot(
          courtId: widget.courtId,
          date: DateFormat('yyyy-MM-dd').format(date),
          startTime:
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
          duration: _selectedDuration,
          size: _selectedSize!,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          price: _courtPrices[_selectedSize!]?[_selectedDuration] ?? 0,
        );

        if (!context.mounted) return;

        if (result['success'] == true) {
          await _fetchReservations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation added successfully!')),
          );
          widget.onBookingAdded?.call();
        } else {
          final error = result['error'] as String?;
          final message = error == 'slot_full'
              ? 'This slot is no longer available. Please choose another time.'
              : 'Could not complete booking (${error ?? 'unknown error'}).';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating reservation: $e')),
        );
      }
    }
  }

  Future<void> _fetchCourtData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch court timing, sizes, and vacation days in parallel
      final results = await Future.wait([
        CourtService.getCourtTimings(widget.courtId),
        CourtService.getCourtSizesAndPrices(widget.courtId),
        CourtService.getUpcomingVacationDays(widget.courtId),
      ]);

      final courtResponse = results[0] as Map<String, dynamic>;
      final sizesResponse = results[1] as List<Map<String, dynamic>>;
      final vacationDateStrings = results[2] as List<String>;

      // Process court timings
      if (courtResponse.isNotEmpty) {
        final now = DateTime.now();
        String endTimeStr = courtResponse['end_time'] as String;

        if (endTimeStr == "23:59:59") {
          _isEndTimeSpecial = true;
        }

        int startHour = int.parse(courtResponse['start_time'].split(':')[0]);
        int endHour = int.parse(endTimeStr.split(':')[0]);

        _courtStartTime = DateTime(now.year, now.month, now.day, startHour);
        _courtEndTime = endHour >= startHour
            ? DateTime(now.year, now.month, now.day, endHour)
            : DateTime(now.year, now.month, now.day + 1, endHour);
      }

      // Process sizes
      _courtSizes.clear();
      _courtPrices.clear();
      for (var sizeRecord in sizesResponse) {
        final size = sizeRecord['size'] as String?;
        final number = sizeRecord['number_of_fields'] as int?;
        final price1 = sizeRecord['price1'] as int?;
        final price2 = sizeRecord['price2'] as int?;
        if (size != null && size.isNotEmpty && number != null && number > 0) {
          _courtSizes[size] = number;
          _courtPrices[size] = {1: price1 ?? 0, 2: price2 ?? 0};
        }
      }

      if (_courtSizes.isNotEmpty) {
        _selectedSize = _courtSizes.keys.first;
        _numberOfFields = _courtSizes[_selectedSize];
      }

      // Process vacation days
      _vacationDays = vacationDateStrings
          .map((d) => _normaliseDate(DateTime.parse(d)))
          .toSet();

      await _fetchReservations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading court data: $e')));
      }
      _courtStartTime = DateTime.now().copyWith(hour: 8, minute: 0);
      _courtEndTime = DateTime.now()
          .copyWith(hour: 2, minute: 0)
          .add(const Duration(days: 1));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReservations() async {
    if (_selectedSize == null) return;

    setState(() => _isLoading = true);

    try {
      final rows = await ReservationService.getUpcomingReservations(
        widget.courtId,
        _selectedSize!,
      );

      _reservations.clear();
      for (var reservation in rows) {
        final date = DateTime.parse(reservation['date']);
        final startTimeStr = reservation['start_time'] as String;
        final startHour = int.parse(startTimeStr.split(':')[0]);
        final startMinute = int.parse(startTimeStr.split(':')[1]);
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          startHour,
          startMinute,
        );
        final dateKey = DateTime(date.year, date.month, date.day);
        _reservations[dateKey] ??= [];
        _reservations[dateKey]!.add({
          'start_time': startTime,
          'duration': reservation['duration'],
          'user_id': reservation['user_id'],
          'size': reservation['size'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reservations: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getMaxConcurrency(
    DateTime slotStart,
    DateTime slotEnd,
    List<Map<String, dynamic>> reservations,
  ) {
    List<Map<String, dynamic>> overlapping = reservations.where((r) {
      DateTime rStart = r['start_time'];
      DateTime rEnd = rStart.add(Duration(hours: r['duration']));
      return rStart.isBefore(slotEnd) && rEnd.isAfter(slotStart);
    }).toList();

    List<Map<String, dynamic>> events = [];
    for (var r in overlapping) {
      DateTime rStart = r['start_time'];
      DateTime rEnd = rStart.add(Duration(hours: r['duration']));
      DateTime effectiveStart = rStart.isAfter(slotStart) ? rStart : slotStart;
      DateTime effectiveEnd = rEnd.isBefore(slotEnd) ? rEnd : slotEnd;
      events.add({'time': effectiveStart, 'type': 'start'});
      events.add({'time': effectiveEnd, 'type': 'end'});
    }

    events.sort((a, b) {
      int cmp = a['time'].compareTo(b['time']);
      if (cmp == 0) {
        if (a['type'] == 'end' && b['type'] == 'start') return -1;
        if (a['type'] == 'start' && b['type'] == 'end') return 1;
      }
      return cmp;
    });

    int counter = 0;
    int maxCounter = 0;
    for (var event in events) {
      if (event['type'] == 'start') {
        counter++;
        maxCounter = counter > maxCounter ? counter : maxCounter;
      } else {
        counter--;
      }
    }
    return maxCounter;
  }

  List<Map<String, dynamic>> _getAvailableSlots(DateTime day) {
    if (_courtStartTime == null ||
        _courtEndTime == null ||
        _selectedSize == null ||
        _numberOfFields == null) {
      return [];
    }

    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    final dayStart = DateTime(
      day.year,
      day.month,
      day.day,
      _courtStartTime!.hour,
      _courtStartTime!.minute,
    );

    DateTime dayEnd;
    if (_isEndTimeSpecial) {
      dayEnd = DateTime(day.year, day.month, day.day + 1, 0, 0);
    } else {
      dayEnd = _courtEndTime!.isAfter(_courtStartTime!)
          ? DateTime(day.year, day.month, day.day, _courtEndTime!.hour,
              _courtEndTime!.minute)
          : DateTime(day.year, day.month, day.day + 1, _courtEndTime!.hour,
              _courtEndTime!.minute);
    }

    final reservedTimes =
        _reservations[DateTime(day.year, day.month, day.day)] ?? [];

    List<Map<String, dynamic>> slots = [];
    DateTime currentTime = dayStart;

    while (true) {
      if (isToday && currentTime.isBefore(now)) {
        currentTime = currentTime.add(const Duration(hours: 1));
        if (currentTime.isAfter(dayEnd)) break;
        continue;
      }

      final slotEnd = currentTime.add(Duration(hours: _selectedDuration));
      if (_selectedDuration == 2 && slotEnd.isAfter(dayEnd)) break;
      if (currentTime.isAtSameMomentAs(dayEnd) ||
          currentTime.isAfter(dayEnd)) {
        break;
      }

      final concurrency =
          _getMaxConcurrency(currentTime, slotEnd, reservedTimes);

      bool isWithinRange;
      if (_isEndTimeSpecial &&
          _selectedDuration == 1 &&
          slotEnd.hour == 0 &&
          slotEnd.minute == 0) {
        isWithinRange = concurrency < _numberOfFields!;
      } else if (slotEnd.isAfter(dayEnd)) {
        isWithinRange = false;
      } else {
        isWithinRange = concurrency < _numberOfFields!;
      }

      slots.add({
        'time': currentTime,
        'isAvailable': isWithinRange,
        'concurrency': concurrency,
      });

      currentTime = currentTime.add(const Duration(hours: 1));
      if (currentTime.isAfter(dayEnd)) break;
    }

    return slots;
  }

  String _formatHour(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '$hour:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    bool canReserve = false;
    if (_selectedSlotTime != null && _selectedDay != null) {
      final slots = _getAvailableSlots(_selectedDay!);
      final match = slots.firstWhere(
        (s) => s['time'] == _selectedSlotTime,
        orElse: () => {'isAvailable': false},
      );
      canReserve = match['isAvailable'] as bool;
    }

    // Admin can still tap vacation days (to view/book override),
    // but we show a warning banner when one is selected.
    final selectedDayIsVacation =
        _selectedDay != null && _isVacationDay(_selectedDay!);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Size selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الأحجام',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (_courtSizes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _courtSizes.keys.map((size) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSize = size;
                        _numberOfFields = _courtSizes[size];
                      });
                      _fetchReservations();
                    },
                    child: Card(
                      elevation: 4,
                      color: _selectedSize == size ? ehjezGreen : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          size,
                          style: TextStyle(
                            color: _selectedSize == size
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No sizes available for this court'),
            ),

          // Calendar — vacation days shown with red decoration
          TableCalendar(
            availableGestures: AvailableGestures.horizontalSwipe,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedSlotTime = null;
              });
              widget.onSelectionReset?.call();
            },
            eventLoader: (day) =>
                _reservations[DateTime(day.year, day.month, day.day)] ?? [],
            calendarBuilders: CalendarBuilders(
              // Paint vacation days with a red background
              defaultBuilder: (context, day, focusedDay) {
                if (_isVacationDay(day)) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }
                return null; // use default rendering for normal days
              },
            ),
            calendarStyle: const CalendarStyle(
              markersMaxCount: 5,
              markersAlignment: Alignment.bottomRight,
              selectedDecoration: BoxDecoration(
                color: Color(0xFF068631),
                shape: BoxShape.circle,
              ),
            ),
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            calendarFormat: CalendarFormat.month,
            onFormatChanged: null,
          ),

          // Vacation day warning banner (shown when selected day is a vacation)
          if (selectedDayIsVacation)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.beach_access,
                      color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This day is marked as a vacation day. '
                      'Users cannot book on this date. '
                      'You can still add a booking as an override.',
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'حدد المدة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Center(
            child: ToggleButtons(
              isSelected: [_selectedDuration == 1, _selectedDuration == 2],
              onPressed: (index) {
                setState(() {
                  _selectedDuration = index + 1;
                  _selectedSlotTime = null;
                });
                widget.onSelectionReset?.call();
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              color: Colors.black,
              fillColor: const Color(0xFF068631),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('1 Hour'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('2 Hours'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Time slots
          if (_selectedDay != null && _selectedSize != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'الأوقات المتاحة ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year} ($_selectedSize)',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ..._getAvailableSlots(_selectedDay!).map((slot) {
              final time = slot['time'] as DateTime;
              final isAvailable = slot['isAvailable'] as bool;
              final concurrency = slot['concurrency'] as int;
              final endTime = time.add(Duration(hours: _selectedDuration));
              final isSelected = _selectedSlotTime == time;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSlotTime = time);
                  widget.onTimeSlotSelected
                      ?.call(time, _selectedDuration, _selectedSize!);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.grey[300]
                        : isAvailable
                            ? const Color(0xFFC8E6C9)
                            : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.green, width: 2)
                        : Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatHour(time)} - ${_formatHour(endTime)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (!isAvailable)
                        Text(
                          'Reserved',
                          style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold),
                        )
                      else
                        Text(
                          '.' * concurrency.clamp(0, 3),
                          style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Select a day and size to view available slots'),
            ),

          // Add booking button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canReserve
                    ? () {
                        final reservationDate = DateTime(
                          _selectedDay!.year,
                          _selectedDay!.month,
                          _selectedDay!.day,
                        );
                        final startTimeOfDay = TimeOfDay(
                          hour: _selectedSlotTime!.hour,
                          minute: _selectedSlotTime!.minute,
                        );
                        _showConfirmationDialog(
                            context, reservationDate, startTimeOfDay);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canReserve ? ehjezGreen : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("اضافة حجز"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
