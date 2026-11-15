import 'package:flutter/material.dart';

class LoadingSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: itemHeight,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  color: baseColor.withOpacity(0.6),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 180,
                  color: baseColor.withOpacity(0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
