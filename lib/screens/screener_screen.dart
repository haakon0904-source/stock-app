import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'stock_detail_screen.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({super.key});
  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  List<StockSummary> _stocks = [];
  bool _loading = false;
  String? _error;
  String _filter = 'all'; // all, buy, sell

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.instance.fetchScreener();
      setState(() { _stocks = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<StockSummary> get _filtered {
    if (_filter == 'buy') return _stocks.where((s) => s.signal.contains('강력매수') || s.signal.contains('매수고려')).toList();
    if (_filter == 'sell') return _stocks.where((s) => s.sellSignal.contains('권고') || s.sellSignal.contains('검토')).toList();
    return _stocks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1120),
        title: const Text('📈 주도주 스크리닝', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: '전체', value: 'all', group: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterChip(label: '🟢 매수', value: 'buy', group: _filter, onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterChip(label: '🚨 매도', value: 'sell', group: _filter, onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),

          // 상단 요약 (강력매수 종목)
          if (_filter == 'all' && _stocks.isNotEmpty)
            _TopBuyCards(stocks: _stocks.where((s) => s.signal.contains('강력매수')).take(3).toList()),

          // 리스트
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _StockCard(
                            stock: _filtered[i],
                            rank: _stocks.indexOf(_filtered[i]) + 1,
                            onTap: () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => StockDetailScreen(ticker: _filtered[i].ticker),
                            )),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, group;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : const Color(0xFF1A2035),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}

class _TopBuyCards extends StatelessWidget {
  final List<StockSummary> stocks;
  const _TopBuyCards({required this.stocks});

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stocks.length,
        itemBuilder: (ctx, i) {
          final s = stocks[i];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF00C853).withOpacity(0.2), const Color(0xFF141929)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${s.current}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('점수 ${s.score}/100', style: const TextStyle(color: Color(0xFF00C853), fontSize: 12)),
                Text('1년 ${s.ret1y >= 0 ? '+' : ''}${s.ret1y.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: s.ret1y >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockSummary stock;
  final int rank;
  final VoidCallback onTap;
  const _StockCard({required this.stock, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = stock;
    final isUp = s.ret1y >= 0;
    final hasSell = s.sellSignal.contains('권고') || s.sellSignal.contains('검토');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141929),
          borderRadius: BorderRadius.circular(12),
          border: hasSell
              ? Border.all(color: const Color(0xFFFF1744).withOpacity(0.4))
              : s.signal.contains('강력매수')
                  ? Border.all(color: const Color(0xFF00C853).withOpacity(0.4))
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Text('$rank', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(s.name, style: TextStyle(color: Colors.grey[500], fontSize: 11), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${s.current}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${isUp ? '+' : ''}${s.ret1y.toStringAsFixed(1)}% 1년',
                        style: TextStyle(color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744), fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 점수 바
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.score / 100,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(_scoreColor(s.score)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${s.score}점', style: TextStyle(color: _scoreColor(s.score), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),

            // 신호 + 주요 지표
            Row(
              children: [
                _SignalBadge(signal: s.signalLabel, color: s.signalColor),
                const SizedBox(width: 8),
                Text('RSI ${s.rsi}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(width: 8),
                Text('Piotroski ${s.piotroski}/9', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),

            const SizedBox(height: 8),

            // 재무 지표 한줄
            Wrap(
              spacing: 12,
              children: [
                if (s.revenueGrowth != null)
                  _MiniStat('매출성장', '${s.revenueGrowth!.toStringAsFixed(1)}%', s.revenueGrowth! > 0),
                if (s.roe != null)
                  _MiniStat('ROE', '${s.roe!.toStringAsFixed(1)}%', s.roe! > 15),
                if (s.operatingMargin != null)
                  _MiniStat('영업이익률', '${s.operatingMargin!.toStringAsFixed(1)}%', s.operatingMargin! > 15),
                if (s.pe != null)
                  _MiniStat('PER', '${s.pe!.toStringAsFixed(1)}', false),
                if (s.upsidePct != null)
                  _MiniStat('목표괴리', '${s.upsidePct!.toStringAsFixed(1)}%', s.upsidePct! > 0),
              ],
            ),

            // 매도 경고
            if (hasSell) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
                ),
                child: Text(
                  '${s.sellSignal}  ${s.sellReason}',
                  style: const TextStyle(color: Color(0xFFFF1744), fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return const Color(0xFF00C853);
    if (score >= 55) return const Color(0xFFFFD600);
    return const Color(0xFFFF1744);
  }
}

class _SignalBadge extends StatelessWidget {
  final String signal;
  final Color color;
  const _SignalBadge({required this.signal, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(signal, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final bool positive;
  const _MiniStat(this.label, this.value, this.positive);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        Text(value, style: TextStyle(
          color: positive ? const Color(0xFF00C853) : Colors.white70,
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text('연결 실패\napi_server.py 실행 확인', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
