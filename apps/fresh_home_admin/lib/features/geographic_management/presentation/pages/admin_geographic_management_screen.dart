import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

class AdminGeographicManagementScreen extends StatefulWidget {
  const AdminGeographicManagementScreen({super.key});

  @override
  State<AdminGeographicManagementScreen> createState() => _AdminGeographicManagementScreenState();
}

class _AdminGeographicManagementScreenState extends State<AdminGeographicManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int? _selectedGovernorateIdForCities;
  int? _selectedGovernorateIdForDistricts;
  int? _selectedCityIdForDistricts;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;

    return Scaffold(
      backgroundColor: themeColor.background,
      appBar: AppBar(
        title: const Text(
          'إدارة البيانات الجغرافية (المحافظات والمدن والأحياء)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: themeColor.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded), text: 'المحافظات'),
            Tab(icon: Icon(Icons.location_city_rounded), text: 'المدن'),
            Tab(icon: Icon(Icons.holiday_village_rounded), text: 'الأحياء'),
          ],
        ),
      ),
      body: BlocConsumer<AdminGeographicReferenceCubit, AdminGeographicReferenceState>(
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure!.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
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

  // ───────────────────────────────────────────────────────────────────────────
  // 1. GOVERNORATES TAB
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildGovernoratesTab(BuildContext context, AdminGeographicReferenceState state) {
    final themeColor = context.themeColor;
    final cubit = context.read<AdminGeographicReferenceCubit>();

    final filteredList = state.governorates.where((g) {
      final query = _searchQuery.trim().toLowerCase();
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث باسم المحافظة بالعربية أو الإنجليزية...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  backgroundColor: themeColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddEditGovernorateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة محافظة'),
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
                    Text('لا توجد محافظات مطابقة للبحث', style: TextStyle(color: Colors.grey)),
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        '${gov.nameAr} (${gov.nameEn})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('كود المحافظة: ${gov.code} | الترتيب: ${gov.sortOrder}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: gov.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: gov.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              gov.isActive ? 'مفعل (Active)' : 'معطل (Inactive)',
                              style: TextStyle(
                                color: gov.isActive ? Colors.green.shade900 : Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            onPressed: () => _showAddEditGovernorateDialog(context, governorate: gov),
                          ),
                          Switch(
                            value: gov.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              cubit.toggleActiveStatus(
                                table: 'governorates',
                                id: gov.id,
                                isActive: val,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Governorate Dropdown Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_rounded, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'اختر المحافظة: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('-- اختر محافظة لعرض مدنها --'),
                      value: _selectedGovernorateIdForCities,
                      items: state.governorates.map((gov) {
                        return DropdownMenuItem<int>(
                          value: gov.id,
                          child: Text('${gov.nameAr} (${gov.nameEn})'),
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
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: themeColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _selectedGovernorateIdForCities == null
                      ? null
                      : () => _showAddEditCityDialog(
                            context,
                            governorateId: _selectedGovernorateIdForCities!,
                          ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة مدينة'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedGovernorateIdForCities == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 64, color: Colors.blueAccent),
                    SizedBox(height: 12),
                    Text(
                      'الرجاء اختيار محافظة من القائمة لعرض وإدارة مدنها',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                child: Text('لا توجد مدن مضافة لهذه المحافظة حتى الآن', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.cities.length,
                itemBuilder: (ctx, idx) {
                  final city = state.cities[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        '${city.nameAr} (${city.nameEn})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('معرف المدينة: ${city.id} | الترتيب: ${city.sortOrder}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: city.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: city.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              city.isActive ? 'مفعل (Active)' : 'معطل (Inactive)',
                              style: TextStyle(
                                color: city.isActive ? Colors.green.shade900 : Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            onPressed: () => _showAddEditCityDialog(
                              context,
                              governorateId: _selectedGovernorateIdForCities!,
                              city: city,
                            ),
                          ),
                          Switch(
                            value: city.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              cubit.toggleActiveStatus(
                                table: 'cities',
                                id: city.id,
                                isActive: val,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cascading Governorate & City Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text('المحافظة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('-- اختر محافظة --'),
                          value: _selectedGovernorateIdForDistricts,
                          items: state.governorates.map((gov) {
                            return DropdownMenuItem<int>(
                              value: gov.id,
                              child: Text('${gov.nameAr} (${gov.nameEn})'),
                            );
                          }).toList(),
                          onChanged: (govId) {
                            if (govId != null) {
                              setState(() {
                                _selectedGovernorateIdForDistricts = govId;
                                _selectedCityIdForDistricts = null; // Cascading Reset
                              });
                              cubit.loadCities(govId);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text('المدينة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('-- اختر مدينة لعرض أحياءها --'),
                          value: _selectedCityIdForDistricts,
                          items: state.cities.map((city) {
                            return DropdownMenuItem<int>(
                              value: city.id,
                              child: Text('${city.nameAr} (${city.nameEn})'),
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
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: themeColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedCityIdForDistricts == null
                          ? null
                          : () => _showAddEditDistrictDialog(
                                context,
                                cityId: _selectedCityIdForDistricts!,
                              ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة حي'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedCityIdForDistricts == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 64, color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'الرجاء اختيار المحافظة والمدينة لعرض وإدارة أحياءها',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.districts.isEmpty)
            const Expanded(
              child: Center(
                child: Text('لا توجد أحياء مضافة لهذه المدينة حتى الآن', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.districts.length,
                itemBuilder: (ctx, idx) {
                  final district = state.districts[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        '${district.nameAr} (${district.nameEn})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('معرف الحي: ${district.id} | الترتيب: ${district.sortOrder}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: district.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: district.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              district.isActive ? 'مفعل (Active)' : 'معطل (Inactive)',
                              style: TextStyle(
                                color: district.isActive ? Colors.green.shade900 : Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            onPressed: () => _showAddEditDistrictDialog(
                              context,
                              cityId: _selectedCityIdForDistricts!,
                              district: district,
                            ),
                          ),
                          Switch(
                            value: district.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              cubit.toggleActiveStatus(
                                table: 'districts',
                                id: district.id,
                                isActive: val,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
        title: Text(governorate == null ? 'إضافة محافظة جديدة' : 'تعديل المحافظة'),
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
            child: const Text('إلغاء'),
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
            child: Text(governorate == null ? 'إضافة' : 'حفظ التعديلات'),
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
        title: Text(city == null ? 'إضافة مدينة جديدة' : 'تعديل المدينة'),
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
            child: const Text('إلغاء'),
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
            child: Text(city == null ? 'إضافة' : 'حفظ التعديلات'),
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
        title: Text(district == null ? 'إضافة حي جديد' : 'تعديل الحي'),
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
            child: const Text('إلغاء'),
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
            child: Text(district == null ? 'إضافة' : 'حفظ التعديلات'),
          ),
        ],
      ),
    );
  }
}
