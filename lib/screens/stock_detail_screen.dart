import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;
  const StockDetailScreen({super.key, required this.ticker});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ApiService.instance.fetchStockDetail(widget.ticker);
      setState(() { _detail = d; _loading = false; });
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
        title: Text(widget.ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final s = d.stock;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.ticker, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(s.name, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${s.current}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text('${s.ret1y >= 0 ? '+' : ''}${s.ret1y.toStringAsFixed(1)}% (1년)',
                      style: TextStyle(color: s.ret1y >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744), fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 신호 ──
          _SignalRow(stock: s),
          const SizedBox(height: 20),

          // ── 종합점수 & 팩터 ──
          _SectionTitle('📊 종합 분석 점수'),
          _ScoreCard(stock: s),
          const SizedBox(height: 20),

          // ── 가격 차트 ──
          if (d.priceHistory.isNotEmpty) ...[
            _SectionTitle('📈 주가 추이 (1년)'),
            _PriceChart(history: d.priceHistory),
            const SizedBox(height: 20),
          ],

          // ── 재무 지표 ──
          _SectionTitle('💰 재무 지표'),
          _FinancialGrid(stock: s),
          const SizedBox(height: 20),

          // ── 밸류에이션 ──
          _SectionTitle('💲 밸류에이션'),
          _ValuationCard(stock: s),
          const SizedBox(height: 20),

          // ── 실적 차트 ──
          if (d.quarterlyRevenue.isNotEmpty) ...[
            _SectionTitle('📅 분기별 매출 (\$B)'),
            _RevenueChart(data: d.quarterlyRevenue),
            const SizedBox(height: 20),
          ],

          if (d.surpriseHistory.isNotEmpty) ...[
            _SectionTitle('🎯 EPS 서프라이즈 (%)'),
            _SurpriseChart(data: d.surpriseHistory),
            const SizedBox(height: 20),
          ],

          // ── 실적 발표일 ──
          if (d.nextEarningsDate != null) ...[
            _EarningsAlert(date: d.nextEarningsDate!, daysTo: d.daysToEarnings),
            const SizedBox(height: 20),
          ],

          // ── 매도 경고 ──
          if (s.sellSignal.contains('권고') || s.sellSignal.contains('검토'))
            _SellAlert(signal: s.sellSignal, reason: s.sellReason),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 위젯들
// ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
  );
}

class _SignalRow extends StatelessWidget {
  final StockSummary stock;
  const _SignalRow({required this.stock});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(stock.signalLabel, stock.signalColor),
        const SizedBox(width: 8),
        _Badge('RSI ${stock.rsi}', Colors.blueGrey),
        const SizedBox(width: 8),
        _Badge('Piotroski ${stock.piotroski}/9',
            stock.piotroski >= 7 ? const Color(0xFF00C853) : stock.piotroski >= 4 ? Colors.orange : Colors.red),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

class _ScoreCard extends StatelessWidget {
  final StockSummary stock;
  const _ScoreCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final s = stock;
    Color scoreColor = s.score >= 75 ? const Color(0xFF00C853) : s.score >= 55 ? const Color(0xFFFFD600) : const Color(0xFFFF1744);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('종합점수', style: TextStyle(color: Colors.grey[400])),
              Text('${s.score}/100', style: TextStyle(color: scoreColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.score / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          // 팩터별 상세는 추후 API에서 받아와서 추가
          Row(
            children: [
              Expanded(child: _FactorStat('1년수익', '${s.ret1y >= 0 ? '+' : ''}${s.ret1y.toStringAsFixed(1)}%', s.ret1y >= 0)),
              Expanded(child: _FactorStat('SPY대비', '${s.rsVsSpy >= 0 ? '+' : ''}${s.rsVsSpy.toStringAsFixed(1)}%', s.rsVsSpy >= 0)),
              Expanded(child: _FactorStat('고점대비', '${s.from52wHigh.toStringAsFixed(1)}%', s.from52wHigh >= -10)),
            ],
          ),
          if (s.recommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2035),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('애널리스트 의견', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(s.recommendation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (s.targetPrice != null) ...[
                        const SizedBox(width: 12),
                        Text('목표주가 \$${s.targetPrice}', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                        if (s.upsidePct != null) ...[
                          const SizedBox(width: 8),
                          Text('(${s.upsidePct! >= 0 ? '+' : ''}${s.upsidePct!.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: s.upsidePct! >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                                fontSize: 13, fontWeight: FontWeight.bold,
                              )),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactorStat extends StatelessWidget {
  final String label, value;
  final bool positive;
  const _FactorStat(this.label, this.value, this.positive);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        color: positive ? const Color(0xFF00C853) : const Color(0xFFFF1744),
        fontWeight: FontWeight.bold, fontSize: 14,
      )),
    ],
  );
}

class _FinancialGrid extends StatelessWidget {
  final StockSummary stock;
  const _FinancialGrid({required this.stock});
  @override
  Widget build(BuildContext context) {
    final s = stock;
    final items = [
      ('매출성장', s.revenueGrowth != null ? '${s.revenueGrowth!.toStringAsFixed(1)}%' : '-', (s.revenueGrowth ?? 0) > 0),
      ('이익성장', s.earningsGrowth != null ? '${s.earningsGrowth!.toStringAsFixed(1)}%' : '-', (s.earningsGrowth ?? 0) > 0),
      ('ROE', s.roe != null ? '${s.roe!.toStringAsFixed(1)}%' : '-', (s.roe ?? 0) > 15),
      ('영업이익률', s.operatingMargin != null ? '${s.operatingMargin!.toStringAsFixed(1)}%' : '-', (s.operatingMargin ?? 0) > 15),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.$1, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(item.$2, style: TextStyle(
              color: item.$3 ? const Color(0xFF00C853) : Colors.white70,
              fontWeight: FontWeight.bold, fontSize: 18,
            )),
          ],
        ),
      )).toList(),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  final StockSummary stock;
  const _ValuationCard({required this.stock});
  @override
  Widget build(BuildContext context) {
    final s = stock;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ValItem('PER (현재)', s.pe?.toStringAsFixed(1) ?? '-'),
          _ValItem('PEG', s.peg?.toStringAsFixed(2) ?? '-', highlight: (s.peg ?? 99) < 1.5),
          _ValItem('EV/EBITDA', s.evEbitda?.toStringAsFixed(1) ?? '-'),
        ],
      ),
    );
  }
}

class _ValItem extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ValItem(this.label, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        color: highlight ? const Color(0xFF00C853) : Colors.white,
        fontWeight: FontWeight.bold, fontSize: 18,
      )),
    ],
  );
}

class _PriceChart extends StatelessWidget {
  final List<PricePoint> history;
  const _PriceChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final prices = history.map((p) => p.close).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.97;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.03;
    final firstPrice = prices.first;
    final lastPrice = prices.last;
    final isUp = lastPrice >= firstPrice;
    final color = isUp ? const Color(0xFF00C853) : const Color(0xFFFF1744);

    final spots = prices.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: LineChart(
        LineChartData(
          minY: minY, maxY: maxY,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<QuarterData> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(data[i].quarter.replaceAll('20', '').replaceAll('-', '\n'),
                    style: const TextStyle(color: Colors.grey, fontSize: 9));
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(
              toY: e.value.revenueB,
              color: const Color(0xFF1565C0),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )],
          )).toList(),
        ),
      ),
    );
  }
}

class _SurpriseChart extends StatelessWidget {
  final List<SurpriseData> data;
  const _SurpriseChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF141929), borderRadius: BorderRadius.circular(12)),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(data[i].quarter.replaceAll('20', '').replaceAll('-', '\n'),
                    style: const TextStyle(color: Colors.grey, fontSize: 9));
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [BarChartRodData(
              toY: e.value.surprisePct,
              color: e.value.surprisePct >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF1744),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )],
          )).toList(),
        ),
      ),
    );
  }
}

class _EarningsAlert extends StatelessWidget {
  final String date;
  final int? daysTo;
  const _EarningsAlert({required this.date, this.daysTo});
  @override
  Widget build(BuildContext context) {
    final isClose = (daysTo ?? 99) <= 14;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClose ? const Color(0xFFFF6F00).withOpacity(0.1) : const Color(0xFF141929),
        borderRadius: BorderRadius.circular(12),
        border: isClose ? Border.all(color: const Color(0xFFFF6F00).withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: isClose ? const Color(0xFFFF6F00) : Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('다음 실적 발표', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (daysTo != null && daysTo! > 0)
                Text('D-$daysTo', style: TextStyle(
                  color: isClose ? const Color(0xFFFF6F00) : Colors.grey[400],
                  fontSize: 13, fontWeight: FontWeight.bold,
                )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellAlert extends StatelessWidget {
  final String signal, reason;
  const _SellAlert({required this.signal, required this.reason});
  @override
  Widget build(BuildContext context) {
    final isStrong = signal.contains('강력');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1744).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(signal, style: const TextStyle(color: Color(0xFFFF1744), fontWeight: FontWeight.bold, fontSize: 15)),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(reason, style: TextStyle(color: Colors.red[300], fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
