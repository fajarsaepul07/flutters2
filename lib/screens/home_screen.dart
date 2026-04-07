import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../features/auth/providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/screens/login_screen.dart';
import '../core/services/api_service.dart';

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
          ? json['waktu_dibuat'].toString().substring(0, 16).replaceAll('T', ' ')
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
  Map<String, dynamic> stats = {'total': 0, 'selesai': 0, 'diproses': 0, 'ditolak': 0};

  final List<Map<String, dynamic>> _kategoris = [
    {'id': 1, 'nama': 'Hardware'},
    {'id': 2, 'nama': 'Software'},
    {'id': 3, 'nama': 'Jaringan'},
    {'id': 4, 'nama': 'Akun & Akses'},
    {'id': 5, 'nama': 'Lainnya'},
  ];

  bool isLoading = true;

    Future<void> _fetchHomeData() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.get('/home', token: token);

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final s = data['stats'] ?? {};

        setState(() {
          stats = {
            'total': s['total'] ?? 0,
            'selesai': s['selesai'] ?? 0,
            'diproses': s['diproses'] ?? 0,
            'ditolak': s['ditolak'] ?? 0,
          };
          tikets = (data['recent_tikets'] as List? ?? [])
              .map((e) => Tiket.fromJson(e))
              .toList();
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

    Future<void> _createTiket(int kategoriId, String judul, String deskripsi) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final response = await ApiService.post(
        '/tikets',
        {
          'kategori_id': kategoriId,
          'judul': judul,
          'deskripsi': deskripsi,
        },
        token: token,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil dibuat ✓'), backgroundColor: Colors.green),
        );
        _fetchHomeData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateTiketDialog() {
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    int? selectedKategoriId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Tiket Baru'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  value: selectedKategoriId,
                  items: _kategoris.map((k) => DropdownMenuItem<int>(
                        value: k['id'] as int,
                        child: Text(k['nama'] as String),
                      )).toList(),
                  onChanged: (val) => setStateDialog(() => selectedKategoriId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: judulController,
                  decoration: const InputDecoration(labelText: 'Judul Tiket'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (selectedKategoriId == null || judulController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori dan Judul wajib diisi')),
                );
                return;
              }
              Navigator.pop(context);
              _createTiket(
                selectedKategoriId!,
                judulController.text.trim(),
                deskripsiController.text.trim(),
              );
            },
            child: const Text('Buat Tiket'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHomeData());
  }

  @override
  void dispose() {
    super.dispose();
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
        title: const Text('Home'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📋 Tiket Saya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Kelola dan pantau semua tiket bantuan Anda',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _btn('Riwayat', Colors.orange),
                                  const SizedBox(width: 8),
                                  _btn('Buat Tiket', Colors.blue, onPressed: _showCreateTiketDialog),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // STAT
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

                        // TABLE
                        Container(
                          decoration: _card(),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Daftar Tiket Terbaru', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                                      child: Text('${tikets.length} tiket', style: const TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              if (tikets.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Text('Belum Ada Tiket', style: TextStyle(fontWeight: FontWeight.w600)),
                                      SizedBox(height: 6),
                                      Text('Silakan buat tiket baru', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 30,
                                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                                    columns: const [
                                      DataColumn(label: Text('Kode & Judul')),
                                      DataColumn(label: Text('Kategori')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Tanggal')),
                                      DataColumn(label: Text('Ditangani')),
                                    ],
                                    rows: tikets.map((t) => DataRow(cells: [
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('#${t.kodeTiket}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                          Text(t.judul),
                                        ],
                                      )),
                                      DataCell(_badge(t.kategori, Colors.cyan)),
                                      DataCell(_badge(t.status, Colors.grey)),
                                      DataCell(Text(t.tanggal)),
                                      DataCell(Text(t.ditangani)),
                                    ])).toList(),
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
            ),
    );
  }

  Widget _btn(String text, Color color, {VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onPressed ?? () {},
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  Widget _stat(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}