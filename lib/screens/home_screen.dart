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
    final kategori = json['kategori'] is Map<String, dynamic>
        ? json['kategori']['nama_kategori'] ?? '-'
        : '-';

    final status = json['status'] is Map<String, dynamic>
        ? json['status']['nama_status'] ?? 'Pending'
        : 'Pending';

    String tanggal = '';
    if (json['waktu_dibuat'] != null) {
      final raw = json['waktu_dibuat'].toString();
      tanggal = raw.length >= 16
          ? raw.substring(0, 16).replaceAll('T', ' ')
          : raw;
    }

    String ditangani = '-';
    if (json['assignedTo'] is Map<String, dynamic>) {
      ditangani = json['assignedTo']['name']?.toString() ?? '-';
    } else if (json['assigned_to'] is Map<String, dynamic>) {
      ditangani = json['assigned_to']['name']?.toString() ?? '-';
    } else if (json['assigned_to'] != null) {
      ditangani = "ID: ${json['assigned_to']}";
    } else if (json['assigned_to_name'] != null) {
      ditangani = json['assigned_to_name'].toString();
    } else if (json['assignedTo_name'] != null) {
      ditangani = json['assignedTo_name'].toString();
    }

    return Tiket(
      tiketId: json['tiket_id'] ?? json['id'] ?? 0,
      kodeTiket: json['kode_tiket'] ?? '',
      judul: json['judul'] ?? '',
      kategori: kategori,
      status: status,
      tanggal: tanggal,
      ditangani: ditangani,
    );
  }
}

// ─── Warna & konstanta desain ───────────────────────────────────────────────
const _primary      = Color(0xFF3B5BDB);
const _bgPage       = Color(0xFFF5F6FA);
const _cardBg       = Colors.white;
const _borderColor  = Color(0xFFE5E7EB);
const _textPrimary  = Color(0xFF111827);
const _textMuted    = Color(0xFF9CA3AF);
const _radius       = 10.0;

// ─── Helper: status → warna ─────────────────────────────────────────────────
_StatusStyle _statusStyle(String status) {
  final s = status.toLowerCase();
  if (s.contains('selesai'))  return _StatusStyle(const Color(0xFFD1FAE5), const Color(0xFF065F46));
  if (s.contains('proses'))   return _StatusStyle(const Color(0xFFFCE7F3), const Color(0xFF9D174D));
  if (s.contains('ditolak'))  return _StatusStyle(const Color(0xFFFEE2E2), const Color(0xFF991B1B));
  return _StatusStyle(const Color(0xFFFEF3C7), const Color(0xFF92400E)); // pending
}

class _StatusStyle {
  final Color bg, text;
  const _StatusStyle(this.bg, this.text);
}

// ─── HomeScreen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tiket> tikets   = [];
  bool isLoading       = true;
  int totalTiket       = 0;
  int selesaiTiket     = 0;
  int prosesTiket      = 0;
  int ditolakTiket     = 0;

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
    final auth  = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) { setState(() => isLoading = false); return; }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('/home', token: token);
      if (response.statusCode == 200) {
        final data  = json.decode(response.body);
        final List<dynamic> list = data['recent_tikets'] ?? [];
        tikets      = list.map((e) => Tiket.fromJson(e as Map<String, dynamic>)).toList();
        final stats = data['stats'] ?? {};
        totalTiket   = stats['total_tiket']    ?? 0;
        selesaiTiket = stats['tiket_selesai']  ?? 0;
        prosesTiket  = stats['tiket_proses']   ?? 0;
        ditolakTiket = stats['tiket_ditolak']  ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetch home: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createTiket(int kategoriId, String judul, String deskripsi) async {
    final auth  = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final response = await ApiService.post(
      '/tikets',
      {'kategori_id': kategoriId, 'judul': judul, 'deskripsi': deskripsi},
      token: token,
    );
    if (response.statusCode == 200 || response.statusCode == 201) _fetchHomeData();
  }

  Future<void> _deleteTiket(int tiketId) async {
    final auth  = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        title: const Text('Hapus tiket?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Tiket ini akan dihapus secara permanen.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final response = await ApiService.delete('/tikets/$tiketId', token: token);
    if (response.statusCode == 200 || response.statusCode == 204) _fetchHomeData();
  }

  void _showCreateTiketDialog() {
    final judulCtrl     = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    int? selectedKategoriId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        title: const Text('Buat tiket baru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (ctx, setD) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogLabel('Kategori'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedKategoriId,
                decoration: _inputDec('Pilih kategori'),
                items: _kategoris.map((k) => DropdownMenuItem<int>(
                  value: k['id'], child: Text(k['nama']))).toList(),
                onChanged: (v) => setD(() => selectedKategoriId = v),
              ),
              const SizedBox(height: 14),
              _dialogLabel('Judul'),
              const SizedBox(height: 6),
              TextField(controller: judulCtrl, decoration: _inputDec('Judul tiket')),
              const SizedBox(height: 14),
              _dialogLabel('Deskripsi'),
              const SizedBox(height: 6),
              TextField(
                controller: deskripsiCtrl,
                maxLines: 3,
                decoration: _inputDec('Jelaskan masalahmu...'),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedKategoriId == null || judulCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              _createTiket(selectedKategoriId!, judulCtrl.text.trim(), deskripsiCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );

  Widget _dialogLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textPrimary));

  // ─── Stat card ────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, IconData icon, Color iconBg, Color iconFg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconFg, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: _textMuted,
                    letterSpacing: 0.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status badge ─────────────────────────────────────────────────────────
  Widget _statusBadge(String text) {
    final s = _statusStyle(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: s.text)),
    );
  }

  // ─── Category badge ───────────────────────────────────────────────────────
  Widget _categoryBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE0F2F1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF00695C))),
  );

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: const Text('Home',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textPrimary)),
        backgroundColor: _cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _borderColor),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _fetchHomeData,
              color: _primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Page header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tiket Saya',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                                  color: _textPrimary)),
                          SizedBox(height: 4),
                          Text('Kelola dan pantau semua tiket bantuan Anda',
                              style: TextStyle(fontSize: 13, color: _textMuted)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateTiketDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Buat Tiket', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Stat cards
                  Row(
                    children: [
                      _statCard('TOTAL', tikets.length.toString(),
                          Icons.confirmation_number_outlined,
                          const Color(0xFFEEF2FF), _primary),
                      _statCard('SELESAI', selesaiTiket.toString(),
                          Icons.check_circle_outline,
                          const Color(0xFFD1FAE5), const Color(0xFF065F46)),
                      _statCard('DIPROSES', prosesTiket.toString(),
                          Icons.access_time_outlined,
                          const Color(0xFFFFF7ED), const Color(0xFF92400E)),
                      _statCard('DITOLAK', ditolakTiket.toString(),
                          Icons.cancel_outlined,
                          const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Tiket Terbaru',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                              color: _textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${tikets.length} tiket',
                            style: const TextStyle(fontSize: 12, color: _primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Table
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      border: Border.all(color: _borderColor, width: 0.8),
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: _TH('KODE & JUDUL')),
                              Expanded(flex: 2, child: _TH('KATEGORI')),
                              Expanded(flex: 2, child: _TH('STATUS')),
                              Expanded(flex: 2, child: _TH('TANGGAL')),
                              Expanded(flex: 2, child: _TH('DITANGANI')),
                              SizedBox(width: 52),
                            ],
                          ),
                        ),

                        // Rows
                        if (tikets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('Belum ada tiket',
                                  style: TextStyle(fontSize: 13, color: _textMuted)),
                            ),
                          ),

                        ...tikets.asMap().entries.map((entry) {
                          final t   = entry.value;
                          final idx = entry.key;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: idx == 0 ? _borderColor : const Color(0xFFF3F4F6),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
  children: [
    // Kode & judul
    Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${t.kodeTiket}',
            style: const TextStyle(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            t.judul,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    ),

    // Kategori
    Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _categoryBadge(
          t.kategori.isEmpty ? '-' : t.kategori,
        ),
      ),
    ),

    // Status
    Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _statusBadge(
          t.status.isEmpty ? 'Pending' : t.status,
        ),
      ),
    ),

    // Tanggal
    Expanded(
      flex: 2,
      child: Text(
        t.tanggal.isEmpty ? '-' : t.tanggal.replaceAll(' ', '\n'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
    ),

    // Ditangani
    Expanded(
      flex: 2,
      child: Text(
        t.ditangani.isEmpty ? '-' : t.ditangani,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: t.ditangani == '-' 
              ? FontWeight.normal 
              : FontWeight.w500,
          color: t.ditangani == '-' 
              ? _textMuted 
              : _textPrimary,
        ),
      ),
    ),

    // Hapus
    SizedBox(
      width: 52,
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => _deleteTiket(t.tiketId),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFFFECACA),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.delete_outline,
              size: 15,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
      ),
    ),
  ],
),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// Tabel header widget kecil
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF), letterSpacing: 0.4));
}