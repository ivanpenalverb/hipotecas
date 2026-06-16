import 'dart:math';
import '../models/oferta_hipotecaria.dart';
import '../models/tramo_interes.dart';
import '../models/vinculacion.dart';
import '../models/amortizacion_anticipada.dart';
import '../models/calculo_models.dart';

class CalculadoraService {
  final Map<String, ResumenHipoteca> _cache = {};

  String _generateCacheKey(
    OfertaHipotecaria oferta,
    List<Vinculacion> vinculacionesActivas,
    List<AmortizacionAnticipada> amortizaciones,
  ) {
    // Ordenamos IDs para que la misma combinación siempre de el mismo string
    var vinculacionesIds = vinculacionesActivas.map((v) => v.id).toList()..sort();
    var amortizacionesIds = amortizaciones.map((a) => a.id).toList()..sort();
    return "${oferta.id}_${oferta.capitalSolicitado}_${oferta.plazoAnios}_${vinculacionesIds.join('-')}_${amortizacionesIds.join('-')}";
  }

  ResumenHipoteca calcularCuadroAmortizacion(
    OfertaHipotecaria oferta,
    List<TramoInteres> tramos,
    List<Vinculacion> vinculacionesActivas,
    List<AmortizacionAnticipada> amortizaciones,
  ) {
    final cacheKey = _generateCacheKey(oferta, vinculacionesActivas, amortizaciones);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    double capitalPendiente = oferta.capitalSolicitado;
    int plazoMesesTotal = oferta.plazoAnios * 12;
    int mesesRestantes = plazoMesesTotal;
    
    double totalIntereses = 0;
    double costeTotalVinculaciones = 0;
    double cuotaInicial = 0;
    
    List<MesAmortizacion> cuadro = [];

    // Calcular coste de vinculaciones
    double costeMensualVinculaciones = vinculacionesActivas.fold(
      0.0, 
      (sum, v) => sum + (v.costeAnual / 12)
    );

    double descuentoTinTotal = vinculacionesActivas.fold(
      0.0, 
      (sum, v) => sum + v.descuentoTin
    );

    for (int mes = 1; mes <= plazoMesesTotal; mes++) {
      if (capitalPendiente <= 0) break;

      int anioActual = ((mes - 1) ~/ 12) + 1;
      
      // Buscar tramo actual
      TramoInteres? tramoActual;
      for (var t in tramos) {
        if (anioActual >= t.anioInicio && anioActual <= t.anioFin) {
          tramoActual = t;
          break;
        }
      }
      
      // Fallback en caso de que falten tramos
      if (tramoActual == null) {
        if (tramos.isNotEmpty) {
           tramoActual = tramos.last;
        } else {
           throw Exception("No hay tramos de interés definidos");
        }
      }

      double tinBase = tramoActual.tinBase;
      if (tramoActual.esVariable) {
        tinBase += tramoActual.diferencialEuribor;
      }

      double tinAplicado = tinBase - descuentoTinTotal;
      if (tinAplicado < 0) tinAplicado = 0;

      double r = (tinAplicado / 100) / 12;
      double cuota;
      
      if (r == 0) {
        cuota = capitalPendiente / mesesRestantes;
      } else {
        cuota = capitalPendiente * (r / (1 - pow(1 + r, -mesesRestantes)));
      }

      if (mes == 1) {
        cuotaInicial = cuota;
      }

      double interesesDelMes = capitalPendiente * r;
      double capitalAmortizado = cuota - interesesDelMes;

      if (capitalAmortizado > capitalPendiente) {
        capitalAmortizado = capitalPendiente;
        cuota = capitalAmortizado + interesesDelMes;
      }

      capitalPendiente -= capitalAmortizado;
      totalIntereses += interesesDelMes;
      costeTotalVinculaciones += costeMensualVinculaciones;

      // Amortizaciones anticipadas en el mes actual
      var amortizacionesDelMes = amortizaciones.where((a) => a.mesNumero == mes).toList();
      for (var amortizacion in amortizacionesDelMes) {
        double cantidadAmortizada = amortizacion.cantidad;
        if (cantidadAmortizada > capitalPendiente) {
          cantidadAmortizada = capitalPendiente;
        }
        
        capitalPendiente -= cantidadAmortizada;

        if (amortizacion.tipoAmortizacion == 'ReducirPlazo') {
          if (capitalPendiente > 0) {
             if (r == 0) {
               mesesRestantes = (capitalPendiente / cuota).ceil();
             } else {
               double divisor = 1 - (capitalPendiente * r) / cuota;
               if (divisor <= 0) {
                 mesesRestantes = 1;
               } else {
                 mesesRestantes = (-log(divisor) / log(1 + r)).ceil();
               }
             }
          }
        }
      }

      cuadro.add(MesAmortizacion(
        numeroMes: mes,
        cuotaTotal: cuota,
        interesesPagados: interesesDelMes,
        capitalAmortizado: capitalAmortizado,
        capitalPendiente: capitalPendiente,
        tinAplicado: tinAplicado,
      ));

      mesesRestantes--;
      
      if (capitalPendiente < 0.01) {
        capitalPendiente = 0;
      }
    }

    double costeTotalOperacion = oferta.capitalSolicitado + totalIntereses + costeTotalVinculaciones + 
        (oferta.capitalSolicitado * (oferta.comisionAperturaPorcentaje / 100)) + oferta.gastosTasacion;

    final resumen = ResumenHipoteca(
      totalIntereses: totalIntereses,
      costeTotalOperacion: costeTotalOperacion,
      cuotaInicial: cuotaInicial,
      mesesReales: cuadro.length,
      cuadroAmortizacion: cuadro,
    );
    
    _cache[cacheKey] = resumen;
    return resumen;
  }
}
