// Domain models for the "Mode Chargé Public" dashboard.
//
// Two sources feed [CpDashboard]:
//  • the rich `GET /api/me/charge-public/dashboard` (full parity), and
//  • a fallback parse of `GET /api/me/referrals` used until that endpoint
//    is deployed. When the fallback is used, [CpDashboard.isPartial] is true
//    (guest list / by-show / payments are not available yet).

class CpStats {
  final int brought;
  final int attended;
  final int notAttended;
  final int earnings;
  final int paid;
  final int unpaidBalance;
  final int points;
  final String currency;

  const CpStats({
    this.brought = 0,
    this.attended = 0,
    this.notAttended = 0,
    this.earnings = 0,
    this.paid = 0,
    this.unpaidBalance = 0,
    this.points = 0,
    this.currency = 'MAD',
  });
}

class CpShowRow {
  final String showTitle;
  final String? showDate;
  final int invited;
  final int attended;
  final int notAttended;
  final int earnings;

  const CpShowRow({
    required this.showTitle,
    this.showDate,
    this.invited = 0,
    this.attended = 0,
    this.notAttended = 0,
    this.earnings = 0,
  });

  factory CpShowRow.fromJson(Map<String, dynamic> j) => CpShowRow(
        showTitle: j['show_title'] as String? ?? '—',
        showDate: j['show_date'] as String?,
        invited: (j['invited'] as num?)?.toInt() ?? 0,
        attended: (j['attended'] as num?)?.toInt() ?? 0,
        notAttended: (j['not_attended'] as num?)?.toInt() ?? 0,
        earnings: (j['earnings'] as num?)?.toInt() ?? 0,
      );
}

class CpGuest {
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String show;
  final String? date;
  final bool attended;
  final String? resStatus;
  final int? amount;
  final int? visit;

  const CpGuest({
    required this.name,
    this.avatarUrl,
    this.phone,
    this.show = '—',
    this.date,
    this.attended = false,
    this.resStatus,
    this.amount,
    this.visit,
  });

  factory CpGuest.fromJson(Map<String, dynamic> j) => CpGuest(
        name: j['name'] as String? ?? '—',
        avatarUrl: j['avatar_url'] as String?,
        phone: j['phone'] as String?,
        show: j['show'] as String? ?? '—',
        date: j['date'] as String?,
        attended: j['attended'] as bool? ?? false,
        resStatus: j['res_status'] as String?,
        amount: (j['amount'] as num?)?.toInt(),
        visit: (j['visit'] as num?)?.toInt(),
      );
}

class CpPayment {
  final int amount;
  final String? note;
  final DateTime? paidAt;

  const CpPayment({required this.amount, this.note, this.paidAt});

  factory CpPayment.fromJson(Map<String, dynamic> j) => CpPayment(
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        note: j['note'] as String?,
        paidAt: j['paid_at'] != null
            ? DateTime.tryParse(j['paid_at'] as String)
            : null,
      );
}

/// Aggregated per-referred-user row from the fallback `/api/me/referrals`.
class CpReferredUser {
  final String name;
  final int visits;
  final int totalEarned;
  final int nextDiscountPercent;

  const CpReferredUser({
    required this.name,
    this.visits = 0,
    this.totalEarned = 0,
    this.nextDiscountPercent = 0,
  });

  factory CpReferredUser.fromJson(Map<String, dynamic> j) => CpReferredUser(
        name: j['name'] as String? ?? '—',
        visits: (j['visits'] as num?)?.toInt() ?? 0,
        totalEarned: (j['total_earned'] as num?)?.toInt() ?? 0,
        nextDiscountPercent:
            (j['next_discount_percent'] as num?)?.toInt() ?? 0,
      );
}

class CpDashboard {
  final CpStats stats;
  final List<CpShowRow> byShow;
  final List<CpGuest> guests;
  final List<CpPayment> payments;
  final List<CpReferredUser> referredUsers;

  /// True when built from the `/api/me/referrals` fallback (guest list,
  /// by-show and payment history not yet available from the backend).
  final bool isPartial;

  const CpDashboard({
    required this.stats,
    this.byShow = const [],
    this.guests = const [],
    this.payments = const [],
    this.referredUsers = const [],
    this.isPartial = false,
  });

  /// From the rich `GET /api/me/charge-public/dashboard`.
  factory CpDashboard.fromRich(Map<String, dynamic> j) {
    final s = (j['stats'] as Map<String, dynamic>?) ?? const {};
    return CpDashboard(
      stats: CpStats(
        brought: (s['total_brought'] as num?)?.toInt() ?? 0,
        attended: (s['total_attended'] as num?)?.toInt() ?? 0,
        notAttended: (s['total_not_attended'] as num?)?.toInt() ?? 0,
        earnings: (s['total_earnings'] as num?)?.toInt() ?? 0,
        paid: (s['total_paid'] as num?)?.toInt() ?? 0,
        unpaidBalance: (s['unpaid_balance'] as num?)?.toInt() ?? 0,
        points: (s['total_points'] as num?)?.toInt() ?? 0,
        currency: s['currency'] as String? ?? 'MAD',
      ),
      byShow: ((j['by_show'] as List<dynamic>?) ?? [])
          .map((e) => CpShowRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      guests: ((j['guests'] as List<dynamic>?) ?? [])
          .map((e) => CpGuest.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: ((j['payments'] as List<dynamic>?) ?? [])
          .map((e) => CpPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPartial: false,
    );
  }

  /// Fallback from `GET /api/me/referrals` (CP fields only).
  factory CpDashboard.fromReferralStats(Map<String, dynamic> j) {
    return CpDashboard(
      stats: CpStats(
        brought: (j['total_invited'] as num?)?.toInt() ?? 0,
        attended: (j['total_attended'] as num?)?.toInt() ?? 0,
        notAttended: (j['pending'] as num?)?.toInt() ?? 0,
        earnings: (j['total_rewards'] as num?)?.toInt() ?? 0,
        paid: (j['total_paid'] as num?)?.toInt() ?? 0,
        unpaidBalance: (j['unpaid_balance'] as num?)?.toInt() ?? 0,
        points: (j['total_points'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'MAD',
      ),
      referredUsers: ((j['referred_users'] as List<dynamic>?) ?? [])
          .map((e) => CpReferredUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPartial: true,
    );
  }
}
