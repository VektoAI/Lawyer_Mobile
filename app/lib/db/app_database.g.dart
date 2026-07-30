// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CaseSummariesTable extends CaseSummaries
    with TableInfo<$CaseSummariesTable, CaseSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaseSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseNumberMeta =
      const VerificationMeta('caseNumber');
  @override
  late final GeneratedColumn<String> caseNumber = GeneratedColumn<String>(
      'case_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courtMeta = const VerificationMeta('court');
  @override
  late final GeneratedColumn<String> court = GeneratedColumn<String>(
      'court', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _courtTypeMeta =
      const VerificationMeta('courtType');
  @override
  late final GeneratedColumn<String> courtType = GeneratedColumn<String>(
      'court_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
      'stage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextDateMeta =
      const VerificationMeta('nextDate');
  @override
  late final GeneratedColumn<DateTime> nextDate = GeneratedColumn<DateTime>(
      'next_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextDetailMeta =
      const VerificationMeta('nextDetail');
  @override
  late final GeneratedColumn<String> nextDetail = GeneratedColumn<String>(
      'next_detail', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partiesMeta =
      const VerificationMeta('parties');
  @override
  late final GeneratedColumn<String> parties = GeneratedColumn<String>(
      'parties', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientPhoneMeta =
      const VerificationMeta('clientPhone');
  @override
  late final GeneratedColumn<String> clientPhone = GeneratedColumn<String>(
      'client_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feeAgreedRupeesMeta =
      const VerificationMeta('feeAgreedRupees');
  @override
  late final GeneratedColumn<int> feeAgreedRupees = GeneratedColumn<int>(
      'fee_agreed_rupees', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _urgentMeta = const VerificationMeta('urgent');
  @override
  late final GeneratedColumn<bool> urgent = GeneratedColumn<bool>(
      'urgent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("urgent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _disposedMeta =
      const VerificationMeta('disposed');
  @override
  late final GeneratedColumn<bool> disposed = GeneratedColumn<bool>(
      'disposed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("disposed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _unreadCountMeta =
      const VerificationMeta('unreadCount');
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
      'unread_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        caseNumber,
        court,
        courtType,
        stage,
        nextDate,
        nextDetail,
        parties,
        clientName,
        clientPhone,
        feeAgreedRupees,
        pinned,
        urgent,
        disposed,
        unreadCount,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'case_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<CaseSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_number')) {
      context.handle(
          _caseNumberMeta,
          caseNumber.isAcceptableOrUnknown(
              data['case_number']!, _caseNumberMeta));
    } else if (isInserting) {
      context.missing(_caseNumberMeta);
    }
    if (data.containsKey('court')) {
      context.handle(
          _courtMeta, court.isAcceptableOrUnknown(data['court']!, _courtMeta));
    } else if (isInserting) {
      context.missing(_courtMeta);
    }
    if (data.containsKey('court_type')) {
      context.handle(_courtTypeMeta,
          courtType.isAcceptableOrUnknown(data['court_type']!, _courtTypeMeta));
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    }
    if (data.containsKey('next_date')) {
      context.handle(_nextDateMeta,
          nextDate.isAcceptableOrUnknown(data['next_date']!, _nextDateMeta));
    }
    if (data.containsKey('next_detail')) {
      context.handle(
          _nextDetailMeta,
          nextDetail.isAcceptableOrUnknown(
              data['next_detail']!, _nextDetailMeta));
    }
    if (data.containsKey('parties')) {
      context.handle(_partiesMeta,
          parties.isAcceptableOrUnknown(data['parties']!, _partiesMeta));
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    }
    if (data.containsKey('client_phone')) {
      context.handle(
          _clientPhoneMeta,
          clientPhone.isAcceptableOrUnknown(
              data['client_phone']!, _clientPhoneMeta));
    }
    if (data.containsKey('fee_agreed_rupees')) {
      context.handle(
          _feeAgreedRupeesMeta,
          feeAgreedRupees.isAcceptableOrUnknown(
              data['fee_agreed_rupees']!, _feeAgreedRupeesMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('urgent')) {
      context.handle(_urgentMeta,
          urgent.isAcceptableOrUnknown(data['urgent']!, _urgentMeta));
    }
    if (data.containsKey('disposed')) {
      context.handle(_disposedMeta,
          disposed.isAcceptableOrUnknown(data['disposed']!, _disposedMeta));
    }
    if (data.containsKey('unread_count')) {
      context.handle(
          _unreadCountMeta,
          unreadCount.isAcceptableOrUnknown(
              data['unread_count']!, _unreadCountMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaseSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_number'])!,
      court: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}court'])!,
      courtType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}court_type']),
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage']),
      nextDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_date']),
      nextDetail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_detail']),
      parties: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parties']),
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name']),
      clientPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_phone']),
      feeAgreedRupees: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fee_agreed_rupees']),
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      urgent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}urgent'])!,
      disposed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}disposed'])!,
      unreadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread_count'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CaseSummariesTable createAlias(String alias) {
    return $CaseSummariesTable(attachedDatabase, alias);
  }
}

class CaseSummary extends DataClass implements Insertable<CaseSummary> {
  final String id;
  final String caseNumber;
  final String court;
  final String? courtType;
  final String? stage;
  final DateTime? nextDate;
  final String? nextDetail;
  final String? parties;
  final String? clientName;
  final String? clientPhone;
  final int? feeAgreedRupees;
  final bool pinned;
  final bool urgent;
  final bool disposed;
  final int unreadCount;
  final DateTime updatedAt;
  const CaseSummary(
      {required this.id,
      required this.caseNumber,
      required this.court,
      this.courtType,
      this.stage,
      this.nextDate,
      this.nextDetail,
      this.parties,
      this.clientName,
      this.clientPhone,
      this.feeAgreedRupees,
      required this.pinned,
      required this.urgent,
      required this.disposed,
      required this.unreadCount,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_number'] = Variable<String>(caseNumber);
    map['court'] = Variable<String>(court);
    if (!nullToAbsent || courtType != null) {
      map['court_type'] = Variable<String>(courtType);
    }
    if (!nullToAbsent || stage != null) {
      map['stage'] = Variable<String>(stage);
    }
    if (!nullToAbsent || nextDate != null) {
      map['next_date'] = Variable<DateTime>(nextDate);
    }
    if (!nullToAbsent || nextDetail != null) {
      map['next_detail'] = Variable<String>(nextDetail);
    }
    if (!nullToAbsent || parties != null) {
      map['parties'] = Variable<String>(parties);
    }
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || clientPhone != null) {
      map['client_phone'] = Variable<String>(clientPhone);
    }
    if (!nullToAbsent || feeAgreedRupees != null) {
      map['fee_agreed_rupees'] = Variable<int>(feeAgreedRupees);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['urgent'] = Variable<bool>(urgent);
    map['disposed'] = Variable<bool>(disposed);
    map['unread_count'] = Variable<int>(unreadCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CaseSummariesCompanion toCompanion(bool nullToAbsent) {
    return CaseSummariesCompanion(
      id: Value(id),
      caseNumber: Value(caseNumber),
      court: Value(court),
      courtType: courtType == null && nullToAbsent
          ? const Value.absent()
          : Value(courtType),
      stage:
          stage == null && nullToAbsent ? const Value.absent() : Value(stage),
      nextDate: nextDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDate),
      nextDetail: nextDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDetail),
      parties: parties == null && nullToAbsent
          ? const Value.absent()
          : Value(parties),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      clientPhone: clientPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(clientPhone),
      feeAgreedRupees: feeAgreedRupees == null && nullToAbsent
          ? const Value.absent()
          : Value(feeAgreedRupees),
      pinned: Value(pinned),
      urgent: Value(urgent),
      disposed: Value(disposed),
      unreadCount: Value(unreadCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory CaseSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseSummary(
      id: serializer.fromJson<String>(json['id']),
      caseNumber: serializer.fromJson<String>(json['caseNumber']),
      court: serializer.fromJson<String>(json['court']),
      courtType: serializer.fromJson<String?>(json['courtType']),
      stage: serializer.fromJson<String?>(json['stage']),
      nextDate: serializer.fromJson<DateTime?>(json['nextDate']),
      nextDetail: serializer.fromJson<String?>(json['nextDetail']),
      parties: serializer.fromJson<String?>(json['parties']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      clientPhone: serializer.fromJson<String?>(json['clientPhone']),
      feeAgreedRupees: serializer.fromJson<int?>(json['feeAgreedRupees']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      urgent: serializer.fromJson<bool>(json['urgent']),
      disposed: serializer.fromJson<bool>(json['disposed']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseNumber': serializer.toJson<String>(caseNumber),
      'court': serializer.toJson<String>(court),
      'courtType': serializer.toJson<String?>(courtType),
      'stage': serializer.toJson<String?>(stage),
      'nextDate': serializer.toJson<DateTime?>(nextDate),
      'nextDetail': serializer.toJson<String?>(nextDetail),
      'parties': serializer.toJson<String?>(parties),
      'clientName': serializer.toJson<String?>(clientName),
      'clientPhone': serializer.toJson<String?>(clientPhone),
      'feeAgreedRupees': serializer.toJson<int?>(feeAgreedRupees),
      'pinned': serializer.toJson<bool>(pinned),
      'urgent': serializer.toJson<bool>(urgent),
      'disposed': serializer.toJson<bool>(disposed),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CaseSummary copyWith(
          {String? id,
          String? caseNumber,
          String? court,
          Value<String?> courtType = const Value.absent(),
          Value<String?> stage = const Value.absent(),
          Value<DateTime?> nextDate = const Value.absent(),
          Value<String?> nextDetail = const Value.absent(),
          Value<String?> parties = const Value.absent(),
          Value<String?> clientName = const Value.absent(),
          Value<String?> clientPhone = const Value.absent(),
          Value<int?> feeAgreedRupees = const Value.absent(),
          bool? pinned,
          bool? urgent,
          bool? disposed,
          int? unreadCount,
          DateTime? updatedAt}) =>
      CaseSummary(
        id: id ?? this.id,
        caseNumber: caseNumber ?? this.caseNumber,
        court: court ?? this.court,
        courtType: courtType.present ? courtType.value : this.courtType,
        stage: stage.present ? stage.value : this.stage,
        nextDate: nextDate.present ? nextDate.value : this.nextDate,
        nextDetail: nextDetail.present ? nextDetail.value : this.nextDetail,
        parties: parties.present ? parties.value : this.parties,
        clientName: clientName.present ? clientName.value : this.clientName,
        clientPhone: clientPhone.present ? clientPhone.value : this.clientPhone,
        feeAgreedRupees: feeAgreedRupees.present
            ? feeAgreedRupees.value
            : this.feeAgreedRupees,
        pinned: pinned ?? this.pinned,
        urgent: urgent ?? this.urgent,
        disposed: disposed ?? this.disposed,
        unreadCount: unreadCount ?? this.unreadCount,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CaseSummary copyWithCompanion(CaseSummariesCompanion data) {
    return CaseSummary(
      id: data.id.present ? data.id.value : this.id,
      caseNumber:
          data.caseNumber.present ? data.caseNumber.value : this.caseNumber,
      court: data.court.present ? data.court.value : this.court,
      courtType: data.courtType.present ? data.courtType.value : this.courtType,
      stage: data.stage.present ? data.stage.value : this.stage,
      nextDate: data.nextDate.present ? data.nextDate.value : this.nextDate,
      nextDetail:
          data.nextDetail.present ? data.nextDetail.value : this.nextDetail,
      parties: data.parties.present ? data.parties.value : this.parties,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      clientPhone:
          data.clientPhone.present ? data.clientPhone.value : this.clientPhone,
      feeAgreedRupees: data.feeAgreedRupees.present
          ? data.feeAgreedRupees.value
          : this.feeAgreedRupees,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      urgent: data.urgent.present ? data.urgent.value : this.urgent,
      disposed: data.disposed.present ? data.disposed.value : this.disposed,
      unreadCount:
          data.unreadCount.present ? data.unreadCount.value : this.unreadCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseSummary(')
          ..write('id: $id, ')
          ..write('caseNumber: $caseNumber, ')
          ..write('court: $court, ')
          ..write('courtType: $courtType, ')
          ..write('stage: $stage, ')
          ..write('nextDate: $nextDate, ')
          ..write('nextDetail: $nextDetail, ')
          ..write('parties: $parties, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('feeAgreedRupees: $feeAgreedRupees, ')
          ..write('pinned: $pinned, ')
          ..write('urgent: $urgent, ')
          ..write('disposed: $disposed, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      caseNumber,
      court,
      courtType,
      stage,
      nextDate,
      nextDetail,
      parties,
      clientName,
      clientPhone,
      feeAgreedRupees,
      pinned,
      urgent,
      disposed,
      unreadCount,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseSummary &&
          other.id == this.id &&
          other.caseNumber == this.caseNumber &&
          other.court == this.court &&
          other.courtType == this.courtType &&
          other.stage == this.stage &&
          other.nextDate == this.nextDate &&
          other.nextDetail == this.nextDetail &&
          other.parties == this.parties &&
          other.clientName == this.clientName &&
          other.clientPhone == this.clientPhone &&
          other.feeAgreedRupees == this.feeAgreedRupees &&
          other.pinned == this.pinned &&
          other.urgent == this.urgent &&
          other.disposed == this.disposed &&
          other.unreadCount == this.unreadCount &&
          other.updatedAt == this.updatedAt);
}

class CaseSummariesCompanion extends UpdateCompanion<CaseSummary> {
  final Value<String> id;
  final Value<String> caseNumber;
  final Value<String> court;
  final Value<String?> courtType;
  final Value<String?> stage;
  final Value<DateTime?> nextDate;
  final Value<String?> nextDetail;
  final Value<String?> parties;
  final Value<String?> clientName;
  final Value<String?> clientPhone;
  final Value<int?> feeAgreedRupees;
  final Value<bool> pinned;
  final Value<bool> urgent;
  final Value<bool> disposed;
  final Value<int> unreadCount;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CaseSummariesCompanion({
    this.id = const Value.absent(),
    this.caseNumber = const Value.absent(),
    this.court = const Value.absent(),
    this.courtType = const Value.absent(),
    this.stage = const Value.absent(),
    this.nextDate = const Value.absent(),
    this.nextDetail = const Value.absent(),
    this.parties = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.feeAgreedRupees = const Value.absent(),
    this.pinned = const Value.absent(),
    this.urgent = const Value.absent(),
    this.disposed = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaseSummariesCompanion.insert({
    required String id,
    required String caseNumber,
    required String court,
    this.courtType = const Value.absent(),
    this.stage = const Value.absent(),
    this.nextDate = const Value.absent(),
    this.nextDetail = const Value.absent(),
    this.parties = const Value.absent(),
    this.clientName = const Value.absent(),
    this.clientPhone = const Value.absent(),
    this.feeAgreedRupees = const Value.absent(),
    this.pinned = const Value.absent(),
    this.urgent = const Value.absent(),
    this.disposed = const Value.absent(),
    this.unreadCount = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseNumber = Value(caseNumber),
        court = Value(court),
        updatedAt = Value(updatedAt);
  static Insertable<CaseSummary> custom({
    Expression<String>? id,
    Expression<String>? caseNumber,
    Expression<String>? court,
    Expression<String>? courtType,
    Expression<String>? stage,
    Expression<DateTime>? nextDate,
    Expression<String>? nextDetail,
    Expression<String>? parties,
    Expression<String>? clientName,
    Expression<String>? clientPhone,
    Expression<int>? feeAgreedRupees,
    Expression<bool>? pinned,
    Expression<bool>? urgent,
    Expression<bool>? disposed,
    Expression<int>? unreadCount,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseNumber != null) 'case_number': caseNumber,
      if (court != null) 'court': court,
      if (courtType != null) 'court_type': courtType,
      if (stage != null) 'stage': stage,
      if (nextDate != null) 'next_date': nextDate,
      if (nextDetail != null) 'next_detail': nextDetail,
      if (parties != null) 'parties': parties,
      if (clientName != null) 'client_name': clientName,
      if (clientPhone != null) 'client_phone': clientPhone,
      if (feeAgreedRupees != null) 'fee_agreed_rupees': feeAgreedRupees,
      if (pinned != null) 'pinned': pinned,
      if (urgent != null) 'urgent': urgent,
      if (disposed != null) 'disposed': disposed,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaseSummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseNumber,
      Value<String>? court,
      Value<String?>? courtType,
      Value<String?>? stage,
      Value<DateTime?>? nextDate,
      Value<String?>? nextDetail,
      Value<String?>? parties,
      Value<String?>? clientName,
      Value<String?>? clientPhone,
      Value<int?>? feeAgreedRupees,
      Value<bool>? pinned,
      Value<bool>? urgent,
      Value<bool>? disposed,
      Value<int>? unreadCount,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CaseSummariesCompanion(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      court: court ?? this.court,
      courtType: courtType ?? this.courtType,
      stage: stage ?? this.stage,
      nextDate: nextDate ?? this.nextDate,
      nextDetail: nextDetail ?? this.nextDetail,
      parties: parties ?? this.parties,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      feeAgreedRupees: feeAgreedRupees ?? this.feeAgreedRupees,
      pinned: pinned ?? this.pinned,
      urgent: urgent ?? this.urgent,
      disposed: disposed ?? this.disposed,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseNumber.present) {
      map['case_number'] = Variable<String>(caseNumber.value);
    }
    if (court.present) {
      map['court'] = Variable<String>(court.value);
    }
    if (courtType.present) {
      map['court_type'] = Variable<String>(courtType.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (nextDate.present) {
      map['next_date'] = Variable<DateTime>(nextDate.value);
    }
    if (nextDetail.present) {
      map['next_detail'] = Variable<String>(nextDetail.value);
    }
    if (parties.present) {
      map['parties'] = Variable<String>(parties.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (clientPhone.present) {
      map['client_phone'] = Variable<String>(clientPhone.value);
    }
    if (feeAgreedRupees.present) {
      map['fee_agreed_rupees'] = Variable<int>(feeAgreedRupees.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (urgent.present) {
      map['urgent'] = Variable<bool>(urgent.value);
    }
    if (disposed.present) {
      map['disposed'] = Variable<bool>(disposed.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaseSummariesCompanion(')
          ..write('id: $id, ')
          ..write('caseNumber: $caseNumber, ')
          ..write('court: $court, ')
          ..write('courtType: $courtType, ')
          ..write('stage: $stage, ')
          ..write('nextDate: $nextDate, ')
          ..write('nextDetail: $nextDetail, ')
          ..write('parties: $parties, ')
          ..write('clientName: $clientName, ')
          ..write('clientPhone: $clientPhone, ')
          ..write('feeAgreedRupees: $feeAgreedRupees, ')
          ..write('pinned: $pinned, ')
          ..write('urgent: $urgent, ')
          ..write('disposed: $disposed, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaseEventsTable extends CaseEvents
    with TableInfo<$CaseEventsTable, CaseEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaseEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES case_summaries (id)'));
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dedupKeyMeta =
      const VerificationMeta('dedupKey');
  @override
  late final GeneratedColumn<String> dedupKey = GeneratedColumn<String>(
      'dedup_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
      'side', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        caseId,
        eventId,
        dedupKey,
        side,
        kind,
        payloadJson,
        createdAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'case_events';
  @override
  VerificationContext validateIntegrity(Insertable<CaseEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('dedup_key')) {
      context.handle(_dedupKeyMeta,
          dedupKey.isAcceptableOrUnknown(data['dedup_key']!, _dedupKeyMeta));
    } else if (isInserting) {
      context.missing(_dedupKeyMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
          _sideMeta, side.isAcceptableOrUnknown(data['side']!, _sideMeta));
    } else if (isInserting) {
      context.missing(_sideMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CaseEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaseEvent(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      dedupKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dedup_key'])!,
      side: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}side'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $CaseEventsTable createAlias(String alias) {
    return $CaseEventsTable(attachedDatabase, alias);
  }
}

class CaseEvent extends DataClass implements Insertable<CaseEvent> {
  final int localId;
  final String caseId;
  final String eventId;
  final String dedupKey;
  final String side;
  final String kind;
  final String payloadJson;
  final DateTime createdAt;
  final bool synced;
  const CaseEvent(
      {required this.localId,
      required this.caseId,
      required this.eventId,
      required this.dedupKey,
      required this.side,
      required this.kind,
      required this.payloadJson,
      required this.createdAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['case_id'] = Variable<String>(caseId);
    map['event_id'] = Variable<String>(eventId);
    map['dedup_key'] = Variable<String>(dedupKey);
    map['side'] = Variable<String>(side);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  CaseEventsCompanion toCompanion(bool nullToAbsent) {
    return CaseEventsCompanion(
      localId: Value(localId),
      caseId: Value(caseId),
      eventId: Value(eventId),
      dedupKey: Value(dedupKey),
      side: Value(side),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory CaseEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaseEvent(
      localId: serializer.fromJson<int>(json['localId']),
      caseId: serializer.fromJson<String>(json['caseId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      dedupKey: serializer.fromJson<String>(json['dedupKey']),
      side: serializer.fromJson<String>(json['side']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'caseId': serializer.toJson<String>(caseId),
      'eventId': serializer.toJson<String>(eventId),
      'dedupKey': serializer.toJson<String>(dedupKey),
      'side': serializer.toJson<String>(side),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  CaseEvent copyWith(
          {int? localId,
          String? caseId,
          String? eventId,
          String? dedupKey,
          String? side,
          String? kind,
          String? payloadJson,
          DateTime? createdAt,
          bool? synced}) =>
      CaseEvent(
        localId: localId ?? this.localId,
        caseId: caseId ?? this.caseId,
        eventId: eventId ?? this.eventId,
        dedupKey: dedupKey ?? this.dedupKey,
        side: side ?? this.side,
        kind: kind ?? this.kind,
        payloadJson: payloadJson ?? this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
  CaseEvent copyWithCompanion(CaseEventsCompanion data) {
    return CaseEvent(
      localId: data.localId.present ? data.localId.value : this.localId,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      dedupKey: data.dedupKey.present ? data.dedupKey.value : this.dedupKey,
      side: data.side.present ? data.side.value : this.side,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaseEvent(')
          ..write('localId: $localId, ')
          ..write('caseId: $caseId, ')
          ..write('eventId: $eventId, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('side: $side, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, caseId, eventId, dedupKey, side,
      kind, payloadJson, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaseEvent &&
          other.localId == this.localId &&
          other.caseId == this.caseId &&
          other.eventId == this.eventId &&
          other.dedupKey == this.dedupKey &&
          other.side == this.side &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class CaseEventsCompanion extends UpdateCompanion<CaseEvent> {
  final Value<int> localId;
  final Value<String> caseId;
  final Value<String> eventId;
  final Value<String> dedupKey;
  final Value<String> side;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const CaseEventsCompanion({
    this.localId = const Value.absent(),
    this.caseId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.dedupKey = const Value.absent(),
    this.side = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  CaseEventsCompanion.insert({
    this.localId = const Value.absent(),
    required String caseId,
    required String eventId,
    required String dedupKey,
    required String side,
    required String kind,
    required String payloadJson,
    required DateTime createdAt,
    this.synced = const Value.absent(),
  })  : caseId = Value(caseId),
        eventId = Value(eventId),
        dedupKey = Value(dedupKey),
        side = Value(side),
        kind = Value(kind),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<CaseEvent> custom({
    Expression<int>? localId,
    Expression<String>? caseId,
    Expression<String>? eventId,
    Expression<String>? dedupKey,
    Expression<String>? side,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (caseId != null) 'case_id': caseId,
      if (eventId != null) 'event_id': eventId,
      if (dedupKey != null) 'dedup_key': dedupKey,
      if (side != null) 'side': side,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  CaseEventsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? caseId,
      Value<String>? eventId,
      Value<String>? dedupKey,
      Value<String>? side,
      Value<String>? kind,
      Value<String>? payloadJson,
      Value<DateTime>? createdAt,
      Value<bool>? synced}) {
    return CaseEventsCompanion(
      localId: localId ?? this.localId,
      caseId: caseId ?? this.caseId,
      eventId: eventId ?? this.eventId,
      dedupKey: dedupKey ?? this.dedupKey,
      side: side ?? this.side,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (dedupKey.present) {
      map['dedup_key'] = Variable<String>(dedupKey.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaseEventsCompanion(')
          ..write('localId: $localId, ')
          ..write('caseId: $caseId, ')
          ..write('eventId: $eventId, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('side: $side, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $DocumentRowsTable extends DocumentRows
    with TableInfo<$DocumentRowsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
      'case_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES case_summaries (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, caseId, name, localPath, sha256, sizeBytes, uploadedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_rows';
  @override
  VerificationContext validateIntegrity(Insertable<DocumentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(_caseIdMeta,
          caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta));
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    } else if (isInserting) {
      context.missing(_uploadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      caseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at'])!,
    );
  }

  @override
  $DocumentRowsTable createAlias(String alias) {
    return $DocumentRowsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String caseId;
  final String name;
  final String localPath;
  final String sha256;
  final int sizeBytes;
  final DateTime uploadedAt;
  const DocumentRow(
      {required this.id,
      required this.caseId,
      required this.name,
      required this.localPath,
      required this.sha256,
      required this.sizeBytes,
      required this.uploadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['name'] = Variable<String>(name);
    map['local_path'] = Variable<String>(localPath);
    map['sha256'] = Variable<String>(sha256);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    return map;
  }

  DocumentRowsCompanion toCompanion(bool nullToAbsent) {
    return DocumentRowsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      name: Value(name),
      localPath: Value(localPath),
      sha256: Value(sha256),
      sizeBytes: Value(sizeBytes),
      uploadedAt: Value(uploadedAt),
    );
  }

  factory DocumentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      name: serializer.fromJson<String>(json['name']),
      localPath: serializer.fromJson<String>(json['localPath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      uploadedAt: serializer.fromJson<DateTime>(json['uploadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'name': serializer.toJson<String>(name),
      'localPath': serializer.toJson<String>(localPath),
      'sha256': serializer.toJson<String>(sha256),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'uploadedAt': serializer.toJson<DateTime>(uploadedAt),
    };
  }

  DocumentRow copyWith(
          {String? id,
          String? caseId,
          String? name,
          String? localPath,
          String? sha256,
          int? sizeBytes,
          DateTime? uploadedAt}) =>
      DocumentRow(
        id: id ?? this.id,
        caseId: caseId ?? this.caseId,
        name: name ?? this.name,
        localPath: localPath ?? this.localPath,
        sha256: sha256 ?? this.sha256,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        uploadedAt: uploadedAt ?? this.uploadedAt,
      );
  DocumentRow copyWithCompanion(DocumentRowsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      name: data.name.present ? data.name.value : this.name,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('name: $name, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadedAt: $uploadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, caseId, name, localPath, sha256, sizeBytes, uploadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.name == this.name &&
          other.localPath == this.localPath &&
          other.sha256 == this.sha256 &&
          other.sizeBytes == this.sizeBytes &&
          other.uploadedAt == this.uploadedAt);
}

class DocumentRowsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<String> name;
  final Value<String> localPath;
  final Value<String> sha256;
  final Value<int> sizeBytes;
  final Value<DateTime> uploadedAt;
  final Value<int> rowid;
  const DocumentRowsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.name = const Value.absent(),
    this.localPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentRowsCompanion.insert({
    required String id,
    required String caseId,
    required String name,
    required String localPath,
    required String sha256,
    required int sizeBytes,
    required DateTime uploadedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        caseId = Value(caseId),
        name = Value(name),
        localPath = Value(localPath),
        sha256 = Value(sha256),
        sizeBytes = Value(sizeBytes),
        uploadedAt = Value(uploadedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<String>? name,
    Expression<String>? localPath,
    Expression<String>? sha256,
    Expression<int>? sizeBytes,
    Expression<DateTime>? uploadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (name != null) 'name': name,
      if (localPath != null) 'local_path': localPath,
      if (sha256 != null) 'sha256': sha256,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? caseId,
      Value<String>? name,
      Value<String>? localPath,
      Value<String>? sha256,
      Value<int>? sizeBytes,
      Value<DateTime>? uploadedAt,
      Value<int>? rowid}) {
    return DocumentRowsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRowsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('name: $name, ')
          ..write('localPath: $localPath, ')
          ..write('sha256: $sha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CaseSummariesTable caseSummaries = $CaseSummariesTable(this);
  late final $CaseEventsTable caseEvents = $CaseEventsTable(this);
  late final $DocumentRowsTable documentRows = $DocumentRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [caseSummaries, caseEvents, documentRows];
}

typedef $$CaseSummariesTableCreateCompanionBuilder = CaseSummariesCompanion
    Function({
  required String id,
  required String caseNumber,
  required String court,
  Value<String?> courtType,
  Value<String?> stage,
  Value<DateTime?> nextDate,
  Value<String?> nextDetail,
  Value<String?> parties,
  Value<String?> clientName,
  Value<String?> clientPhone,
  Value<int?> feeAgreedRupees,
  Value<bool> pinned,
  Value<bool> urgent,
  Value<bool> disposed,
  Value<int> unreadCount,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CaseSummariesTableUpdateCompanionBuilder = CaseSummariesCompanion
    Function({
  Value<String> id,
  Value<String> caseNumber,
  Value<String> court,
  Value<String?> courtType,
  Value<String?> stage,
  Value<DateTime?> nextDate,
  Value<String?> nextDetail,
  Value<String?> parties,
  Value<String?> clientName,
  Value<String?> clientPhone,
  Value<int?> feeAgreedRupees,
  Value<bool> pinned,
  Value<bool> urgent,
  Value<bool> disposed,
  Value<int> unreadCount,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$CaseSummariesTableReferences
    extends BaseReferences<_$AppDatabase, $CaseSummariesTable, CaseSummary> {
  $$CaseSummariesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CaseEventsTable, List<CaseEvent>>
      _caseEventsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.caseEvents,
              aliasName: 'case_summaries__id__case_events__case_id');

  $$CaseEventsTableProcessedTableManager get caseEventsRefs {
    final manager = $$CaseEventsTableTableManager($_db, $_db.caseEvents)
        .filter((f) => f.caseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_caseEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DocumentRowsTable, List<DocumentRow>>
      _documentRowsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.documentRows,
              aliasName: 'case_summaries__id__document_rows__case_id');

  $$DocumentRowsTableProcessedTableManager get documentRowsRefs {
    final manager = $$DocumentRowsTableTableManager($_db, $_db.documentRows)
        .filter((f) => f.caseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentRowsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CaseSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $CaseSummariesTable> {
  $$CaseSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get court => $composableBuilder(
      column: $table.court, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get courtType => $composableBuilder(
      column: $table.courtType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDate => $composableBuilder(
      column: $table.nextDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextDetail => $composableBuilder(
      column: $table.nextDetail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parties => $composableBuilder(
      column: $table.parties, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get feeAgreedRupees => $composableBuilder(
      column: $table.feeAgreedRupees,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get urgent => $composableBuilder(
      column: $table.urgent, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get disposed => $composableBuilder(
      column: $table.disposed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> caseEventsRefs(
      Expression<bool> Function($$CaseEventsTableFilterComposer f) f) {
    final $$CaseEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.caseEvents,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseEventsTableFilterComposer(
              $db: $db,
              $table: $db.caseEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> documentRowsRefs(
      Expression<bool> Function($$DocumentRowsTableFilterComposer f) f) {
    final $$DocumentRowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.documentRows,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRowsTableFilterComposer(
              $db: $db,
              $table: $db.documentRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CaseSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $CaseSummariesTable> {
  $$CaseSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get court => $composableBuilder(
      column: $table.court, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get courtType => $composableBuilder(
      column: $table.courtType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDate => $composableBuilder(
      column: $table.nextDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextDetail => $composableBuilder(
      column: $table.nextDetail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parties => $composableBuilder(
      column: $table.parties, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get feeAgreedRupees => $composableBuilder(
      column: $table.feeAgreedRupees,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get urgent => $composableBuilder(
      column: $table.urgent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get disposed => $composableBuilder(
      column: $table.disposed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CaseSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CaseSummariesTable> {
  $$CaseSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => column);

  GeneratedColumn<String> get court =>
      $composableBuilder(column: $table.court, builder: (column) => column);

  GeneratedColumn<String> get courtType =>
      $composableBuilder(column: $table.courtType, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDate =>
      $composableBuilder(column: $table.nextDate, builder: (column) => column);

  GeneratedColumn<String> get nextDetail => $composableBuilder(
      column: $table.nextDetail, builder: (column) => column);

  GeneratedColumn<String> get parties =>
      $composableBuilder(column: $table.parties, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<String> get clientPhone => $composableBuilder(
      column: $table.clientPhone, builder: (column) => column);

  GeneratedColumn<int> get feeAgreedRupees => $composableBuilder(
      column: $table.feeAgreedRupees, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get urgent =>
      $composableBuilder(column: $table.urgent, builder: (column) => column);

  GeneratedColumn<bool> get disposed =>
      $composableBuilder(column: $table.disposed, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
      column: $table.unreadCount, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> caseEventsRefs<T extends Object>(
      Expression<T> Function($$CaseEventsTableAnnotationComposer a) f) {
    final $$CaseEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.caseEvents,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.caseEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> documentRowsRefs<T extends Object>(
      Expression<T> Function($$DocumentRowsTableAnnotationComposer a) f) {
    final $$DocumentRowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.documentRows,
        getReferencedColumn: (t) => t.caseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentRowsTableAnnotationComposer(
              $db: $db,
              $table: $db.documentRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CaseSummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CaseSummariesTable,
    CaseSummary,
    $$CaseSummariesTableFilterComposer,
    $$CaseSummariesTableOrderingComposer,
    $$CaseSummariesTableAnnotationComposer,
    $$CaseSummariesTableCreateCompanionBuilder,
    $$CaseSummariesTableUpdateCompanionBuilder,
    (CaseSummary, $$CaseSummariesTableReferences),
    CaseSummary,
    PrefetchHooks Function({bool caseEventsRefs, bool documentRowsRefs})> {
  $$CaseSummariesTableTableManager(_$AppDatabase db, $CaseSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaseSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaseSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaseSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseNumber = const Value.absent(),
            Value<String> court = const Value.absent(),
            Value<String?> courtType = const Value.absent(),
            Value<String?> stage = const Value.absent(),
            Value<DateTime?> nextDate = const Value.absent(),
            Value<String?> nextDetail = const Value.absent(),
            Value<String?> parties = const Value.absent(),
            Value<String?> clientName = const Value.absent(),
            Value<String?> clientPhone = const Value.absent(),
            Value<int?> feeAgreedRupees = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> urgent = const Value.absent(),
            Value<bool> disposed = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CaseSummariesCompanion(
            id: id,
            caseNumber: caseNumber,
            court: court,
            courtType: courtType,
            stage: stage,
            nextDate: nextDate,
            nextDetail: nextDetail,
            parties: parties,
            clientName: clientName,
            clientPhone: clientPhone,
            feeAgreedRupees: feeAgreedRupees,
            pinned: pinned,
            urgent: urgent,
            disposed: disposed,
            unreadCount: unreadCount,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseNumber,
            required String court,
            Value<String?> courtType = const Value.absent(),
            Value<String?> stage = const Value.absent(),
            Value<DateTime?> nextDate = const Value.absent(),
            Value<String?> nextDetail = const Value.absent(),
            Value<String?> parties = const Value.absent(),
            Value<String?> clientName = const Value.absent(),
            Value<String?> clientPhone = const Value.absent(),
            Value<int?> feeAgreedRupees = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> urgent = const Value.absent(),
            Value<bool> disposed = const Value.absent(),
            Value<int> unreadCount = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CaseSummariesCompanion.insert(
            id: id,
            caseNumber: caseNumber,
            court: court,
            courtType: courtType,
            stage: stage,
            nextDate: nextDate,
            nextDetail: nextDetail,
            parties: parties,
            clientName: clientName,
            clientPhone: clientPhone,
            feeAgreedRupees: feeAgreedRupees,
            pinned: pinned,
            urgent: urgent,
            disposed: disposed,
            unreadCount: unreadCount,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CaseSummariesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {caseEventsRefs = false, documentRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (caseEventsRefs) db.caseEvents,
                if (documentRowsRefs) db.documentRows
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (caseEventsRefs)
                    await $_getPrefetchedData<CaseSummary, $CaseSummariesTable,
                            CaseEvent>(
                        currentTable: table,
                        referencedTable: $$CaseSummariesTableReferences
                            ._caseEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CaseSummariesTableReferences(db, table, p0)
                                .caseEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items),
                  if (documentRowsRefs)
                    await $_getPrefetchedData<CaseSummary, $CaseSummariesTable,
                            DocumentRow>(
                        currentTable: table,
                        referencedTable: $$CaseSummariesTableReferences
                            ._documentRowsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CaseSummariesTableReferences(db, table, p0)
                                .documentRowsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.caseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CaseSummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CaseSummariesTable,
    CaseSummary,
    $$CaseSummariesTableFilterComposer,
    $$CaseSummariesTableOrderingComposer,
    $$CaseSummariesTableAnnotationComposer,
    $$CaseSummariesTableCreateCompanionBuilder,
    $$CaseSummariesTableUpdateCompanionBuilder,
    (CaseSummary, $$CaseSummariesTableReferences),
    CaseSummary,
    PrefetchHooks Function({bool caseEventsRefs, bool documentRowsRefs})>;
typedef $$CaseEventsTableCreateCompanionBuilder = CaseEventsCompanion Function({
  Value<int> localId,
  required String caseId,
  required String eventId,
  required String dedupKey,
  required String side,
  required String kind,
  required String payloadJson,
  required DateTime createdAt,
  Value<bool> synced,
});
typedef $$CaseEventsTableUpdateCompanionBuilder = CaseEventsCompanion Function({
  Value<int> localId,
  Value<String> caseId,
  Value<String> eventId,
  Value<String> dedupKey,
  Value<String> side,
  Value<String> kind,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<bool> synced,
});

final class $$CaseEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CaseEventsTable, CaseEvent> {
  $$CaseEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CaseSummariesTable _caseIdTable(_$AppDatabase db) =>
      db.caseSummaries.createAlias('case_events__case_id__case_summaries__id');

  $$CaseSummariesTableProcessedTableManager get caseId {
    final $_column = $_itemColumn<String>('case_id')!;

    final manager = $$CaseSummariesTableTableManager($_db, $_db.caseSummaries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CaseEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CaseEventsTable> {
  $$CaseEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dedupKey => $composableBuilder(
      column: $table.dedupKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get side => $composableBuilder(
      column: $table.side, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  $$CaseSummariesTableFilterComposer get caseId {
    final $$CaseSummariesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableFilterComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CaseEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CaseEventsTable> {
  $$CaseEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dedupKey => $composableBuilder(
      column: $table.dedupKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get side => $composableBuilder(
      column: $table.side, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  $$CaseSummariesTableOrderingComposer get caseId {
    final $$CaseSummariesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableOrderingComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CaseEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CaseEventsTable> {
  $$CaseEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get dedupKey =>
      $composableBuilder(column: $table.dedupKey, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  $$CaseSummariesTableAnnotationComposer get caseId {
    final $$CaseSummariesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableAnnotationComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CaseEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CaseEventsTable,
    CaseEvent,
    $$CaseEventsTableFilterComposer,
    $$CaseEventsTableOrderingComposer,
    $$CaseEventsTableAnnotationComposer,
    $$CaseEventsTableCreateCompanionBuilder,
    $$CaseEventsTableUpdateCompanionBuilder,
    (CaseEvent, $$CaseEventsTableReferences),
    CaseEvent,
    PrefetchHooks Function({bool caseId})> {
  $$CaseEventsTableTableManager(_$AppDatabase db, $CaseEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaseEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaseEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaseEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> dedupKey = const Value.absent(),
            Value<String> side = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              CaseEventsCompanion(
            localId: localId,
            caseId: caseId,
            eventId: eventId,
            dedupKey: dedupKey,
            side: side,
            kind: kind,
            payloadJson: payloadJson,
            createdAt: createdAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            required String caseId,
            required String eventId,
            required String dedupKey,
            required String side,
            required String kind,
            required String payloadJson,
            required DateTime createdAt,
            Value<bool> synced = const Value.absent(),
          }) =>
              CaseEventsCompanion.insert(
            localId: localId,
            caseId: caseId,
            eventId: eventId,
            dedupKey: dedupKey,
            side: side,
            kind: kind,
            payloadJson: payloadJson,
            createdAt: createdAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CaseEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable:
                        $$CaseEventsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$CaseEventsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CaseEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CaseEventsTable,
    CaseEvent,
    $$CaseEventsTableFilterComposer,
    $$CaseEventsTableOrderingComposer,
    $$CaseEventsTableAnnotationComposer,
    $$CaseEventsTableCreateCompanionBuilder,
    $$CaseEventsTableUpdateCompanionBuilder,
    (CaseEvent, $$CaseEventsTableReferences),
    CaseEvent,
    PrefetchHooks Function({bool caseId})>;
typedef $$DocumentRowsTableCreateCompanionBuilder = DocumentRowsCompanion
    Function({
  required String id,
  required String caseId,
  required String name,
  required String localPath,
  required String sha256,
  required int sizeBytes,
  required DateTime uploadedAt,
  Value<int> rowid,
});
typedef $$DocumentRowsTableUpdateCompanionBuilder = DocumentRowsCompanion
    Function({
  Value<String> id,
  Value<String> caseId,
  Value<String> name,
  Value<String> localPath,
  Value<String> sha256,
  Value<int> sizeBytes,
  Value<DateTime> uploadedAt,
  Value<int> rowid,
});

final class $$DocumentRowsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentRowsTable, DocumentRow> {
  $$DocumentRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CaseSummariesTable _caseIdTable(_$AppDatabase db) => db.caseSummaries
      .createAlias('document_rows__case_id__case_summaries__id');

  $$CaseSummariesTableProcessedTableManager get caseId {
    final $_column = $_itemColumn<String>('case_id')!;

    final manager = $$CaseSummariesTableTableManager($_db, $_db.caseSummaries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DocumentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentRowsTable> {
  $$DocumentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));

  $$CaseSummariesTableFilterComposer get caseId {
    final $$CaseSummariesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableFilterComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentRowsTable> {
  $$DocumentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));

  $$CaseSummariesTableOrderingComposer get caseId {
    final $$CaseSummariesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableOrderingComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentRowsTable> {
  $$DocumentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);

  $$CaseSummariesTableAnnotationComposer get caseId {
    final $$CaseSummariesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.caseId,
        referencedTable: $db.caseSummaries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CaseSummariesTableAnnotationComposer(
              $db: $db,
              $table: $db.caseSummaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentRowsTable,
    DocumentRow,
    $$DocumentRowsTableFilterComposer,
    $$DocumentRowsTableOrderingComposer,
    $$DocumentRowsTableAnnotationComposer,
    $$DocumentRowsTableCreateCompanionBuilder,
    $$DocumentRowsTableUpdateCompanionBuilder,
    (DocumentRow, $$DocumentRowsTableReferences),
    DocumentRow,
    PrefetchHooks Function({bool caseId})> {
  $$DocumentRowsTableTableManager(_$AppDatabase db, $DocumentRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> caseId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> sha256 = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<DateTime> uploadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentRowsCompanion(
            id: id,
            caseId: caseId,
            name: name,
            localPath: localPath,
            sha256: sha256,
            sizeBytes: sizeBytes,
            uploadedAt: uploadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String caseId,
            required String name,
            required String localPath,
            required String sha256,
            required int sizeBytes,
            required DateTime uploadedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentRowsCompanion.insert(
            id: id,
            caseId: caseId,
            name: name,
            localPath: localPath,
            sha256: sha256,
            sizeBytes: sizeBytes,
            uploadedAt: uploadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DocumentRowsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({caseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (caseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.caseId,
                    referencedTable:
                        $$DocumentRowsTableReferences._caseIdTable(db),
                    referencedColumn:
                        $$DocumentRowsTableReferences._caseIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DocumentRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentRowsTable,
    DocumentRow,
    $$DocumentRowsTableFilterComposer,
    $$DocumentRowsTableOrderingComposer,
    $$DocumentRowsTableAnnotationComposer,
    $$DocumentRowsTableCreateCompanionBuilder,
    $$DocumentRowsTableUpdateCompanionBuilder,
    (DocumentRow, $$DocumentRowsTableReferences),
    DocumentRow,
    PrefetchHooks Function({bool caseId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CaseSummariesTableTableManager get caseSummaries =>
      $$CaseSummariesTableTableManager(_db, _db.caseSummaries);
  $$CaseEventsTableTableManager get caseEvents =>
      $$CaseEventsTableTableManager(_db, _db.caseEvents);
  $$DocumentRowsTableTableManager get documentRows =>
      $$DocumentRowsTableTableManager(_db, _db.documentRows);
}
