import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Publicly reachable (no login) so the deployed web app's /privacy URL can be
/// used as the privacy-policy link in the app stores. Content follows the app
/// language (EN / AR).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = S.of(context).isAr;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(
          ar ? 'سياسة الخصوصية' : 'Privacy Policy',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'ehjez',
                style: GoogleFonts.grandstander(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: ehjezGreen,
                ),
              ),
              Text(
                ar
                    ? 'إحجز وإحجز أدمن — آخر تحديث: 18 تموز 2026'
                    : 'Ehjez & Ehjez Admin — Last updated: 18 July 2026',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _P(ar
                  ? 'تدير "إحجز" خدمة حجز الملاعب الرياضية في الأردن، وتتكوّن من تطبيق "إحجز" للعملاء وتطبيق "إحجز أدمن" لأصحاب الملاعب وموظفيهم. توضح هذه السياسة البيانات التي نجمعها عبر التطبيقين وكيفية استخدامها.'
                  : 'Ehjez ("we", "us") operates a sports-court reservation service in Jordan, consisting of the Ehjez app for customers and the Ehjez Admin app for court owners and their staff. This policy explains what data we collect through both apps and how we use it.'),
              _H(ar ? 'البيانات التي نجمعها' : 'Data we collect'),
              _B(ar
                  ? [
                      'رقم الهاتف — لتسجيل الدخول (عبر رمز تحقق SMS) ولتحديد حجوزاتك.',
                      'الاسم — يظهر على حجوزاتك وعلى قائمة التسجيل إذا سجّلت في بطولة.',
                      'تفاصيل الحجز — الملعب والتاريخ والوقت والمدة وحجم الملعب والسعر.',
                      'رمز إشعارات الجهاز — معرّف تقني لإرسال إشعارات الحجز إلى جهازك.',
                      'سجلات الحضور — إذا سجّل الملعب عدم حضورك، يُحتفظ بذلك السجل وقد يقيّد تكرار الغياب حجوزاتك المستقبلية.',
                    ]
                  : [
                      'Phone number — used to sign in (via SMS verification code) and to identify your bookings.',
                      'Name — shown on your reservations and, if you register for a tournament, on the registration list.',
                      'Reservation details — court, date, time, duration, field size, and price of bookings you make.',
                      'Device notification token — a technical identifier that lets us send booking notifications to your device.',
                      'Attendance records — if a court marks a booking as a no-show, that record is kept and repeated no-shows may restrict future booking.',
                    ]),
              _P(ar
                  ? 'لا نجمع بيانات بطاقات الدفع أو الموقع الدقيق أو جهات الاتصال أو الصور أو أي بيانات من تطبيقات أخرى.'
                  : 'We do not collect payment card details, precise location, contacts, photos, or any data from other apps.'),
              _H(ar ? 'كيف نستخدم بياناتك' : 'How we use your data'),
              _B(ar
                  ? [
                      'إنشاء حسابك وإدارة حجوزاتك.',
                      'عرض الحجوزات لموظفي الملعب الخاص بهم فقط (يظهر اسمك ورقم هاتفك لموظفي الملعب الذي تحجز فيه لإدارة الحجز).',
                      'إرسال إشعارات متعلقة بالحجوزات.',
                      'تطبيق الرموز الترويجية وتسجيلات البطولات التي تطلبها.',
                      'حماية الملاعب من تكرار عدم الحضور.',
                    ]
                  : [
                      'To create and manage your account and reservations.',
                      'To show court staff the bookings made at their own court (your name and phone number are visible to the staff of a court you book at).',
                      'To send reservation-related notifications.',
                      'To apply promotional codes and tournament registrations you request.',
                      'To protect courts against repeated no-shows.',
                    ]),
              _P(ar
                  ? 'لا نبيع بياناتك ولا نستخدمها لإعلانات جهات خارجية.'
                  : 'We do not sell your data or use it for third-party advertising.'),
              _H(ar ? 'من يمكنه رؤية بياناتك' : 'Who can see your data'),
              _B(ar
                  ? [
                      'مشغّلو الملاعب — يرون فقط الحجوزات في ملعبهم.',
                      'مزوّدو الخدمة — نستضيف البيانات لدى Supabase ونرسل الإشعارات عبر Google Firebase Cloud Messaging، وتُرسل رموز التحقق عبر مزوّد SMS. يعالج هؤلاء المزودون البيانات نيابةً عنا فقط.',
                    ]
                  : [
                      'Court operators — see only the bookings made at their own court.',
                      'Service providers — we host data with Supabase and deliver notifications through Google Firebase Cloud Messaging. SMS verification codes are delivered through an SMS provider. These providers process data only on our behalf.',
                    ]),
              _H(ar
                  ? 'الاحتفاظ بالبيانات وحذف حسابك'
                  : 'Data retention & deleting your account'),
              _P(ar
                  ? 'نحتفظ ببياناتك ما دام حسابك نشطاً. لحذف حسابك وبياناتك الشخصية، تواصل معنا على العنوان أدناه من رقم الهاتف أو البريد الإلكتروني المرتبط بطلبك. سنحذف بيانات حسابك خلال 30 يوماً، باستثناء السجلات التي يجب الاحتفاظ بها لأغراض تجارية مشروعة (مثل السجلات المالية للحجوزات المكتملة).'
                  : 'We keep your data while your account is active. To delete your account and associated personal data, contact us at the address below from the phone number or email linked to your request. We will remove your account data within 30 days, except records we must keep for legitimate business purposes (for example, completed booking financial records).'),
              _H(ar ? 'الأمان' : 'Security'),
              _P(ar
                  ? 'جميع الاتصالات بين التطبيقات وخوادمنا مشفّرة (TLS)، والوصول إلى قاعدة البيانات مقيّد بقواعد وصول لكل مستخدم — يصل العملاء إلى سجلاتهم فقط، وموظفو الملعب إلى سجلات ملعبهم فقط.'
                  : 'All traffic between the apps and our servers is encrypted (TLS), and database access is restricted by per-user access rules — customers can access only their own records, and court staff only their court\'s records.'),
              _H(ar ? 'الأطفال' : 'Children'),
              _P(ar
                  ? 'خدمة إحجز غير موجهة للأطفال دون 13 عاماً، ولا نجمع بياناتهم عن قصد.'
                  : 'Ehjez is not directed at children under 13, and we do not knowingly collect data from them.'),
              _H(ar ? 'التغييرات على هذه السياسة' : 'Changes to this policy'),
              _P(ar
                  ? 'عند إجراء تغييرات جوهرية سنحدّث هذه الصفحة وتاريخ "آخر تحديث" أعلاه.'
                  : 'If we make material changes, we will update this page and the "last updated" date above.'),
              _H(ar ? 'التواصل' : 'Contact'),
              _P(ar
                  ? 'للاستفسارات أو طلبات الحذف: laitharafehh@gmail.com'
                  : 'Questions or deletion requests: laitharafehh@gmail.com'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ehjezGreen,
          ),
        ),
      );
}

class _P extends StatelessWidget {
  final String text;
  const _P(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      );
}

class _B extends StatelessWidget {
  final List<String> items;
  const _B(this.items);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
