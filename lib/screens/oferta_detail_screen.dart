import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import '../providers/calculadora_provider.dart';
import '../models/calculo_models.dart';
import '../models/vinculacion.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import '../services/pdf_export_service.dart';

class OfertaDetailScreen extends ConsumerStatefulWidget {
  final String ofertaId;
  const OfertaDetailScreen({Key? key, required this.ofertaId}) : super(key: key);

  @override
  ConsumerState<OfertaDetailScreen> createState() => _OfertaDetailScreenState();
}

class _OfertaDetailScreenState extends ConsumerState<OfertaDetailScreen> {
  // Mapa para controlar qué vinculaciones están activas: id -> booleano
  final Map<String, bool> _vinculacionesActivas = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final ofertaAsync = ref.watch(ofertaCompletaProvider(widget.ofertaId));
    final calculadoraService = ref.watch(calculadoraServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador y Detalle'),
        actions: [
          ofertaAsync.maybeWhen(
            data: (data) {
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar a PDF',
                onPressed: () async {
                  List<Vinculacion> activas = data.vinculaciones
                      .where((v) => _vinculacionesActivas[v.id] == true)
                      .toList();
                  ResumenHipoteca resumen = calculadoraService.calcularCuadroAmortizacion(
                    data.oferta,
                    data.tramos,
                    activas,
                    data.amortizaciones,
                  );
                  final pdfBytes = await PdfExportService.generateHipotecaPdf(data.oferta, resumen);
                  await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ofertaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          // Inicializar estado local si no se ha hecho
          if (!_initialized) {
            for (var v in data.vinculaciones) {
              _vinculacionesActivas[v.id] = true; // Empiezan activas
            }
            _initialized = true;
          }

          // Filtrar las vinculaciones activas para el cálculo
          List<Vinculacion> activas = data.vinculaciones
              .where((v) => _vinculacionesActivas[v.id] == true)
              .toList();

          // Realizar cálculo matemático
          ResumenHipoteca resumen = calculadoraService.calcularCuadroAmortizacion(
            data.oferta,
            data.tramos,
            activas,
            data.amortizaciones,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildResumenFinanciero(context, resumen, data.oferta.nombreOferta),
              ),
              if (data.vinculaciones.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildPanelSimulaciones(context, data.vinculaciones),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarCuadroAmortizacion(context, resumen.cuadroAmortizacion),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Ver Cuadro de Amortización Completo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumenFinanciero(BuildContext context, ResumenHipoteca resumen, String nombreOferta) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nombreOferta,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTarjetaDestacada(
                  context,
                  'Cuota Inicial',
                  '${resumen.cuotaInicial.toStringAsFixed(2)} €/mes',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTarjetaDestacada(
                  context,
                  'Total Intereses',
                  '${resumen.totalIntereses.toStringAsFixed(0)} €',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTarjetaDestacada(
            context,
            'Coste Total Operación',
            '${resumen.costeTotalOperacion.toStringAsFixed(0)} €',
            Icons.account_balance,
            isLarge: true,
          ),
          const SizedBox(height: 24),
          _buildGraficoDistribucion(context, resumen),
        ],
      ),
    );
  }

  Widget _buildGraficoDistribucion(BuildContext context, ResumenHipoteca resumen) {
    double capital = resumen.cuadroAmortizacion.isNotEmpty 
        ? resumen.cuadroAmortizacion.fold(0.0, (sum, m) => sum + m.capitalAmortizado) 
        : 0;
    double intereses = resumen.totalIntereses;
    double otrosGastos = resumen.costeTotalOperacion - capital - intereses;
    if (otrosGastos < 0) otrosGastos = 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Distribución del Coste', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Theme.of(context).colorScheme.primary,
                      value: capital,
                      title: 'Capital\n${(capital / resumen.costeTotalOperacion * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: intereses,
                      title: 'Intereses\n${(intereses / resumen.costeTotalOperacion * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (otrosGastos > 0)
                      PieChartSectionData(
                        color: Colors.grey,
                        value: otrosGastos,
                        title: 'Extra\n${(otrosGastos / resumen.costeTotalOperacion * 100).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLeyendaItem(Theme.of(context).colorScheme.primary, 'Capital'),
                const SizedBox(width: 12),
                _buildLeyendaItem(Colors.orange, 'Intereses'),
                const SizedBox(width: 12),
                _buildLeyendaItem(Colors.grey, 'Gastos Extra'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String texto) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTarjetaDestacada(BuildContext context, String titulo, String valor, IconData icono, {bool isLarge = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.secondary, size: isLarge ? 32 : 24),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: isLarge
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                  : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSimulaciones(BuildContext context, List<Vinculacion> vinculaciones) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simulador de Vinculaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Activa o desactiva productos para ver cómo impacta en tu cuota al instante.'),
          const SizedBox(height: 16),
          ...vinculaciones.map((v) {
            final activa = _vinculacionesActivas[v.id] ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(v.tipoVinculacion, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Descuento TIN: ${v.descuentoTin}%  |  Coste: ${v.costeAnual}€/año'),
                value: activa,
                activeColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool val) {
                  setState(() {
                    _vinculacionesActivas[v.id] = val;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _mostrarCuadroAmortizacion(BuildContext context, List<MesAmortizacion> cuadro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text('Cuadro de Amortización', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: cuadro.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final mes = cuadro[index];
                        return Row(
                          children: [
                            SizedBox(width: 40, child: Text('${mes.numeroMes}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cuota: ${mes.cuotaTotal.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Intereses: ${mes.interesesPagados.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Pendiente: ${mes.capitalPendiente.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('Amortizado: ${mes.capitalAmortizado.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
