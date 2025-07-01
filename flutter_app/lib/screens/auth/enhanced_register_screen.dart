import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/face_validation_service.dart';

class EnhancedRegisterScreen extends StatefulWidget {
  const EnhancedRegisterScreen({Key? key}) : super(key: key);

  @override
  _EnhancedRegisterScreenState createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends State<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _facePhotoFile;
  final ImagePicker _picker = ImagePicker();
  String _errorMessage = '';
  bool _isUploading = false;
  bool _usernameChecked = false;
  bool _usernameAvailable = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameChecked = false;
        _usernameAvailable = false;
      });
      return;
    }

    final authService = context.read<AuthService>();
    final available = await authService.isUsernameAvailable(username);
    
    setState(() {
      _usernameChecked = true;
      _usernameAvailable = available;
    });
  }

  Future<void> _pickFacePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _validateAndSetFacePhoto(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photo: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _validateAndSetFacePhoto(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select photo: $e';
      });
    }
  }

  Future<void> _validateAndSetFacePhoto(File imageFile) async {
    setState(() {
      _errorMessage = '';
    });

    // Validate the face photo
    final validationResult = await FaceValidationService.validateFacePhoto(imageFile);
    
    if (validationResult.isValid) {
      setState(() {
        _facePhotoFile = imageFile;
      });
      
      // Show success message with recommendations if any
      if (validationResult.recommendations != null && validationResult.recommendations!.isNotEmpty) {
        _showPhotoTips(validationResult.recommendations!);
      }
    } else {
      setState(() {
        _errorMessage = validationResult.errorMessage ?? 'Photo validation failed';
      });
    }
  }

  void _showPhotoTips(List<String> recommendations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Photo Tips'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For the best verification results:'),
              SizedBox(height: 8),
              ...recommendations.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(tip),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                subtitle: Text('Use camera for best results'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFacePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _validateFacePhoto() {
    if (_facePhotoFile == null) {
      setState(() {
        _errorMessage = 'Please provide a clear photo of your face for account verification.';
      });
      return false;
    }
    return true;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_usernameAvailable) {
      setState(() {
        _errorMessage = 'Username is not available. Please choose another one.';
      });
      return;
    }
    if (!_validateFacePhoto()) return;

    final navigator = Navigator.of(context);
    final authService = context.read<AuthService>();

    try {
      setState(() {
        _errorMessage = '';
        _isUploading = true;
      });
      
      // First create the user account
      final userCredential = await authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
        '', // Temporary empty URL, will be updated after upload
      );

      if (userCredential?.user != null) {
        // Upload face photo
        final facePhotoUrl = await authService.uploadFacePhoto(
          _facePhotoFile!,
          userCredential!.user!.uid,
        );

        // Update user profile with the photo URL
        await authService.updateUserProfile({
          'face_photo_url': facePhotoUrl,
          'has_verified_face': true,
        });

        // Success - navigate back
        navigator.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title and Description
                Text(
                  'Join Bacon13',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Create your account with a clear photo of your face for verification',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),

                // Face Photo Section
                Container(
                  height: 150,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _facePhotoFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _facePhotoFile!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  onPressed: _showPhotoOptions,
                                ),
                              ),
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: _showPhotoOptions,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add Face Photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Required for account verification',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    suffixIcon: _usernameChecked
                        ? Icon(
                            _usernameAvailable ? Icons.check_circle : Icons.error,
                            color: _usernameAvailable ? Colors.green : Colors.red,
                          )
                        : null,
                    helperText: 'Minimum 3 characters, will be public',
                  ),
                  onChanged: (value) {
                    // Debounce username checking
                    Future.delayed(Duration(milliseconds: 500), () {
                      if (_usernameController.text == value) {
                        _checkUsername();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w\-\.+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Minimum 6 characters',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Register Button
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return ElevatedButton(
                      onPressed: (authService.isLoading || _isUploading) ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: (authService.isLoading || _isUploading)
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Requirements Info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Requirements:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('• Unique username (3+ characters)', style: TextStyle(color: Colors.blue[700])),
                      Text('• Valid email address', style: TextStyle(color: Colors.blue[700])),
                      Text('• Strong password (6+ characters)', style: TextStyle(color: Colors.blue[700])),
                      Text('• Clear photo of your face', style: TextStyle(color: Colors.blue[700])),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Back to Login Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}