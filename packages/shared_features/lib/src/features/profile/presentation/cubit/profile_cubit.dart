import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../../domain/use_cases/add_address.dart';
import '../../domain/use_cases/delete_address.dart';
import '../../domain/use_cases/load_profile.dart';
import '../../domain/use_cases/update_address.dart';
import '../../domain/use_cases/update_phone_number.dart';
import '../../domain/use_cases/update_user_name.dart';
import '../../domain/use_cases/update_profile.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final LoadProfileUseCase loadProfileUseCase;
  final UpdateUserNameUseCase updateUserNameUseCase;
  final UpdatePhoneNumbersUseCase updatePhoneNumbersUseCase;
  final AddAddressUseCase addAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;
  final DeleteAddressUseCase deleteAddressUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  ProfileCubit(
    this.loadProfileUseCase,
    this.updateUserNameUseCase,
    this.updatePhoneNumbersUseCase,
    this.addAddressUseCase,
    this.updateAddressUseCase,
    this.deleteAddressUseCase,
    this.updateProfileUseCase,
  ) : super(ProfileInitial());

  Future<void> load() async {
    emit(ProfileLoading());
    final res = await loadProfileUseCase();
    if (isClosed) return;
    res.fold(
      (l) {
        print('ProfileCubit Load Error: ${l.message}');
        emit(ProfileError(l));
      },
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> updateProfileInfo({
    required String firstName,
    required String lastName,
    required String phone,
    String? gender,
    String? avatarUrl,
  }) async {
    final currentProfile = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
    emit(ProfileLoading());

    // 1. Update Core Profile (Name, Gender, Avatar)
    final res = await updateProfileUseCase(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      avatarUrl: avatarUrl,
    );

    if (isClosed) return;

    await res.fold(
      (l) async {
        print('ProfileCubit UpdateProfileInfo Error: ${l.message}');
        emit(ProfileError(l, profile: currentProfile));
      },
      (profileAfterCore) async {
        // 2. Check and Update Phone if changed
        final currentPhones = profileAfterCore.phoneNumbers;
        
        final hasPrimary = currentPhones.any((p) => p.isPrimary);
        Phone? primaryPhone = hasPrimary 
            ? currentPhones.firstWhere((p) => p.isPrimary) 
            : (currentPhones.isNotEmpty ? currentPhones.first : null);

        if (primaryPhone != null && primaryPhone.phoneNumber != phone) {
           List<Phone> updatedPhones = currentPhones.map((p) {
             if (p.id == primaryPhone.id) {
               return p.copyWith(phoneNumber: phone);
             }
             return p;
           }).toList();
           
           final resPhone = await updatePhoneNumbersUseCase(updatedPhones);
           if (isClosed) return;
           resPhone.fold(
               (l) {
                 print('ProfileCubit UpdatePhone Error: ${l.message}');
                 emit(ProfileError(l, profile: profileAfterCore));
               },
               (finalProfile) => emit(ProfileLoaded(finalProfile))
           );
        } else if (primaryPhone == null && phone.isNotEmpty) {
           final updatedPhones = [Phone(id: null, userId: profileAfterCore.uid, phoneNumber: phone, isPrimary: true, isVerified: false, createdAt: DateTime.now())];
           final resPhone = await updatePhoneNumbersUseCase(updatedPhones);
           if (isClosed) return;
           resPhone.fold(
               (l) {
                 print('ProfileCubit AddPhone Error: ${l.message}');
                 emit(ProfileError(l, profile: profileAfterCore));
               },
               (finalProfile) => emit(ProfileLoaded(finalProfile))
           );
        } else {
           emit(ProfileLoaded(profileAfterCore));
        }
      }
    );
  }

  Future<void> updateName(String firstName, String lastName) async {
    // Legacy support, redirects to updateProfileInfo or similar
    final current = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
    if (current == null) return;
    
    final currentPhones = current.phoneNumbers;
    final primaryPhone = currentPhones.isNotEmpty 
        ? currentPhones.firstWhere((p) => p.isPrimary, orElse: () => currentPhones.first).phoneNumber 
        : '';
        
    await updateProfileInfo(
      firstName: firstName,
      lastName: lastName,
      phone: primaryPhone,
      gender: current.gender,
      avatarUrl: current.avatarUrl,
    );
  }

  // New method to handle adding phone numbers intelligently
  Future<void> addPhoneNumber(String phone) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      
        final currentList = currentProfile.phoneNumbers;
        bool phoneExists = currentList.any((p) => p.phoneNumber == phone);
        if (!phoneExists) {
          final updatedList = List<Phone>.from(currentList)
            ..add(Phone(
              id: null,
              userId: currentProfile.uid,
              phoneNumber: phone,
              isPrimary: currentList.isEmpty,
              isVerified: false,
              createdAt: DateTime.now(),
            ));
          await updatePhones(updatedList);
        }
    }
  }

  Future<void> updatePhones(List<Phone> phones) async {
    emit(ProfileLoading());
    final res = await updatePhoneNumbersUseCase(phones);
    if (isClosed) return;
    res.fold(
        (l) {
          print('ProfileCubit UpdatePhones Error: ${l.message}');
          final currentProfile = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
          emit(ProfileError(l, profile: currentProfile));
        }, (profile) => emit(ProfileLoaded(profile)));
  }

  Future<void> addAddress(Address address) async {
    emit(ProfileLoading());
    final res = await addAddressUseCase(address);
    if (isClosed) return;
    res.fold(
        (l) {
          print('ProfileCubit AddAddress Error: ${l.message}');
          final currentProfile = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
          emit(ProfileError(l, profile: currentProfile));
        }, (profile) => emit(ProfileLoaded(profile)));
  }

  Future<void> updateAddress(int index, Address address) async {
    emit(ProfileLoading());
    final res = await updateAddressUseCase(index, address);
    if (isClosed) return;
    res.fold(
        (l) {
          print('ProfileCubit UpdateAddress Error: ${l.message}');
          final currentProfile = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
          emit(ProfileError(l, profile: currentProfile));
        }, (profile) => emit(ProfileLoaded(profile)));
  }

  Future<void> deleteAddress(int index) async {
    emit(ProfileLoading());
    final res = await deleteAddressUseCase(index);
    if (isClosed) return;
    res.fold(
        (l) {
          print('ProfileCubit DeleteAddress Error: ${l.message}');
          final currentProfile = state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
          emit(ProfileError(l, profile: currentProfile));
        }, (profile) => emit(ProfileLoaded(profile)));
  }
}
