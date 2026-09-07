import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class AdminGeographicManagementScreen extends StatefulWidget {
  const AdminGeographicManagementScreen({super.key});

  @override
  State<AdminGeographicManagementScreen> createState() =>
      _AdminGeographicManagementScreenState();
}

class _AdminGeographicManagementScreenState
    extends State<AdminGeographicManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int? _selectedGovernorateIdForCities;
  int? _selectedGovernorateIdForDistricts;
  int? _selectedCityIdForDistricts;

  final TextEditingController _govSearchController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _districtSearchController = TextEditingController();

  String _govSearchQuery = '';
  String _citySearchQuery = '';
  String _districtSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _govSearchController.dispose();
    _citySearchController.dispose();
    _districtSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'إدارة البيانات الجغرافية',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'Cairo',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Cairo',
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded), text: 'المحافظات'),
            Tab(icon: Icon(Icons.location_city_rounded), text: 'المدن'),
            Tab(icon: Icon(Icons.holiday_village_rounded), text: 'الأحياء'),
          ],
        ),
      ),
      body: BlocConsumer<AdminGeographicReferenceCubit,
          AdminGeographicReferenceState>(
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.failure!.message,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.successMessage!,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGovernoratesTab(context, state),
              _buildCitiesTab(context, state),
              _buildDistrictsTab(context, state),
            ],
          );
        },
      ),
    );
  }

  void _navigateToCities(Governorate gov) {
    final cubit = context.read<AdminGeographicReferenceCubit>();
    setState(() {
      _selectedGovernorateIdForCities = gov.id;
    });
    cubit.loadCities(gov.id);
    _tabController.animateTo(1);
  }

  void _navigateToDistricts(City city) {
    final cubit = context.read<AdminGeographicReferenceCubit>();
    setState(() {
      _selectedGovernorateIdForDistricts = city.governorateId;
      _selectedCityIdForDistricts = city.id;
    });
    if (cubit.state.selectedGovernorateId != city.governorateId) {
      cubit.loadCities(city.governorateId);
    }
    cubit.loadDistricts(city.id);
    _tabController.animateTo(2);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. GOVERNORATES TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildGovernoratesTab(
    BuildContext context,
    AdminGeographicReferenceState state,
  ) {
    final themeColor = context.themeColor;
    final cubit = context.read<AdminGeographicReferenceCubit>();

    final filteredList = state.governorates.where((g) {
      final query = _govSearchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return g.nameAr.toLowerCase().contains(query) ||
          g.nameEn.toLowerCase().contains(query) ||
          g.code.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _govSearchController,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم المحافظة أو الكود...',
                    hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => setState(() => _govSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showAddEditGovernorateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'إضافة محافظة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filteredList.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد محافظات مطابقة للبحث',
                      style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (ctx, idx) {
                  final gov = filteredList[idx];
                  return _buildGeographicCard(
                    context: context,
                    titleAr: gov.nameAr,
                    titleEn: gov.nameEn,
                    subtitle: 'كود: ${gov.code} • الترتيب: ${gov.sortOrder}',
                    isActive: gov.isActive,
                    onTap: () => _navigateToCities(gov),
                    onToggleActive: (val) {
                      cubit.toggleActiveStatus(
                        table: 'governorates',
                        id: gov.id,
                        isActive: val,
                      );
                    },
                    actions: [
                      _buildActionButton(
                        icon: Icons.arrow_forward_rounded,
                        label: 'المدن',
                        color: const Color(0xFF0284C7),
                        tooltip: 'عرض المدن التابعة لهذه المحافظة',
                        onTap: () => _navigateToCities(gov),
                      ),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'تعديل',
                        color: const Color(0xFFD97706),
                        tooltip: 'تعديل بيانات المحافظة',
                        onTap: () => _showAddEditGovernorateDialog(context, governorate: gov),
                      ),
                      _buildActionButton(
                        icon: Icons.add_location_alt_outlined,
                        label: '+ مدينة',
                        color: const Color(0xFF16A34A),
                        tooltip: 'إضافة مدينة تابعة لهذه المحافظة',
                        onTap: () => _showAddEditCityDialog(context, governorateId: gov.id),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'حذف',
                        color: const Color(0xFFDC2626),
                        tooltip: 'حذف المحافظة نهائياً',
                        onTap: () {
                          _confirmDelete(
                            context: context,
                            title: 'حذف المحافظة',
                            message: 'هل أنت متأكد من حذف محافظة "${gov.nameAr}" نهائياً؟ قد يتأثر أي عناصر تابعة لها.',
                            onConfirm: () => cubit.deleteGovernorate(gov.id),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. CITIES TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCitiesTab(BuildContext context, AdminGeographicReferenceState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<AdminGeographicReferenceCubit>();

    final selectedGov = state.governorates
        .where((g) => g.id == _selectedGovernorateIdForCities)
        .firstOrNull;

    final filteredCities = state.cities.where((c) {
      final query = _citySearchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return c.nameAr.toLowerCase().contains(query) ||
          c.nameEn.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_rounded, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'المحافظة: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text(
                        '-- اختر محافظة لعرض مدنها --',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      ),
                      value: _selectedGovernorateIdForCities,
                      items: state.governorates.map((gov) {
                        return DropdownMenuItem<int>(
                          value: gov.id,
                          child: Text(
                            '${gov.nameAr} (${gov.nameEn})',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (govId) {
                        if (govId != null) {
                          setState(() {
                            _selectedGovernorateIdForCities = govId;
                          });
                          cubit.loadCities(govId);
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedGovernorateIdForCities != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: themeColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showAddEditCityDialog(
                      context,
                      governorateId: _selectedGovernorateIdForCities!,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'إضافة مدينة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedGovernorateIdForCities != null) ...[
            TextField(
              controller: _citySearchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم المدينة في محافظة ${selectedGov?.nameAr ?? ''}...',
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => setState(() => _citySearchQuery = val),
            ),
            const SizedBox(height: 12),
          ],

          if (_selectedGovernorateIdForCities == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 64, color: Color(0xFF0284C7)),
                    SizedBox(height: 12),
                    Text(
                      'الرجاء اختيار محافظة من القائمة لعرض وإدارة مدنها',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.cities.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'لا توجد مدن مضافة لهذه المحافظة حتى الآن',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredCities.length,
                itemBuilder: (ctx, idx) {
                  final city = filteredCities[idx];
                  return _buildGeographicCard(
                    context: context,
                    titleAr: city.nameAr,
                    titleEn: city.nameEn,
                    subtitle: 'الترتيب: ${city.sortOrder} • تابعة لمحافظة: ${selectedGov?.nameAr ?? ''}',
                    isActive: city.isActive,
                    onTap: () => _navigateToDistricts(city),
                    onToggleActive: (val) {
                      cubit.toggleActiveStatus(
                        table: 'cities',
                        id: city.id,
                        isActive: val,
                      );
                    },
                    actions: [
                      _buildActionButton(
                        icon: Icons.arrow_forward_rounded,
                        label: 'الأحياء',
                        color: const Color(0xFF0284C7),
                        tooltip: 'عرض الأحياء التابعة لهذه المدينة',
                        onTap: () => _navigateToDistricts(city),
                      ),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'تعديل',
                        color: const Color(0xFFD97706),
                        tooltip: 'تعديل بيانات المدينة',
                        onTap: () => _showAddEditCityDialog(
                          context,
                          governorateId: city.governorateId,
                          city: city,
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.holiday_village_outlined,
                        label: '+ حي',
                        color: const Color(0xFF16A34A),
                        tooltip: 'إضافة حي تابع لهذه المدينة',
                        onTap: () => _showAddEditDistrictDialog(
                          context,
                          cityId: city.id,
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'حذف',
                        color: const Color(0xFFDC2626),
                        tooltip: 'حذف المدينة نهائياً',
                        onTap: () {
                          _confirmDelete(
                            context: context,
                            title: 'حذف المدينة',
                            message: 'هل أنت متأكد من حذف مدينة "${city.nameAr}" نهائياً؟ قد يتأثر أي أحياء تابعة لها.',
                            onConfirm: () => cubit.deleteCity(city.id),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. DISTRICTS TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDistrictsTab(BuildContext context, AdminGeographicReferenceState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<AdminGeographicReferenceCubit>();

    final selectedGov = state.governorates
        .where((g) => g.id == _selectedGovernorateIdForDistricts)
        .firstOrNull;

    final selectedCity = state.cities
        .where((c) => c.id == _selectedCityIdForDistricts)
        .firstOrNull;

    final filteredDistricts = state.districts.where((d) {
      final query = _districtSearchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return d.nameAr.toLowerCase().contains(query) ||
          d.nameEn.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cascading Filter Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Color(0xFF0284C7), size: 20),
                    const SizedBox(width: 8),
                    const Text('المحافظة: ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('-- اختر محافظة --', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          value: _selectedGovernorateIdForDistricts,
                          items: state.governorates.map((gov) {
                            return DropdownMenuItem<int>(
                              value: gov.id,
                              child: Text('${gov.nameAr} (${gov.nameEn})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (govId) {
                            if (govId != null) {
                              setState(() {
                                _selectedGovernorateIdForDistricts = govId;
                                _selectedCityIdForDistricts = null;
                              });
                              cubit.loadCities(govId);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    const Text('المدينة: ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('-- اختر مدينة لعرض أحياءها --', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                          value: _selectedCityIdForDistricts,
                          items: state.cities.map((city) {
                            return DropdownMenuItem<int>(
                              value: city.id,
                              child: Text('${city.nameAr} (${city.nameEn})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: _selectedGovernorateIdForDistricts == null
                              ? null
                              : (cityId) {
                                  if (cityId != null) {
                                    setState(() {
                                      _selectedCityIdForDistricts = cityId;
                                    });
                                    cubit.loadDistricts(cityId);
                                  }
                                },
                        ),
                      ),
                    ),
                    if (_selectedCityIdForDistricts != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: themeColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showAddEditDistrictDialog(
                          context,
                          cityId: _selectedCityIdForDistricts!,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'إضافة حي',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedCityIdForDistricts != null) ...[
            TextField(
              controller: _districtSearchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم الحي في ${selectedCity?.nameAr ?? ''}...',
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => setState(() => _districtSearchQuery = val),
            ),
            const SizedBox(height: 12),
          ],

          if (_selectedCityIdForDistricts == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 64, color: Color(0xFFD97706)),
                    SizedBox(height: 12),
                    Text(
                      'الرجاء اختيار المحافظة والمدينة لعرض وإدارة أحياءها',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.districts.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: _buildEmptyDistrictsCard(context, selectedGov, selectedCity),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredDistricts.length,
                itemBuilder: (ctx, idx) {
                  final district = filteredDistricts[idx];
                  return _buildGeographicCard(
                    context: context,
                    titleAr: district.nameAr,
                    titleEn: district.nameEn,
                    subtitle: 'الترتيب: ${district.sortOrder} • تابع لمدينة: ${selectedCity?.nameAr ?? ''}',
                    isActive: district.isActive,
                    onToggleActive: (val) {
                      cubit.toggleActiveStatus(
                        table: 'districts',
                        id: district.id,
                        isActive: val,
                      );
                    },
                    actions: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'تعديل',
                        color: const Color(0xFFD97706),
                        tooltip: 'تعديل بيانات الحي',
                        onTap: () => _showAddEditDistrictDialog(
                          context,
                          cityId: district.cityId,
                          district: district,
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'حذف',
                        color: const Color(0xFFDC2626),
                        tooltip: 'حذف الحي نهائياً',
                        onTap: () {
                          _confirmDelete(
                            context: context,
                            title: 'حذف الحي',
                            message: 'هل أنت متأكد من حذف حي "${district.nameAr}" نهائياً؟',
                            onConfirm: () => cubit.deleteDistrict(district.id),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDistrictsCard(
    BuildContext context,
    Governorate? selectedGov,
    City? selectedCity,
  ) {
    final themeColor = context.themeColor;
    final defaultDistricts = EgyptGeographicHierarchy.getDistricts(
      selectedGov?.nameAr,
      selectedCity?.nameAr,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 56, color: Colors.amber.shade700),
          const SizedBox(height: 14),
          Text(
            'لا توجد أحياء مسجلة لمدينة "${selectedCity?.nameAr ?? ''}"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (defaultDistricts.isNotEmpty) ...[
            Text(
              'يتوفر في النظام (${defaultDistricts.length}) حي قياسي لهذه المدينة جاهزة للاستيراد.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    'استيراد الأحياء القياسية (${defaultDistricts.length})',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _importStandardDistricts(
                    context,
                    cityId: _selectedCityIdForDistricts!,
                    districts: defaultDistricts,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'إضافة حي يدوياً',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _showAddEditDistrictDialog(
                    context,
                    cityId: _selectedCityIdForDistricts!,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'لم يتم إضافة أي أحياء بعد. يمكنك إضافة حي جديد للبدء.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'إضافة حي جديد',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _showAddEditDistrictDialog(
                context,
                cityId: _selectedCityIdForDistricts!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importStandardDistricts(
    BuildContext context, {
    required int cityId,
    required List<String> districts,
  }) async {
    final cubit = context.read<AdminGeographicReferenceCubit>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جاري استيراد ${districts.length} حي للمدينة...',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    int order = 1;
    for (final nameAr in districts) {
      if (nameAr == 'أخرى') continue;
      await cubit.repository.createDistrict(
        cityId: cityId,
        nameAr: nameAr,
        nameEn: nameAr,
        sortOrder: order++,
      );
    }
    await cubit.loadDistricts(cityId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم استيراد الأحياء القياسية بنجاح!',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // THE TWO-HALF GEOGRAPHIC CARD WIDGET
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildGeographicCard({
    required BuildContext context,
    required String titleAr,
    required String titleEn,
    required String subtitle,
    required bool isActive,
    required ValueChanged<bool> onToggleActive,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    final themeColor = context.themeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: themeColor.unselectedItem.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── UPPER HALF: Names on right, Active Badge + Switch on left ───────
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  titleAr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: themeColor.textPrimary,
                                    fontFamily: 'Cairo',
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onTap != null) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  size: 20,
                                  color: themeColor.primary.withValues(alpha: 0.7),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$titleEn • $subtitle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: themeColor.secondaryText,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Active Badge & Switch
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isActive ? 'مفعل' : 'معطل',
                            style: TextStyle(
                              color: isActive ? const Color(0xFF047857) : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: isActive,
                            activeThumbColor: const Color(0xFF10B981),
                            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                            onChanged: onToggleActive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── HORIZONTAL DIVIDER ──────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 0.8,
            color: themeColor.unselectedItem.withValues(alpha: 0.1),
          ),

          // ── LOWER HALF: Action Icons Bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CONFIRMATION DIALOG
  // ───────────────────────────────────────────────────────────────────────────

  void _confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onConfirm();
            },
            child: const Text(
              'تأكيد الحذف',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DIALOG FORMS (Add/Edit Governorate, City, District)
  // ───────────────────────────────────────────────────────────────────────────

  void _showAddEditGovernorateDialog(BuildContext context, {Governorate? governorate}) {
    final nameArCtrl = TextEditingController(text: governorate?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: governorate?.nameEn ?? '');
    final codeCtrl = TextEditingController(text: governorate?.code ?? '');
    final sortCtrl = TextEditingController(text: (governorate?.sortOrder ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          governorate == null ? 'إضافة محافظة جديدة' : 'تعديل المحافظة',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المحافظة بالعربية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المحافظة بالإنجليزية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'كود المحافظة (e.g. CAI) *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ترتيب العرض (Sort Order)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final cubit = context.read<AdminGeographicReferenceCubit>();
                if (governorate == null) {
                  cubit.createGovernorate(
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    code: codeCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                } else {
                  cubit.updateGovernorate(
                    id: governorate.id,
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    code: codeCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                }
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(
              governorate == null ? 'إضافة' : 'حفظ التعديلات',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditCityDialog(BuildContext context, {required int governorateId, City? city}) {
    final nameArCtrl = TextEditingController(text: city?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: city?.nameEn ?? '');
    final sortCtrl = TextEditingController(text: (city?.sortOrder ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          city == null ? 'إضافة مدينة جديدة' : 'تعديل المدينة',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المدينة بالعربية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'اسم المدينة بالإنجليزية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ترتيب العرض (Sort Order)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final cubit = context.read<AdminGeographicReferenceCubit>();
                if (city == null) {
                  cubit.createCity(
                    governorateId: governorateId,
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                } else {
                  cubit.updateCity(
                    id: city.id,
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                }
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(
              city == null ? 'إضافة' : 'حفظ التعديلات',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDistrictDialog(BuildContext context, {required int cityId, District? district}) {
    final nameArCtrl = TextEditingController(text: district?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: district?.nameEn ?? '');
    final sortCtrl = TextEditingController(text: (district?.sortOrder ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          district == null ? 'إضافة حي جديد' : 'تعديل الحي',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الحي بالعربية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameEnCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الحي بالإنجليزية *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ترتيب العرض (Sort Order)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final cubit = context.read<AdminGeographicReferenceCubit>();
                if (district == null) {
                  cubit.createDistrict(
                    cityId: cityId,
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                } else {
                  cubit.updateDistrict(
                    id: district.id,
                    nameAr: nameArCtrl.text,
                    nameEn: nameEnCtrl.text,
                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                  );
                }
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(
              district == null ? 'إضافة' : 'حفظ التعديلات',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
