/// Case payload shape — mirrors munshi-ui/vault.js `saveCasePayload` objects.
library;

class ClientInfo {
  const ClientInfo({this.name = '', this.phone = ''});
  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory ClientInfo.fromJson(Map<String, dynamic>? j) =>
      ClientInfo(name: j?['name'] as String? ?? '', phone: j?['phone'] as String? ?? '');
}

class FeeInfo {
  const FeeInfo({this.agreed = 0});
  final int agreed;

  Map<String, dynamic> toJson() => {'agreed': agreed};
  factory FeeInfo.fromJson(Map<String, dynamic>? j) => FeeInfo(agreed: (j?['agreed'] as num?)?.toInt() ?? 0);
}

class CaseHearing {
  const CaseHearing({required this.date, required this.purpose, this.outcome});
  final String date;
  final String purpose;
  final String? outcome;

  Map<String, dynamic> toJson() => {'date': date, 'purpose': purpose, if (outcome != null) 'outcome': outcome};
  factory CaseHearing.fromJson(Map<String, dynamic> j) => CaseHearing(
        date: j['date'] as String? ?? '',
        purpose: j['purpose'] as String? ?? '',
        outcome: j['outcome'] as String?,
      );
}

class CaseDocument {
  const CaseDocument({
    required this.name,
    this.size = '',
    this.date = '',
    this.pdf = true,
    this.id,
  });
  final String? id;
  final String name;
  final String size;
  final String date;
  final bool pdf;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'size': size,
        'date': date,
        'pdf': pdf,
      };
  factory CaseDocument.fromJson(Map<String, dynamic> j) => CaseDocument(
        id: j['id'] as String?,
        name: j['name'] as String? ?? '',
        size: j['size'] as String? ?? '',
        date: j['date'] as String? ?? '',
        pdf: j['pdf'] as bool? ?? true,
      );
}

class CasePayment {
  const CasePayment({
    required this.id,
    required this.amount,
    required this.mode,
    required this.date,
    this.note = '',
  });
  final String id;
  final int amount;
  final String mode;
  final String date;
  final String note;

  Map<String, dynamic> toJson() =>
      {'id': id, 'amount': amount, 'mode': mode, 'date': date, 'note': note};
  factory CasePayment.fromJson(Map<String, dynamic> j) => CasePayment(
        id: j['id'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        mode: j['mode'] as String? ?? '',
        date: j['date'] as String? ?? '',
        note: j['note'] as String? ?? '',
      );
}

class CaseUpdate {
  const CaseUpdate({
    required this.date,
    required this.side,
    required this.kind,
    required this.text,
    this.time = '',
    this.sub = '',
    this.share = false,
  });
  final String date;
  final String side; // court | lawyer — PWA uses right/left; stored as court/lawyer in mobile
  final String kind;
  final String text;
  final String time;
  final String sub;
  final bool share;

  bool get isCourt => side == 'court' || side == 'right';

  Map<String, dynamic> toJson() => {
        'date': date,
        'side': side,
        'kind': kind,
        'text': text,
        'time': time,
        'sub': sub,
        'share': share,
      };
  factory CaseUpdate.fromJson(Map<String, dynamic> j) => CaseUpdate(
        date: j['date'] as String? ?? '',
        side: _normalizeSide(j['side'] as String? ?? 'left'),
        kind: j['kind'] as String? ?? 'note',
        text: j['text'] as String? ?? '',
        time: j['time'] as String? ?? '',
        sub: j['sub'] as String? ?? '',
        share: j['share'] as bool? ?? false,
      );

  static String _normalizeSide(String s) {
    if (s == 'right') return 'court';
    if (s == 'left') return 'lawyer';
    return s;
  }

  static String sideToWire(String s) => s == 'court' ? 'right' : 'left';
}

class MunshiCase {
  MunshiCase({
    required this.id,
    required this.parties,
    required this.caseNo,
    required this.court,
    this.courtType = '',
    this.color = '#2F5D50',
    this.stage = '',
    this.nextDate,
    this.nextDetail = '',
    this.unread = 0,
    this.pinned = false,
    this.urgent = false,
    this.disposed = false,
    this.cnr = '',
    this.references = '',
    ClientInfo? client,
    FeeInfo? fee,
    List<CaseHearing>? hearings,
    List<CaseDocument>? docs,
    List<CasePayment>? payments,
    List<CaseUpdate>? updates,
  })  : client = client ?? const ClientInfo(),
        fee = fee ?? const FeeInfo(),
        hearings = hearings ?? [],
        docs = docs ?? [],
        payments = payments ?? [],
        updates = updates ?? [];

  String id;
  String parties;
  String caseNo;
  String court;
  String courtType;
  String color;
  String stage;
  String? nextDate;
  String nextDetail;
  int unread;
  bool pinned;
  bool urgent;
  bool disposed;
  String cnr;
  String references;
  ClientInfo client;
  FeeInfo fee;
  List<CaseHearing> hearings;
  List<CaseDocument> docs;
  List<CasePayment> payments;
  List<CaseUpdate> updates;

  int get collectedRupees => payments.fold(0, (s, p) => s + p.amount);
  int get dueRupees => (fee.agreed - collectedRupees).clamp(0, 1 << 31);

  Map<String, dynamic> toJson() => {
        'id': id,
        'parties': parties,
        'caseNo': caseNo,
        'court': court,
        'courtType': courtType,
        'color': color,
        'stage': stage,
        'nextDate': nextDate,
        'nextDetail': nextDetail,
        'unread': unread,
        'pinned': pinned,
        'urgent': urgent,
        'disposed': disposed,
        'cnr': cnr,
        'references': references,
        'client': client.toJson(),
        'fee': fee.toJson(),
        'hearings': hearings.map((e) => e.toJson()).toList(),
        'docs': docs.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'updates': updates.map((e) => e.toJson()).toList(),
      };

  factory MunshiCase.fromJson(Map<String, dynamic> j) => MunshiCase(
        id: j['id'] as String? ?? '',
        parties: j['parties'] as String? ?? '',
        caseNo: j['caseNo'] as String? ?? '',
        court: j['court'] as String? ?? '',
        courtType: j['courtType'] as String? ?? '',
        color: j['color'] as String? ?? '#2F5D50',
        stage: j['stage'] as String? ?? '',
        nextDate: j['nextDate'] as String?,
        nextDetail: j['nextDetail'] as String? ?? '',
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        pinned: j['pinned'] as bool? ?? false,
        urgent: j['urgent'] as bool? ?? false,
        disposed: j['disposed'] as bool? ?? false,
        cnr: j['cnr'] as String? ?? '',
        references: j['references'] as String? ?? '',
        client: ClientInfo.fromJson(j['client'] as Map<String, dynamic>?),
        fee: FeeInfo.fromJson(j['fee'] as Map<String, dynamic>?),
        hearings: (j['hearings'] as List<dynamic>?)
                ?.map((e) => CaseHearing.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        docs: (j['docs'] as List<dynamic>?)
                ?.map((e) => CaseDocument.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        payments: (j['payments'] as List<dynamic>?)
                ?.map((e) => CasePayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        updates: (j['updates'] as List<dynamic>?)
                ?.map((e) => CaseUpdate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  MunshiCase copyWith() => MunshiCase.fromJson(toJson());
}

class ChamberProfile {
  const ChamberProfile({
    this.name = '',
    this.enrolment = '',
    this.barCouncil = '',
    this.chamber = '',
    this.phone = '',
    this.initials = '',
  });
  final String name;
  final String enrolment;
  final String barCouncil;
  final String chamber;
  final String phone;
  final String initials;

  Map<String, dynamic> toJson() => {
        'name': name,
        'enrolment': enrolment,
        'barCouncil': barCouncil,
        'chamber': chamber,
        'phone': phone,
        'initials': initials,
      };

  factory ChamberProfile.fromJson(Map<String, dynamic>? j) => ChamberProfile(
        name: j?['name'] as String? ?? '',
        enrolment: j?['enrolment'] as String? ?? '',
        barCouncil: j?['barCouncil'] as String? ?? '',
        chamber: j?['chamber'] as String? ?? '',
        phone: j?['phone'] as String? ?? '',
        initials: j?['initials'] as String? ?? '',
      );
}
