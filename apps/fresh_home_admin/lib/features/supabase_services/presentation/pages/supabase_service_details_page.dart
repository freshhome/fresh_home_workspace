import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../cubit/supabase_services_cubit.dart';

class SupabaseServiceDetailsPage extends StatelessWidget {
  final SupabaseServicesCubit cubit;

  const SupabaseServiceDetailsPage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return BlocProvider.value(
      value: cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: themeColor.background,
          body: BlocBuilder<SupabaseServicesCubit, SupabaseServicesState>(
            builder: (context, state) {
          if (state is! SupabaseServicesLoaded ||
                  state.selectedSubService == null) {
                return const Center(child: Text('لايوجد بيانات'));
              }

              final sub = state.selectedSubService!;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: themeColor.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: sub.id,
                        child: Image.network(sub.image ?? '', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sub.title['ar'] ?? sub.title['en'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: themeColor.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${sub.price.value} ${sub.price.unit}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            sub.description['ar'] ??
                                sub.description['en'] ??
                                '',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: themeColor.unselectedItem,
                              height: 1.6,
                            ),
                          ),
                          const Divider(height: 40),

                          _buildSectionTitle(
                            'المشمولات',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          ...sub.details.map((detail) => _buildInclusionItem(detail, context)),

                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'غير المشمولات',
                            Icons.cancel_outlined,
                            Colors.red,
                          ),
                          const SizedBox(height: 12),
                          _buildExclusionSection(sub.notIncluded, context),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInclusionItem(DetailEntity detail, BuildContext context) {
    final title = detail.ar.title ?? detail.en.title ?? '';
    final points = detail.ar.points ?? detail.en.points ?? [];
    final iconUrl = detail.ar.icon ?? detail.en.icon ?? '';

    if (points.isEmpty) {
      return _buildDetailItem(title, true);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: (iconUrl.startsWith('http'))
                ? Image.network(iconUrl, width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.check, color: Colors.green, size: 18))
                : const Icon(Icons.check, color: Colors.green, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          children: points.map((point) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.circle, size: 4, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildExclusionSection(NotIncludedEntity notIncluded, BuildContext context) {
    final title = notIncluded.ar.title ?? notIncluded.en.title ?? 'تنبيه';
    final points = notIncluded.ar.points ?? notIncluded.en.points ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded, color: Colors.red, size: 14),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.circle, size: 4, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailItem(String text, bool isIncluded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isIncluded
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncluded ? Icons.check : Icons.close,
            size: 18,
            color: isIncluded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
