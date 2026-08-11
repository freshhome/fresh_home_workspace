import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetPrimary;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return AddressCardWidget(
      address: address,
      onEdit: onEdit,
      onDelete: onDelete,
      onSetPrimary: onSetPrimary,
    );
  }
}
