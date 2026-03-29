import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../providers/receiver_map_provider.dart';
import 'receiver_donor_card.dart';

class ReceiverDonorList extends StatelessWidget {
  final bool isDark;
  final ReceiverMapState state;
  final double horizontalPadding;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onOpenDonor;
  final void Function(String? phone) onCall;

  const ReceiverDonorList({
    super.key,
    required this.isDark,
    required this.state,
    required this.horizontalPadding,
    required this.scrollController,
    required this.onRefresh,
    required this.onOpenDonor,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.accent,
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                120,
              ),
              itemCount: state.donors.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.donors.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CustomLoader(size: 28),
                  );
                }

                final donor = state.donors[index];
                return _StaggeredItem(
                  delay: Duration(milliseconds: (index * 60).clamp(0, 600)),
                  child: GestureDetector(
                    onTap: () => onOpenDonor(donor),
                    child: ReceiverDonorCard(
                      userData: donor,
                      onCall: () => onCall(donor['phone'] as String?),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredItem({
    required this.child,
    required this.delay,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
