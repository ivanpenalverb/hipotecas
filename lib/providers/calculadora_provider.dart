import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/calculadora_service.dart';

final calculadoraServiceProvider = Provider<CalculadoraService>((ref) {
  return CalculadoraService();
});
