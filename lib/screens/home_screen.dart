import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../features/auth/providers/auth_provider.dart';
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
    final kategori = json['kategori'] is Map
        ? json['kategori']['nama_kategori']
        : null;

    final status = json['status'] is Map
        ? json['status']['nama_status']
        : null;

    String tanggal = '';
    if (json['waktu_dibuat'] != null) {
      final raw = json['waktu_dibuat'].toString();
      tanggal = raw.length >= 16
          ? raw.substring(0, 16).replaceAll('T', ' ')
          : raw;
    }

    String ditangani = '-';
    if (json['assignedTo'] is Map) {
      ditangani = json['assignedTo']['name'] ?? '-';
    } else if (json['assigned_to'] is Map) {
      ditangani = json['assigned_to']['name'] ?? '-';
    } else if (json['assignedTo_name'] != null) {
      ditangani = json['assignedTo_name'];
    }

    return Tiket(
      tiketId: json['tiket_id'] ?? 0,
      kodeTiket: json['kode_tiket'] ?? '',
      judul: json['judul'] ?? '',
      kategori: kategori ?? '-',
      status: status ?? 'Pending',
      tanggal: tanggal,
      ditangani: ditangani,
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
  bool isLoading = true;

  final List<Map<String, dynamic>> _kategoris = [
    {'id': 1, 'nama': 'Hardware'},
    {'id': 2, 'nama': 'Software'},
    {'id': 3, 'nama': 'Jaringan'},
    {'id': 4, 'nama': 'Akun & Akses'},
    {'id': 5, 'nama': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.get('/home', token: token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['recent_tikets'] ?? [];

        setState(() {
          tikets = list.map((e) => Tiket.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createTiket(
      int kategoriId, String judul, String deskripsi) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final response = await ApiService.post(
      '/tikets',
      {
        'kategori_id': kategoriId,
        'judul': judul,
        'deskripsi': deskripsi,
      },
      token: token,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _fetchHomeData();
    }
  }

  Future<void> _deleteTiket(int tiketId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tiket?'),
        content: const Text('Tiket ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response =
        await ApiService.delete('/tikets/$tiketId', token: token);

    if (response.statusCode == 200 || response.statusCode == 204) {
      _fetchHomeData();
    }
  }

  void _showCreateTiketDialog() {
    final judulController = TextEditingController();
    final deskripsiController = TextEditingController();
    int? selectedKategoriId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buat Tiket'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedKategoriId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _kategoris.map((k) {
                  return DropdownMenuItem<int>(
                    value: k['id'],
                    child: Text(k['nama']),
                  );
                }).toList(),
                onChanged: (val) =>
                    setStateDialog(() => selectedKategoriId = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (selectedKategoriId == null ||
                  judulController.text.trim().isEmpty) return;

              Navigator.pop(context);

              _createTiket(
                selectedKategoriId!,
                judulController.text.trim(),
                deskripsiController.text.trim(),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(title: const Text('Home')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
               Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiket Saya',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Kelola dan pantau semua tiket bantuan Anda',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
    ElevatedButton.icon(
      onPressed: _showCreateTiketDialog,
      icon: const Icon(Icons.add),
      label: const Text('Buat Tiket Baru'),
    )
  ],
),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _statCard('TOTAL', tikets.length.toString(),
                        Icons.confirmation_number, Colors.blue),
                    _statCard(
                        'SELESAI', '1', Icons.check_circle, Colors.green),
                    _statCard('DIPROSES', '0',
                        Icons.access_time, Colors.orange),
                    _statCard(
                        'DITOLAK', '0', Icons.cancel, Colors.red),
                  ],
                ),

                const SizedBox(height: 20),

                Column(
  children: [
    /// HEADER
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Tiket Terbaru',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${tikets.length} tiket',
            style: const TextStyle(color: Colors.white),
          ),
        )
      ],
    ),

    const SizedBox(height: 10),

    /// TABLE
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [

          /// TABLE HEADER
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('KODE & JUDUL')),
                Expanded(flex: 2, child: Text('KATEGORI')),
                Expanded(flex: 2, child: Text('STATUS')),
                Expanded(flex: 2, child: Text('TANGGAL')),
                Expanded(flex: 2, child: Text('DITANGANI')),
                SizedBox(width: 60),
              ],
            ),
          ),

          /// DATA
          ...tikets.map((t) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [

                    /// KODE & JUDUL
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${t.kodeTiket}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(t.judul),
                        ],
                      ),
                    ),

                    /// KATEGORI
                    Expanded(
                      flex: 2,
                      child: _badge(t.kategori, Colors.cyan),
                    ),

                    /// STATUS
                    Expanded(
                      flex: 2,
                      child: _badge(t.status, Colors.grey),
                    ),

                    /// TANGGAL
                    Expanded(
                      flex: 2,
                      child: Text(
                        t.tanggal.replaceAll(' ', '\n'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                    /// DITANGANI
                    Expanded(
                      flex: 2,
                      child: Text(t.ditangani),
                    ),

                    /// AKSI DELETE
                    SizedBox(
                      width: 60,
                      child: IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () =>
                            _deleteTiket(t.tiketId),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ),
  ],
),
              ],
            ),
    );
  }
}