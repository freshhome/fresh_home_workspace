import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../cubit/supabase_services_cubit.dart';

class SupabaseSubServicesPage extends StatefulWidget {
  final SupabaseServicesCubit cubit;
  final String mainServiceId;
  final String mainServiceTitle;

  const SupabaseSubServicesPage({
    super.key,
    required this.cubit,
    required this.mainServiceId,
    required this.mainServiceTitle,
  });

  @override
  State<SupabaseSubServicesPage> createState() =>
      _SupabaseSubServicesPageState();
}

class _SupabaseSubServicesPageState extends State<SupabaseSubServicesPage> {
  @override
  void initState() {
    super.initState();
    widget.cubit.loadSubServices(widget.mainServiceId);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: themeColor.background,
        appBar: AppBar(
          title: Text(
            widget.mainServiceTitle,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: themeColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<SupabaseServicesCubit, SupabaseServicesState>(
            builder: (context, state) {
              if (state is SupabaseServicesLoading) {
                return Center(
                  child: CircularProgressIndicator(color: themeColor.primary),
                );
              }

              if (state is SupabaseServicesError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }

              if (state is SupabaseServicesLoaded) {
                final subs = state.subServices ?? [];
                if (subs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد خدمات فرعية',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    return _SubServiceCard(sub: sub, cubit: widget.cubit);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _SubServiceCard extends StatelessWidget {
  final SubServiceEntity sub;
  final SupabaseServicesCubit cubit;

  const _SubServiceCard({required this.sub, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.primary.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          cubit.selectSubService(sub);
          context.toNamed(
            AppRoutes.adminSupabaseServiceDetails,
            extra: {'cubit': cubit},
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  sub.image ?? '',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[100],
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.title['ar'] ?? sub.title['en'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.price.value} ${sub.price.unit}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: themeColor.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: themeColor.unselectedItem,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'التفاصيل، المشمولات، السعر',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: themeColor.unselectedItem,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: themeColor.primary),
            ],
          ),
        ),
      ),
    );
  }
}
