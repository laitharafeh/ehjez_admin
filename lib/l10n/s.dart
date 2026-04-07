import 'package:flutter/material.dart';

/// Simple compile-time-safe string lookup.
/// Usage: final s = S.of(context);  then s.reservations, etc.
class S {
  final bool _ar;
  const S._(this._ar);

  static S of(BuildContext context) =>
      S._(Localizations.localeOf(context).languageCode == 'ar');

  bool get isAr => _ar;
  String _t(String en, String ar) => _ar ? ar : en;

  // ── General ────────────────────────────────────────────────────────────────
  String get cancel => _t('Cancel', 'إلغاء');
  String get confirm => _t('Confirm', 'تأكيد');
  String get ok => _t('OK', 'موافق');
  String get error => _t('Error', 'خطأ');
  String get remove => _t('Remove', 'إزالة');

  // ── Home ───────────────────────────────────────────────────────────────────
  String get reservations => _t('Reservations', 'الحجوزات');
  String get finances => _t('Finances', 'المالية');
  String get analytics => _t('Analytics', 'الإحصائيات');
  String get blacklist => _t('Blacklist', 'القائمة السوداء');
  String get courtSettings => _t('Court Settings', 'إعدادات الملعب');
  String get notLinkedToCourt =>
      _t('This account is not linked to any court.',
          'هذا الحساب غير مرتبط بأي ملعب.');
  String get signInWithCourtPhone =>
      _t('Sign in again with a court phone number to continue.',
          'سجّل الدخول مجدداً برقم هاتف الملعب للمتابعة.');
  String get backToLogin => _t('Back To Login', 'العودة لتسجيل الدخول');

  // ── Auth ───────────────────────────────────────────────────────────────────
  String get adminPortal => _t('Admin Portal', 'بوابة المشرف');
  String get signInTitle => _t('Sign in', 'تسجيل الدخول');
  String get enterPhoneLinkedToCourt =>
      _t('Enter the phone number linked to your court',
          'أدخل رقم الهاتف المرتبط بملعبك');
  String get continueBtn => _t('Continue', 'متابعة');
  String get checking => _t('Checking...', 'جارٍ التحقق...');
  String get invalidJordanianNumber =>
      _t('Enter a valid Jordanian mobile number.',
          'أدخل رقم هاتف أردني صحيح.');
  String get phoneNotLinked =>
      _t('This number is not linked to any court account.',
          'هذا الرقم غير مرتبط بأي ملعب.');
  String get somethingWentWrong =>
      _t('Something went wrong. Please try again.',
          'حدث خطأ ما. يرجى المحاولة مجدداً.');

  // ── OTP ────────────────────────────────────────────────────────────────────
  String get verifyYourNumber => _t('Verify your number', 'تحقق من رقمك');
  String codeSentTo(String phone) =>
      _ar ? 'تم إرسال الرمز إلى $phone' : 'Code sent to $phone';
  String get verify => _t('Verify', 'تحقق');
  String get changeNumber => _t('Change number', 'تغيير الرقم');
  String get resendCode => _t('Resend code', 'إعادة إرسال الرمز');
  String get sending => _t('Sending...', 'جارٍ الإرسال...');
  String get pleaseEnterCode => _t('Please enter the code.', 'يرجى إدخال الرمز.');
  String get invalidCode =>
      _t('Invalid code. Please try again.', 'رمز غير صحيح. يرجى المحاولة مجدداً.');
  String get resendFailed =>
      _t('Failed to resend. Please go back and try again.',
          'فشل إعادة الإرسال. يرجى العودة والمحاولة مجدداً.');
  String get codeResent => _t('Code resent.', 'تم إعادة إرسال الرمز.');

  // ── Reservations ──────────────────────────────────────────────────────────
  String errorLoadingCourt(String e) =>
      _ar ? 'خطأ في تحميل الملعب: $e' : 'Error loading court: $e';

  // ── Analytics ─────────────────────────────────────────────────────────────
  String get summary => _t('Summary', 'الملخص');
  String get thisMonth => _t('This Month', 'هذا الشهر');
  String get allTimeRevenue => _t('All-time Revenue', 'إجمالي الإيرادات');
  String get avgBookingValue => _t('Avg Booking Value', 'متوسط قيمة الحجز');
  String get totalCommission => _t('Total Commission', 'إجمالي العمولة');
  String get bookingsLabel => _t('bookings', 'حجوزات');
  String get totalBookings => _t('total bookings', 'إجمالي الحجوزات');
  String get perReservation => _t('per reservation', 'لكل حجز');
  String get allTime => _t('all time', 'طوال الوقت');
  String get monthlyRevenueJod => _t('Monthly Revenue (JOD)', 'الإيرادات الشهرية (د.أ)');
  String get peakHours => _t('Peak Hours', 'أوقات الذروة');
  String get bookingsPerHour =>
      _t('Number of bookings per hour of day', 'عدد الحجوزات لكل ساعة');
  String get busiestDays => _t('Busiest Days', 'أكثر الأيام ازدحاماً');
  String get bookingsPerWeekday =>
      _t('Total bookings per day of week', 'إجمالي الحجوزات لكل يوم');
  String get bookingsBySize =>
      _t('Bookings by Court Size', 'الحجوزات حسب حجم الملعب');

  // ── Accounting ─────────────────────────────────────────────────────────────
  String get revenue => _t('Revenue', 'الإيرادات');
  String get bookingsCount => _t('Bookings', 'الحجوزات');
  String get commission => _t('Commission', 'العمولة');
  String get netProfit => _t('Net Profit', 'صافي الربح');
  String get dailyRevenue => _t('Daily Revenue', 'الإيرادات اليومية');
  String get revenueBySize =>
      _t('Revenue by Field Size', 'الإيرادات حسب الحجم');
  String get noBookingsThisMonth =>
      _t('No bookings this month.', 'لا توجد حجوزات هذا الشهر.');
  String get previousMonth => _t('Previous month', 'الشهر السابق');
  String get nextMonth => _t('Next month', 'الشهر التالي');
  String vsLastMonth(String val) =>
      _ar ? 'مقابل $val الشهر الماضي' : 'vs $val last month';
  String get dateCol => _t('Date', 'التاريخ');
  String get timeCol => _t('Time', 'الوقت');
  String get fieldCol => _t('Field', 'الملعب');
  String get sizeCol => _t('Size', 'الحجم');
  String get customerCol => _t('Customer', 'العميل');
  String get phoneCol => _t('Phone', 'الهاتف');
  String get priceCol => _t('Price', 'السعر');
  String get invoiceDownloaded => _t('Invoice downloaded.', 'تم تنزيل الفاتورة.');
  String pdfError(String e) => _ar ? 'خطأ في PDF: $e' : 'PDF error: $e';
  String bookingsSection(int n) => _ar ? 'الحجوزات ($n)' : 'Bookings ($n)';

  // ── Blacklist ──────────────────────────────────────────────────────────────
  String get blacklistedNumbers =>
      _t('Blacklisted Numbers', 'الأرقام المحظورة');
  String get noBlacklistedNumbers =>
      _t('No blacklisted numbers.', 'لا توجد أرقام محظورة.');
  String get unban => _t('Unban', 'رفع الحظر');
  String get unbanNumber => _t('Unban number?', 'رفع حظر الرقم؟');
  String removeFromBlacklist(String phone) =>
      _ar ? 'إزالة $phone من القائمة السوداء؟'
          : 'Remove $phone from the blacklist?';

  // ── Court Settings ─────────────────────────────────────────────────────────
  String get basicInformation => _t('Basic Information', 'المعلومات الأساسية');
  String get courtName => _t('Court Name', 'اسم الملعب');
  String get category => _t('Category', 'الفئة');
  String get categoryHint =>
      _t('e.g. Football, Basketball', 'مثال: كرة قدم، كرة سلة');
  String get location => _t('Location', 'الموقع');
  String get locationHint => _t('Address or area', 'العنوان أو المنطقة');
  String get openingHours => _t('Opening Hours', 'ساعات العمل');
  String get openingTime => _t('Opening time', 'وقت الفتح');
  String get closingTime => _t('Closing time', 'وقت الإغلاق');
  String get workingDays => _t('Working Days', 'أيام العمل');
  String get sizesAndPricing => _t('Sizes & Pricing', 'الأحجام والأسعار');
  String get price1hr => _t('Price (1 hr)', 'السعر (ساعة)');
  String get price2hr => _t('Price (2 hr)', 'السعر (ساعتان)');
  String get fields => _t('Fields', 'ملاعب');
  String get sizeNameHint =>
      _t('Size name (e.g. 5v5)', 'اسم الحجم (مثال: 5×5)');
  String get addSize => _t('Add Size', 'إضافة حجم');
  String get removeThisSize => _t('Remove this size', 'حذف هذا الحجم');
  String get courtPhotos => _t('Court Photos', 'صور الملعب');
  String photoN(int n) => _ar ? 'صورة $n' : 'Photo $n';
  String get change => _t('Change', 'تغيير');
  String get manageVacationDays =>
      _t('Manage Vacation Days', 'إدارة أيام الإجازة');
  String get saveChanges => _t('Save Changes', 'حفظ التغييرات');
  String get saving => _t('Saving…', 'جارٍ الحفظ…');
  String get settingsSaved => _t('Settings saved.', 'تم حفظ الإعدادات.');
  String saveFailed(String e) =>
      _ar ? 'فشل الحفظ: $e' : 'Save failed: $e';

  // Settings validation
  String get courtNameEmpty =>
      _t('Court name cannot be empty.', 'لا يمكن أن يكون اسم الملعب فارغاً.');
  String get closingBeforeOpening =>
      _t('Closing time must be after opening time.',
          'يجب أن يكون وقت الإغلاق بعد وقت الفتح.');
  String get selectOneWorkingDay =>
      _t('Select at least one working day.', 'اختر يوماً عملياً واحداً على الأقل.');
  String get uniqueSizeNames =>
      _t('Each size must have a unique name.', 'يجب أن يكون لكل حجم اسم فريد.');
  String get sizeNameEmpty =>
      _t('Size name cannot be empty.', 'لا يمكن أن يكون اسم الحجم فارغاً.');
  String weekdayPriceInvalid(String size) =>
      _ar ? 'سعر ساعة لـ "$size" يجب أن يكون رقماً صحيحاً.'
          : 'Weekday price for "$size" must be a valid number.';
  String weekendPriceInvalid(String size) =>
      _ar ? 'سعر ساعتين لـ "$size" يجب أن يكون رقماً صحيحاً.'
          : 'Weekend price for "$size" must be a valid number.';
  String priceNegative(String label, String size) =>
      _ar ? '$label لـ "$size" لا يمكن أن يكون سالباً.'
          : '$label for "$size" cannot be negative.';
  String fieldsRequired(String size) =>
      _ar ? 'عدد الملاعب لـ "$size" مطلوب.'
          : 'Number of fields for "$size" is required.';
  String fieldsWholeNumber(String size) =>
      _ar ? 'عدد الملاعب لـ "$size" يجب أن يكون رقماً صحيحاً.'
          : 'Number of fields for "$size" must be a whole number.';
  String fieldsMinOne(String size) =>
      _ar ? 'عدد الملاعب لـ "$size" يجب أن يكون 1 على الأقل.'
          : 'Number of fields for "$size" must be at least 1.';

  // Size delete dialog
  String get deleteSizeTitle => _t('Remove size?', 'حذف الحجم؟');
  String upcomingReservationsWarning(int n) =>
      _ar ? 'يوجد $n حجز قادم لهذا الحجم. لا يمكن الحذف.'
          : 'There are $n upcoming reservations for this size. Cannot delete.';
  String confirmDeleteSize(String size) =>
      _ar ? 'حذف حجم "$size"؟ لا يمكن التراجع عن هذا الإجراء.'
          : 'Delete size "$size"? This cannot be undone.';
  String get delete => _t('Delete', 'حذف');
  String get checking2 => _t('Checking...', 'جارٍ التحقق...');
  String errorCheckingReservations(String e) =>
      _ar ? 'خطأ في التحقق: $e' : 'Error checking reservations: $e';
  String errorDeletingSize(String e) =>
      _ar ? 'خطأ في الحذف: $e' : 'Error deleting size: $e';

  // ── Vacation Days ──────────────────────────────────────────────────────────
  String get vacationDays => _t('Vacation Days', 'أيام الإجازة');
  String get clearAll => _t('Clear All', 'مسح الكل');
  String get clearAllTitle =>
      _t('Clear all vacation days?', 'مسح جميع أيام الإجازة؟');
  String get clearAllBody =>
      _t('This will remove all vacation days and allow bookings on all dates.',
          'سيؤدي هذا إلى إزالة جميع أيام الإجازة والسماح بالحجوزات في جميع التواريخ.');
  String get tapDateToMarkVacation =>
      _t('Tap any date to mark it as a vacation day. '
          'Users will not be able to book on those days.',
          'اضغط على أي تاريخ لتحديده كيوم إجازة. '
          'لن يتمكن المستخدمون من الحجز في تلك الأيام.');
  String get vacationClosed => _t('Vacation / Closed', 'إجازة / مغلق');
  String get today => _t('Today', 'اليوم');
  String get noVacationDays =>
      _t('No vacation days set.', 'لم يتم تحديد أيام إجازة.');
  String get tapDateToClose =>
      _t('Tap a date on the calendar above to close it.',
          'اضغط على تاريخ في التقويم أعلاه لإغلاقه.');
  String vacationDaysCount(int n) => _ar
      ? '$n ${n == 1 ? 'يوم إجازة محدد' : 'أيام إجازة محددة'}'
      : '$n vacation day${n > 1 ? 's' : ''} set';
  String errorUpdatingVacation(String e) =>
      _ar ? 'خطأ في تحديث أيام الإجازة: $e'
          : 'Error updating vacation days: $e';
  String errorClearingVacation(String e) =>
      _ar ? 'خطأ في مسح أيام الإجازة: $e' : 'Error clearing vacation days: $e';

  // ── Overlapping reservations ───────────────────────────────────────────────
  String get overlappingReservations =>
      _t('Overlapping Reservations', 'الحجوزات المتداخلة');
  String get confirmDelete => _t('Confirm delete', 'تأكيد الحذف');
  String get confirmDeleteBody =>
      _t('Are you sure you want to delete this reservation?',
          'هل أنت متأكد من حذف هذا الحجز؟');
  String get no => _t('No', 'لا');
  String get yes => _t('Yes', 'نعم');
  String get noOverlapping =>
      _t('No overlapping reservations.', 'لا توجد حجوزات متداخلة.');
  String nameLabel(String name) => _ar ? 'الاسم: $name' : 'Name: $name';
  String phoneLabel(String phone) => _ar ? 'الهاتف: $phone' : 'Phone: $phone';

  // ── Working day labels ─────────────────────────────────────────────────────
  Map<int, String> get dayLabels => _ar
      ? {1: 'إثنين', 2: 'ثلاثاء', 3: 'أربعاء', 4: 'خميس', 5: 'جمعة', 6: 'سبت', 7: 'أحد'}
      : {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

  // ── Court Assignment Board ─────────────────────────────────────────────────
  String get courtAssignment => _t('Court Assignment', 'جدول الملاعب');
  String get addBooking => _t('Add Booking', 'إضافة حجز');
  String get edit => _t('Edit', 'تعديل');
  String get refresh => _t('Refresh', 'تحديث');
  String fieldN(int n) => _ar ? 'ملعب $n' : 'Field $n';
  String sizeWithFields(String size, int n) =>
      _ar ? '$size  ($n ملاعب)' : '$size  ($n fields)';
  String get durationShort => _t('Duration', 'المدة');
  String durationHours(int n) =>
      _ar ? '$n ${n == 1 ? 'ساعة' : 'ساعات'}' : '$n hour${n > 1 ? 's' : ''}';
  String get close => _t('Close', 'إغلاق');
  String get confirmDeletion => _t('Confirm deletion', 'تأكيد الحذف');
  String deleteBookingConfirm(String name, String time) =>
      _ar ? 'حذف حجز $name في $time؟' : "Delete $name's reservation at $time?";
  String get reservationDeleted => _t('Reservation deleted', 'تم حذف الحجز');
  String noBookingsToday(String? size) =>
      _ar ? 'لا توجد حجوزات اليوم لـ ${size ?? ''}'
          : 'No bookings today for $size';
  String noBookingsOnDate(String date, String? size) =>
      _ar ? 'لا توجد حجوزات في $date لـ ${size ?? ''}'
          : 'No bookings on $date for $size';

  // ── Today Reservations ────────────────────────────────────────────────────
  String get todayReservations => _t("Today's Reservations", 'حجوزات اليوم');
  String get noReservationsToday =>
      _t('No reservations today.', 'لا توجد حجوزات لليوم.');
  String errorMsg(String e) => _ar ? 'خطأ: $e' : 'Error: $e';
  String get markAsNoShow => _t('Mark as No-Show?', 'تسجيل غياب؟');
  String noShowWarning(String phone) => _ar
      ? 'سيضاف تحذير إلى $phone.\nعند 5 تحذيرات نشطة لن يتمكن من الحجز.'
      : 'This will add a strike to $phone.\n'
          'At 5 active strikes they will be blocked from booking.';
  String get addStrike => _t('Add Strike', 'إضافة تحذير');
  String get markAsNoShowTooltip => _t('Mark as no-show', 'تسجيل غياب');
  String blacklistedAfterStrikes(String phone, int n) => _ar
      ? 'تم حجب $phone بعد $n تحذيرات. لن يتمكن من الحجز.'
      : '$phone has been blocked after $n strikes. They can no longer book.';
  String strikeAdded(String phone, int n) => _ar
      ? 'تمت إضافة تحذير. لدى $phone $n ${n == 1 ? 'تحذير نشط' : 'تحذيرات نشطة'}.'
      : 'Strike added. $phone now has $n active strike${n == 1 ? '' : 's'}.';
  String reservationSubtitle(String phone, String size, String name) => _ar
      ? ' $phone :رقم الهاتف\n $size :الحجم\n $name :الاسم'
      : 'Phone: $phone\nSize: $size\nName: $name';

  // No-show (board edit dialog)
  String get noShow => _t('No-show', 'غياب');
  String noShowDialogBody(String name, String phone) => _ar
      ? 'تسجيل غياب لـ $name؟\nسيضاف تحذير إلى $phone ويُحذف الحجز.\nعند 5 تحذيرات نشطة لن يتمكن من الحجز.'
      : 'Mark $name as no-show?\nA strike will be added to $phone and the reservation will be deleted.\nAt 5 active strikes they will be blocked from booking.';
  String noShowRecorded(String phone) => _ar
      ? 'تم تسجيل الغياب. تمت إضافة تحذير لـ $phone.'
      : 'No-show recorded. Strike added to $phone.';

  // ── Sports Court Calendar ─────────────────────────────────────────────────
  String get sizesLabel => _t('Sizes', 'الأحجام');
  String get selectDuration => _t('Select Duration', 'حدد المدة');
  String get noSizesAvailable =>
      _t('No sizes available for this court', 'لا توجد أحجام لهذا الملعب');
  String get oneHour => _t('1 Hour', 'ساعة');
  String get twoHours => _t('2 Hours', 'ساعتان');
  String availableSlotsLabel(int day, int month, int year, String size) =>
      _ar
          ? 'الأوقات المتاحة $day/$month/$year ($size)'
          : 'Available slots $day/$month/$year ($size)';
  String get reserved => _t('Reserved', 'محجوز');
  String get selectDayAndSize =>
      _t('Select a day and size to view available slots',
          'اختر يوماً وحجماً لعرض الأوقات المتاحة');
  String get confirmReservation => _t('Confirm Reservation', 'تأكيد الحجز');
  String confirmDate(String date) => _ar ? 'التاريخ: $date' : 'Date: $date';
  String confirmTime(String time) => _ar ? 'الوقت: $time' : 'Time: $time';
  String confirmDurationLabel(int n) => _ar
      ? 'المدة: $n ${n == 1 ? 'ساعة' : 'ساعات'}'
      : 'Duration: $n hour${n > 1 ? 's' : ''}';
  String confirmSize(String size) => _ar ? 'الحجم: $size' : 'Size: $size';
  String confirmPrice(int price) =>
      _ar ? 'السعر: $price د.أ' : 'Price: $price JOD';
  String get nameField => _t('Name', 'الاسم');
  String get phoneNumberField => _t('Phone Number', 'رقم الهاتف');
  String get reservationAddedSuccess =>
      _t('Reservation added successfully!', 'تم إضافة الحجز بنجاح!');
  String get slotFullError =>
      _t('This slot is no longer available. Please choose another time.',
          'هذا الوقت لم يعد متاحاً. يرجى اختيار وقت آخر.');
  String bookingErrorGeneric(String err) => _ar
      ? 'تعذر إتمام الحجز ($err).'
      : 'Could not complete booking ($err).';
  String errorCreatingReservation(String e) =>
      _ar ? 'خطأ في إنشاء الحجز: $e' : 'Error creating reservation: $e';
  String errorLoadingCourtData(String e) =>
      _ar ? 'خطأ في تحميل بيانات الملعب: $e' : 'Error loading court data: $e';
  String errorLoadingReservations(String e) =>
      _ar ? 'خطأ في تحميل الحجوزات: $e' : 'Error loading reservations: $e';
  String get vacationDayWarning =>
      _t('This day is marked as a vacation day. '
          'Users cannot book on this date. '
          'You can still add a booking as an override.',
          'هذا اليوم محدد كيوم إجازة. لا يمكن للمستخدمين الحجز في هذا التاريخ. يمكنك إضافة حجز كاستثناء.');
}
