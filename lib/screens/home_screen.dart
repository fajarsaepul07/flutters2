import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../features/auth/providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/screens/login_screen.dart';

class Tiket {
  final int tiketId;
  final String kodeTiket;
  final String judul;
  final String kategori;
  final String status;
  final String tanggal;
  final String ditangani;

  Tiket({
    required this.tiketId,
    required this.kodeTiket,
    required this.judul,
    required this.kategori,
    required this.status,
    required this.tanggal,
    required this.ditangani,
  });

  factory Tiket.fromJson(Map<String, dynamic> json) {
    return Tiket(
      tiketId: json['tiket_id'] ?? 0,
      kodeTiket: json['kode_tiket'] ?? '',
      judul: json['judul'] ?? '',
      kategori: json['kategori']?['nama_kategori'] ?? '-',
      status: json['status']?['nama_status'] ?? 'Pending',
      tanggal: json['waktu_dibuat'] != null
          ? json['waktu_dibuat']
              .toString()
              .substring(0, 16)
              .replaceAll('T', ' ')
          : '',
      ditangani: json['assignedTo']?['name'] ?? '-',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tiket> tikets = [];
  Map<String, dynamic> stats = {
    'total': 0,
    'selesai': 0,
    'diproses': 0,
    'ditolak': 0
  };

  bool isLoading = true;

  Future<void> _fetchHomeData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/home'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final s = data['stats'] ?? {};

        setState(() {
          stats = {
            'total': s['total_tiket'] ?? 0,
            'selesai': s['tiket_selesai'] ?? 0,
            'diproses': s['tiket_proses'] ?? 0,
            'ditolak': 0,
          };

          tikets = (data['recent_tikets'] as List? ?? [])
              .map((e) => Tiket.fromJson(e))
              .toList();

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHomeData());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHomeData,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [

                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('📋 Tiket Saya',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text(
                                  'Kelola dan pantau semua tiket bantuan Anda',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              _btn('Riwayat', Colors.orange),
                              const SizedBox(width: 10),
                              _btn('Buat Tiket', Colors.blue),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// STAT
                      Row(
                        children: [
                          _stat('Total Tiket', stats['total'], Icons.confirmation_number, Colors.blue),
                          const SizedBox(width: 16),
                          _stat('Selesai', stats['selesai'], Icons.check_circle, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat('Diproses', stats['diproses'], Icons.timer, Colors.orange),
                          const SizedBox(width: 16),
                          _stat('Ditolak', stats['ditolak'], Icons.cancel, Colors.red),
                        ],
                      ),

                      const SizedBox(height: 30),

                      /// TABLE CARD
                      Container(
                        decoration: _card(),
                        child: Column(
                          children: [

                            /// HEADER TABLE
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Daftar Tiket Terbaru',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text('${tikets.length} tiket',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  )
                                ],
                              ),
                            ),

                            const Divider(height: 1),

                            /// CONTENT
                            tikets.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Text('Belum Ada Tiket',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 6),
                                        Text('Silakan buat tiket baru',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 30,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                              const Color(0xFFF8F9FA)),
                                      columns: const [
                                        DataColumn(label: Text('Kode & Judul')),
                                        DataColumn(label: Text('Kategori')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Tanggal')),
                                        DataColumn(label: Text('Ditangani')),
                                      ],
                                      rows: tikets.map((t) {
                                        return DataRow(cells: [
                                          DataCell(Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('#${t.kodeTiket}',
                                                  style: const TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(t.judul),
                                            ],
                                          )),
                                          DataCell(_badge(t.kategori, Colors.cyan)),
                                          DataCell(_badge(t.status, Colors.grey)),
                                          DataCell(Text(t.tanggal)),
                                          DataCell(Text(t.ditangani)),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// BUTTON
  Widget _btn(String text, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      onPressed: () {},
      child: Text(text),
    );
  }

  /// CARD STYLE
  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  /// STAT
  Widget _stat(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                Text(value.toString(),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// BADGE
  Widget _badge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 12)),
    );
  }
}