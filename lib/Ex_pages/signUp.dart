import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking_system/Ex_pages/customerlogin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SignUpPage()),
  );
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Check if NIC already exists
        final nicExists = await FirebaseFirestore.instance
            .collection('customer')
            .where('nic', isEqualTo: _nicController.text.trim())
            .get();

        if (nicExists.docs.isNotEmpty) {
          throw Exception('NIC already registered');
        }

        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = userCredential.user?.uid;
        if (uid == null) {
          throw Exception('User UID is null');
        }

        await FirebaseFirestore.instance.collection('customer').doc(uid).set({
          'email': _emailController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'nic': _nicController.text.trim(),
          'phone': _phoneController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful! Redirecting...')),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      } on FirebaseAuthException catch (e) {
        String errorMsg;
        if (e.code == 'email-already-in-use') {
          errorMsg = 'Email already in use. Please try logging in.';
        } else if (e.code == 'invalid-email') {
          errorMsg = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          errorMsg = 'Password is too weak';
        } else {
          errorMsg = e.message ?? 'Signup failed';
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        const Text(
                          "Welcome",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "AppoiMate",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Let's create an account",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 30),

                        _buildTextField(
                          _emailController,
                          "Email",
                          TextInputType.emailAddress,
                          (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _fullNameController,
                          "Full Name",
                          TextInputType.text,
                          (value) => value == null || value.trim().isEmpty
                              ? 'Please enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _nicController,
                          "NIC",
                          TextInputType.text,
                          (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your NIC number';
                            } else if (!RegExp(r'^\d{12}$|^\d{9}[vV]$')
                                .hasMatch(value)) {
                              return 'NIC must be 12 digits or 9 digits + V';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _phoneController,
                          "Phone Number",
                          TextInputType.phone,
                          (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            } else if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                              return 'Phone must start with 0 and be 10 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          _passwordController,
                          "Password",
                          TextInputType.visiblePassword,
                          (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a password';
                            } else if (value.length < 6) {
                              return 'At least 6 characters';
                            } else if (!RegExp(
                                    r'^(?=.*[!@#\$%^&*()_+{}\[\]:;<>,.?~\\/-]).+$')
                                .hasMatch(value)) {
                              return 'Include a special character';
                            }
                            return null;
                          },
                          obscureText: _obscurePassword,
                          toggleVisibility: () {
                            setState(() =>
                                _obscurePassword = !_obscurePassword);
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          _confirmPasswordController,
                          "Confirm Password",
                          TextInputType.visiblePassword,
                          (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          obscureText: _obscureConfirmPassword,
                          toggleVisibility: () {
                            setState(() => _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                          },
                        ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            "Already have an account? Log In",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    TextInputType inputType,
    String? Function(String?)? validator, {
    bool obscureText = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
    );
  }
}
