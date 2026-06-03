import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/cv_templates_data.dart';
import '../models/cv_profile.dart';
import '../models/cv_template.dart';
import '../../../services/auth_service.dart';

class CvMakerProvider extends ChangeNotifier {
  static const _savedProfilesKey = 'cv_maker_saved_profiles_v1';
  static const _premiumKey = 'cv_maker_premium_unlocked';
  static const _premiumPlanKey = 'cv_maker_premium_plan';

  List<CvProfile> _savedProfiles = [];
  CvProfile? _activeProfile;
  CvTemplate _selectedTemplate = cvTemplates.first;
  bool _isPremiumUnlocked = false;
  String? _premiumPlan;
  bool _loaded = false;
  Color? _customPrimaryColor;
  String? _customFontFamily;

  List<CvProfile> get savedProfiles => _savedProfiles;
  CvProfile? get activeProfile => _activeProfile;
  CvTemplate get selectedTemplate => _selectedTemplate;
  bool get isPremiumUnlocked => _isPremiumUnlocked;
  String? get premiumPlan => _premiumPlan;
  bool get loaded => _loaded;
  Color? get customPrimaryColor => _customPrimaryColor;
  String? get customFontFamily => _customFontFamily;

  bool canUseTemplate(CvTemplate template) =>
      !template.isPremium || _isPremiumUnlocked;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    final profilesJsonList = prefs.getStringList(_savedProfilesKey);
    if (profilesJsonList != null) {
      _savedProfiles = profilesJsonList.map((str) {
        try {
          return CvProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<CvProfile>().toList();
    }
    
    // Fetch premium status from backend if authenticated
    try {
      if (await AuthService.isAuthenticated()) {
        final user = await AuthService.getCurrentUser();
        if (user.plan == 'premium') {
          _isPremiumUnlocked = true;
          await prefs.setBool(_premiumKey, true);
        }
      }
    } catch (e) {
      debugPrint('Failed to sync premium status from backend: $e');
    }

    if (!_isPremiumUnlocked) {
      _isPremiumUnlocked = prefs.getBool(_premiumKey) ?? false;
      _premiumPlan = prefs.getString(_premiumPlanKey);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _savedProfiles.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_savedProfilesKey, list);
  }

  void createNewProfile() {
    final newId = const Uuid().v4();
    _activeProfile = CvProfile(id: newId, title: 'New CV');
    _selectedTemplate = cvTemplates.first;
    _customPrimaryColor = null;
    _customFontFamily = null;
    notifyListeners();
  }

  void loadProfile(CvProfile profile) {
    _activeProfile = profile;
    _selectedTemplate = cvTemplates.first; // Reset or load saved template if added later
    _customPrimaryColor = null;
    _customFontFamily = null;
    notifyListeners();
  }
  
  void duplicateProfile(CvProfile profile) {
    final duplicated = profile.copyWith(
      id: const Uuid().v4(),
      title: '${profile.title} (Copy)',
      updatedAt: DateTime.now(),
    );
    _savedProfiles.insert(0, duplicated);
    notifyListeners();
    _persistProfiles();
  }

  void deleteProfile(String id) {
    _savedProfiles.removeWhere((p) => p.id == id);
    if (_activeProfile?.id == id) {
      _activeProfile = null;
    }
    notifyListeners();
    _persistProfiles();
  }

  void saveActiveProfile() {
    if (_activeProfile == null) return;
    _activeProfile!.updatedAt = DateTime.now();
    
    final idx = _savedProfiles.indexWhere((p) => p.id == _activeProfile!.id);
    if (idx != -1) {
      _savedProfiles[idx] = _activeProfile!;
    } else {
      _savedProfiles.insert(0, _activeProfile!);
    }
    notifyListeners();
    _persistProfiles();
  }

  void updateProfile(CvProfile profile) {
    _activeProfile = profile;
    notifyListeners();
  }

  void selectTemplate(CvTemplate template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  void updateCustomStyle({Color? color, String? fontFamily}) {
    if (color != null) _customPrimaryColor = color;
    if (fontFamily != null) _customFontFamily = fontFamily;
    notifyListeners();
  }

  /// Simulates purchasing premium and synchronizes with backend if authenticated
  Future<void> purchasePremium({String plan = 'yearly'}) async {
    try {
      if (await AuthService.isAuthenticated()) {
        await AuthService.authorizedRequest(
          method: 'POST',
          path: '/api/stripe/create-checkout-session',
          data: {'plan': plan},
        );
      } else {
        // Simulate network delay for a realistic feel if not logged in
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (e) {
      debugPrint('Backend premium purchase failed: $e');
      // In a real app we might throw here, but for now we fallback to local mock
    }

    _isPremiumUnlocked = true;
    _premiumPlan = plan;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    await prefs.setString(_premiumPlanKey, plan);
  }

  /// Legacy alias kept for backwards compatibility
  Future<void> unlockPremiumDemo() => purchasePremium();

  /// Revoke premium (for testing / account management)
  Future<void> revokePremium() async {
    _isPremiumUnlocked = false;
    _premiumPlan = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_premiumKey);
    await prefs.remove(_premiumPlanKey);
  }

  void resetToSample() {
    final sample = CvProfile.sample().copyWith(id: const Uuid().v4());
    _activeProfile = sample;
    notifyListeners();
  }
}
