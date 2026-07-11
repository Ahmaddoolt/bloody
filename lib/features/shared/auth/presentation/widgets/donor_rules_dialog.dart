import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../references/button_patterns.dart';

/// Shows the donor eligibility rules dialog.
/// Returns `true` if the user confirmed, `false` if they declined.
Future<bool> showDonorRulesDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DonorRulesDialog(),
  );
  return result ?? false;
}

class _DonorRulesDialog extends StatelessWidget {
  const _DonorRulesDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text('donor_eligibility'.tr()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'donor_rules_intro'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.sm),
            _RuleItem(text: 'rule_age'.tr()),
            _RuleItem(text: 'rule_weight'.tr()),
            _RuleItem(text: 'rule_tattoos'.tr()),
            _RuleItem(text: 'rule_health'.tr()),
            _RuleItem(text: 'rule_travel'.tr()),
            SizedBox(height: AppSpacing.md),
            Text(
              'donor_testing_tests_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.sm),
            _RuleItem(text: 'test_cbc'.tr()),
            _RuleItem(text: 'test_blood_group'.tr()),
            _RuleItem(text: 'test_hiv'.tr()),
            _RuleItem(text: 'test_hepatitis_b'.tr()),
            _RuleItem(text: 'test_hepatitis_c'.tr()),
            _RuleItem(text: 'test_syphilis'.tr()),
            SizedBox(height: AppSpacing.sm),
            Text(
              'donor_testing_note'.tr(),
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.58),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'do_not_qualify'.tr(),
          variant: AppButtonVariant.ghost,
          isExpanded: false,
          onPressed: () => Navigator.pop(context, false),
        ),
        SizedBox(width: AppSpacing.sm),
        AppButton(
          label: 'confirm_agree'.tr(),
          isExpanded: false,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
