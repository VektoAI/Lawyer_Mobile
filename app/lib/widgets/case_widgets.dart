library;

import 'package:flutter/material.dart';

import '../models/case_models.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/rupee.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.update});

  final CaseUpdate update;

  @override
  Widget build(BuildContext context) {
    final court = update.isCourt;
    return Align(
      alignment: court ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: court ? MunshiColors.courtBubble : MunshiColors.lawyerBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(court ? 16 : 4),
            bottomRight: Radius.circular(court ? 4 : 16),
          ),
          border: court ? null : Border.all(color: Colors.black12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (update.time.isNotEmpty)
              Text(
                update.time,
                style: TextStyle(fontSize: 11, color: court ? Colors.white70 : Colors.black45),
              ),
            Text(
              update.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: court ? Colors.white : MunshiColors.inkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (update.sub.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                update.sub,
                style: TextStyle(fontSize: 12.5, color: court ? Colors.white70 : Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CaseListTile extends StatelessWidget {
  const CaseListTile({super.key, required this.caseItem, required this.onTap});

  final MunshiCase caseItem;
  final VoidCallback onTap;

  Color get _accent {
    try {
      final hex = caseItem.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return MunshiColors.inkGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: _accent, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseItem.parties,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${caseItem.caseNo} · ${caseItem.court.split(',').first}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    if (caseItem.nextDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Next: ${fmtShort(caseItem.nextDate!)} · ${caseItem.nextDetail}',
                        // Brass gold is reserved for genuinely urgent cases (CLAUDE.md
                        // invariant 13) — every other upcoming hearing reads as neutral.
                        style: TextStyle(
                          fontSize: 12.5,
                          color: caseItem.urgent ? MunshiColors.brassGold : Colors.grey.shade700,
                          fontWeight: caseItem.urgent ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                    if (caseItem.fee.agreed > 0 && caseItem.dueRupees > 0) ...[
                      const SizedBox(height: 4),
                      Text('Due ${rupee(caseItem.dueRupees)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (caseItem.pinned)
                    Semantics(
                      label: 'Pinned',
                      child: const Icon(Icons.push_pin, size: 16, color: MunshiColors.brassGold),
                    ),
                  if (caseItem.urgent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MunshiColors.brassGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Urgent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MunshiColors.brassGold)),
                    ),
                  if (caseItem.unread > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: MunshiColors.inkGreen, borderRadius: BorderRadius.circular(10)),
                      child: Text('${caseItem.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
