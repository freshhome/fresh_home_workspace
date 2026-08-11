import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';
import 'package:shared/domain/user/usecases/create_address_usecase.dart';
import 'package:shared/domain/user/usecases/update_address_usecase.dart';

class MockAddressRepository implements AddressRepository {
  bool createCalled = false;
  bool updateCalled = false;

  @override
  Future<Either<Failure, Address>> createAddress(Address address) async {
    createCalled = true;
    return right(address);
  }

  @override
  Future<Either<Failure, Address>> updateAddress(Address address) async {
    updateCalled = true;
    return right(address);
  }

  @override
  Future<Either<Failure, void>> deleteAddress(String addressId) async => right(null);

  @override
  Future<Either<Failure, Address>> getAddressById(String addressId) async => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Address>>> getAddresses(String userId) async => right([]);

  @override
  Future<Either<Failure, Address?>> getPrimaryAddress(String userId) async => right(null);

  @override
  Future<Either<Failure, void>> setPrimaryAddress({required String userId, required String addressId}) async => right(null);
}

void main() {
  late MockAddressRepository mockRepository;
  late CreateAddressUseCase createAddressUseCase;
  late AddAddressUseCase addAddressUseCase;
  late UpdateAddressUseCase updateAddressUseCase;

  setUp(() {
    mockRepository = MockAddressRepository();
    createAddressUseCase = CreateAddressUseCase(mockRepository);
    addAddressUseCase = AddAddressUseCase(mockRepository);
    updateAddressUseCase = UpdateAddressUseCase(mockRepository);
  });

  final validAddress = Address(
    id: 'addr-1',
    userId: 'user-1',
    governorate: 'Cairo',
    city: 'New Cairo',
    district: 'Fifth Settlement',
    streetOrCompound: 'South 90th Street',
    buildingIdentifier: 'Building 12',
    floor: '3',
    apartmentOrUnit: '302',
    landmark: 'Near Air Force Hospital',
    latitude: 30.0275,
    longitude: 31.4361,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final invalidAddress = validAddress.copyWith(governorate: 'X');

  group('CreateAddressUseCase / AddAddressUseCase Unit Tests', () {
    test('Valid Address -> Validator succeeds -> Repository called', () async {
      final result = await createAddressUseCase(validAddress);

      expect(result.isRight(), isTrue);
      expect(mockRepository.createCalled, isTrue);
    });

    test('Invalid Address -> Validator fails -> Repository NOT called', () async {
      final result = await addAddressUseCase(invalidAddress);

      expect(result.isLeft(), isTrue);
      expect(mockRepository.createCalled, isFalse);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });

  group('UpdateAddressUseCase Unit Tests', () {
    test('Valid Address -> Validator succeeds -> Repository called', () async {
      final result = await updateAddressUseCase(validAddress);

      expect(result.isRight(), isTrue);
      expect(mockRepository.updateCalled, isTrue);
    });

    test('Invalid Address -> Validator fails -> Repository NOT called', () async {
      final result = await updateAddressUseCase(invalidAddress);

      expect(result.isLeft(), isTrue);
      expect(mockRepository.updateCalled, isFalse);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should not succeed'),
      );
    });
  });
}
