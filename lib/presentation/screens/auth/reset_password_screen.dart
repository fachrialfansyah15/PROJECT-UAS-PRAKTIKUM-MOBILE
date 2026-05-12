import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // Status verifikasi token recovery
  bool _verified = false;
  bool _verifying = true; // masih loading
  bool _tokenInvalid = false;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenForRecoverySession();
  }

  void _listenForRecoverySession() {
    // Cek apakah sudah ada session recovery aktif
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Session sudah ada (misalnya dari deep link yang sudah diproses)
      if (mounted) {
        setState(() {
          _verified = true;
          _verifying = false;
        });
      }
      return;
    }

    // Dengarkan event auth — saat deep link dibuka, Supabase akan emit
    // event AuthChangeEvent.passwordRecovery dengan session baru
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (!mounted) return;
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.passwordRecovery && session != null) {
          setState(() {
            _verified = true;
            _verifying = false;
          });
        } else if (event == AuthChangeEvent.signedOut) {
          setState(() {
            _verified = false;
            _verifying = false;
            _tokenInvalid = true;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _verifying = false;
            _tokenInvalid = true;
          });
        }
      },
    );

    // Timeout 5 detik — jika tidak ada event, anggap token tidak valid
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _verifying) {
        setState(() {
          _verifying = false;
          _tokenInvalid = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Isi semua field dulu'),
          backgroundColor: Colors.red));
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password tidak cocok'),
          backgroundColor: Colors.red));
      return;
    }
    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password minimal 6 karakter'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passCtrl.text),
      );
      if (mounted) {
        // Clear recovery flag agar router tidak loop ke /reset-password lagi
        ref.read(authChangeProvider).clearRecovery();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password berhasil diubah!'),
            backgroundColor: Colors.green));
        await Supabase.instance.client.auth.signOut();
        if (mounted) context.go('/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Masih memverifikasi token
    if (_verifying) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Memverifikasi token...',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    // Token tidak valid / kadaluarsa
    if (_tokenInvalid || !_verified) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_off_rounded,
                    size: 44, color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'Link Tidak Valid',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Link reset password sudah kadaluarsa atau tidak valid. Silakan minta link baru.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Minta Link Baru',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Token valid — tampilkan form reset password
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_open_rounded,
                size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          const Text('Buat Password Baru',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Masukkan password baru kamu di bawah ini.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Password Baru',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Konfirmasi Password Baru',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Password Baru',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}