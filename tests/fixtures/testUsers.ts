import { aadhaar, mobile, storageKey, vehicleRegistration } from '../utils/randomData';
import { guardian, password } from './testData';

export function adultFemaleRider(overrides: Record<string, unknown> = {}) {
  return {
    fullName: 'SheGo Adult Rider',
    mobileNumber: mobile(),
    password,
    gender: 'FEMALE',
    dateOfBirth: '1998-04-15',
    emergencyContact: mobile(),
    riderAadhaarNumber: aadhaar(),
    profilePhotoStorageKey: storageKey('profile', 'rider.jpg'),
    ...overrides
  };
}

export function minorFemaleRider(overrides: Record<string, unknown> = {}) {
  return {
    fullName: 'SheGo Minor Rider',
    mobileNumber: mobile(),
    password,
    gender: 'FEMALE',
    dateOfBirth: '2012-04-15',
    guardianAadhaarNumber: aadhaar(),
    ...guardian,
    ...overrides
  };
}

export function maleChildRider(overrides: Record<string, unknown> = {}) {
  return {
    fullName: 'SheGo Child Rider',
    mobileNumber: mobile(),
    password,
    gender: 'MALE',
    dateOfBirth: '2015-03-10',
    guardianAadhaarNumber: aadhaar(),
    ...guardian,
    ...overrides
  };
}

export function adultFemaleDriver(overrides: Record<string, unknown> = {}) {
  return {
    fullName: 'SheGo Driver',
    mobileNumber: mobile(),
    password,
    gender: 'FEMALE',
    dateOfBirth: '1995-06-10',
    address: 'Driver onboarding address',
    aadhaarNumber: aadhaar(),
    drivingLicenseNumber: `DL-${Date.now()}`,
    vehicleType: 'SCOOTY',
    vehicleRegistrationNumber: vehicleRegistration(),
    insuranceDetails: `INS-${Date.now()}`,
    profilePhotoStorageKey: storageKey('profile', 'driver.jpg'),
    selfieStorageKey: storageKey('kyc', 'selfie.jpg'),
    aadhaarStorageKey: storageKey('kyc', 'aadhaar.jpg'),
    licenseStorageKey: storageKey('kyc', 'license.jpg'),
    vehicleDocumentStorageKey: storageKey('kyc', 'vehicle.jpg'),
    insuranceDocumentStorageKey: storageKey('kyc', 'insurance.jpg'),
    ...overrides
  };
}
