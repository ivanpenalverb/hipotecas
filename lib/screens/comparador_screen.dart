import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../providers/calculadora_provider.dart';
import '../models/calculo_models.dart';
import '../models/oferta_hipotecaria.dart';

class ComparadorScreen extends ConsumerStatefulWidget {
  const ComparadorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends ConsumerState<ComparadorScreen> {
  String? _ofertaAId;
  String? _ofertaBId;

  @override
  Widget build(BuildContext context) {
    final ofertasAsync = ref.watch(ofertasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparador Cara a Cara'),
      ),
      body: ofertasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (ofertas) {
          if (ofertas.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Necesitas tener al menos 2 ofertas guardadas para usar el comparador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildCabecera(ofertas),
              const Divider(height: 1),
              Expanded(
                child: (_ofertaAId != null && _ofertaBId != null && _ofertaAId != _ofertaBId)
                    ? _buildComparativa(context)
                    : const Center(
                        child: Text('Selecciona dos ofertas distintas para comparar.'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCabecera(List<OfertaHipotecaria> ofertas) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Oferta A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _ofertaAId,
                  hint: const Text('Seleccionar...'),
                  items: ofertas.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombreOferta, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _ofertaAId = val),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Oferta B', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _ofertaBId,
                  hint: const Text('Seleccionar...'),
                  items: ofertas.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombreOferta, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _ofertaBId = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativa(BuildContext context) {
    final asyncA = ref.watch(ofertaCompletaProvider(_ofertaAId!));
    final asyncB = ref.watch(ofertaCompletaProvider(_ofertaBId!));
    final calcService = ref.watch(calculadoraServiceProvider);

    if (asyncA.isLoading || asyncB.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (asyncA.hasError || asyncB.hasError) {
      return const Center(child: Text('Error al cargar datos'));
    }

    final dataA = asyncA.value!;
    final dataB = asyncB.value!;

    // Simulamos que todas las vinculaciones obligatorias o añadidas están activas
    final resumenA = calcService.calcularCuadroAmortizacion(
      dataA.oferta, dataA.tramos, dataA.vinculaciones, dataA.amortizaciones);
    final resumenB = calcService.calcularCuadroAmortizacion(
      dataB.oferta, dataB.tramos, dataB.vinculaciones, dataB.amortizaciones);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildResultColumn(context, dataA.oferta.nombreOferta, resumenA, resumenB)),
              const SizedBox(width: 16),
              Expanded(child: _buildResultColumn(context, dataB.oferta.nombreOferta, resumenB, resumenA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultColumn(BuildContext context, String nombre, ResumenHipoteca res1, ResumenHipoteca res2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(nombre, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        _buildComparisonCard(
          context,
          'Cuota Mensual (Ini)',
          res1.cuotaInicial,
          res2.cuotaInicial,
          isCurrency: true,
        ),
        _buildComparisonCard(
          context,
          'Total Intereses',
          res1.totalIntereses,
          res2.totalIntereses,
          isCurrency: true,
        ),
        _buildComparisonCard(
          context,
          'Coste Total Operación',
          res1.costeTotalOperacion,
          res2.costeTotalOperacion,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, String label, double val1, double val2, {bool isCurrency = false}) {
    // Es mejor el valor más bajo
    bool isBetter = val1 < val2;
    bool isEqual = val1 == val2;

    Color bgColor = isEqual ? Colors.white : (isBetter ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.05));
    Color textColor = isEqual ? Colors.black87 : (isBetter ? Colors.green[800]! : Colors.red[800]!);

    String displayVal = isCurrency ? '${val1.toStringAsFixed(2)} €' : val1.toStringAsFixed(2);

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isBetter ? Colors.green.withOpacity(0.5) : Colors.transparent),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              displayVal,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
