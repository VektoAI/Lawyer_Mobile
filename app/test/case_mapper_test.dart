/// `case_mapper.dart` is the boundary between the in-memory [MunshiCase]
/// model and the JSON payload that actually gets encrypted onto disk (see
/// `vault_store.dart`'s `_persistEncrypted`/`_decryptCasesIntoMemory`). A
/// silent bug here doesn't crash anything — it just quietly drops or
/// mis-maps a field the next time a case round-trips through the vault,
/// which is exactly the kind of regression unit tests catch and manual
/// testing doesn't.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:munshi_mobile/data/case_mapper.dart';
import 'package:munshi_mobile/models/case_models.dart';

void main() {
  group('munshiCaseToPayload / munshiCaseFromPayload round-trip', () {
    test('a fully-populated case survives the round-trip unchanged', () {
      final original = MunshiCase(
        id: 'case-1',
        parties: 'Alice vs Bob',
        caseNo: 'A/123/2026',
        court: 'District Court',
        courtType: 'district',
        color: '#112233',
        stage: 'Evidence',
        nextDate: '2026-09-01',
        nextDetail: 'Court 3',
        unread: 2,
        pinned: true,
        urgent: true,
        disposed: false,
        cnr: 'CNR123',
        references: 'Sec 138 NI Act',
        client: const ClientInfo(name: 'Alice', phone: '+911234567890'),
        fee: const FeeInfo(agreed: 50000),
        hearings: [const CaseHearing(date: '2026-08-01', purpose: 'First hearing', outcome: 'Adjourned')],
        docs: const [CaseDocument(id: 'doc-1', name: 'petition.pdf', size: '1 MB', date: '1 Aug', pdf: true)],
        payments: const [CasePayment(id: 'pay-1', amount: 10000, mode: 'UPI', date: '1 Aug', note: 'Retainer')],
        updates: [
          const CaseUpdate(date: '2026-08-01', side: 'court', kind: 'hearing', time: '10:00 AM', text: 'Hearing held', sub: 'detail'),
          const CaseUpdate(date: '2026-08-02', side: 'lawyer', kind: 'note', time: '11:00 AM', text: 'Prepare rejoinder'),
        ],
      );

      final payload = munshiCaseToPayload(original);
      final restored = munshiCaseFromPayload(original.id, payload);

      expect(restored.id, original.id);
      expect(restored.parties, original.parties);
      expect(restored.caseNo, original.caseNo);
      expect(restored.court, original.court);
      expect(restored.courtType, original.courtType);
      expect(restored.stage, original.stage);
      expect(restored.nextDate, original.nextDate);
      expect(restored.unread, original.unread);
      expect(restored.pinned, isTrue);
      expect(restored.urgent, isTrue);
      expect(restored.cnr, original.cnr);
      expect(restored.references, original.references);
      expect(restored.client.name, 'Alice');
      expect(restored.fee.agreed, 50000);
      expect(restored.hearings.single.outcome, 'Adjourned');
      expect(restored.docs.single.name, 'petition.pdf');
      expect(restored.payments.single.amount, 10000);
      expect(restored.updates, hasLength(2));
    });

    test('an update\'s side survives the wire-format translation (court/lawyer <-> right/left)', () {
      // The wire format uses vault.js's right/left convention (see
      // munshiCaseToPayload's explicit override of CaseUpdate.toJson's own
      // 'side' field) while the in-memory model uses court/lawyer — this is
      // exactly the kind of translation a refactor could silently break.
      final c = MunshiCase(
        id: 'case-2',
        parties: 'X vs Y',
        caseNo: 'B/1',
        court: 'High Court',
        updates: [
          const CaseUpdate(date: '2026-01-01', side: 'court', kind: 'hearing', text: 'from court'),
          const CaseUpdate(date: '2026-01-02', side: 'lawyer', kind: 'note', text: 'from lawyer'),
        ],
      );

      final payload = munshiCaseToPayload(c);
      final wireUpdates = payload['updates'] as List;
      expect(wireUpdates[0]['side'], 'right');
      expect(wireUpdates[1]['side'], 'left');

      final restored = munshiCaseFromPayload(c.id, payload);
      expect(restored.updates[0].side, 'court');
      expect(restored.updates[0].isCourt, isTrue);
      expect(restored.updates[1].side, 'lawyer');
      expect(restored.updates[1].isCourt, isFalse);
    });

    test('a minimal/empty payload map produces safe defaults instead of throwing', () {
      final restored = munshiCaseFromPayload('case-3', <String, dynamic>{});

      expect(restored.parties, '');
      expect(restored.caseNo, '');
      expect(restored.nextDate, isNull);
      expect(restored.unread, 0);
      expect(restored.pinned, isFalse);
      expect(restored.hearings, isEmpty);
      expect(restored.docs, isEmpty);
      expect(restored.payments, isEmpty);
      expect(restored.updates, isEmpty);
      expect(restored.client.name, '');
      expect(restored.fee.agreed, 0);
    });
  });

  group('profileToPayload / profileFromPayload round-trip', () {
    test('a populated profile survives the round-trip', () {
      const profile = ChamberProfile(
        name: 'Adv. Test',
        enrolment: 'UK/1/2020',
        barCouncil: 'Bar Council of Uttarakhand',
        chamber: 'Chamber 1',
        phone: '+911234567890',
        initials: 'AT',
      );
      final restored = profileFromPayload(profileToPayload(profile));
      expect(restored.name, profile.name);
      expect(restored.enrolment, profile.enrolment);
      expect(restored.initials, profile.initials);
    });

    test('a null payload produces an empty ChamberProfile instead of throwing', () {
      final restored = profileFromPayload(null);
      expect(restored.name, '');
      expect(restored.initials, '');
    });
  });
}
