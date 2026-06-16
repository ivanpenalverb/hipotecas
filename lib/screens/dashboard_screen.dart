import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ui_providers.dart';
import 'formulario_oferta_screen.dart';
import '../providers/ui_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ofertasAsyncValue = ref.watch(ofertasProvider);
    final bancosAsyncValue = ref.watch(bancosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hipotecas'),
      ),
      body: ofertasAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (ofertas) {
          if (ofertas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes ofertas guardadas.\n¡Empieza a comparar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ofertas.length,
            itemBuilder: (context, index) {
              final oferta = ofertas[index];
              
              // Intentar buscar el nombre del banco si tenemos la lista de bancos cargada
              String nombreBanco = 'Desconocido';
              bancosAsyncValue.whenData((bancos) {
                try {
                  final banco = bancos.firstWhere((b) => b.id == oferta.bancoBrokerId);
                  nombreBanco = banco.nombre;
                } catch (_) {}
              });

              // Para el TIN base usamos el provider de tramos
              final tramosAsyncValue = ref.watch(tramosProvider(oferta.id));

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nombreBanco,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${oferta.capitalSolicitado.toStringAsFixed(0)} €',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        oferta.nombreOferta,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoColumn(
                            context, 
                            'Plazo', 
                            '${oferta.plazoAnios} años',
                          ),
                          tramosAsyncValue.when(
                            loading: () => const SizedBox(width: 50, height: 20, child: LinearProgressIndicator()),
                            error: (_, __) => _buildInfoColumn(context, 'TIN Base', 'Error'),
                            data: (tramos) {
                              String tinText = 'N/A';
                              if (tramos.isNotEmpty) {
                                // Asumimos que el primer tramo es el inicial y lo ordenamos por si acaso
                                tramos.sort((a, b) => a.anioInicio.compareTo(b.anioInicio));
                                double tinBase = tramos.first.tinBase;
                                tinText = '${tinBase.toStringAsFixed(2)}%';
                              }
                              return _buildInfoColumn(context, 'TIN Base', tinText);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormularioOfertaScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Añadir Oferta',
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
