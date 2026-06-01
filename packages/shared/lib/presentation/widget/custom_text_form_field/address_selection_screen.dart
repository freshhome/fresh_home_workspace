import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared/presentation/widget/custom_text_form_field/base_text_form_field.dart';
import 'package:shared/presentation/widget/custom_text_form_field/my_text_form_field_rido.dart';

class AddressSelectionScreen extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  const AddressSelectionScreen({
    super.key,
    required this.controller,
    required this.validator,
  });

  @override
  AddressSelectionScreenState createState() => AddressSelectionScreenState();
}

class AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController buildingController = TextEditingController();
  final TextEditingController compoundController = TextEditingController();
  final TextEditingController apartmentController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void dispose() {
    provinceController.dispose();
    districtController.dispose();
    streetController.dispose();
    buildingController.dispose();
    compoundController.dispose();
    apartmentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  final Map<String, List<String>> cityData = {
    "القاهرة": [
      "جاردن سيتي",
      "الزمالك",
      "الرحاب",
      "مدينتي",
      "التجمع الخامس",
      "القطامية هايتس",
      "غرب الجولف",
      "حي الدبلوماسيين",
      "الشويفات",
      "درة القاهرة",
      "النرجس",
      "اللوتس",
      "الأندلس",
      "بيت الوطن",
      "حي الياسمين",
      "حي البنفسج",
      "مصر الجديدة",
      "هليوبوليس",
      "النزهة",
      "مدينة نصر",
      "المعادي",
      "المقطم",
      "الشروق",
      "العبور"
    ],
    "الجيزة": [
      "الزمالك",
      "بيفرلي هيلز",
      "الربوة",
      "الريف الأوروبي",
      "جرين لاند",
      "جراند هايتس",
      "مونتن فيو أكتوبر",
      "إيست تاون الشيخ زايد",
      "الشيخ زايد",
      "الدقي",
      "المهندسين",
      "العجوزة",
      "6 أكتوبر",
      "القرية الذكية",
      "الخمايل",
      "غرب سوميد",
      "الحي المتميز",
      "الحي التاسع",
      "الحي السابع",
      "حدائق الأهرام",
      "الهرم",
      "المنصورية"
    ],
  };

  List<String> districts = [];

  Future<Map<String, dynamic>?> _showAddressDialog() async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("اختر العنوان"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyTextFormFieldRido(
                      hint: "اختر المحافظة",
                      controller: provinceController,
                      options: cityData.keys.toList(),
                      onSelectOption: (selectedProvince) {
                        setState(() {
                          provinceController.text = selectedProvince;
                          districts = cityData[selectedProvince] ?? [];
                          districtController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    MyTextFormFieldRido(
                      hint: "اختر المنطقة أو الحي",
                      controller: districtController,
                      options: districts,
                      onSelectOption: (selectedDistrict) {
                        districtController.text = selectedDistrict;
                      },
                    ),
                    const SizedBox(height: 10),
                    BaseTextFormField(
                      hint: "اسم الشارع",
                      controller: streetController,
                    ),
                    const SizedBox(height: 10),
                    BaseTextFormField(
                      hint: "رقم العقار",
                      controller: buildingController,
                    ),
                    const SizedBox(height: 10),
                    BaseTextFormField(
                      hint: "اسم الكومباوند أو البرج (اختياري)",
                      controller: compoundController,
                    ),
                    const SizedBox(height: 10),
                    BaseTextFormField(
                      hint: "رقم الشقة",
                      controller: apartmentController,
                    ),
                    const SizedBox(height: 10),
                    BaseTextFormField(
                      hint: "ملاحظات إضافية",
                      controller: notesController,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("إلغاء"),
                ),
                TextButton(
                  onPressed: () {
                    if (provinceController.text.isNotEmpty &&
                        districtController.text.isNotEmpty &&
                        streetController.text.isNotEmpty &&
                        buildingController.text.isNotEmpty) {
                      Map<String, dynamic> selectedAddress = {
                        "المحافظة": provinceController.text,
                        "المنطقة": districtController.text,
                        "الشارع": streetController.text,
                        "رقم العقار": buildingController.text,
                        "الكومباوند": compoundController.text,
                        "رقم الشقة": apartmentController.text,
                        "ملاحظات": notesController.text,
                      };

                      Navigator.pop(context, selectedAddress); // تصحيح هنا
                    }
                  },
                  child: Text("حفظ"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        var address = await _showAddressDialog();
        if (address != null) {
          widget.controller.text = jsonEncode(address);
        
        }
      },
      child: BaseTextFormField(
        enabled: false,
        textAlign: TextAlign.center,
        validator: widget.validator,
        hint: "اختر العنوان",
        controller: widget.controller,
      ),
    );
  }
}
