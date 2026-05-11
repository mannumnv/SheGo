import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const shegoLogoAsset = 'assets/images/shego_logo.png';

void main() {
  runApp(const SheGoApp());
}

class SheGoApp extends StatelessWidget {
  const SheGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SheGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE83D8F)),
        useMaterial3: true,
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;
      final destination = await restoreDestination();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destination));
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F557E), Color(0xFFD78AB4), Color(0xFFFF4FA1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.28),
                      blurRadius: 42,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(shegoLogoAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Ride Freely. Ride Safely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheGoApi {
  SheGoApi(
      {this.baseUrl = const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'http://localhost:8080')});

  final String baseUrl;
  String? token;

  Map<String, String> headersFor([String? tokenOverride]) => {
        'Content-Type': 'application/json',
        if ((tokenOverride ?? token) != null)
          'Authorization': 'Bearer ${tokenOverride ?? token}',
      };

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {String? tokenOverride}) async {
    final response = await http.post(Uri.parse('$baseUrl$path'),
        headers: headersFor(tokenOverride), body: jsonEncode(body));
    return _decode(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body,
      {String? tokenOverride}) async {
    final response = await http.put(Uri.parse('$baseUrl$path'),
        headers: headersFor(tokenOverride), body: jsonEncode(body));
    return _decode(response);
  }

  Future<dynamic> get(String path, {String? tokenOverride}) async {
    final response = await http.get(Uri.parse('$baseUrl$path'),
        headers: headersFor(tokenOverride));
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final payload =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
          payload['message'] ?? 'Unauthorized. Please login again.');
    }
    if (response.statusCode >= 400 || payload['success'] == false) {
      throw Exception(payload['message'] ?? 'Request failed');
    }
    return payload['data'];
  }
}

final api = SheGoApi();
String? adminToken;
const secureSessionStorage = FlutterSecureStorage();

class SessionData {
  const SessionData({required this.token, required this.role});

  final String token;
  final String role;
}

Future<void> saveSession(String token, String role) async {
  await secureSessionStorage.write(key: 'accessToken', value: token);
  await secureSessionStorage.write(key: 'role', value: role);
  api.token = token;
  adminToken = role == 'ADMIN' ? token : null;
}

Future<void> clearSession() async {
  await secureSessionStorage.delete(key: 'accessToken');
  await secureSessionStorage.delete(key: 'role');
  api.token = null;
  adminToken = null;
}

List<String> rolesFrom(dynamic me) {
  if (me is! Map) return const [];
  return List<dynamic>.from(me['roles'] ?? const [])
      .map((role) => role.toString())
      .toList();
}

String primaryRole(List<String> roles) {
  if (roles.contains('ADMIN')) return 'ADMIN';
  if (roles.contains('DRIVER')) return 'DRIVER';
  if (roles.contains('RIDER')) return 'RIDER';
  return roles.isEmpty ? 'RIDER' : roles.first;
}

Widget dashboardForRole(String role) {
  return switch (role) {
    'ADMIN' => const AdminDashboardScreen(),
    'DRIVER' => const DriverHomeScreen(),
    _ => const RiderHomeScreen(),
  };
}

Future<Widget> restoreDestination() async {
  final token = await secureSessionStorage.read(key: 'accessToken');
  if (token == null || token.isEmpty) return const RoleSelectionScreen();
  try {
    final me = await api.get('/api/users/me', tokenOverride: token);
    final role = primaryRole(rolesFrom(me));
    api.token = token;
    adminToken = role == 'ADMIN' ? token : null;
    return dashboardForRole(role);
  } catch (_) {
    await clearSession();
    return const RoleSelectionScreen();
  }
}

Future<void> completeAuthenticatedNavigation(BuildContext context, String token,
    String expectedRole, String message) async {
  final me = await api.get('/api/users/me', tokenOverride: token);
  final roles = rolesFrom(me);
  if (!roles.contains(expectedRole)) {
    throw Exception(
        'This account is not allowed to access ${expectedRole.toLowerCase()} app.');
  }
  final role = primaryRole(roles);
  await saveSession(token, role);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboardForRole(role)), (_) => false);
}

class AuthApi {
  Future<dynamic> login(String path, String mobileNumber, String password) {
    return api.post(path, {'mobileNumber': mobileNumber, 'password': password});
  }
}

class RiderApi {
  Future<dynamic> profile() => api.get('/api/riders/profile');
  Future<dynamic> history() => api.get('/api/rides/history');
}

class DriverApi {
  Future<dynamic> profile() => api.get('/api/drivers/profile');
  Future<dynamic> setAvailability(bool available, bool online) => api.put(
      '/api/drivers/availability', {'available': available, 'online': online});
  Future<dynamic> earnings() => api.get('/api/drivers/me/earnings');
}

class RideApi {
  Future<dynamic> estimate(Map<String, dynamic> body) =>
      api.post('/api/rides/estimate', body);
  Future<dynamic> book(Map<String, dynamic> body) =>
      api.post('/api/rides/book', body);
  Future<dynamic> details(String rideId) => api.get('/api/rides/$rideId');
  Future<dynamic> accept(String rideId) =>
      api.post('/api/rides/$rideId/accept', {});
  Future<dynamic> reject(String rideId) =>
      api.post('/api/rides/$rideId/reject', {});
  Future<dynamic> arrive(String rideId) =>
      api.post('/api/rides/$rideId/arrive', {});
  Future<dynamic> start(String rideId, String otp) =>
      api.post('/api/rides/$rideId/start', {'otp': otp});
  Future<dynamic> complete(String rideId) =>
      api.post('/api/rides/$rideId/complete', {});
}

class PaymentApi {
  Future<dynamic> initiate(String rideId, String amount, String method) =>
      api.post('/api/payments/initiate', {
        'rideId': rideId,
        'amount': amount,
        'method': method,
      });
  Future<dynamic> history() => api.get('/api/payments/history');
}

class RatingApi {
  Future<dynamic> submit(Map<String, dynamic> body) =>
      api.post('/api/ratings', body);
}

class GuardianApi {
  Future<dynamic> list() => api.get('/api/guardians');
  Future<dynamic> add(String name, String mobileNumber, String relationship) =>
      api.post('/api/guardians', {
        'name': name,
        'mobileNumber': mobileNumber,
        'relationship': relationship,
      });
}

class AdminApi {
  Future<dynamic> pendingDrivers() =>
      api.get('/api/admin/pending-driver-kyc', tokenOverride: adminToken);
  Future<dynamic> approveDriver(String driverId) =>
      api.post('/api/admin/drivers/$driverId/approve', {},
          tokenOverride: adminToken);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    AuthScreen(),
    RideFlowScreen(),
    SafetyScreen(),
    CommuteScreen(),
    ChildRideScreen(),
    SubscriptionScreen(),
    DeliveryScreen(),
    AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
                child: Image.asset(shegoLogoAsset,
                    width: 34, height: 34, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            const Text('SheGo'),
          ],
        ),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'Auth'),
          NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'Ride'),
          NavigationDestination(
              icon: Icon(Icons.health_and_safety), label: 'Safety'),
          NavigationDestination(
              icon: Icon(Icons.work_history), label: 'Commute'),
          NavigationDestination(icon: Icon(Icons.child_care), label: 'Child'),
          NavigationDestination(
              icon: Icon(Icons.card_membership), label: 'Pass'),
          NavigationDestination(
              icon: Icon(Icons.local_shipping), label: 'Delivery'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class AsyncPanel extends StatelessWidget {
  const AsyncPanel(
      {super.key,
      required this.loading,
      required this.error,
      required this.empty,
      required this.child});

  final bool loading;
  final String? error;
  final bool empty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
                child: Image.asset(shegoLogoAsset,
                    width: 96, height: 96, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
          child: Text(error!, style: const TextStyle(color: Colors.red)));
    }
    if (empty) return const Center(child: Text('No records yet'));
    return child;
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleSelectionScreen();
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  shegoLogoAsset,
                                  width: 132,
                                  height: 132,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'SheGo',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ride Freely. Ride Safely.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Choose how you want to continue',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: () =>
                                      open(context, const RiderSignupScreen()),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Continue as Rider'),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      open(context, const DriverSignupScreen()),
                                  icon: const Icon(Icons.two_wheeler),
                                  label: const Text('Continue as Driver'),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      open(context, const RiderLoginScreen()),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Rider login'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      open(context, const DriverLoginScreen()),
                                  icon: const Icon(Icons.verified_user),
                                  label: const Text('Driver login'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      open(context, const AdminLoginScreen()),
                                  icon: const Icon(Icons.admin_panel_settings),
                                  label: const Text('Admin login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Riders: women/girls of any age and boys below 14. Drivers: verified adult women only.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SignupSelectionScreen extends RoleSelectionScreen {
  const SignupSelectionScreen({super.key});
}

class RiderSignupScreen extends StatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  State<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends State<RiderSignupScreen> {
  final fullName = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final dob = TextEditingController();
  final address = TextEditingController();
  final emergencyContact = TextEditingController();
  final riderAadhaar = TextEditingController();
  final guardianName = TextEditingController();
  final guardianMobile = TextEditingController();
  final guardianAadhaar = TextEditingController();
  String gender = 'FEMALE';
  String guardianRelationship = 'Mother';
  bool guardianConsent = false;
  bool loading = false;
  String? message;

  int? get age => calculateAge(dob.text.trim());
  bool get guardianRequired {
    final currentAge = age;
    if (currentAge == null) return false;
    return (gender == 'FEMALE' && currentAge < 18) ||
        (gender == 'MALE' && currentAge < 14);
  }

  bool get selfAadhaarRequired {
    final currentAge = age;
    return gender == 'FEMALE' && currentAge != null && currentAge >= 18;
  }

  String verificationType() {
    if (guardianRequired) return 'GUARDIAN_AADHAAR';
    if (selfAadhaarRequired) return 'SELF_AADHAAR';
    return 'PENDING_ADMIN_REVIEW';
  }

  String? validate() {
    final currentAge = age;
    if (fullName.text.trim().isEmpty ||
        mobile.text.trim().isEmpty ||
        password.text.isEmpty) {
      return 'Full name, mobile number, and password are required.';
    }
    if (currentAge == null) return 'Enter date of birth in YYYY-MM-DD format.';
    if (gender == 'MALE' && currentAge >= 14) {
      return 'Male riders age 14 or above are not allowed.';
    }
    if (guardianRequired) {
      if (guardianName.text.trim().isEmpty ||
          guardianMobile.text.trim().isEmpty ||
          guardianAadhaar.text.trim().isEmpty ||
          !guardianConsent) {
        return 'Parent/guardian verification is required for riders below 18 and boys below 14.';
      }
    }
    if (selfAadhaarRequired && riderAadhaar.text.trim().isEmpty) {
      return 'Rider Aadhaar is required for adult female riders.';
    }
    return null;
  }

  Future<void> submit() async {
    final validation = validate();
    if (validation != null) {
      setState(() => message = validation);
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final data = await api.post('/api/riders/signup', {
        'fullName': fullName.text.trim(),
        'mobileNumber': mobile.text.trim(),
        'password': password.text,
        'gender': gender,
        'dateOfBirth': dob.text.trim(),
        'address': emptyToNull(address.text),
        'emergencyContact': emptyToNull(emergencyContact.text),
        'riderAadhaarNumber': emptyToNull(riderAadhaar.text),
        'guardianName': emptyToNull(guardianName.text),
        'guardianRelationship': guardianRelationship,
        'guardianMobileNumber': emptyToNull(guardianMobile.text),
        'guardianAadhaarNumber': emptyToNull(guardianAadhaar.text),
        'guardianConsent': guardianConsent,
      });
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Access token missing.');
      }
      if (!mounted) return;
      await completeAuthenticatedNavigation(
          context, token, 'RIDER', 'Rider signup complete. Welcome to SheGo.');
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Rider signup',
        children: [
          TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['FEMALE', 'MALE', 'OTHER']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => gender = value ?? gender),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dob,
            decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                helperText: age == null ? null : 'Age: $age'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: address,
              decoration:
                  const InputDecoration(labelText: 'Address (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: emergencyContact,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Emergency contact')),
          const SizedBox(height: 12),
          if (selfAadhaarRequired) ...[
            TextField(
                controller: riderAadhaar,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Rider Aadhaar number')),
            const SizedBox(height: 12),
          ],
          if (guardianRequired) ...[
            const Text(
                'Parent/guardian verification is required for this rider.'),
            const SizedBox(height: 12),
            TextField(
                controller: guardianName,
                decoration: const InputDecoration(labelText: 'Guardian name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: guardianRelationship,
              decoration:
                  const InputDecoration(labelText: 'Guardian relationship'),
              items: const ['Mother', 'Father', 'Guardian']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(
                  () => guardianRelationship = value ?? guardianRelationship),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: guardianMobile,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Guardian mobile number')),
            const SizedBox(height: 12),
            TextField(
                controller: guardianAadhaar,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Guardian Aadhaar number')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardianConsent,
              onChanged: (value) =>
                  setState(() => guardianConsent = value ?? false),
              title: const Text('Guardian consent received'),
            ),
          ],
          InfoStrip(text: 'Verification type: ${verificationType()}'),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.person_add),
              label: const Text('Create rider account')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final fullName = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final dob = TextEditingController();
  final address = TextEditingController();
  final aadhaarNumber = TextEditingController();
  final license = TextEditingController();
  final registration = TextEditingController();
  final insurance = TextEditingController();
  final profilePhotoKey = TextEditingController();
  final selfieKey = TextEditingController();
  final aadhaarKey = TextEditingController();
  final licenseKey = TextEditingController();
  final vehicleDocumentKey = TextEditingController();
  final insuranceDocumentKey = TextEditingController();
  String gender = 'FEMALE';
  String vehicleType = 'SCOOTY';
  bool loading = false;
  String? message;

  int? get age => calculateAge(dob.text.trim());

  String? validate() {
    final currentAge = age;
    if (fullName.text.trim().isEmpty ||
        mobile.text.trim().isEmpty ||
        password.text.isEmpty) {
      return 'Full name, mobile number, and password are required.';
    }
    if (gender != 'FEMALE') return 'Only female drivers are allowed.';
    if (currentAge == null) return 'Enter date of birth in YYYY-MM-DD format.';
    if (currentAge < 18) return 'Driver must be a legally adult woman.';
    if (address.text.trim().isEmpty ||
        aadhaarNumber.text.trim().isEmpty ||
        license.text.trim().isEmpty ||
        registration.text.trim().isEmpty ||
        insurance.text.trim().isEmpty) {
      return 'Address, Aadhaar, license, vehicle registration, and insurance details are required.';
    }
    return null;
  }

  Future<void> submit() async {
    final validation = validate();
    if (validation != null) {
      setState(() => message = validation);
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final data = await api.post('/api/drivers/signup', {
        'fullName': fullName.text.trim(),
        'mobileNumber': mobile.text.trim(),
        'password': password.text,
        'gender': gender,
        'dateOfBirth': dob.text.trim(),
        'address': address.text.trim(),
        'aadhaarNumber': aadhaarNumber.text.trim(),
        'drivingLicenseNumber': license.text.trim(),
        'vehicleType': vehicleType,
        'vehicleRegistrationNumber': registration.text.trim(),
        'insuranceDetails': insurance.text.trim(),
        'profilePhotoStorageKey': emptyToNull(profilePhotoKey.text),
        'selfieStorageKey': emptyToNull(selfieKey.text),
        'aadhaarStorageKey': emptyToNull(aadhaarKey.text),
        'licenseStorageKey': emptyToNull(licenseKey.text),
        'vehicleDocumentStorageKey': emptyToNull(vehicleDocumentKey.text),
        'insuranceDocumentStorageKey': emptyToNull(insuranceDocumentKey.text),
      });
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Access token missing.');
      }
      if (!mounted) return;
      await completeAuthenticatedNavigation(context, token, 'DRIVER',
          'Driver signup submitted. KYC and admin approval are required before going online.');
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Driver signup',
        children: [
          TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['FEMALE', 'MALE', 'OTHER']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => gender = value ?? gender),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dob,
            decoration: InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                helperText: age == null ? null : 'Age: $age'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(
              controller: aadhaarNumber,
              decoration: const InputDecoration(labelText: 'Aadhaar number')),
          const SizedBox(height: 12),
          TextField(
              controller: license,
              decoration:
                  const InputDecoration(labelText: 'Driving license number')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: const ['SCOOTY', 'BIKE']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => vehicleType = value ?? vehicleType),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: registration,
              decoration: const InputDecoration(
                  labelText: 'Vehicle registration number')),
          const SizedBox(height: 12),
          TextField(
              controller: insurance,
              decoration:
                  const InputDecoration(labelText: 'Insurance details')),
          const SizedBox(height: 12),
          TextField(
              controller: profilePhotoKey,
              decoration: const InputDecoration(
                  labelText: 'Profile photo storage key (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: aadhaarKey,
              decoration: const InputDecoration(
                  labelText: 'Aadhaar document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: licenseKey,
              decoration: const InputDecoration(
                  labelText: 'License document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: vehicleDocumentKey,
              decoration: const InputDecoration(
                  labelText: 'Vehicle document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: insuranceDocumentKey,
              decoration: const InputDecoration(
                  labelText: 'Insurance document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(
              controller: selfieKey,
              decoration: const InputDecoration(
                  labelText: 'Selfie verification storage key (optional)')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.verified),
              label: const Text('Create driver account')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class RiderLoginScreen extends StatelessWidget {
  const RiderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginForm(
        title: 'Rider login',
        path: '/api/riders/login',
        expectedRole: 'RIDER',
        forgotPasswordScreen: RiderForgotPasswordScreen(),
        successMessage: 'Login successful. Welcome to SheGo.',
      );
}

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginForm(
        title: 'Driver login',
        path: '/api/drivers/login',
        expectedRole: 'DRIVER',
        forgotPasswordScreen: DriverForgotPasswordScreen(),
        successMessage: 'Login successful. Welcome to SheGo Driver.',
      );
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.title,
    required this.path,
    required this.expectedRole,
    required this.forgotPasswordScreen,
    required this.successMessage,
  });

  final String title;
  final String path;
  final String expectedRole;
  final Widget forgotPasswordScreen;
  final String successMessage;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final mobile = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> login() async {
    if (mobile.text.trim().isEmpty || password.text.trim().isEmpty) {
      setState(() => message = 'Mobile number and password are required.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final data = await api.post(widget.path,
          {'mobileNumber': mobile.text.trim(), 'password': password.text});
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Access token missing.');
      }
      if (!mounted) return;
      await completeAuthenticatedNavigation(
          context, token, widget.expectedRole, widget.successMessage);
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: widget.title,
        children: [
          TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : login,
              icon: const Icon(Icons.login),
              label: const Text('Login')),
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => widget.forgotPasswordScreen)),
            child: const Text('Forgot password?'),
          ),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class AdminForgotPasswordScreen extends StatelessWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen(
      title: 'Admin forgot password', returnTo: 'Admin login');
}

class RiderForgotPasswordScreen extends StatelessWidget {
  const RiderForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen(
      title: 'Rider forgot password', returnTo: 'Rider login');
}

class DriverForgotPasswordScreen extends StatelessWidget {
  const DriverForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordScreen(
      title: 'Driver forgot password', returnTo: 'Driver login');
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen(
      {super.key, required this.title, required this.returnTo});

  final String title;
  final String returnTo;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final identifier = TextEditingController();
  final otp = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool loading = false;
  String? message;
  String? devOtp;

  Future<void> sendOtp() async {
    if (identifier.text.trim().isEmpty) {
      setState(() => message = 'Registered mobile number is required.');
      return;
    }
    await run(() async {
      final data = await api.post('/api/auth/forgot-password/send-otp',
          {'identifier': identifier.text.trim()});
      devOtp = data is Map ? data['devOtp']?.toString() : null;
      message = devOtp == null || devOtp!.isEmpty
          ? 'If the account exists, an OTP has been sent.'
          : 'Dev OTP: $devOtp';
    });
  }

  Future<void> verifyOtp() async {
    if (identifier.text.trim().isEmpty || otp.text.trim().isEmpty) {
      setState(() => message = 'Mobile number and OTP are required.');
      return;
    }
    await run(() async {
      await api.post('/api/auth/forgot-password/verify-otp',
          {'identifier': identifier.text.trim(), 'otp': otp.text.trim()});
      message = 'OTP verified. Set a new password.';
    });
  }

  Future<void> resetPassword() async {
    if (newPassword.text != confirmPassword.text) {
      setState(() => message = 'Passwords do not match.');
      return;
    }
    await run(() async {
      await api.post('/api/auth/forgot-password/reset', {
        'identifier': identifier.text.trim(),
        'otp': otp.text.trim(),
        'newPassword': newPassword.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset. Return to ${widget.returnTo}.')));
      Navigator.of(context).pop();
    });
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await action();
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: widget.title,
        children: [
          TextField(
              controller: identifier,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Registered mobile number')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : sendOtp,
              icon: const Icon(Icons.sms),
              label: const Text('Send OTP')),
          const SizedBox(height: 12),
          TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: loading ? null : verifyOtp,
              icon: const Icon(Icons.verified),
              label: const Text('Verify OTP')),
          const SizedBox(height: 12),
          TextField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(
              controller: confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : resetPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Reset password')),
          if (loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class AppDashboardScaffold extends StatelessWidget {
  const AppDashboardScaffold(
      {super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  Future<void> logout(BuildContext context) async {
    await clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              ClipOval(
                  child: Image.asset(shegoLogoAsset,
                      width: 32, height: 32, fit: BoxFit.cover)),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: children),
      );
}

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final pickup = TextEditingController(text: 'Connaught Place');
  final drop = TextEditingController(text: 'Noida Sector 18');
  bool loading = false;
  String? error;
  dynamic profile;
  List<dynamic> recentRides = [];
  dynamic activeRide;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      profile = await RiderApi().profile();
      recentRides = List<dynamic>.from(await RiderApi().history());
      activeRide = recentRides.cast<dynamic>().firstWhere(
            (ride) =>
                ride is Map &&
                !['COMPLETED', 'CANCELLED'].contains(ride['status']),
            orElse: () => null,
          );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen))
      .then((_) => load());

  @override
  Widget build(BuildContext context) => AppDashboardScaffold(
        title: 'SheGo Rider',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Text('Welcome ${profile is Map ? profile['fullName'] ?? '' : ''}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
              controller: pickup,
              decoration: const InputDecoration(labelText: 'Pickup location')),
          const SizedBox(height: 12),
          TextField(
              controller: drop,
              decoration: const InputDecoration(labelText: 'Drop location')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => open(BookRideScreen(
                initialPickup: pickup.text, initialDrop: drop.text)),
            icon: const Icon(Icons.two_wheeler),
            label: const Text('Book ride'),
          ),
          const SizedBox(height: 16),
          if (activeRide != null)
            RideSummaryCard(
                title: 'Active ride',
                ride: Map<String, dynamic>.from(activeRide as Map)),
          const SizedBox(height: 12),
          Text('Recent rides', style: Theme.of(context).textTheme.titleMedium),
          if (recentRides.isEmpty)
            const InfoStrip(text: 'No recent rides yet.'),
          ...recentRides.take(3).whereType<Map>().map((ride) => RideSummaryCard(
              title: 'Ride', ride: Map<String, dynamic>.from(ride))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                  onPressed: () => open(const GuardianContactsScreen()),
                  icon: const Icon(Icons.family_restroom),
                  label: const Text('Guardian mode')),
              OutlinedButton.icon(
                  onPressed: () => open(const SOSScreen()),
                  icon: const Icon(Icons.sos),
                  label: const Text('SOS')),
              OutlinedButton.icon(
                  onPressed: () => open(const RideHistoryScreen()),
                  icon: const Icon(Icons.history),
                  label: const Text('Ride history')),
              OutlinedButton.icon(
                  onPressed: () => open(const RiderProfileScreen()),
                  icon: const Icon(Icons.person),
                  label: const Text('Profile')),
            ],
          ),
        ],
      );
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool loading = false;
  String? error;
  Map<String, dynamic>? profile;
  bool available = false;
  bool online = false;

  bool get approved =>
      profile?['kycStatus'] == 'APPROVED' &&
      profile?['adminApprovalStatus'] == 'APPROVED';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      profile = Map<String, dynamic>.from(await DriverApi().profile());
      available = profile?['available'] == true;
      online = profile?['online'] == true;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateAvailability(bool value) async {
    setState(() {
      available = value;
      online = value;
      loading = true;
      error = null;
    });
    try {
      await DriverApi().setAvailability(value, value);
      await load();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen))
      .then((_) => load());

  @override
  Widget build(BuildContext context) => AppDashboardScaffold(
        title: 'SheGo Driver',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Text('Welcome ${profile?['fullName'] ?? ''}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          InfoStrip(
              text:
                  'KYC: ${profile?['kycStatus'] ?? '-'} | Admin: ${profile?['adminApprovalStatus'] ?? '-'}'),
          if (!approved) ...[
            const SizedBox(height: 10),
            const InfoStrip(
                text: 'Your account is pending admin verification.'),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: online,
            onChanged: approved && !loading ? updateAvailability : null,
            title: const Text('Online / available for rides'),
            subtitle: Text(approved
                ? 'Go online after admin approval.'
                : 'Approval required before going online.'),
          ),
          const SizedBox(height: 12),
          Text('Available ride requests',
              style: Theme.of(context).textTheme.titleMedium),
          const InfoStrip(
              text:
                  'Ride requests arrive through backend WebSocket/push. Use Ride request to accept a ride by ID during local testing.'),
          const SizedBox(height: 8),
          Text('Active ride', style: Theme.of(context).textTheme.titleMedium),
          const InfoStrip(text: 'No active ride loaded.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                  onPressed:
                      approved ? () => open(const RideRequestScreen()) : null,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Ride requests')),
              OutlinedButton.icon(
                  onPressed: () => open(const DriverAvailabilityScreen()),
                  icon: const Icon(Icons.toggle_on),
                  label: const Text('Availability')),
              OutlinedButton.icon(
                  onPressed: () => open(const DriverKycStatusScreen()),
                  icon: const Icon(Icons.verified_user),
                  label: const Text('KYC status')),
              OutlinedButton.icon(
                  onPressed: () => open(const DriverEarningsScreen()),
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text('Earnings')),
              OutlinedButton.icon(
                  onPressed: () => open(const DriverRideHistoryScreen()),
                  icon: const Icon(Icons.history),
                  label: const Text('History')),
              OutlinedButton.icon(
                  onPressed: () => open(const DriverProfileScreen()),
                  icon: const Icon(Icons.person),
                  label: const Text('Profile')),
            ],
          ),
        ],
      );
}

class RideSummaryCard extends StatelessWidget {
  const RideSummaryCard({super.key, required this.title, required this.ride});

  final String title;
  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text('$title: ${ride['status'] ?? '-'}'),
          subtitle: Text(
              'Vehicle: ${ride['vehicleType'] ?? '-'} | Fare: ${ride['estimatedFare'] ?? ride['finalFare'] ?? '-'}'),
          trailing: Text(ride['id']?.toString().substring(0, 8) ?? ''),
        ),
      );
}

class BookRideScreen extends StatefulWidget {
  const BookRideScreen(
      {super.key, this.initialPickup = '', this.initialDrop = ''});

  final String initialPickup;
  final String initialDrop;

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  late final pickup = TextEditingController(text: widget.initialPickup);
  late final drop = TextEditingController(text: widget.initialDrop);
  String vehicleType = 'SCOOTY';
  bool loading = false;
  String? error;
  dynamic estimate;

  Map<String, dynamic> rideBody() => {
        'vehicleType': vehicleType,
        'pickupLat': 28.6139,
        'pickupLng': 77.2090,
        'dropLat': 28.5355,
        'dropLng': 77.3910,
        'pickupAddress': pickup.text.trim(),
        'dropAddress': drop.text.trim(),
      };

  Future<void> getEstimate() async {
    await run(() async {
      estimate = await RideApi().estimate(rideBody());
    });
  }

  Future<void> book() async {
    await run(() async {
      final ride = await RideApi().book(rideBody());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SearchingDriverScreen(
              ride: Map<String, dynamic>.from(ride as Map))));
    });
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Book ride',
        children: [
          TextField(
              controller: pickup,
              decoration: const InputDecoration(labelText: 'Pickup address')),
          const SizedBox(height: 12),
          TextField(
              controller: drop,
              decoration: const InputDecoration(labelText: 'Drop address')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: const ['SCOOTY', 'BIKE']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => vehicleType = value ?? vehicleType),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
                onPressed: loading ? null : getEstimate,
                icon: const Icon(Icons.calculate),
                label: const Text('Estimate')),
            FilledButton.icon(
                onPressed: loading ? null : book,
                icon: const Icon(Icons.two_wheeler),
                label: const Text('Book')),
          ]),
          if (loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red))),
          if (estimate != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RideEstimateScreen(estimate: estimate)),
        ],
      );
}

class RideEstimateScreen extends StatelessWidget {
  const RideEstimateScreen({super.key, required this.estimate});

  final dynamic estimate;

  @override
  Widget build(BuildContext context) => InfoStrip(
      text:
          "Estimate: ${const JsonEncoder.withIndent('  ').convert(estimate)}");
}

class SearchingDriverScreen extends StatelessWidget {
  const SearchingDriverScreen({super.key, required this.ride});

  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Searching driver',
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const InfoStrip(
              text:
                  'Ride requested. Waiting for an approved woman driver to accept.'),
          const SizedBox(height: 12),
          Text('Ride ID: ${ride['id'] ?? ride['rideId'] ?? '-'}'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RideAcceptedScreen(
                    rideId: (ride['id'] ?? ride['rideId']).toString()))),
            icon: const Icon(Icons.refresh),
            label: const Text('Check ride status'),
          ),
        ],
      );
}

class RideAcceptedScreen extends StatefulWidget {
  const RideAcceptedScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<RideAcceptedScreen> createState() => _RideAcceptedScreenState();
}

class _RideAcceptedScreenState extends State<RideAcceptedScreen> {
  bool loading = false;
  String? error;
  Map<String, dynamic>? details;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      details =
          Map<String, dynamic>.from(await RideApi().details(widget.rideId));
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Ride accepted',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (details != null) ...[
            DriverDetailsScreen(details: details!),
            const SizedBox(height: 12),
            RideOtpScreen(details: details!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ActiveRideTrackingScreen(rideId: widget.rideId))),
              icon: const Icon(Icons.map),
              label: const Text('Open tracking'),
            ),
          ],
        ],
      );
}

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({super.key, required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final driver = details['driver'] is Map
        ? Map<String, dynamic>.from(details['driver'] as Map)
        : <String, dynamic>{};
    return Card(
      child: ListTile(
        leading: const Icon(Icons.two_wheeler),
        title: Text(driver['fullName']?.toString() ?? 'Driver details pending'),
        subtitle: Text(
            'Contact: ${driver['contactNumber'] ?? '-'}\nVehicle: ${driver['vehicleType'] ?? details['vehicleType'] ?? '-'} ${driver['vehicleRegistrationNumber'] ?? ''}\nETA: ${details['etaMinutes'] ?? '-'} min'),
      ),
    );
  }
}

class RideOtpScreen extends StatelessWidget {
  const RideOtpScreen({super.key, required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) => InfoStrip(
      text:
          'Start OTP: ${details['startOtp'] ?? 'Shown after driver reaches pickup.'}');
}

class ActiveRideTrackingScreen extends StatelessWidget {
  const ActiveRideTrackingScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Live tracking',
        children: [
          const InfoStrip(
              text:
                  'Live driver/rider tracking is handled by backend WebSocket and Redis live location.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RideCompletionScreen(rideId: rideId))),
            icon: const Icon(Icons.flag),
            label: const Text('Ride completed'),
          ),
        ],
      );
}

class RideCompletionScreen extends StatelessWidget {
  const RideCompletionScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Ride completed',
        children: [
          InfoStrip(text: 'Ride $rideId is ready for payment and rating.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PaymentScreen(rideId: rideId))),
            icon: const Icon(Icons.payments),
            label: const Text('Continue to payment'),
          ),
        ],
      );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;
  String? message;

  Future<void> cashPayment() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await PaymentApi().initiate(widget.rideId, '0', 'CASH');
      message = 'Cash payment recorded or pending backend confirmation.';
    } catch (e) {
      message = 'Payment API not completed yet: $e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Payment',
        children: [
          const InfoStrip(
              text:
                  'MVP supports cash payment. Online payment remains a placeholder until provider integration is complete.'),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : cashPayment,
              icon: const Icon(Icons.money),
              label: const Text('Cash payment')),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RatingReviewScreen(rideId: widget.rideId))),
            icon: const Icon(Icons.star),
            label: const Text('Rate ride'),
          ),
          if (loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final ratedUserId = TextEditingController();
  final comments = TextEditingController();
  double overall = 5;
  bool loading = false;
  String? message;

  Future<void> submit() async {
    if (ratedUserId.text.trim().isEmpty) {
      setState(() =>
          message = 'Rated user ID is required by the current rating API.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await RatingApi().submit({
        'rideId': widget.rideId,
        'ratedUserId': ratedUserId.text.trim(),
        'overallRating': overall.round(),
        'safetyRating': overall.round(),
        'comfortRating': overall.round(),
        'drivingBehaviorRating': overall.round(),
        'comments': comments.text.trim(),
        'unsafeReported': false,
      });
      message = 'Review submitted.';
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Rating and review',
        children: [
          TextField(
              controller: ratedUserId,
              decoration:
                  const InputDecoration(labelText: 'Driver/Rider user ID')),
          const SizedBox(height: 12),
          Slider(
              value: overall,
              min: 1,
              max: 5,
              divisions: 4,
              label: overall.round().toString(),
              onChanged: (value) => setState(() => overall = value)),
          TextField(
              controller: comments,
              decoration: const InputDecoration(labelText: 'Comments')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.star),
              label: const Text('Submit review')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ApiListScreen(title: 'Ride history', path: '/api/rides/history');
}

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApiDetailsScreen(
      title: 'Rider profile', path: '/api/riders/profile');
}

class GuardianContactsScreen extends StatelessWidget {
  const GuardianContactsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ApiListScreen(title: 'Guardian contacts', path: '/api/guardians');
}

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool loading = false;
  String? message;

  Future<void> trigger() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await api.post('/api/sos/trigger', {
        'latitude': 28.6139,
        'longitude': 77.2090,
        'message': 'Emergency help requested'
      });
      message = 'SOS sent to guardians and admin support.';
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'SOS',
        children: [
          const InfoStrip(
              text:
                  'Long press panic support and voice trigger are future integrations.'),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : trigger,
              icon: const Icon(Icons.sos),
              label: const Text('Trigger SOS')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class DriverKycStatusScreen extends StatelessWidget {
  const DriverKycStatusScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApiDetailsScreen(
      title: 'Driver KYC status', path: '/api/drivers/profile');
}

class DriverAvailabilityScreen extends StatefulWidget {
  const DriverAvailabilityScreen({super.key});

  @override
  State<DriverAvailabilityScreen> createState() =>
      _DriverAvailabilityScreenState();
}

class _DriverAvailabilityScreenState extends State<DriverAvailabilityScreen> {
  bool online = false;
  bool loading = false;
  String? message;

  Future<void> update(bool value) async {
    setState(() {
      online = value;
      loading = true;
      message = null;
    });
    try {
      await DriverApi().setAvailability(value, value);
      message = value ? 'You are online.' : 'You are offline.';
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Driver availability',
        children: [
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: online,
              onChanged: loading ? null : update,
              title: const Text('Online')),
          if (message != null) Text(message!),
        ],
      );
}

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final rideId = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> accept() async {
    await run(() async {
      final accepted = await RideApi().accept(rideId.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RiderDetailsScreen(
              details: Map<String, dynamic>.from(accepted as Map))));
    });
  }

  Future<void> reject() async {
    await run(() async {
      await RideApi().reject(rideId.text.trim());
      message = 'Ride rejected.';
    });
  }

  Future<void> run(Future<void> Function() action) async {
    if (rideId.text.trim().isEmpty) {
      setState(() => message = 'Ride ID is required.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await action();
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Ride request',
        children: [
          TextField(
              controller: rideId,
              decoration:
                  const InputDecoration(labelText: 'Ride ID from request')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton.icon(
                onPressed: loading ? null : accept,
                icon: const Icon(Icons.check),
                label: const Text('Accept')),
            OutlinedButton.icon(
                onPressed: loading ? null : reject,
                icon: const Icon(Icons.close),
                label: const Text('Reject')),
          ]),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class RiderDetailsScreen extends StatelessWidget {
  const RiderDetailsScreen({super.key, required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final driverView = details['driverView'] is Map
        ? Map<String, dynamic>.from(details['driverView'] as Map)
        : details;
    final rider = driverView['rider'] is Map
        ? Map<String, dynamic>.from(driverView['rider'] as Map)
        : <String, dynamic>{};
    final rideId = (details['id'] ?? driverView['id']).toString();
    return SignupScaffold(
      title: 'Rider details',
      children: [
        InfoStrip(
            text:
                'Rider: ${rider['fullName'] ?? '-'} | Contact: ${rider['contactNumber'] ?? '-'}'),
        const SizedBox(height: 8),
        Text('Pickup: ${driverView['pickupAddress'] ?? '-'}'),
        Text('Drop: ${driverView['dropAddress'] ?? '-'}'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => NavigateToPickupScreen(rideId: rideId))),
          icon: const Icon(Icons.navigation),
          label: const Text('Navigate to pickup'),
        ),
      ],
    );
  }
}

class NavigateToPickupScreen extends StatelessWidget {
  const NavigateToPickupScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Navigate to pickup',
        children: [
          const InfoStrip(
              text:
                  'Use Google Maps integration in production. For MVP, mark pickup arrival from here.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PickupArrivedScreen(rideId: rideId))),
            icon: const Icon(Icons.pin_drop),
            label: const Text('Mark arrived'),
          ),
        ],
      );
}

class PickupArrivedScreen extends StatefulWidget {
  const PickupArrivedScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<PickupArrivedScreen> createState() => _PickupArrivedScreenState();
}

class _PickupArrivedScreenState extends State<PickupArrivedScreen> {
  bool loading = false;
  String? message;

  Future<void> arrive() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await RideApi().arrive(widget.rideId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EnterRideOtpScreen(rideId: widget.rideId)));
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Pickup arrived',
        children: [
          FilledButton.icon(
              onPressed: loading ? null : arrive,
              icon: const Icon(Icons.pin_drop),
              label: const Text('Confirm arrival')),
          if (message != null) Text(message!),
        ],
      );
}

class EnterRideOtpScreen extends StatefulWidget {
  const EnterRideOtpScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<EnterRideOtpScreen> createState() => _EnterRideOtpScreenState();
}

class _EnterRideOtpScreenState extends State<EnterRideOtpScreen> {
  final otp = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> start() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await RideApi().start(widget.rideId, otp.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ActiveRideScreen(rideId: widget.rideId)));
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Enter ride OTP',
        children: [
          TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP from rider')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : start,
              icon: const Icon(Icons.password),
              label: const Text('Start ride')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class ActiveRideScreen extends StatelessWidget {
  const ActiveRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Active ride',
        children: [
          const InfoStrip(
              text:
                  'Ride is running. Live location updates continue through WebSocket.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CompleteRideScreen(rideId: rideId))),
            icon: const Icon(Icons.flag),
            label: const Text('Complete ride'),
          ),
        ],
      );
}

class CompleteRideScreen extends StatefulWidget {
  const CompleteRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<CompleteRideScreen> createState() => _CompleteRideScreenState();
}

class _CompleteRideScreenState extends State<CompleteRideScreen> {
  bool loading = false;
  String? message;

  Future<void> complete() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await RideApi().complete(widget.rideId);
      message =
          'Ride completed. Fare and earning summary will appear in earnings.';
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Complete ride',
        children: [
          FilledButton.icon(
              onPressed: loading ? null : complete,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete ride')),
          if (message != null)
            Padding(
                padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApiListScreen(
      title: 'Driver earnings', path: '/api/drivers/me/earnings');
}

class DriverRideHistoryScreen extends StatelessWidget {
  const DriverRideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApiListScreen(
      title: 'Driver ride history', path: '/api/rides/history');
}

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApiDetailsScreen(
      title: 'Driver profile', path: '/api/drivers/profile');
}

class ApiDetailsScreen extends StatefulWidget {
  const ApiDetailsScreen({super.key, required this.title, required this.path});

  final String title;
  final String path;

  @override
  State<ApiDetailsScreen> createState() => _ApiDetailsScreenState();
}

class _ApiDetailsScreenState extends State<ApiDetailsScreen> {
  bool loading = false;
  String? error;
  dynamic data;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      data = await api.get(widget.path);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: widget.title,
        children: [
          AsyncPanel(
            loading: loading,
            error: error,
            empty: data == null,
            child: Text(const JsonEncoder.withIndent('  ').convert(data)),
          ),
        ],
      );
}

class ApiListScreen extends StatefulWidget {
  const ApiListScreen({super.key, required this.title, required this.path});

  final String title;
  final String path;

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  bool loading = false;
  String? error;
  List<dynamic> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      rows = List<dynamic>.from(await api.get(widget.path));
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: widget.title,
        children: [
          OutlinedButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh')),
          const SizedBox(height: 12),
          AsyncPanel(
            loading: loading,
            error: error,
            empty: rows.isEmpty,
            child: Text(const JsonEncoder.withIndent('  ').convert(rows)),
          ),
        ],
      );
}

class SignupScaffold extends StatelessWidget {
  const SignupScaffold(
      {super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
                child: ClipOval(
                    child: Image.asset(shegoLogoAsset,
                        width: 110, height: 110, fit: BoxFit.cover))),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8)),
        child: Text(text),
      );
}

int? calculateAge(String value) {
  final dob = DateTime.tryParse(value);
  if (dob == null) {
    return null;
  }
  final now = DateTime.now();
  var years = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    years--;
  }
  return years;
}

String? emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

class RideFlowScreen extends StatefulWidget {
  const RideFlowScreen({super.key});

  @override
  State<RideFlowScreen> createState() => _RideFlowScreenState();
}

class _RideFlowScreenState extends State<RideFlowScreen> {
  final rideId = TextEditingController();
  final otp = TextEditingController();
  String vehicleType = 'SCOOTY';
  bool loading = false;
  String? error;
  dynamic result;

  Future<void> run(Future<dynamic> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      result = await action();
      if (result is Map && result['id'] != null) {
        rideId.text = result['id'].toString();
      }
      if (result is Map && result['rideId'] != null) {
        rideId.text = result['rideId'].toString();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  String get id => rideId.text.trim();

  Future<void> book() => run(() => api.post('/api/rides/book', {
        'vehicleType': vehicleType,
        'pickupLat': 28.6139,
        'pickupLng': 77.2090,
        'dropLat': 28.5355,
        'dropLng': 77.3910,
        'pickupAddress': 'Connaught Place',
        'dropAddress': 'Noida Sector 18',
      }));

  Future<void> accept() => run(() => api.post('/api/rides/$id/accept', {}));
  Future<void> arrive() => run(() => api.post('/api/rides/$id/arrive', {}));
  Future<void> start() =>
      run(() => api.post('/api/rides/$id/start', {'otp': otp.text.trim()}));
  Future<void> load() => run(() => api.get('/api/rides/$id'));

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ride booking and OTP flow',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vehicleType,
            decoration: const InputDecoration(labelText: 'Ride vehicle type'),
            items: const ['SCOOTY', 'BIKE']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) =>
                setState(() => vehicleType = value ?? vehicleType),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: rideId,
              decoration: const InputDecoration(labelText: 'Ride ID')),
          const SizedBox(height: 12),
          TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ride start OTP')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                  onPressed: loading ? null : book,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Book')),
              OutlinedButton.icon(
                  onPressed: loading || id.isEmpty ? null : accept,
                  icon: const Icon(Icons.check),
                  label: const Text('Accept')),
              OutlinedButton.icon(
                  onPressed: loading || id.isEmpty ? null : arrive,
                  icon: const Icon(Icons.pin_drop),
                  label: const Text('Arrived')),
              FilledButton.tonalIcon(
                  onPressed: loading || id.isEmpty ? null : start,
                  icon: const Icon(Icons.password),
                  label: const Text('Start with OTP')),
              OutlinedButton.icon(
                  onPressed: loading || id.isEmpty ? null : load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load details')),
            ],
          ),
          const SizedBox(height: 16),
          AsyncPanel(
            loading: loading,
            error: error,
            empty: result == null,
            child: Text(const JsonEncoder.withIndent('  ').convert(result)),
          ),
        ],
      );
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool loading = false;
  String? error;
  Map<String, dynamic>? policy;

  Future<void> loadPolicy() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      policy = Map<String, dynamic>.from(
          await api.get('/api/safety/late-night-policy'));
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> triggerSos() async {
    try {
      await api.post('/api/sos/trigger', {
        'latitude': 28.6139,
        'longitude': 77.2090,
        'message': 'Emergency help requested'
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS sent to support dashboard')));
      }
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
            onPressed: loadPolicy,
            icon: const Icon(Icons.nightlight),
            label: const Text('Load late-night policy')),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
            onPressed: triggerSos,
            icon: const Icon(Icons.sos),
            label: const Text('Trigger SOS')),
        const SizedBox(height: 16),
        AsyncPanel(
          loading: loading,
          error: error,
          empty: policy == null,
          child: Text(const JsonEncoder.withIndent('  ').convert(policy)),
        ),
      ],
    );
  }
}

class CommuteScreen extends StatefulWidget {
  const CommuteScreen({super.key});

  @override
  State<CommuteScreen> createState() => _CommuteScreenState();
}

class _CommuteScreenState extends State<CommuteScreen> {
  bool loading = false;
  String? error;
  List<dynamic> rows = [];

  Future<void> create() async {
    setState(() => loading = true);
    try {
      await api.post('/api/commutes', {
        'commuteType': 'OFFICE',
        'frequency': 'DAILY',
        'vehicleType': 'SCOOTY',
        'pickupAddress': 'Home',
        'dropAddress': 'Office',
        'pickupLat': 28.61,
        'pickupLng': 77.20,
        'dropLat': 28.55,
        'dropLng': 77.25,
        'pickupTime': '09:00:00'
      });
      await load();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = List<dynamic>.from(await api.get('/api/commutes/me'));
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FeatureList(
        title: 'Office, college, metro pickup/drop schedules',
        loading: loading,
        error: error,
        rows: rows,
        onCreate: create,
        onRefresh: load,
      );
}

class ChildRideScreen extends StatelessWidget {
  const ChildRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleActionScreen(
      title: 'Child safe ride',
      description:
          'Book school pickup/drop with verified female drivers, pickup OTP, drop OTP, and guardian tracking.',
      path: '/api/child-rides/book',
      body: {
        'childName': 'Demo Child',
        'scheduledAt': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String()
      },
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = false;
  String? error;
  List<dynamic> rows = [];

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = List<dynamic>.from(await api.get('/api/subscriptions/plans'));
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FeatureList(
        title: 'Office, college, premium safety, and late-night passes',
        loading: loading,
        error: error,
        rows: rows,
        onRefresh: load,
      );
}

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleActionScreen(
      title: 'Women delivery network',
      description:
          'Future-safe parcel, pharmacy, cosmetics, and women-only delivery request flow.',
      path: '/api/deliveries',
      body: {
        'category': 'PHARMACY',
        'pickupAddress': 'Pharmacy',
        'dropAddress': 'Home',
        'itemDescription': 'Demo medicine parcel'
      },
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool loading = false;
  String? error;
  String? activePath;
  dynamic result;

  bool get authenticated => adminToken != null;

  void onAdminAuthenticated(String token) {
    setState(() {
      adminToken = token;
      error = null;
      result = null;
    });
    loadDashboard();
  }

  Future<void> logout() async {
    await clearSession();
    setState(() {
      adminToken = null;
      result = null;
      activePath = null;
      error = null;
    });
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (_) => false);
  }

  Future<void> loadDashboard() async {
    if (!authenticated) return;
    setState(() => loading = true);
    try {
      result = await api.get('/api/admin/dashboard', tokenOverride: adminToken);
      activePath = '/api/admin/dashboard';
      error = null;
    } catch (e) {
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Forbidden') ||
          e.toString().contains('Invalid credentials')) {
        adminToken = null;
      }
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loadPath(String path) async {
    if (!authenticated) return;
    setState(() => loading = true);
    try {
      result = await api.get(path, tokenOverride: adminToken);
      activePath = path;
      error = null;
    } catch (e) {
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Forbidden') ||
          e.toString().contains('Invalid credentials')) {
        adminToken = null;
      }
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> approveDriver(String driverId) async {
    await adminAction(() => api.post('/api/admin/drivers/$driverId/approve', {},
        tokenOverride: adminToken));
  }

  Future<void> rejectDriver(String driverId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller =
            TextEditingController(text: 'Rejected by admin review');
        return AlertDialog(
          title: const Text('Reject driver'),
          content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Reason')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Reject')),
          ],
        );
      },
    );
    if (reason == null) return;
    await adminAction(() => api.post(
          '/api/admin/reject-driver-verification?driverId=$driverId&reason=${Uri.encodeComponent(reason)}',
          {},
          tokenOverride: adminToken,
        ));
  }

  Future<void> adminAction(Future<dynamic> Function() action) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await action();
      await loadPath('/api/admin/pending-driver-kyc');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!authenticated) {
      return AdminLoginScreen(onAuthenticated: onAdminAuthenticated);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: Text('Admin dashboard',
                    style: Theme.of(context).textTheme.titleLarge)),
            TextButton.icon(
                onPressed: () => logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
                onPressed: loadDashboard,
                icon: const Icon(Icons.dashboard),
                label: const Text('Dashboard')),
            OutlinedButton.icon(
              onPressed: () => loadPath('/api/admin/minor-riders'),
              icon: const Icon(Icons.family_restroom),
              label: const Text('Minor riders'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  loadPath('/api/admin/pending-guardian-verifications'),
              icon: const Icon(Icons.verified_user),
              label: const Text('Guardian approvals'),
            ),
            OutlinedButton.icon(
              onPressed: () => loadPath('/api/admin/pending-driver-kyc'),
              icon: const Icon(Icons.two_wheeler),
              label: const Text('Pending drivers'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncPanel(
          loading: loading,
          error: error,
          empty: result == null,
          child: _resultView(),
        ),
      ],
    );
  }

  Widget _resultView() {
    if (activePath == '/api/admin/pending-driver-kyc' && result is List) {
      final drivers = result as List;
      if (drivers.isEmpty) {
        return const Text('No pending driver verifications.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: drivers
            .map((item) =>
                _pendingDriverTile(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    }
    return Text(const JsonEncoder.withIndent('  ').convert(result));
  }

  Widget _pendingDriverTile(Map<String, dynamic> driver) {
    final status =
        '${driver['kycStatus'] ?? '-'} / ${driver['adminApprovalStatus'] ?? '-'}';
    final driverId = driver['driverId']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.two_wheeler),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(driver['fullName']?.toString() ?? 'Driver',
                        style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mobile: ${driver['mobileNumber'] ?? '-'}'),
            Text(
                'Gender/Age: ${driver['gender'] ?? '-'} / ${driver['age'] ?? '-'}'),
            Text(
                'Vehicle: ${driver['vehicleType'] ?? '-'} ${driver['vehicleRegistrationNumber'] ?? ''}'),
            Text('KYC/Admin: $status'),
            Text(
                'Admin approved: ${driver['adminApproved'] == true ? 'Yes' : 'No'}'),
            Text(
                'Available/Online: ${driver['available'] == true ? 'Yes' : 'No'} / ${driver['online'] == true ? 'Yes' : 'No'}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: loading || driverId == null
                      ? null
                      : () => approveDriver(driverId),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: loading || driverId == null
                      ? null
                      : () => rejectDriver(driverId),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SafeArea(child: AdminScreen()));
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, this.onAuthenticated});

  final ValueChanged<String>? onAuthenticated;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final identifier = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    if (identifier.text.trim().isEmpty || password.text.trim().isEmpty) {
      setState(() => error = 'Admin mobile/email and password are required.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.post('/api/auth/login',
          {'mobileNumber': identifier.text.trim(), 'password': password.text});
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Access token missing');
      }
      final me = Map<String, dynamic>.from(
          await api.get('/api/users/me', tokenOverride: token));
      final roles = List<dynamic>.from(me['roles'] ?? const []);
      if (!roles.contains('ADMIN')) {
        throw Exception(
            'This account is not allowed to access admin dashboard.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Login successful. Welcome to Admin Dashboard.')));
      }
      await saveSession(token, 'ADMIN');
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(token);
      } else if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (_) => false);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
              child: ClipOval(
                  child: Image.asset(shegoLogoAsset,
                      width: 118, height: 118, fit: BoxFit.cover))),
          const SizedBox(height: 16),
          Text('Admin login', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
              controller: identifier,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Admin mobile number or email')),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : login,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Login')),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminForgotPasswordScreen())),
            child: const Text('Forgot password?'),
          ),
          if (loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator()),
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red))),
        ],
      );
}

class SimpleActionScreen extends StatefulWidget {
  const SimpleActionScreen(
      {super.key,
      required this.title,
      required this.description,
      required this.path,
      required this.body});

  final String title;
  final String description;
  final String path;
  final Map<String, dynamic> body;

  @override
  State<SimpleActionScreen> createState() => _SimpleActionScreenState();
}

class _SimpleActionScreenState extends State<SimpleActionScreen> {
  bool loading = false;
  String? error;
  dynamic result;

  Future<void> create() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      result = await api.post(widget.path, widget.body);
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(widget.description),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: loading ? null : create,
              icon: const Icon(Icons.add),
              label: const Text('Create demo request')),
          const SizedBox(height: 16),
          AsyncPanel(
            loading: loading,
            error: error,
            empty: result == null,
            child: Text(const JsonEncoder.withIndent('  ').convert(result)),
          ),
        ],
      );
}

class FeatureList extends StatelessWidget {
  const FeatureList({
    super.key,
    required this.title,
    required this.loading,
    required this.error,
    required this.rows,
    this.onCreate,
    required this.onRefresh,
  });

  final String title;
  final bool loading;
  final String? error;
  final List<dynamic> rows;
  final VoidCallback? onCreate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (onCreate != null)
                FilledButton.icon(
                    onPressed: loading ? null : onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create')),
              OutlinedButton.icon(
                  onPressed: loading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 16),
          AsyncPanel(
            loading: loading,
            error: error,
            empty: rows.isEmpty,
            child: Column(
              children: rows
                  .map((row) => Card(
                        child: ListTile(
                          title: Text(row['commuteType']?.toString() ??
                              row['name']?.toString() ??
                              'SheGo item'),
                          subtitle: Text(row.toString()),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}
