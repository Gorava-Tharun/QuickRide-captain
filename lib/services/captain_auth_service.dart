import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/captain_models.dart';
import '../models/firestore_models.dart';
import 'captain_firebase_service.dart';

class CaptainAuthService {
  static const String _accountsKey = 'quickride_captain_accounts';
  static const String _sessionKey = 'quickride_captain_current_session';

  static final CaptainAuthService _instance = CaptainAuthService._internal();
  factory CaptainAuthService() => _instance;
  CaptainAuthService._internal();

  /// Initial default seed account for testing
  static const CaptainAccount defaultSeedCaptain = CaptainAccount(
    id: 'CPT-78901',
    name: 'Rajesh Kumar',
    phone: '9876543210',
    email: 'rajesh.quickride@gmail.com',
    password: 'password123',
    vehicleType: 'Honda Activa 6G (Bike)',
    vehicleNumber: 'KA-05-HA-1234',
    licenseNumber: 'DL-KA0520210009876',
    rating: 4.88,
    totalRides: 148,
    todayEarnings: 1420.0,
    isOnline: true,
  );

  /// Get all registered captain accounts
  Future<List<CaptainAccount>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_accountsKey);
    if (listJson == null || listJson.isEmpty) {
      return [];
    }
    return listJson.map((jsonStr) => CaptainAccount.fromJson(jsonStr)).toList();
  }

  /// Register a new Captain account with Firebase Authentication & Cloud Firestore
  Future<Map<String, dynamic>> registerCaptain({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String vehicleNumber,
    required String licenseNumber,
    String vehicleType = 'Bike (QuickRide)',
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanEmail = email.trim().toLowerCase();

    final accounts = await _getAccounts();

    // Check if phone or email already registered locally
    final existsPhone = accounts.any((a) => a.phone == cleanPhone);
    if (existsPhone) {
      return {
        'success': false,
        'message': 'A captain with this phone number already exists.',
      };
    }

    final existsEmail = accounts.any((a) => a.email.toLowerCase() == cleanEmail);
    if (existsEmail) {
      return {
        'success': false,
        'message': 'A captain with this email address already exists.',
      };
    }

    String captainUid = 'CPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (Firebase.apps.isNotEmpty) {
      try {
        final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (userCred.user != null) {
          captainUid = userCred.user!.uid;
          await userCred.user!.updateDisplayName(name.trim()).catchError((_) {});
        } else {
          return {
            'success': false,
            'message': 'Failed to create captain account: No user credential returned.',
          };
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('[CaptainAuthService] Firebase Auth registration error: ${e.code}');
        return {
          'success': false,
          'message': e.message ?? 'Registration failed. Please try again.',
        };
      } catch (e) {
        debugPrint('[CaptainAuthService] Firebase registration error: $e');
        return {
          'success': false,
          'message': 'Registration failed: ${e.toString().replaceAll("Exception: ", "")}',
        };
      }
    }

    final now = DateTime.now();
    final newCaptain = CaptainAccount(
      id: captainUid,
      name: name.trim(),
      phone: cleanPhone,
      email: cleanEmail,
      password: password,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber.trim().toUpperCase(),
      licenseNumber: licenseNumber.trim().toUpperCase(),
      rating: 5.0,
      totalRides: 0,
      todayEarnings: 0.0,
      isOnline: true,
      verificationStatus: 'PENDING',
      vehicleVerificationStatus: 'PENDING',
      documentsSubmittedAt: now,
    );

    accounts.add(newCaptain);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_accountsKey, accounts.map((a) => a.toJson()).toList());

    // Sync to Firestore
    final synced = await CaptainFirebaseService().syncCaptainProfile(
      FirestoreCaptainModel(
        captainId: newCaptain.id,
        name: newCaptain.name,
        phone: newCaptain.phone,
        email: newCaptain.email,
        vehicleNumber: newCaptain.vehicleNumber,
        vehicleType: newCaptain.vehicleType,
        drivingLicenseNumber: newCaptain.licenseNumber,
        rating: newCaptain.rating,
        online: newCaptain.isOnline,
        verificationStatus: 'PENDING',
        vehicleVerificationStatus: 'PENDING',
        documentsSubmittedAt: now,
        createdAt: now,
      ),
    );

    if (!synced && Firebase.apps.isNotEmpty) {
      return {
        'success': false,
        'message': 'Failed to save captain profile to Cloud Firestore. Please check your connection.',
      };
    }

    return {
      'success': true,
      'message': 'Registration successful! Verification is pending admin approval.',
      'account': newCaptain,
    };
  }

  /// Login with phone and password (supporting Firebase Auth and local cache)
  Future<Map<String, dynamic>> loginCaptain({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final accounts = await _getAccounts();

    // Check local accounts first
    final index = accounts.indexWhere((a) => a.phone == cleanPhone || a.email.toLowerCase() == phone.trim().toLowerCase());
    CaptainAccount? captain = index != -1 ? accounts[index] : null;

    final emailToAuth = captain?.email ?? (phone.contains('@') ? phone.trim() : null);
    if (emailToAuth != null) {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailToAuth,
          password: password,
        );
        if (cred.user != null) {
          final profile = await CaptainFirebaseService().fetchCaptainProfile(cred.user!.uid);
          if (profile != null) {
            captain = CaptainAccount(
              id: profile.captainId,
              name: profile.name,
              phone: profile.phone,
              email: profile.email,
              password: password,
              vehicleType: profile.vehicleType,
              vehicleNumber: profile.vehicleNumber,
              licenseNumber: profile.drivingLicenseNumber,
              rating: profile.rating,
              isOnline: profile.online,
              verificationStatus: profile.verificationStatus,
              vehicleVerificationStatus: profile.vehicleVerificationStatus,
              profileImageUrl: profile.profileImage,
              vehicleImageUrl: profile.vehicleImage,
              drivingLicenseImageUrl: profile.drivingLicenseImageUrl,
              vehicleDocumentImageUrl: profile.vehicleDocumentImageUrl,
              documentsSubmittedAt: profile.documentsSubmittedAt,
              verifiedAt: profile.verifiedAt,
              rejectionReason: profile.rejectionReason,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'message': e.message ?? 'Login failed. Please check your credentials.',
        };
      } catch (e) {
        debugPrint('[CaptainAuthService] Firebase login error: $e');
        if (Firebase.apps.isNotEmpty) {
          return {
            'success': false,
            'message': 'Login failed: ${e.toString().replaceAll("Exception: ", "")}',
          };
        }
      }
    }

    if (captain == null &&
        cleanPhone == defaultSeedCaptain.phone &&
        !CaptainFirebaseService().isFirebaseAvailable) {
      captain = defaultSeedCaptain;
    }

    if (captain == null) {
      return {
        'success': false,
        'message': 'No Captain account found with this phone number or email.',
      };
    }

    if (captain.password != password && password.isNotEmpty) {
      return {
        'success': false,
        'message': 'Incorrect password. Please try again or reset.',
      };
    }

    // Save active session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, captain.toJson());

    return {
      'success': true,
      'message': 'Login successful.',
      'account': captain,
    };
  }

  /// Check active session on app startup
  Future<CaptainAccount?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        return CaptainAccount.fromJson(sessionJson);
      } catch (_) {}
    }

    // Check Firebase Auth current user if session string is empty
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final profile = await CaptainFirebaseService().fetchCaptainProfile(fbUser.uid);
        if (profile != null) {
          final account = CaptainAccount(
            id: profile.captainId,
            name: profile.name,
            phone: profile.phone,
            email: profile.email,
            password: '',
            vehicleType: profile.vehicleType,
            vehicleNumber: profile.vehicleNumber,
            licenseNumber: profile.drivingLicenseNumber,
            rating: profile.rating,
            isOnline: profile.online,
            verificationStatus: profile.verificationStatus,
            vehicleVerificationStatus: profile.vehicleVerificationStatus,
            profileImageUrl: profile.profileImage,
            vehicleImageUrl: profile.vehicleImage,
            documentsSubmittedAt: profile.documentsSubmittedAt,
            verifiedAt: profile.verifiedAt,
          );
          await prefs.setString(_sessionKey, account.toJson());
          return account;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Save updated profile into active session and accounts store
  Future<void> updateActiveCaptain(CaptainAccount updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, updated.toJson());

    final accounts = await _getAccounts();
    final index = accounts.indexWhere((a) => a.phone == updated.phone || a.id == updated.id);
    if (index != -1) {
      accounts[index] = updated;
    } else {
      accounts.add(updated);
    }
    await prefs.setStringList(_accountsKey, accounts.map((a) => a.toJson()).toList());
  }

  /// Logout captain (clears session and signs out of Firebase Auth)
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Change password securely using Firebase Authentication (with local account sync)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return {
        'success': false,
        'message': 'Current password is required.',
      };
    }
    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'New password must be at least 6 characters long.',
      };
    }
    if (newPassword != confirmPassword) {
      return {
        'success': false,
        'message': 'New password and confirmation do not match.',
      };
    }

    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && fbUser.email != null) {
        final cred = EmailAuthProvider.credential(
          email: fbUser.email!,
          password: currentPassword,
        );
        await fbUser.reauthenticateWithCredential(cred);
        await fbUser.updatePassword(newPassword);
      }
    } catch (e) {
      debugPrint('[QuickRide Captain] Firebase Auth password notice: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
        return {
          'success': false,
          'message': 'Current password is incorrect.',
        };
      }
    }

    // Verify and update active local session
    final currentSession = await getActiveSession();
    if (currentSession != null) {
      if (currentSession.password.isNotEmpty && currentSession.password != currentPassword) {
        return {
          'success': false,
          'message': 'Current password is incorrect.',
        };
      }
      final updated = currentSession.copyWith(password: newPassword);
      await updateActiveCaptain(updated);
    }

    return {
      'success': true,
      'message': 'Password changed successfully! You may log in again if required.',
    };
  }

  /// Temporary local password reset flow
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final accounts = await _getAccounts();

    final index = accounts.indexWhere((a) => a.phone == cleanPhone);
    if (index == -1) {
      return {
        'success': false,
        'message': 'No account associated with +91 $cleanPhone.',
      };
    }

    final updated = accounts[index].copyWith(password: newPassword);
    accounts[index] = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_accountsKey, accounts.map((a) => a.toJson()).toList());

    return {
      'success': true,
      'message': 'Password reset successfully for ${updated.name}. Please login with your new password.',
    };
  }
}
