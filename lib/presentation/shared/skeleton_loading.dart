import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;
  
  const ListSkeleton({
    super.key, 
    this.itemCount = 6,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return const ListTileSkeleton();
      },
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Skeleton(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                Skeleton(width: MediaQuery.of(context).size.width * 0.5, height: 12),
                const SizedBox(height: 8),
                Skeleton(width: MediaQuery.of(context).size.width * 0.3, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Skeleton(width: 80, height: 80, borderRadius: BorderRadius.all(Radius.circular(40))),
          ),
          const SizedBox(height: 24),
          const Skeleton(width: double.infinity, height: 24),
          const SizedBox(height: 16),
          const Skeleton(width: 150, height: 16),
          const SizedBox(height: 32),
          const Skeleton(width: 100, height: 20),
          const SizedBox(height: 16),
          const Skeleton(width: double.infinity, height: 60),
          const SizedBox(height: 16),
          const Skeleton(width: double.infinity, height: 60),
        ],
      ),
    );
  }
}
