import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/banco_broker.dart';
import '../models/oferta_hipotecaria.dart';
import '../models/tramo_interes.dart';
import '../models/vinculacion.dart';
import '../models/amortizacion_anticipada.dart';

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

class OfertaCompletaData {
  final OfertaHipotecaria oferta;
  final List<TramoInteres> tramos;
  final List<Vinculacion> vinculaciones;
  final List<AmortizacionAnticipada> amortizaciones;

  OfertaCompletaData(this.oferta, this.tramos, this.vinculaciones, this.amortizaciones);
}

final ofertaCompletaProvider = FutureProvider.family<OfertaCompletaData, String>((ref, ofertaId) async {
  final oferta = await DatabaseHelper.instance.getOfertaById(ofertaId);
  if (oferta == null) throw Exception("Oferta no encontrada");
  final tramos = await DatabaseHelper.instance.getTramosPorOferta(ofertaId);
  final vinculaciones = await DatabaseHelper.instance.getVinculacionesPorOferta(ofertaId);
  final amortizaciones = await DatabaseHelper.instance.getAmortizacionesPorOferta(ofertaId);
  
  return OfertaCompletaData(oferta, tramos, vinculaciones, amortizaciones);
});
