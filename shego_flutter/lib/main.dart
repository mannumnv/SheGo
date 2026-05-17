import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const shegoLogoAsset = 'assets/images/shego_logo.png';
const googleMapsApiKey =
    String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

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
      throw SheGoApiException(
          payload['message'] ?? 'Unauthorized. Please login again.');
    }
    if (response.statusCode >= 400 || payload['success'] == false) {
      throw SheGoApiException(payload['message'] ?? 'Request failed');
    }
    return payload['data'];
  }
}

class SheGoApiException implements Exception {
  SheGoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '');
  if (message == 'Unexpected server error') {
    return 'Something went wrong. Please try again or contact SheGo support.';
  }
  return message;
}

LatLng coordinateForAddress(String value, {required bool pickup}) {
  final text = value.toLowerCase();
  if (text.contains('noida')) return const LatLng(28.5355, 77.3910);
  if (text.contains('gurugram') || text.contains('cyber')) {
    return const LatLng(28.4950, 77.0890);
  }
  if (text.contains('airport')) return const LatLng(28.5562, 77.1000);
  if (text.contains('saket')) return const LatLng(28.5245, 77.2066);
  if (text.contains('railway')) return const LatLng(28.6426, 77.2197);
  if (text.contains('huda')) return const LatLng(28.4595, 77.0266);
  if (text.contains('connaught')) return const LatLng(28.6315, 77.2167);
  return pickup
      ? const LatLng(28.6139, 77.2090)
      : const LatLng(28.5355, 77.3910);
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
  Future<dynamic> setActive(bool active) =>
      api.put('/api/riders/active', {'active': active});
  Future<dynamic> history() => api.get('/api/rides/history');
}

class DriverApi {
  Future<dynamic> profile() => api.get('/api/drivers/profile');
  Future<dynamic> verificationStatus() =>
      api.get('/api/drivers/verification-status');
  Future<dynamic> submitDocuments(Map<String, dynamic> body) =>
      api.post('/api/drivers/verification-documents', body);
  Future<dynamic> setAvailability(bool available, bool online) => api.put(
      '/api/drivers/availability', {'available': available, 'online': online});
  Future<dynamic> earnings() => api.get('/api/drivers/me/earnings');
}

class RideApi {
  Future<dynamic> estimate(Map<String, dynamic> body) =>
      api.post('/api/rides/estimate', body);
  Future<dynamic> book(Map<String, dynamic> body) =>
      api.post('/api/rides/book', body);
  Future<dynamic> requests() => api.get('/api/rides/requests');
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

class LocationApi {
  Future<dynamic> route(Map<String, dynamic> body) =>
      api.post('/api/directions/route', body);
  Future<dynamic> saved() => api.get('/api/locations/saved');
  Future<dynamic> saveRecent(Map<String, dynamic> body) =>
      api.post('/api/locations/recent', body);
  Future<dynamic> recent() => api.get('/api/locations/recent');
  Future<dynamic> routeSnapshot(String rideId) =>
      api.get('/api/rides/$rideId/route-snapshot');
}

class PaymentApi {
  Future<dynamic> initiate(String rideId, String amount, String method) =>
      api.post('/api/payments/initiate', {
        'rideId': rideId,
        'amount': amount,
        'method': method,
      });
  Future<dynamic> history() => api.get('/api/payments/history');
  Future<dynamic> invoice(String rideId) =>
      api.get('/api/payments/ride/$rideId/invoice');
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

class NotificationApi {
  Future<List<dynamic>> list() async =>
      List<dynamic>.from(await api.get('/api/notifications'));
  Future<dynamic> unreadCount() => api.get('/api/notifications/unread-count');
  Future<dynamic> markRead(String id) =>
      api.post('/api/notifications/$id/read', {});
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
          backgroundColor: Theme.of(context).colorScheme.surface,
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
            const NotificationBell(),
            IconButton(
              tooltip: 'Logout',
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SheGoBackground(
          child:
              ListView(padding: const EdgeInsets.all(16), children: children),
        ),
      );
}

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int unread = 0;
  bool loading = false;
  Timer? pollTimer;

  @override
  void initState() {
    super.initState();
    loadCount();
    pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => loadCount());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCount() async {
    try {
      final data = await NotificationApi().unreadCount();
      if (mounted && data is Map) {
        setState(() => unread = int.tryParse('${data['count']}') ?? 0);
      }
    } catch (_) {
      // Notification count should never break dashboard rendering.
    }
  }

  Future<void> openPanel() async {
    setState(() => loading = true);
    try {
      final rows = await NotificationApi().list();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => NotificationPanel(
          notifications: rows.whereType<Map>().map((item) {
            return Map<String, dynamic>.from(item);
          }).toList(),
        ),
      );
      await loadCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
              tooltip: 'Notifications',
              onPressed: loading ? null : openPanel,
              icon: const Icon(Icons.notifications_none)),
          if (unread > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
        ],
      );
}

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key, required this.notifications});

  final List<Map<String, dynamic>> notifications;

  IconData iconFor(String? type) => switch (type) {
        'ACTION_REQUIRED' => Icons.assignment_late,
        'APPROVAL' => Icons.verified,
        'REJECTION' => Icons.report,
        'RIDE' => Icons.two_wheeler,
        'PAYMENT' => Icons.payments,
        'PROFILE' => Icons.person,
        _ => Icons.notifications,
      };

  Color colorFor(BuildContext context, String? type) => switch (type) {
        'APPROVAL' => const Color(0xFF1FA463),
        'REJECTION' => Theme.of(context).colorScheme.error,
        'ACTION_REQUIRED' => const Color(0xFFB7791F),
        'RIDE' => const Color(0xFFE83D8F),
        _ => Theme.of(context).colorScheme.primary,
      };

  Future<void> openTarget(
      BuildContext context, Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null) {
      await NotificationApi().markRead(id).catchError((_) => null);
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    final route = notification['route']?.toString();
    Widget? target;
    if (route == 'driver-documents') {
      target = const DriverDocumentSubmissionScreen();
    } else if (route == 'driver-profile') {
      target = const DriverProfileScreen();
    } else if (route == 'driver-ride-requests') {
      target = const RideRequestScreen();
    } else if (route == 'driver-earnings') {
      target = const DriverEarningsScreen();
    } else if (route == 'rider-profile') {
      target = const RiderProfileScreen();
    } else if (route == 'ride-details' && notification['targetId'] != null) {
      target = RideAcceptedScreen(rideId: notification['targetId'].toString());
    } else if (route == 'admin-driver-verification' ||
        route == 'admin-rider-verification') {
      target = const AdminDashboardScreen();
    }
    if (target != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => target!));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notifications',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (notifications.isEmpty)
                const InfoStrip(text: 'No notifications yet.'),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: notifications.map((notification) {
                    final read = notification['read'] == true;
                    final type = notification['type']?.toString();
                    return Card(
                      color: read
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.24),
                      child: ListTile(
                        leading:
                            Icon(iconFor(type), color: colorFor(context, type)),
                        title: Text(notification['title']?.toString() ?? '-'),
                        subtitle: Text(
                            '${notification['body'] ?? ''}\n${notification['createdAt'] ?? ''}'),
                        isThreeLine: true,
                        trailing:
                            read ? null : const Icon(Icons.mark_email_unread),
                        onTap: () => openTarget(context, notification),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
}

class SheGoBackground extends StatelessWidget {
  const SheGoBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              const Color(0xFFFFF1F8),
              colorScheme.primaryContainer.withValues(alpha: 0.32),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.055,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                            child: Image.asset(shegoLogoAsset,
                                width: 220, height: 220, fit: BoxFit.cover)),
                        const SizedBox(height: 10),
                        Text(
                          'SheGo',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
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
  bool riderActive = true;

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
      if (profile is Map) riderActive = profile['active'] != false;
      try {
        recentRides = List<dynamic>.from(await RiderApi().history());
      } catch (_) {
        recentRides = [];
      }
      activeRide = recentRides.cast<dynamic>().firstWhere(
            (ride) =>
                ride is Map &&
                !['COMPLETED', 'CANCELLED'].contains(ride['status']),
            orElse: () => null,
          );
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen))
      .then((_) => load());

  Future<void> updateActive(bool value) async {
    setState(() {
      riderActive = value;
      loading = true;
      error = null;
    });
    try {
      profile = await RiderApi().setActive(value);
      if (profile is Map) riderActive = profile['active'] != false;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppDashboardScaffold(
        title: 'SheGo Rider',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (error != null) ErrorBanner(message: error!),
          Text('Welcome ${profile is Map ? profile['fullName'] ?? '' : ''}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ActiveStatusCard(
              title: 'Rider booking status',
              active: riderActive,
              loading: loading,
              onChanged: updateActive),
          const SizedBox(height: 12),
          LocationField(
              controller: pickup,
              label: 'Pickup location',
              icon: Icons.my_location,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          LocationField(
              controller: drop,
              label: 'Drop location',
              icon: Icons.location_on,
              onChanged: (_) => setState(() {})),
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
  List<dynamic> rideRequests = [];

  bool get approved => profile?['verificationStatus'] == 'APPROVED';

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
      if (available && online && approved) {
        rideRequests = List<dynamic>.from(await RideApi().requests());
      } else {
        rideRequests = [];
      }
    } catch (e) {
      error = friendlyError(e);
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
      setState(() => error = friendlyError(e));
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
                  'Verification: ${profile?['verificationStatus'] ?? 'INCOMPLETE'} | KYC: ${profile?['kycStatus'] ?? '-'} | Admin: ${profile?['adminApprovalStatus'] ?? '-'}'),
          if (!approved) ...[
            const SizedBox(height: 10),
            InfoStrip(
                text: profile?['verificationStatus'] == 'REJECTED'
                    ? 'Rejected: ${profile?['verificationRejectionReason'] ?? 'Please re-submit documents.'}'
                    : 'Your documents must be approved by Admin before going active.'),
          ],
          const SizedBox(height: 12),
          ActiveStatusCard(
              title: 'Driver availability',
              active: online && available,
              loading: loading || !approved,
              onChanged: approved ? updateAvailability : null),
          const SizedBox(height: 12),
          Text('Available ride requests',
              style: Theme.of(context).textTheme.titleMedium),
          if (rideRequests.isEmpty)
            InfoStrip(
                text: online && available
                    ? 'No nearby ride requests right now.'
                    : 'Go active to receive ride requests.'),
          ...rideRequests.whereType<Map>().map((ride) => RideSummaryCard(
              title: 'Request', ride: Map<String, dynamic>.from(ride))),
          const SizedBox(height: 8),
          Text('Active ride', style: Theme.of(context).textTheme.titleMedium),
          const InfoStrip(text: 'No active ride loaded.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
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
                  onPressed: () => open(const DriverDocumentSubmissionScreen()),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Submit documents')),
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
          title: Row(children: [
            Expanded(child: Text(title)),
            StatusBadge(
                label: (ride['status'] ?? '-').toString(),
                active: ['ACCEPTED', 'STARTED', 'DRIVER_REACHED']
                    .contains(ride['status'])),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Ride ID: ${ride['id'] ?? '-'}\nVehicle: ${ride['vehicleType'] ?? '-'} | Fare: ${ride['estimatedFare'] ?? ride['finalFare'] ?? '-'}'),
          ),
        ),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFE5F7EB) : const Color(0xFFECEFF3);
    final fg = active ? const Color(0xFF167A3E) : const Color(0xFF5F6672);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class ActiveStatusCard extends StatelessWidget {
  const ActiveStatusCard(
      {super.key,
      required this.active,
      required this.loading,
      required this.onChanged,
      required this.title});

  final bool active;
  final bool loading;
  final ValueChanged<bool>? onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1FA463) : const Color(0xFF6B7280);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(active ? Icons.toggle_on : Icons.toggle_off,
                color: color, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  StatusBadge(
                      label: active ? 'ACTIVE' : 'INACTIVE', active: active),
                ],
              ),
            ),
            Switch(
              value: active,
              activeThumbColor: const Color(0xFF1FA463),
              onChanged: loading ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.rows,
      this.children = const []});

  final String title;
  final IconData icon;
  final Map<String, dynamic> rows;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const Divider(height: 22),
              ...rows.entries.map(
                  (entry) => _DetailRow(label: entry.key, value: entry.value)),
              ...children,
            ],
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 132,
                child: Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700))),
            Expanded(
                child: Text((value == null || value == '') ? '-' : '$value')),
          ],
        ),
      );
}

class LocationField extends StatelessWidget {
  const LocationField(
      {super.key,
      required this.controller,
      required this.label,
      required this.icon,
      this.onChanged});

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  static const suggestions = [
    'Connaught Place Metro Gate 1',
    'Noida Sector 18 Metro',
    'Huda City Centre Metro',
    'Indira Gandhi Airport Terminal 3',
    'Saket Select Citywalk',
    'Cyber Hub Gurugram',
    'New Delhi Railway Station',
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: PopupMenuButton<String>(
                tooltip: 'Suggestions',
                icon: const Icon(Icons.expand_more),
                onSelected: (value) {
                  controller.text = value;
                  onChanged?.call(value);
                },
                itemBuilder: (context) => suggestions
                    .map((value) =>
                        PopupMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Google Places suggestions will use the configured Maps API key in production.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
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
  Map<String, dynamic>? estimate;
  bool showEstimateMath = false;

  LatLng get pickupPoint =>
      coordinateForAddress(pickup.text.trim(), pickup: true);
  LatLng get dropPoint => coordinateForAddress(drop.text.trim(), pickup: false);

  Map<String, dynamic> rideBody() => {
        'vehicleType': vehicleType,
        'pickupLat': pickupPoint.latitude,
        'pickupLng': pickupPoint.longitude,
        'dropLat': dropPoint.latitude,
        'dropLng': dropPoint.longitude,
        'pickupAddress': pickup.text.trim(),
        'dropAddress': drop.text.trim(),
      };

  Future<void> getEstimate() async {
    await run(() async {
      final body = rideBody();
      await LocationApi().saveRecent({
        'queryText': '${pickup.text.trim()} to ${drop.text.trim()}',
        'address': drop.text.trim(),
        'latitude': body['dropLat'],
        'longitude': body['dropLng'],
      }).catchError((_) => null);
      final route = await LocationApi().route({
        'pickupLat': body['pickupLat'],
        'pickupLng': body['pickupLng'],
        'dropLat': body['dropLat'],
        'dropLng': body['dropLng'],
        'pickupAddress': pickup.text.trim(),
        'dropAddress': drop.text.trim(),
      });
      estimate = route is Map
          ? {
              'distanceKm': route['distanceKm'],
              'etaMinutes': route['etaMinutes'],
              'estimatedFare': route['fareBreakdown'] is Map
                  ? route['fareBreakdown']['totalFare']
                  : null,
              'fareBreakdown': route['fareBreakdown'],
              'provider': route['provider'],
            }
          : await RideApi().estimate(body);
      if (estimate is! Map) estimate = null;
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
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Book ride',
        children: [
          MapPreviewCard(
              pickupPoint: pickupPoint,
              dropPoint: dropPoint,
              vehicleType: vehicleType),
          const SizedBox(height: 12),
          LocationField(
              controller: pickup,
              label: 'Pickup address',
              icon: Icons.my_location,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          LocationField(
              controller: drop,
              label: 'Drop address',
              icon: Icons.location_on,
              onChanged: (_) => setState(() {})),
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
                child: ErrorBanner(message: error!)),
          if (estimate != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RideEstimateScreen(
                  estimate: estimate!,
                  expanded: showEstimateMath,
                  onToggle: () =>
                      setState(() => showEstimateMath = !showEstimateMath),
                )),
        ],
      );
}

class RideEstimateScreen extends StatelessWidget {
  const RideEstimateScreen(
      {super.key,
      required this.estimate,
      required this.expanded,
      required this.onToggle});

  final Map<String, dynamic> estimate;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final distance = estimate['distanceKm'] ?? '-';
    final eta = estimate['etaMinutes'] ?? '-';
    final fare = estimate['estimatedFare'] ?? '-';
    final breakdown = estimate['fareBreakdown'] is Map
        ? Map<String, dynamic>.from(estimate['fareBreakdown'] as Map)
        : <String, dynamic>{};
    return Card(
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Fare estimate',
                          style: Theme.of(context).textTheme.titleMedium)),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _EstimateItem(label: 'Distance', value: '$distance km'),
                  _EstimateItem(label: 'ETA', value: '$eta min'),
                  _EstimateItem(label: 'Fare', value: '₹$fare'),
                ],
              ),
              if (expanded) ...[
                const Divider(height: 24),
                const Text('Calculation'),
                const SizedBox(height: 6),
                if (breakdown.isEmpty)
                  Text(
                      'Base fare ₹25 + distance ($distance km) × ₹12/km = ₹$fare')
                else ...[
                  _BreakdownRow('Base fare', breakdown['baseFare']),
                  _BreakdownRow('Distance fare', breakdown['distanceFare']),
                  _BreakdownRow('Time fare', breakdown['timeFare']),
                  _BreakdownRow('Platform fee', breakdown['platformFee']),
                  _BreakdownRow('Surge fee', breakdown['surgeFee']),
                  const Divider(),
                  _BreakdownRow('Total', breakdown['totalFare'], strong: true),
                ],
                if (estimate['provider'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Route provider: ${estimate['provider']}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.value, {this.strong = false});

  final String label;
  final dynamic value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('₹${value ?? 0}',
                style: strong
                    ? const TextStyle(fontWeight: FontWeight.w800)
                    : null),
          ],
        ),
      );
}

class _EstimateItem extends StatelessWidget {
  const _EstimateItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      );
}

class MapPreviewCard extends StatefulWidget {
  const MapPreviewCard(
      {super.key,
      required this.pickupPoint,
      required this.dropPoint,
      required this.vehicleType});

  final LatLng pickupPoint;
  final LatLng dropPoint;
  final String vehicleType;

  @override
  State<MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends State<MapPreviewCard> {
  LatLng? currentPoint;
  String? permissionMessage;
  List<LatLng> nearbyDrivers = [];

  @override
  void initState() {
    super.initState();
    detectCurrentLocation();
    loadNearbyDrivers();
  }

  @override
  void didUpdateWidget(covariant MapPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleType != widget.vehicleType ||
        oldWidget.pickupPoint != widget.pickupPoint) {
      loadNearbyDrivers();
    }
  }

  Future<void> loadNearbyDrivers() async {
    try {
      final rows = List<dynamic>.from(await api
          .get('/api/drivers/nearby?vehicleType=${widget.vehicleType}'));
      if (!mounted) return;
      setState(() {
        nearbyDrivers = rows.asMap().entries.map((entry) {
          final offset = (entry.key + 1) * 0.006;
          return LatLng(widget.pickupPoint.latitude + offset,
              widget.pickupPoint.longitude - offset);
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => nearbyDrivers = []);
    }
  }

  Future<void> detectCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => permissionMessage =
            'Location permission denied. Pickup/drop map still works.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) {
        setState(
            () => currentPoint = LatLng(position.latitude, position.longitude));
      }
    } catch (_) {
      if (mounted) {
        setState(() => permissionMessage =
            'Map loaded with default Delhi route. GPS unavailable in this environment.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            if (googleMapsApiKey.isEmpty)
              _FallbackMap(
                  pickupPoint: widget.pickupPoint,
                  dropPoint: widget.dropPoint,
                  nearbyDrivers: nearbyDrivers)
            else
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: widget.pickupPoint, zoom: 11),
                myLocationEnabled: currentPoint != null,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                      markerId: const MarkerId('pickup'),
                      position: widget.pickupPoint,
                      infoWindow: const InfoWindow(title: 'Pickup')),
                  Marker(
                      markerId: const MarkerId('drop'),
                      position: widget.dropPoint,
                      infoWindow: const InfoWindow(title: 'Drop')),
                  ...nearbyDrivers.asMap().entries.map((entry) => Marker(
                      markerId: MarkerId('driver-${entry.key}'),
                      position: entry.value,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                      infoWindow: const InfoWindow(title: 'Nearby driver'))),
                  if (currentPoint != null)
                    Marker(
                        markerId: const MarkerId('current'),
                        position: currentPoint!,
                        infoWindow: const InfoWindow(title: 'You')),
                },
                polylines: {
                  Polyline(
                      polylineId: const PolylineId('route'),
                      points: [widget.pickupPoint, widget.dropPoint],
                      color: const Color(0xFFE83D8F),
                      width: 4),
                },
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    permissionMessage ??
                        (googleMapsApiKey.isEmpty
                            ? 'Map preview is dynamic. Add GOOGLE_MAPS_API_KEY to enable Google Maps tiles.'
                            : 'Google Maps route preview with pickup, drop, and nearby drivers.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ));
}

class _FallbackMap extends StatelessWidget {
  const _FallbackMap(
      {required this.pickupPoint,
      required this.dropPoint,
      required this.nearbyDrivers});

  final LatLng pickupPoint;
  final LatLng dropPoint;
  final List<LatLng> nearbyDrivers;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFEAF3F0),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _RoutePreviewPainter()),
            const Positioned(
                left: 28,
                top: 34,
                child: _MapPin(color: Color(0xFFE83D8F), label: 'Pickup')),
            const Positioned(
                right: 30,
                bottom: 44,
                child: _MapPin(color: Color(0xFF355C9A), label: 'Drop')),
            ...nearbyDrivers.take(4).toList().asMap().entries.map((entry) =>
                Positioned(
                    left: 72.0 + (entry.key * 34),
                    top: 78.0 + (entry.key.isEven ? 0 : 22),
                    child: const _MapPin(
                        color: Color(0xFF1FA463), label: 'Driver'))),
          ],
        ),
      );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_pin, color: color, size: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
        ],
      );
}

class _RoutePreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Paint()
      ..color = const Color(0xFFE83D8F)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(44, 58)
      ..cubicTo(size.width * .36, 30, size.width * .48, 136, size.width - 48,
          size.height - 56);
    canvas.drawPath(path, road);
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key, required this.ride});

  final Map<String, dynamic> ride;

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  bool loading = false;
  String? message;

  String get rideId => (widget.ride['id'] ?? widget.ride['rideId']).toString();

  Future<void> checkStatus() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final details =
          Map<String, dynamic>.from(await RideApi().details(rideId));
      final status = details['status']?.toString();
      if (!mounted) return;
      if (status == 'COMPLETED') {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => PaymentScreen(rideId: rideId)));
      } else if (status == 'ACCEPTED' ||
          status == 'DRIVER_REACHED' ||
          status == 'STARTED') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RideAcceptedScreen(rideId: rideId)));
      } else {
        message = 'Still searching nearby verified women drivers.';
      }
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Searching driver',
        children: [
          if (loading)
            const LinearProgressIndicator()
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const InfoStrip(
              text:
                  'Ride requested. Waiting for an approved woman driver to accept.'),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                  avatar: Icon(Icons.verified, size: 18),
                  label: Text('Verified drivers')),
              Chip(
                  avatar: Icon(Icons.two_wheeler, size: 18),
                  label: Text('Scooty/Bike only')),
              Chip(
                  avatar: Icon(Icons.shield, size: 18),
                  label: Text('Guardian ready')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Ride ID: $rideId'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : checkStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Check ride status'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InfoStrip(text: message!),
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
  String method = 'CASH';
  Map<String, dynamic>? payment;

  Future<void> confirmPayment() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      final result = await PaymentApi().initiate(widget.rideId, '0', method);
      payment = result is Map ? Map<String, dynamic>.from(result) : null;
      message = method == 'CASH'
          ? 'Cash on delivery selected. Please pay the driver after ride completion.'
          : '$method selected. Online provider integration is pending for production.';
    } catch (e) {
      message = friendlyError(e);
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
                  'Choose payment mode. Cash works for MVP; online providers need production gateway integration.'),
          const SizedBox(height: 12),
          if (payment != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Payment status: ${payment!['status'] ?? '-'}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Amount: ₹${payment!['amount'] ?? '-'}'),
                    Text('Invoice: ${payment!['invoiceNumber'] ?? '-'}'),
                    if (payment!['fareBreakdown'] is Map) ...[
                      const Divider(),
                      _BreakdownRow('Base fare',
                          (payment!['fareBreakdown'] as Map)['baseFare']),
                      _BreakdownRow('Distance fare',
                          (payment!['fareBreakdown'] as Map)['distanceFare']),
                      _BreakdownRow('Time fare',
                          (payment!['fareBreakdown'] as Map)['timeFare']),
                      _BreakdownRow('Platform fee',
                          (payment!['fareBreakdown'] as Map)['platformFee']),
                      _BreakdownRow('Total',
                          (payment!['fareBreakdown'] as Map)['totalFare'],
                          strong: true),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Payment mode'),
            items: const ['CASH', 'UPI', 'PHONEPE', 'PAYTM', 'DEBIT_CARD']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => method = value ?? method),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : confirmPayment,
              icon: const Icon(Icons.money),
              label: const Text('Confirm payment mode')),
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

  @override
  void initState() {
    super.initState();
    loadRatedUser();
  }

  Future<void> loadRatedUser() async {
    try {
      final details =
          Map<String, dynamic>.from(await RideApi().details(widget.rideId));
      final driver = details['driver'] is Map
          ? Map<String, dynamic>.from(details['driver'] as Map)
          : null;
      final userId = driver?['userId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        ratedUserId.text = userId;
      }
    } catch (_) {
      // Rating can still be opened manually if the ride details endpoint is unavailable.
    }
  }

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
      message = friendlyError(e);
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

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final upi = TextEditingController();
  final card = TextEditingController();
  String wallet = 'PhonePe';
  bool loading = false;
  String? message;
  dynamic profile;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      profile = await RiderApi().profile();
      final me = await api.get('/api/users/me');
      fullName.text = me['fullName']?.toString() ?? '';
      email.text = me['email']?.toString() ?? '';
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await api.put('/api/users/me', {
        'fullName': fullName.text.trim(),
        'email': emptyToNull(email.text),
      });
      message =
          'Profile updated. Address, profile photo, and payment methods are ready as UI fields for the next backend API.';
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Rider profile',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (message != null) InfoStrip(text: message!),
          TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Profile photo upload coming soon')),
          const SizedBox(height: 16),
          Text('Payment options',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
              controller: upi,
              decoration: const InputDecoration(labelText: 'UPI ID')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: wallet,
            decoration: const InputDecoration(labelText: 'Preferred wallet'),
            items: const ['PhonePe', 'Paytm', 'Google Pay', 'Cash']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => wallet = value ?? wallet),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: card,
              decoration:
                  const InputDecoration(labelText: 'Debit card last 4 digits')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : save,
              icon: const Icon(Icons.save),
              label: const Text('Save profile')),
          const SizedBox(height: 16),
          if (profile is Map) ...[
            ActiveStatusCard(
                title: 'Rider active status',
                active: profile['active'] != false,
                loading: loading,
                onChanged: (value) async {
                  setState(() => loading = true);
                  try {
                    profile = await RiderApi().setActive(value);
                  } catch (e) {
                    message = friendlyError(e);
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                }),
            const SizedBox(height: 12),
            ...profileSections(Map<String, dynamic>.from(profile as Map),
                isDriver: false),
          ],
        ],
      );
}

class GuardianContactsScreen extends StatefulWidget {
  const GuardianContactsScreen({super.key});

  @override
  State<GuardianContactsScreen> createState() => _GuardianContactsScreenState();
}

class _GuardianContactsScreenState extends State<GuardianContactsScreen> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final relationship = TextEditingController(text: 'Mother');
  bool autoShareLateNight = true;
  bool loading = false;
  String? error;
  List<dynamic> guardians = [];

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
      guardians = List<dynamic>.from(await api.get('/api/guardians'));
    } catch (e) {
      error = friendlyError(e);
      guardians = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    if (name.text.trim().isEmpty || mobile.text.trim().isEmpty) {
      setState(() => error = 'Guardian name and mobile number are required.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await api.post('/api/guardians', {
        'name': name.text.trim(),
        'mobileNumber': mobile.text.trim(),
        'relationship': relationship.text.trim(),
        'autoShareLateNight': autoShareLateNight,
      });
      name.clear();
      mobile.clear();
      await load();
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Guardian mode',
        children: [
          const InfoStrip(
              text:
                  'Trusted contacts receive ride start/end alerts and can be used for late-night auto-share.'),
          const SizedBox(height: 12),
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Guardian name')),
          const SizedBox(height: 12),
          TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Guardian mobile number')),
          const SizedBox(height: 12),
          TextField(
              controller: relationship,
              decoration: const InputDecoration(labelText: 'Relationship')),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: autoShareLateNight,
            onChanged: (value) => setState(() => autoShareLateNight = value),
            title: const Text('Auto-share late-night rides'),
          ),
          FilledButton.icon(
              onPressed: loading ? null : add,
              icon: const Icon(Icons.person_add),
              label: const Text('Add guardian')),
          const SizedBox(height: 16),
          if (loading) const LinearProgressIndicator(),
          if (error != null) ErrorBanner(message: error!),
          Text('Saved guardians',
              style: Theme.of(context).textTheme.titleMedium),
          if (guardians.isEmpty)
            const InfoStrip(text: 'No guardian contacts yet.'),
          ...guardians.whereType<Map>().map((item) {
            final guardian = Map<String, dynamic>.from(item);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.family_restroom),
                title: Text(guardian['name']?.toString() ?? 'Guardian'),
                subtitle: Text(
                    '${guardian['relationship'] ?? '-'} | ${guardian['mobileNumber'] ?? '-'}'),
                trailing: guardian['autoShareLateNight'] == true
                    ? const Icon(Icons.nightlight)
                    : null,
              ),
            );
          }),
        ],
      );
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
  Widget build(BuildContext context) => const ProfileDetailsScreen(
      title: 'Driver KYC status', path: '/api/drivers/profile', isDriver: true);
}

class DriverDocumentSubmissionScreen extends StatefulWidget {
  const DriverDocumentSubmissionScreen({super.key});

  @override
  State<DriverDocumentSubmissionScreen> createState() =>
      _DriverDocumentSubmissionScreenState();
}

class _DriverDocumentSubmissionScreenState
    extends State<DriverDocumentSubmissionScreen> {
  final profilePhoto = TextEditingController();
  final aadhaar = TextEditingController();
  final license = TextEditingController();
  final vehicle = TextEditingController();
  final insurance = TextEditingController();
  bool loading = false;
  String? message;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      profile = Map<String, dynamic>.from(await DriverApi().profile());
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    if (!canEditDocuments) {
      setState(() => message =
          'Documents are locked unless Admin requests re-submission.');
      return;
    }
    final missing = <String>[
      if (profilePhoto.text.trim().isEmpty) 'profile photo/selfie',
      if (aadhaar.text.trim().isEmpty) 'Aadhaar document',
      if (license.text.trim().isEmpty) 'driving license',
      if (vehicle.text.trim().isEmpty) 'vehicle document/photo',
      if (insurance.text.trim().isEmpty) 'insurance document',
    ];
    if (missing.isNotEmpty) {
      setState(() => message = 'Missing: ${missing.join(', ')}');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit documents?'),
        content: const Text(
            'Please confirm that all uploaded documents are clear and correct before sending them for admin verification.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review again')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      loading = true;
      message = null;
    });
    try {
      profile = Map<String, dynamic>.from(await DriverApi().submitDocuments({
        'profilePhotoData': profilePhoto.text.trim(),
        'aadhaarDocumentData': aadhaar.text.trim(),
        'licenseDocumentData': license.text.trim(),
        'vehicleDocumentData': vehicle.text.trim(),
        'insuranceDocumentData': insurance.text.trim(),
      }));
      message =
          'Your documents have been submitted and are pending admin verification.';
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickLocalDocument(
      TextEditingController controller, String label) async {
    if (!canEditDocuments) return;
    setState(() => message = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final name = file.name;
      final type = fileType(name);
      if (!['JPG', 'JPEG', 'PNG', 'WEBP', 'PDF'].contains(type)) {
        setState(() =>
            message = 'Unsupported file type. Use JPG, PNG, WEBP, or PDF.');
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        setState(() =>
            message = 'File is too large. Please upload a file under 5 MB.');
        return;
      }
      if (file.bytes != null) {
        final bytes = file.bytes!;
        if (['JPG', 'JPEG', 'PNG', 'WEBP'].contains(type) && mounted) {
          final cropped = await Navigator.of(context).push<Uint8List>(
              MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => FullScreenImageCropPreview(
                      fileName: name, bytes: bytes)));
          if (cropped == null) return;
          controller.text =
              'local-file:cropped-$name;base64,${base64Encode(cropped)}';
        } else {
          controller.text = 'local-file:$name;base64,${base64Encode(bytes)}';
        }
      } else if (file.path != null) {
        controller.text = 'local-path:${file.path}';
      } else {
        controller.text = 'local-file:$name';
      }
      setState(() => message = '$label selected from local system.');
    } catch (e) {
      setState(() => message = friendlyError(e));
    }
  }

  Future<void> attachGoogleDriveDocument(
      TextEditingController controller, String label) async {
    if (!canEditDocuments) return;
    final link = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attach $label'),
        content: TextField(
          controller: link,
          keyboardType: TextInputType.url,
          decoration:
              const InputDecoration(labelText: 'Google Drive share link'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(context, link.text.trim()),
              icon: const Icon(Icons.add_to_drive),
              label: const Text('Attach')),
        ],
      ),
    );
    if (value == null) return;
    if (!value.startsWith('https://drive.google.com/') &&
        !value.startsWith('https://docs.google.com/')) {
      setState(() => message = 'Please paste a valid Google Drive link.');
      return;
    }
    controller.text = 'google-drive:$value';
    setState(() => message = '$label attached from Google Drive.');
  }

  Widget documentUploadCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool alreadySubmitted,
  }) {
    final selected = controller.text.trim().isNotEmpty;
    final status = selected
        ? 'Selected'
        : alreadySubmitted
            ? 'Submitted'
            : 'Required';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.titleMedium)),
                StatusBadge(
                    label: status, active: selected || alreadySubmitted),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              documentPreview(controller.text),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                    onPressed: loading || !canEditDocuments
                        ? null
                        : () => pickLocalDocument(controller, label),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from device')),
                OutlinedButton.icon(
                    onPressed: loading || !canEditDocuments
                        ? null
                        : () => attachGoogleDriveDocument(controller, label),
                    icon: const Icon(Icons.add_to_drive),
                    label: const Text('Google Drive')),
                if (selected)
                  TextButton.icon(
                      onPressed: loading || !canEditDocuments
                          ? null
                          : () => setState(() => controller.clear()),
                      icon: const Icon(Icons.clear),
                      label: const Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget documentPreview(String value) {
    if (value.startsWith('google-drive:')) {
      return DetailSectionCard(
          title: 'Google Drive file',
          icon: Icons.add_to_drive,
          rows: {'Link': value.replaceFirst('google-drive:', '')});
    }
    if (value.startsWith('local-path:')) {
      final path = value.replaceFirst('local-path:', '');
      return DetailSectionCard(
          title: 'Local file',
          icon: Icons.insert_drive_file,
          rows: {'File name': path.split('/').last, 'Type': fileType(path)});
    }
    if (value.startsWith('local-file:')) {
      final metaAndData = value.replaceFirst('local-file:', '');
      final split = metaAndData.split(';base64,');
      final fileName = split.first;
      final type = fileType(fileName);
      if (split.length == 2 && ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(type)) {
        try {
          final bytes = base64Decode(split.last);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              DetailSectionCard(
                  title: 'Image preview',
                  icon: Icons.image,
                  rows: {'File name': fileName, 'Type': type}),
            ],
          );
        } catch (_) {
          // Fall through to metadata preview.
        }
      }
      return DetailSectionCard(
          title: 'Selected file',
          icon: Icons.insert_drive_file,
          rows: {'File name': fileName, 'Type': type});
    }
    return const DetailSectionCard(
        title: 'Selected file',
        icon: Icons.insert_drive_file,
        rows: {'Preview': 'File ready for submission'});
  }

  String fileType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'UNKNOWN';
    return fileName.substring(dot + 1).toUpperCase();
  }

  bool get canEditDocuments {
    final status = profile?['verificationStatus']?.toString() ?? 'INCOMPLETE';
    return status == 'INCOMPLETE' ||
        status == 'REJECTED' ||
        status == 'RESUBMISSION_REQUIRED';
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Submit driver documents',
        children: [
          if (loading) const LinearProgressIndicator(),
          if (message != null) InfoStrip(text: message!),
          if (profile != null) ...[
            StatusBadge(
                label:
                    profile!['verificationStatus']?.toString() ?? 'INCOMPLETE',
                active: profile!['verificationStatus'] == 'APPROVED'),
            if (!canEditDocuments) ...[
              const SizedBox(height: 8),
              const InfoStrip(
                  text:
                      'Document upload is locked while verification is pending or approved. Admin must request re-submission to unlock it.'),
            ],
            if (profile!['verificationStatus'] == 'REJECTED') ...[
              const SizedBox(height: 8),
              ErrorBanner(
                  message:
                      'Rejected: ${profile!['verificationRejectionReason'] ?? 'Please re-submit documents.'}'),
            ],
            const SizedBox(height: 12),
            DetailSectionCard(
                title: 'Missing Documents',
                icon: Icons.assignment_late,
                rows: {
                  'Profile photo/selfie':
                      profile!['profilePhotoSubmitted'] == true
                          ? 'Submitted'
                          : 'Required',
                  'Aadhaar document':
                      profile!['aadhaarDocumentSubmitted'] == true
                          ? 'Submitted'
                          : 'Required',
                  'Driving license':
                      profile!['licenseDocumentSubmitted'] == true
                          ? 'Submitted'
                          : 'Required',
                  'Vehicle document':
                      profile!['vehicleDocumentSubmitted'] == true
                          ? 'Submitted'
                          : 'Required',
                  'Insurance document':
                      profile!['insuranceDocumentSubmitted'] == true
                          ? 'Submitted'
                          : 'Required',
                }),
          ],
          documentUploadCard(
              label: 'Profile photo/selfie',
              icon: Icons.account_circle,
              controller: profilePhoto,
              alreadySubmitted: profile?['profilePhotoSubmitted'] == true),
          documentUploadCard(
              label: 'Aadhaar document photo',
              icon: Icons.badge,
              controller: aadhaar,
              alreadySubmitted: profile?['aadhaarDocumentSubmitted'] == true),
          documentUploadCard(
              label: 'Driving license photo',
              icon: Icons.credit_card,
              controller: license,
              alreadySubmitted: profile?['licenseDocumentSubmitted'] == true),
          documentUploadCard(
              label: 'Vehicle document/photo',
              icon: Icons.two_wheeler,
              controller: vehicle,
              alreadySubmitted: profile?['vehicleDocumentSubmitted'] == true),
          documentUploadCard(
              label: 'Insurance document photo',
              icon: Icons.policy,
              controller: insurance,
              alreadySubmitted: profile?['insuranceDocumentSubmitted'] == true),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit for admin verification')),
        ],
      );
}

class FullScreenImageCropPreview extends StatefulWidget {
  const FullScreenImageCropPreview(
      {super.key, required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  @override
  State<FullScreenImageCropPreview> createState() =>
      _FullScreenImageCropPreviewState();
}

class _FullScreenImageCropPreviewState
    extends State<FullScreenImageCropPreview> {
  double cropSize = 0.9;
  bool processing = false;

  Future<void> confirm() async {
    setState(() => processing = true);
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final side =
          (image.width < image.height ? image.width : image.height) * cropSize;
      final source = Rect.fromCenter(
          center: Offset(image.width / 2, image.height / 2),
          width: side,
          height: side);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const output = 900.0;
      canvas.drawImageRect(
          image, source, const Rect.fromLTWH(0, 0, output, output), Paint());
      final cropped =
          await recorder.endRecording().toImage(output.toInt(), output.toInt());
      final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || byteData == null) return;
      Navigator.of(context).pop(byteData.buffer.asUint8List());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          actions: [
            TextButton(
                onPressed: processing ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(widget.bytes, fit: BoxFit.contain),
                        IgnorePointer(
                          child: FractionallySizedBox(
                            widthFactor: cropSize,
                            heightFactor: cropSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Crop size',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                      value: cropSize,
                      min: 0.45,
                      max: 1,
                      onChanged: processing
                          ? null
                          : (value) => setState(() => cropSize = value)),
                  FilledButton.icon(
                      onPressed: processing ? null : confirm,
                      icon: const Icon(Icons.crop),
                      label: Text(processing
                          ? 'Processing...'
                          : 'Confirm cropped image')),
                ],
              ),
            ),
          ],
        ),
      );
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

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final profile = Map<String, dynamic>.from(await DriverApi().profile());
      online = profile['online'] == true && profile['available'] == true;
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> update(bool value) async {
    setState(() {
      online = value;
      loading = true;
      message = null;
    });
    try {
      final profile = Map<String, dynamic>.from(
          await DriverApi().setAvailability(value, value));
      online = profile['online'] == true && profile['available'] == true;
      message = value ? 'You are online.' : 'You are offline.';
    } catch (e) {
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Driver availability',
        children: [
          ActiveStatusCard(
              title: 'Driver active status',
              active: online,
              loading: loading,
              onChanged: update),
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
  List<dynamic> requests = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      requests = List<dynamic>.from(await RideApi().requests());
    } catch (e) {
      message = friendlyError(e);
      requests = [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

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
      message = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: 'Ride request',
        children: [
          OutlinedButton.icon(
              onPressed: loading ? null : loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh requests')),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            const InfoStrip(text: 'No active ride requests available.'),
          ...requests.whereType<Map>().map((item) {
            final request = Map<String, dynamic>.from(item);
            final id = request['id']?.toString() ?? '';
            return Card(
              child: ListTile(
                title:
                    Text('Ride ID: ${id.length > 8 ? id.substring(0, 8) : id}'),
                subtitle: Text(
                    '${request['pickupAddress'] ?? '-'} to ${request['dropAddress'] ?? '-'}'),
                trailing: FilledButton(
                    onPressed: loading
                        ? null
                        : () {
                            rideId.text = id;
                            accept();
                          },
                    child: const Text('Accept')),
              ),
            );
          }),
          const SizedBox(height: 12),
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
  Widget build(BuildContext context) => const ProfileDetailsScreen(
      title: 'Driver profile', path: '/api/drivers/profile', isDriver: true);
}

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen(
      {super.key,
      required this.title,
      required this.path,
      required this.isDriver});

  final String title;
  final String path;
  final bool isDriver;

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  bool loading = false;
  String? error;
  Map<String, dynamic>? profile;

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
      profile = Map<String, dynamic>.from(await api.get(widget.path));
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateDriverAvailability(bool value) async {
    setState(() => loading = true);
    try {
      profile = Map<String, dynamic>.from(
          await DriverApi().setAvailability(value, value));
    } catch (e) {
      error = friendlyError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupScaffold(
        title: widget.title,
        children: [
          OutlinedButton.icon(
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh')),
          const SizedBox(height: 12),
          AsyncPanel(
            loading: loading,
            error: error,
            empty: profile == null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile != null && widget.isDriver) ...[
                  ActiveStatusCard(
                      title: 'Driver active status',
                      active: profile!['online'] == true &&
                          profile!['available'] == true,
                      loading: loading ||
                          profile!['verificationStatus'] != 'APPROVED',
                      onChanged: profile!['verificationStatus'] == 'APPROVED'
                          ? updateDriverAvailability
                          : null),
                  if (profile!['verificationStatus'] != 'APPROVED') ...[
                    const SizedBox(height: 8),
                    const InfoStrip(
                        text:
                            'Your documents must be approved by Admin before going active.'),
                  ],
                  const SizedBox(height: 12),
                ],
                if (profile != null)
                  ...profileSections(profile!, isDriver: widget.isDriver),
              ],
            ),
          ),
        ],
      );
}

List<Widget> profileSections(Map<String, dynamic> data,
    {required bool isDriver}) {
  if (isDriver) {
    return [
      DetailSectionCard(title: 'Personal Details', icon: Icons.person, rows: {
        'Driver ID': data['id'],
        'Full name': data['fullName'],
        'Mobile': data['mobileNumber'],
        'Gender': data['gender'],
        'Date of birth': data['dateOfBirth'],
        'Age': data['age'],
        'Address': data['address'],
      }),
      DetailSectionCard(title: 'Document Details', icon: Icons.badge, rows: {
        'Aadhaar last 4': data['aadhaarLast4'],
        'Selfie key': data['selfieStorageKey'],
      }),
      DetailSectionCard(
          title: 'Vehicle Details',
          icon: Icons.two_wheeler,
          rows: {
            'Vehicle type': data['vehicleType'],
            'Registration': data['vehicleRegistrationNumber'],
            'Insurance': data['insuranceDetails'],
          }),
      DetailSectionCard(
          title: 'Verification Status',
          icon: Icons.verified_user,
          rows: {
            'KYC': data['kycStatus'],
            'Admin approval': data['adminApprovalStatus'],
            'Verification': data['verificationStatus'],
            'Rejection reason': data['verificationRejectionReason'],
            'Documents complete':
                data['documentsComplete'] == true ? 'Yes' : 'No',
            'Available': data['available'] == true ? 'ACTIVE' : 'INACTIVE',
            'Online': data['online'] == true ? 'ACTIVE' : 'INACTIVE',
          }),
      DetailSectionCard(
          title: 'Uploaded Documents / Images',
          icon: Icons.image,
          rows: {
            'Profile photo': data['profilePhotoStorageKey'],
            'Profile photo submitted':
                data['profilePhotoSubmitted'] == true ? 'Yes' : 'No',
            'Aadhaar': data['aadhaarStorageKey'],
            'Aadhaar submitted':
                data['aadhaarDocumentSubmitted'] == true ? 'Yes' : 'No',
            'License': data['licenseStorageKey'],
            'License submitted':
                data['licenseDocumentSubmitted'] == true ? 'Yes' : 'No',
            'Vehicle document': data['vehicleDocumentStorageKey'],
            'Vehicle submitted':
                data['vehicleDocumentSubmitted'] == true ? 'Yes' : 'No',
            'Insurance': data['insuranceDocumentStorageKey'],
            'Insurance submitted':
                data['insuranceDocumentSubmitted'] == true ? 'Yes' : 'No',
          }),
    ];
  }
  return [
    DetailSectionCard(title: 'Personal Details', icon: Icons.person, rows: {
      'Rider ID': data['id'],
      'Full name': data['fullName'],
      'Mobile': data['mobileNumber'],
      'Gender': data['gender'],
      'Date of birth': data['dateOfBirth'],
      'Age': data['age'],
      'Age category': data['ageCategory'],
      'Address': data['address'],
      'Emergency contact': data['emergencyContact'],
    }),
    DetailSectionCard(title: 'Document Details', icon: Icons.badge, rows: {
      'Verification type': data['verificationType'],
      'Rider Aadhaar last 4': data['riderAadhaarLast4'],
      'Guardian Aadhaar last 4': data['guardianAadhaarLast4'],
    }),
    DetailSectionCard(
        title: 'Guardian Details',
        icon: Icons.family_restroom,
        rows: {
          'Guardian relationship': data['guardianRelationship'],
          'Guardian name': data['guardianName'],
          'Guardian mobile': data['guardianMobileNumber'],
          'Guardian consent': data['guardianConsent'] == true ? 'Yes' : 'No',
        }),
    DetailSectionCard(
        title: 'Uploaded Documents / Images',
        icon: Icons.image,
        rows: {
          'Profile photo': data['profilePhotoStorageKey'],
          'Rider Aadhaar': data['riderAadhaarLast4'] == null
              ? null
              : 'Verified last 4: ${data['riderAadhaarLast4']}',
          'Guardian Aadhaar': data['guardianAadhaarLast4'] == null
              ? null
              : 'Verified last 4: ${data['guardianAadhaarLast4']}',
        }),
    DetailSectionCard(
        title: 'Verification Status',
        icon: Icons.verified_user,
        rows: {
          'KYC': data['kycStatus'],
          'Account': data['accountStatus'],
          'Active': data['active'] != false ? 'ACTIVE' : 'INACTIVE',
        }),
  ];
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
        body: SheGoBackground(
          child: ListView(
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

  Future<void> requestDriverResubmission(String driverId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller =
            TextEditingController(text: 'Please upload clearer documents');
        return AlertDialog(
          title: const Text('Request re-submission'),
          content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Reason')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Request')),
          ],
        );
      },
    );
    if (reason == null) return;
    await adminAction(() => api.post(
          '/api/admin/request-driver-resubmission?driverId=$driverId&reason=${Uri.encodeComponent(reason)}',
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
            const NotificationBell(),
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
            Text('Verification: ${driver['verificationStatus'] ?? '-'}'),
            if (driver['verificationRejectionReason'] != null)
              Text(
                  'Rejection reason: ${driver['verificationRejectionReason']}'),
            Text(
                'Admin approved: ${driver['adminApproved'] == true ? 'Yes' : 'No'}'),
            Text(
                'Available/Online: ${driver['available'] == true ? 'Yes' : 'No'} / ${driver['online'] == true ? 'Yes' : 'No'}'),
            const SizedBox(height: 8),
            DetailSectionCard(
                title: 'Submitted Documents',
                icon: Icons.folder_copy,
                rows: {
                  'Profile photo/selfie': driver['profilePhotoStorageKey'] ??
                      previewLabel(driver['profilePhotoData']),
                  'Aadhaar': driver['aadhaarStorageKey'] ??
                      previewLabel(driver['aadhaarDocumentData']),
                  'License': driver['licenseStorageKey'] ??
                      previewLabel(driver['licenseDocumentData']),
                  'Vehicle': driver['vehicleDocumentStorageKey'] ??
                      previewLabel(driver['vehicleDocumentData']),
                  'Insurance': driver['insuranceDocumentStorageKey'] ??
                      previewLabel(driver['insuranceDocumentData']),
                }),
            documentPreviewForAdmin(
                'Profile photo/selfie', driver['profilePhotoData']?.toString()),
            documentPreviewForAdmin(
                'Aadhaar document', driver['aadhaarDocumentData']?.toString()),
            documentPreviewForAdmin(
                'Driving license', driver['licenseDocumentData']?.toString()),
            documentPreviewForAdmin(
                'Vehicle document', driver['vehicleDocumentData']?.toString()),
            documentPreviewForAdmin('Insurance document',
                driver['insuranceDocumentData']?.toString()),
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
                OutlinedButton.icon(
                  onPressed: loading || driverId == null
                      ? null
                      : () => requestDriverResubmission(driverId),
                  icon: const Icon(Icons.replay),
                  label: const Text('Request re-submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String previewLabel(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return '-';
    }
    if (text.startsWith('google-drive:')) {
      return text.replaceFirst('google-drive:', '');
    }
    if (text.startsWith('local-file:')) {
      return text.replaceFirst('local-file:', '').split(';base64,').first;
    }
    if (text.startsWith('local-path:')) {
      return text.replaceFirst('local-path:', '').split('/').last;
    }
    return 'Submitted as DB/local data';
  }

  Widget documentPreviewForAdmin(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (value.startsWith('local-file:')) {
      final split = value.replaceFirst('local-file:', '').split(';base64,');
      final fileName = split.first;
      final type = fileName.contains('.')
          ? fileName.split('.').last.toUpperCase()
          : 'FILE';
      if (split.length == 2 && ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(type)) {
        try {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(base64Decode(split.last),
                    height: 140, fit: BoxFit.cover)),
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }
    }
    return const SizedBox.shrink();
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
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: ListView(
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
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red))),
          ],
        ),
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
