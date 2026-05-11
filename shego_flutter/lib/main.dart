import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
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
    _navigationTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
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
  SheGoApi({this.baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080')});

  final String baseUrl;
  String? token;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _decode(response);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final payload = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode >= 400 || payload['success'] == false) {
      throw Exception(payload['message'] ?? 'Request failed');
    }
    return payload['data'];
  }
}

final api = SheGoApi();

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
            ClipOval(child: Image.asset(shegoLogoAsset, width: 34, height: 34, fit: BoxFit.cover)),
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
          NavigationDestination(icon: Icon(Icons.health_and_safety), label: 'Safety'),
          NavigationDestination(icon: Icon(Icons.work_history), label: 'Commute'),
          NavigationDestination(icon: Icon(Icons.child_care), label: 'Child'),
          NavigationDestination(icon: Icon(Icons.card_membership), label: 'Pass'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Delivery'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class AsyncPanel extends StatelessWidget {
  const AsyncPanel({super.key, required this.loading, required this.error, required this.empty, required this.child});

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
            ClipOval(child: Image.asset(shegoLogoAsset, width: 96, height: 96, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }
    if (error != null) return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    if (empty) return const Center(child: Text('No records yet'));
    return child;
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignupSelectionScreen();
  }
}

class SignupSelectionScreen extends StatelessWidget {
  const SignupSelectionScreen({super.key});

  void open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              ClipOval(child: Image.asset(shegoLogoAsset, width: 132, height: 132, fit: BoxFit.cover)),
              const SizedBox(height: 12),
              Text('SheGo', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Ride Freely. Ride Safely.', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Choose how you want to continue', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => open(context, const RiderSignupScreen()),
          icon: const Icon(Icons.person_add),
          label: const Text('Continue as Rider'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => open(context, const DriverSignupScreen()),
          icon: const Icon(Icons.two_wheeler),
          label: const Text('Continue as Driver'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => open(context, const RiderLoginScreen()),
          icon: const Icon(Icons.login),
          label: const Text('Rider login'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => open(context, const DriverLoginScreen()),
          icon: const Icon(Icons.verified_user),
          label: const Text('Driver login'),
        ),
        const SizedBox(height: 12),
        const Text('Riders: women/girls of any age and boys below 14. Drivers: verified adult women only.'),
      ],
    );
  }
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
    return (gender == 'FEMALE' && currentAge < 18) || (gender == 'MALE' && currentAge < 14);
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
    if (fullName.text.trim().isEmpty || mobile.text.trim().isEmpty || password.text.isEmpty) {
      return 'Full name, mobile number, and password are required.';
    }
    if (currentAge == null) return 'Enter date of birth in YYYY-MM-DD format.';
    if (gender == 'MALE' && currentAge >= 14) return 'Male riders age 14 or above are not allowed.';
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
      api.token = data['accessToken'];
      setState(() => message = 'Rider signup complete. Verification type: ${verificationType()}.');
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
          TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['FEMALE', 'MALE', 'OTHER'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => gender = value ?? gender),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dob,
            decoration: InputDecoration(labelText: 'Date of birth', hintText: 'YYYY-MM-DD', helperText: age == null ? null : 'Age: $age'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Address (optional)')),
          const SizedBox(height: 12),
          TextField(controller: emergencyContact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Emergency contact')),
          const SizedBox(height: 12),
          if (selfAadhaarRequired) ...[
            TextField(controller: riderAadhaar, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rider Aadhaar number')),
            const SizedBox(height: 12),
          ],
          if (guardianRequired) ...[
            const Text('Parent/guardian verification is required for this rider.'),
            const SizedBox(height: 12),
            TextField(controller: guardianName, decoration: const InputDecoration(labelText: 'Guardian name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: guardianRelationship,
              decoration: const InputDecoration(labelText: 'Guardian relationship'),
              items: const ['Mother', 'Father', 'Guardian'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => setState(() => guardianRelationship = value ?? guardianRelationship),
            ),
            const SizedBox(height: 12),
            TextField(controller: guardianMobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Guardian mobile number')),
            const SizedBox(height: 12),
            TextField(controller: guardianAadhaar, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Guardian Aadhaar number')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardianConsent,
              onChanged: (value) => setState(() => guardianConsent = value ?? false),
              title: const Text('Guardian consent received'),
            ),
          ],
          InfoStrip(text: 'Verification type: ${verificationType()}'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: loading ? null : submit, icon: const Icon(Icons.person_add), label: const Text('Create rider account')),
          if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
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
    if (fullName.text.trim().isEmpty || mobile.text.trim().isEmpty || password.text.isEmpty) return 'Full name, mobile number, and password are required.';
    if (gender != 'FEMALE') return 'Only female drivers are allowed.';
    if (currentAge == null) return 'Enter date of birth in YYYY-MM-DD format.';
    if (currentAge < 18) return 'Driver must be a legally adult woman.';
    if (address.text.trim().isEmpty || aadhaarNumber.text.trim().isEmpty || license.text.trim().isEmpty || registration.text.trim().isEmpty || insurance.text.trim().isEmpty) {
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
      api.token = data['accessToken'];
      setState(() => message = 'Driver signup submitted. KYC and admin approval are required before going online.');
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
          TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['FEMALE', 'MALE', 'OTHER'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => gender = value ?? gender),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dob,
            decoration: InputDecoration(labelText: 'Date of birth', hintText: 'YYYY-MM-DD', helperText: age == null ? null : 'Age: $age'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(controller: aadhaarNumber, decoration: const InputDecoration(labelText: 'Aadhaar number')),
          const SizedBox(height: 12),
          TextField(controller: license, decoration: const InputDecoration(labelText: 'Driving license number')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: const ['SCOOTY', 'BIKE'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => vehicleType = value ?? vehicleType),
          ),
          const SizedBox(height: 12),
          TextField(controller: registration, decoration: const InputDecoration(labelText: 'Vehicle registration number')),
          const SizedBox(height: 12),
          TextField(controller: insurance, decoration: const InputDecoration(labelText: 'Insurance details')),
          const SizedBox(height: 12),
          TextField(controller: profilePhotoKey, decoration: const InputDecoration(labelText: 'Profile photo storage key (optional)')),
          const SizedBox(height: 12),
          TextField(controller: aadhaarKey, decoration: const InputDecoration(labelText: 'Aadhaar document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(controller: licenseKey, decoration: const InputDecoration(labelText: 'License document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(controller: vehicleDocumentKey, decoration: const InputDecoration(labelText: 'Vehicle document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(controller: insuranceDocumentKey, decoration: const InputDecoration(labelText: 'Insurance document storage key (optional)')),
          const SizedBox(height: 12),
          TextField(controller: selfieKey, decoration: const InputDecoration(labelText: 'Selfie verification storage key (optional)')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: loading ? null : submit, icon: const Icon(Icons.verified), label: const Text('Create driver account')),
          if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class RiderLoginScreen extends StatelessWidget {
  const RiderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginForm(title: 'Rider login', path: '/api/riders/login');
}

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const LoginForm(title: 'Driver login', path: '/api/drivers/login');
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.title, required this.path});

  final String title;
  final String path;

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
      final data = await api.post(widget.path, {'mobileNumber': mobile.text.trim(), 'password': password.text});
      api.token = data['accessToken'];
      setState(() => message = 'Login successful. Authenticated tabs can now call backend APIs.');
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
          TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: loading ? null : login, icon: const Icon(Icons.login), label: const Text('Login')),
          if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        ],
      );
}

class SignupScaffold extends StatelessWidget {
  const SignupScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: ClipOval(child: Image.asset(shegoLogoAsset, width: 110, height: 110, fit: BoxFit.cover))),
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Text(text),
      );
}

int? calculateAge(String value) {
  final dob = DateTime.tryParse(value);
  if (dob == null) return null;
  final now = DateTime.now();
  var years = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years--;
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
      if (result is Map && result['id'] != null) rideId.text = result['id'].toString();
      if (result is Map && result['rideId'] != null) rideId.text = result['rideId'].toString();
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
  Future<void> start() => run(() => api.post('/api/rides/$id/start', {'otp': otp.text.trim()}));
  Future<void> load() => run(() => api.get('/api/rides/$id'));

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ride booking and OTP flow', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vehicleType,
            decoration: const InputDecoration(labelText: 'Ride vehicle type'),
            items: const ['SCOOTY', 'BIKE'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setState(() => vehicleType = value ?? vehicleType),
          ),
          const SizedBox(height: 12),
          TextField(controller: rideId, decoration: const InputDecoration(labelText: 'Ride ID')),
          const SizedBox(height: 12),
          TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ride start OTP')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: loading ? null : book, icon: const Icon(Icons.add_location_alt), label: const Text('Book')),
              OutlinedButton.icon(onPressed: loading || id.isEmpty ? null : accept, icon: const Icon(Icons.check), label: const Text('Accept')),
              OutlinedButton.icon(onPressed: loading || id.isEmpty ? null : arrive, icon: const Icon(Icons.pin_drop), label: const Text('Arrived')),
              FilledButton.tonalIcon(onPressed: loading || id.isEmpty ? null : start, icon: const Icon(Icons.password), label: const Text('Start with OTP')),
              OutlinedButton.icon(onPressed: loading || id.isEmpty ? null : load, icon: const Icon(Icons.refresh), label: const Text('Load details')),
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
      policy = Map<String, dynamic>.from(await api.get('/api/safety/late-night-policy'));
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> triggerSos() async {
    try {
      await api.post('/api/sos/trigger', {'latitude': 28.6139, 'longitude': 77.2090, 'message': 'Emergency help requested'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS sent to support dashboard')));
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(onPressed: loadPolicy, icon: const Icon(Icons.nightlight), label: const Text('Load late-night policy')),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(onPressed: triggerSos, icon: const Icon(Icons.sos), label: const Text('Trigger SOS')),
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
      description: 'Book school pickup/drop with verified female drivers, pickup OTP, drop OTP, and guardian tracking.',
      path: '/api/child-rides/book',
      body: {'childName': 'Demo Child', 'scheduledAt': DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String()},
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
      description: 'Future-safe parcel, pharmacy, cosmetics, and women-only delivery request flow.',
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
  dynamic result;

  Future<void> loadDashboard() async {
    setState(() => loading = true);
    try {
      result = await api.get('/api/admin/dashboard');
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loadPath(String path) async {
    setState(() => loading = true);
    try {
      result = await api.get(path);
      error = null;
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: loadDashboard, icon: const Icon(Icons.dashboard), label: const Text('Dashboard')),
              OutlinedButton.icon(
                onPressed: () => loadPath('/api/admin/minor-riders'),
                icon: const Icon(Icons.family_restroom),
                label: const Text('Minor riders'),
              ),
              OutlinedButton.icon(
                onPressed: () => loadPath('/api/admin/pending-guardian-verifications'),
                icon: const Icon(Icons.verified_user),
                label: const Text('Guardian approvals'),
              ),
              OutlinedButton.icon(
                onPressed: () => loadPath('/api/admin/pending-driver-kyc'),
                icon: const Icon(Icons.two_wheeler),
                label: const Text('Driver KYC'),
              ),
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

class SimpleActionScreen extends StatefulWidget {
  const SimpleActionScreen({super.key, required this.title, required this.description, required this.path, required this.body});

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
          FilledButton.icon(onPressed: loading ? null : create, icon: const Icon(Icons.add), label: const Text('Create demo request')),
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
              if (onCreate != null) FilledButton.icon(onPressed: loading ? null : onCreate, icon: const Icon(Icons.add), label: const Text('Create')),
              OutlinedButton.icon(onPressed: loading ? null : onRefresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
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
                          title: Text(row['commuteType']?.toString() ?? row['name']?.toString() ?? 'SheGo item'),
                          subtitle: Text(row.toString()),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}
