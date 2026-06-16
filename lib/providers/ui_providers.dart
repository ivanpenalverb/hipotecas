import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/banco_broker.dart';
import '../models/oferta_hipotecaria.dart';
import '../models/tramo_interes.dart';

final bancosProvider = FutureProvider<List<BancoBroker>>((ref) async {
  return await DatabaseHelper.instance.getBancosBrokers();
});

final ofertasProvider = FutureProvider<List<OfertaHipotecaria>>((ref) async {
  return await DatabaseHelper.instance.getOfertasHipotecarias();
});

// Helper provider to get tramos for a specific oferta
final tramosProvider = FutureProvider.family<List<TramoInteres>, String>((ref, ofertaId) async {
  return await DatabaseHelper.instance.getTramosPorOferta(ofertaId);
});
