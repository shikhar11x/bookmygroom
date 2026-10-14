import 'dart:convert';

enum AppointmentStatus {
  pendingPayment,
  confirmed,
  checkedIn,
  inService,
  completed,
  cancelled,
}

class Appointment {
  const Appointment({
    required this.id,
    required this.branchName,
    required this.stylistName,
    required this.serviceNames,
    required this.start,
    required this.durationMin,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.couponCode,
    this.status = AppointmentStatus.confirmed,
  });

  final String id;
  final String branchName;
  final String stylistName;
  final List<String> serviceNames;
  final DateTime start;
  final int durationMin;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final String paymentMethod;
  final String? couponCode;
  final AppointmentStatus status;

  DateTime get end => start.add(Duration(minutes: durationMin));

  Appointment copyWith({AppointmentStatus? status}) => Appointment(
    id: id,
    branchName: branchName,
    stylistName: stylistName,
    serviceNames: serviceNames,
    start: start,
    durationMin: durationMin,
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: total,
    paymentMethod: paymentMethod,
    couponCode: couponCode,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchName': branchName,
    'stylistName': stylistName,
    'serviceNames': serviceNames,
    'start': start.toIso8601String(),
    'durationMin': durationMin,
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'total': total,
    'paymentMethod': paymentMethod,
    'couponCode': couponCode,
    'status': status.name,
  };

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
    id: j['id'] as String,
    branchName: j['branchName'] as String,
    stylistName: j['stylistName'] as String,
    serviceNames: List<String>.from(j['serviceNames'] as List),
    start: DateTime.parse(j['start'] as String),
    durationMin: j['durationMin'] as int,
    subtotal: j['subtotal'] as int,
    discount: j['discount'] as int,
    tax: j['tax'] as int,
    total: j['total'] as int,
    paymentMethod: j['paymentMethod'] as String,
    couponCode: j['couponCode'] as String?,
    status: AppointmentStatus.values.byName(j['status'] as String),
  );
  factory Appointment.fromRow(Map<String, dynamic> r) => Appointment(
    id: r['id'] as String,
    branchName: r['branch_name'] as String,
    stylistName: r['stylist_name'] as String,
    serviceNames: List<String>.from(r['service_names'] as List),
    start: DateTime.parse(r['start_at'] as String).toLocal(),
    durationMin: r['duration_min'] as int,
    subtotal: r['subtotal'] as int,
    discount: r['discount'] as int,
    tax: r['tax'] as int,
    total: r['total'] as int,
    paymentMethod: r['payment_method'] as String,
    couponCode: r['coupon_code'] as String?,
    status: _statusFromDb(r['status'] as String),
  );

  static AppointmentStatus _statusFromDb(String s) => switch (s) {
    'pending_payment' => AppointmentStatus.pendingPayment,
    'checked_in' => AppointmentStatus.checkedIn,
    'in_service' => AppointmentStatus.inService,
    'completed' => AppointmentStatus.completed,
    'cancelled' => AppointmentStatus.cancelled,
    _ => AppointmentStatus.confirmed,
  };
  static String encodeList(List<Appointment> list) =>
      jsonEncode(list.map((a) => a.toJson()).toList());

  static List<Appointment> decodeList(String raw) => (jsonDecode(raw) as List)
      .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
      .toList();
}
