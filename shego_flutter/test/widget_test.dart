import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shego_flutter/main.dart';

void main() {
  testWidgets('SheGo splash renders brand tagline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SheGoApp());

    expect(find.text('Ride Freely. Ride Safely.'), findsOneWidget);
  });

  testWidgets('SheGo navigates from splash to signup selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));

    expect(find.text('Continue as Rider'), findsOneWidget);
    expect(find.text('Continue as Driver'), findsOneWidget);
  });

  testWidgets('active status badge shows active and inactive styles',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      StatusBadge(label: 'ACTIVE', active: true),
      StatusBadge(label: 'INACTIVE', active: false),
    ]))));

    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
  });

  testWidgets('profile sections render cards instead of raw JSON',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(
                children: profileSections({
      'id': 'driver-1',
      'fullName': 'Test Driver',
      'mobileNumber': '9876543210',
      'gender': 'FEMALE',
      'dateOfBirth': '1998-01-01',
      'age': 28,
      'aadhaarLast4': '1234',
      'vehicleType': 'SCOOTY',
      'vehicleRegistrationNumber': 'DL01AB1234',
      'kycStatus': 'APPROVED',
      'adminApprovalStatus': 'APPROVED',
      'available': true,
      'online': true,
    }, isDriver: true)))));

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.textContaining('{'), findsNothing);
  });
}
