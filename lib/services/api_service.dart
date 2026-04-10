import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://stock-api-3y2n.onrender.com';

class ApiService {
  static final ApiService _instance = ApiService._();
  ApiService._();
  static ApiService get instance => _instance;

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 60));
    if (resp.statusCode == 200) {
      return json.decode(utf8.decode(resp.bodyBytes));
    }
    throw Exception('API 오류: ${resp.statusCode}');
  }

  Future<List<StockSummary>> fetchScreener() async {
    final data = await _get('/api/screener');
    return (data['data'] as List).map((e) => StockSummary.fromJson(e)).toList();
  }

  Future<StockDetail> fetchStockDetail(String ticker) async {
    final data = await _get('/api/stock/$ticker');
    return StockDetail.fromJson(data);
  }

  Future<PortfolioData> fetchPortfolio() async {
    final data = await _get('/api/portfolio');
    return PortfolioData.fromJson(data);
  }

  Future<List<EtfData>> fetchEtf() async {
    final data = await _get('/api/etf');
    return (data['data'] as List).map((e) => EtfData.fromJson(e)).toList();
  }
}

class StockSummary {
  final String ticker, name, signal, sellSignal, sellReason, recommendation;
  final double current, ret1y, rsVsSpy, from52wHigh, rsi;
  final int score, piotroski;
  final double? revenueGrowth, earningsGrowth, roe, operatingMargin;
  final double? pe, peg, evEbitda, targetPrice, upsidePct;

  StockSummary({
    required this.ticker, required this.name,
    required this.signal, required this.sellSignal,
    required this.sellReason, required this.recommendation,
    required this.current, required this.ret1y,
    required this.rsVsSpy, required this.from52wHigh,
    required this.score, required this.piotroski, required this.rsi,
    this.revenueGrowth, this.earningsGrowth,
    this.roe, this.operatingMargin,
    this.pe, this.peg, this.evEbitda,
    this.targetPrice, this.upsidePct,
  });

  factory StockSummary.fromJson(Map<String, dynamic> j) => StockSummary(
    ticker:          j['ticker'] ?? '',
    name:            j['name'] ?? '',
    signal:          j['signal'] ?? '',
    sellSignal:      j['sell_signal'] ?? '',
    sellReason:      j['sell_reason'] ?? '',
    recommendation:  j['recommendation'] ?? '',
    current:         (j['current'] ?? 0).toDouble(),
    ret1y:           (j['ret_1y'] ?? 0).toDouble(),
    rsVsSpy:         (j['rs_vs_spy'] ?? 0).toDouble(),
    from52wHigh:     (j['from_52w_high'] ?? 0).toDouble(),
    score:           (j['canslim_score'] ?? 0).toInt(),
    piotroski:       (j['piotroski'] ?? 0).toInt(),
    rsi:             (j['rsi'] ?? 0).toDouble(),
    revenueGrowth:   j['revenue_growth']?.toDouble(),
    earningsGrowth:  j['earnings_growth']?.toDouble(),
    roe:             j['roe']?.toDouble(),
    operatingMargin: j['operating_margin']?.toDouble(),
    pe:              j['pe']?.toDouble(),
    peg:             j['peg']?.toDouble(),
    evEbitda:        j['ev_ebitda']?.toDouble(),
    targetPrice:     j['target_price']?.toDouble(),
    upsidePct:       j['upside_pct']?.toDouble(),
  );

  Color get signalColor {
    if (signal.contains('강력매수')) return const Color(0xFF00C853);
    if (signal.contains('매수고려')) return const Color(0xFFFFD600);
    if (signal.contains('부적합')) return const Color(0xFFFF1744);
    return const Color(0xFF9E9E9E);
  }

  String get signalLabel {
    if (signal.contains('강력매수')) return '강력매수';
    if (signal.contains('매수고려')) return '매수고려';
    if (signal.contains('관심')) return '관심유지';
    return '중립';
  }
}

class StockDetail {
  final StockSummary stock;
  final List<PricePoint> priceHistory;
  final List<QuarterData> quarterlyRevenue;
  final List<SurpriseData> surpriseHistory;
  final String? nextEarningsDate;
  final int? daysToEarnings;

  StockDetail({
    required this.stock, required this.priceHistory,
    required this.quarterlyRevenue, required this.surpriseHistory,
    this.nextEarningsDate, this.daysToEarnings,
  });

  factory StockDetail.fromJson(Map<String, dynamic> j) {
    final s = StockSummary.fromJson(j['stock'] ?? {});
    final earn = j['earnings'] ?? {};
    return StockDetail(
      stock: s,
      priceHistory: (j['price_history'] as List? ?? [])
          .map((e) => PricePoint.fromJson(e)).toList(),
      quarterlyRevenue: (j['quarterly_revenue'] as List? ?? [])
          .map((e) => QuarterData.fromJson(e)).toList(),
      surpriseHistory: (j['surprise_history'] as List? ?? [])
          .map((e) => SurpriseData.fromJson(e)).toList(),
      nextEarningsDate: earn['next_earnings_date'],
      daysToEarnings:   earn['days_to_earnings']?.toInt(),
    );
  }
}

class PricePoint {
  final String date;
  final double open, high, low, close;
  final int volume;
  PricePoint({required this.date, required this.open, required this.high,
    required this.low, required this.close, required this.volume});
  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
    date: j['date'], open: j['open'].toDouble(), high: j['high'].toDouble(),
    low: j['low'].toDouble(), close: j['close'].toDouble(), volume: j['volume'],
  );
}

class QuarterData {
  final String quarter;
  final double revenueB;
  QuarterData({required this.quarter, required this.revenueB});
  factory QuarterData.fromJson(Map<String, dynamic> j) =>
      QuarterData(quarter: j['quarter'] ?? '', revenueB: (j['revenue_B'] ?? 0).toDouble());
}

class SurpriseData {
  final String quarter;
  final double surprisePct;
  SurpriseData({required this.quarter, required this.surprisePct});
  factory SurpriseData.fromJson(Map<String, dynamic> j) =>
      SurpriseData(quarter: j['quarter'] ?? '', surprisePct: (j['surprise_pct'] ?? 0).toDouble());
}

class PortfolioData {
  final List<Holding> holdings;
  final double totalInvestedUsd, totalValueUsd, totalPnlUsd, totalPnlPct;
  final double totalValueKrw, exrate;

  PortfolioData({
    required this.holdings, required this.totalInvestedUsd,
    required this.totalValueUsd, required this.totalPnlUsd,
    required this.totalPnlPct, required this.totalValueKrw, required this.exrate,
  });

  factory PortfolioData.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] ?? {};
    return PortfolioData(
      holdings: (j['holdings'] as List? ?? []).map((e) => Holding.fromJson(e)).toList(),
      totalInvestedUsd: (s['total_invested_usd'] ?? 0).toDouble(),
      totalValueUsd:    (s['total_value_usd'] ?? 0).toDouble(),
      totalPnlUsd:      (s['total_pnl_usd'] ?? 0).toDouble(),
      totalPnlPct:      (s['total_pnl_pct'] ?? 0).toDouble(),
      totalValueKrw:    (s['total_value_krw'] ?? 0).toDouble(),
      exrate:           (j['exrate'] ?? 1350).toDouble(),
    );
  }
}

class Holding {
  final String ticker, signal, sellSignal;
  final double qty, avgPrice, current, valueUsd, valueKrw, pnlUsd, pnlPct;

  Holding({required this.ticker, required this.signal, required this.sellSignal,
    required this.qty, required this.avgPrice, required this.current,
    required this.valueUsd, required this.valueKrw,
    required this.pnlUsd, required this.pnlPct});

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
    ticker:     j['ticker'] ?? '',
    signal:     j['signal'] ?? '',
    sellSignal: j['sell_signal'] ?? '',
    qty:        (j['qty'] ?? 0).toDouble(),
    avgPrice:   (j['avg_price'] ?? 0).toDouble(),
    current:    (j['current'] ?? 0).toDouble(),
    valueUsd:   (j['value_usd'] ?? 0).toDouble(),
    valueKrw:   (j['value_krw'] ?? 0).toDouble(),
    pnlUsd:     (j['pnl_usd'] ?? 0).toDouble(),
    pnlPct:     (j['pnl_pct'] ?? 0).toDouble(),
  );
}

class EtfData {
  final String ticker, signal;
  final double current, rsi, ret1y;
  final Map<String, dynamic> info;

  EtfData({required this.ticker, required this.signal, required this.current,
    required this.rsi, required this.ret1y, required this.info});

  factory EtfData.fromJson(Map<String, dynamic> j) => EtfData(
    ticker:  j['ticker'] ?? '',
    signal:  j['signal'] ?? '',
    current: (j['current'] ?? 0).toDouble(),
    rsi:     (j['rsi'] ?? 0).toDouble(),
    ret1y:   (j['ret_1y'] ?? 0).toDouble(),
    info:    Map<String, dynamic>.from(j['info'] ?? {}),
  );
}
