import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../cubit/supabase_services_cubit.dart';

class SupabaseServicesPage extends StatelessWidget {
  const SupabaseServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'الخدمات السحابية (Supabase)',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
                  'حدث خطأ: ${state.message}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            if (state is SupabaseServicesLoaded) {
              final services = state.mainServices;
              if (services.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد خدمات في Supabase',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceCard(service: service);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final MainServiceEntity service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.toNamed(
            AppRoutes.adminSupabaseSubServices,
            extra: {
              'cubit': context.read<SupabaseServicesCubit>(),
              'mainServiceId': service.id,
              'mainServiceTitle':
                  service.title['ar'] ?? service.title['en'] ?? '',
            },
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                service.image ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title['ar'] ?? service.title['en'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'عرض الخدمات الفرعية والتجهيزات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: themeColor.unselectedItem.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: themeColor.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
