import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  PortfolioData? _data;
  bool _loading = false;
  String? _error;

  final _numFmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ApiService.instance.fetchPortfolio();
      setState(() { _data = d; _loading = false; });
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
        title: const Text('💼 내 포트폴리오', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('연결 실패', style: TextStyle(color: Colors.grey[400])),
                  ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
                ]))
              : _data == null || _data!.holdings.isEmpty
                  ? Center(child: Text('포트폴리오 없음', style: TextStyle(color: Colors.grey[400])))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SummaryCard(data: _data!, numFmt: _numFmt),
                          const SizedBox(height: 16),
                          ...(_data!.holdings.map((h) => _HoldingCard(holding: h, numFmt: _numFmt))),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PortfolioData data;
  final NumberFormat numFmt;
  const _SummaryCard({required this.data, required this.numFmt});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final isUp = d.totalPnlPct >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUp
              ? [const Color(0xFF00C853).withOpacity(0.2), const Color(0xFF141929)]
              : [const Color(0xFFFF1744).withOpacity(0.2), const Color(0xFF141929)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUp ? const Color(0xFF00C853).withOpacity(0.3) : const Color(0xFFFF1744).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('총 평가금액', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 4),
          Text('\$${d.totalValueUsd.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('≈ ${numFmt.format(d.totalValueKrw.toInt())}원',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SumStat('투자원금', '\$${d.totalInvestedUsd.toStringAsFixed(0)}')),
              Expanded(child: _SumStat('평가손익',
                  '${isUp ? '+' : ''}\$${d.totalPnlUsd.toStringAsFixed(2)}',
                  color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744))),
              Expanded(child: _SumStat('수익률',
                  '${isUp ? '+' : ''}${d.totalPnlPct.toStringAsFixed(1)}%',
                  color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744))),
            ],
          ),
          const SizedBox(height: 8),
          Text('환율: ${d.exrate.toStringAsFixed(0)}원/달러',
              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _SumStat(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    ],
  );
}

class _HoldingCard extends StatelessWidget {
  final Holding holding;
  final NumberFormat numFmt;
  const _HoldingCard({required this.holding, required this.numFmt});

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final isUp = h.pnlPct >= 0;
    final hasSellAlert = h.sellSignal.contains('권고') || h.sellSignal.contains('검토');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(12),
        border: hasSellAlert ? Border.all(color: const Color(0xFFFF1744).withOpacity(0.4)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${h.qty}주  평균단가 \$${h.avgPrice}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${h.current}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('평가 \$${h.valueUsd.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUp ? const Color(0xFF00C853).withOpacity(0.1) : const Color(0xFFFF1744).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('손익', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      Text('${isUp ? '+' : ''}\$${h.pnlUsd.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                            fontWeight: FontWeight.bold, fontSize: 16,
                          )),
                      Text('${isUp ? '+' : ''}${h.pnlPct.toStringAsFixed(1)}%',
                          style: TextStyle(color: isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1A2035), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('원화환산', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      Text('${numFmt.format(h.valueKrw.toInt())}원',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(h.signal, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasSellAlert) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
              ),
              child: Text(h.sellSignal, style: const TextStyle(color: Color(0xFFFF1744), fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
