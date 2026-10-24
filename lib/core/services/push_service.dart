// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_router.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Every method is a safe no-op when Firebase is not initialised (tests,
/// or a failed Firebase setup), so the app never breaks because of push.
class PushService {
  PushService(this._ref);
  final Ref _ref;
  bool _wired = false;

  bool get _ready => Firebase.apps.isNotEmpty;

  void listen() {
    if (!_ready || _wired) return;
    _wired = true;
    final fm = FirebaseMessaging.instance;

    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('${n.title ?? ''}\n${n.body ?? ''}'.trim()),
            action: m.data['appointment_id'] == null
                ? null
                : SnackBarAction(label: 'View', onPressed: () => _open(m)),
          ),
        );
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    fm.getInitialMessage().then((m) {
      if (m != null) {
        Future.delayed(const Duration(milliseconds: 600), () => _open(m));
      }
    });
    fm.onTokenRefresh.listen(_save);
  }

  void _open(RemoteMessage m) {
    final id = m.data['appointment_id'] as String?;
    if (id == null) return;
    _ref.read(appRouterProvider).push(AppRoutes.passPath(id));
  }

  Future<void> register() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(token);
    } catch (_) {}
  }

  Future<void> _save(String token) async {
    final db = Supabase.instance.client;
    if (db.auth.currentUser == null) return;
    try {
      await db.rpc('register_device_token', params: {'p_token': token});
    } catch (_) {}
  }

  /// Call before signing out, while the session is still valid.
  Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client.rpc(
          'unregister_device_token',
          params: {'p_token': token},
        );
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
