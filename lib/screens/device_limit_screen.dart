import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

import '../../core/network/dio_client.dart';

// daftar device + lepas device, dipakai saat login kena batas 5 device.
// backend mengenali user ini lewat cookie _tmpUser (didapat saat error login)
class DeviceLimitScreen extends StatefulWidget {
  const DeviceLimitScreen({super.key});

  @override
  State<DeviceLimitScreen> createState() => _DeviceLimitScreenState();
}

class _DeviceLimitScreenState extends State<DeviceLimitScreen> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await DioClient.instance.get(ApiRouteConfig.limitDevice);
      final data = response.data['data'];
      setState(() {
        _devices = (data?['userDevice'] as List?) ?? [];
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error =
            e.response?.data?['error']?['message'] ?? 'Failed to load devices';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeDevice(Map<String, dynamic> device) async {
    final deviceId = device['id'];
    // device saat ini bersifat virtual (tanpa id), tidak bisa dilepas
    if (deviceId == null) return;

    setState(() => _isLoading = true);
    try {
      await DioClient.instance.delete(
        '${ApiRouteConfig.limitDevice}/$deviceId',
      );
      await _loadDevices();
    } on DioException catch (e) {
      setState(() {
        _error =
            e.response?.data?['error']?['message'] ?? 'Failed to remove device';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryLogin(BuildContext context) async {
    await SystemNavigator.pop();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDevices,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _retryLogin(context),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.devices, size: 56, color: Color(0xFF3B62FF)),
                        SizedBox(height: 12),
                        Text(
                          'Device Limit Reached',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'You are signed in on 5 devices. Remove one to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index] as Map<String, dynamic>;
                        final isCurrent = device['isCurrent'] == true;
                        final label = [
                          device['browser'],
                          device['os'],
                        ].where((s) => (s as String).isNotEmpty).join(' · ');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrent
                                    ? Icons.phone_android
                                    : Icons.devices_other,
                                color: const Color(0xFF3B62FF),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrent
                                          ? 'This device (you)'
                                          : (label.isEmpty
                                                ? 'Device ${index + 1}'
                                                : label),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (device['refreshTokens']?['createdAt'] !=
                                        null)
                                      Text(
                                        'Last active: ${DateTime.parse(device['refreshTokens']['createdAt']).toLocal()}'
                                            .substring(0, 34),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                onPressed: isCurrent
                                    ? null
                                    : () => _removeDevice(device),
                                tooltip: isCurrent
                                    ? 'Cannot remove current device'
                                    : 'Remove device',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () => _retryLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B62FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Try Login Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
