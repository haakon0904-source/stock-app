import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EtfScreen extends StatefulWidget {
  const EtfScreen({super.key});
  @override
  State<EtfScreen> createState() => _EtfScreenState();
}

class _EtfScreenState extends State<EtfScreen> {
  List<EtfData> _etfs = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.instance.fetchEtf();
      setState(() { _etfs = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1120),
        title: const Text('🏦 ETF 분석', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _etfs.length,
                    itemBuilder: (ctx, i) => _EtfCard(etf: _etfs[i]),
                  ),
                ),
    );
  }
}

class _EtfCard extends StatelessWidget {
  final EtfData etf;
  const _EtfCard({required this.etf});

  @override
  Widget build(BuildContext context) {
    final e = etf;
    final isUp = e.ret1y >= 0;
    final rsiColor = e.rsi > 70 ? const Color(0xFFFF1744) : e.rsi < 30 ? const Color(0xFF00C853) : Colors.grey;
    final signalIcon = e.signal.contains('매수') ? '🟢' : e.signal.contains('중립') ? '⚪' : '🔴';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(e.info['name'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Text(e.info['desc'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    overflow: TextOverflow.ellipsis, maxLines: 2),
                const SizedBox(height: 6),
                Text('$signalIcon ${e.signal}', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${e.current.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${isUp ? '+' : ''}${e.ret1y.toStringAsFixed(1)}% 1년',
                  style: TextStyle(color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744), fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rsiColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rsiColor.withOpacity(0.4)),
                ),
                child: Text('RSI ${e.rsi.toStringAsFixed(1)}',
                    style: TextStyle(color: rsiColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
