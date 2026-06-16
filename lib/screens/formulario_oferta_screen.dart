import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/ui_providers.dart';
import '../database/database_helper.dart';
import '../models/banco_broker.dart';
import '../models/oferta_hipotecaria.dart';
import '../models/tramo_interes.dart';
import '../models/vinculacion.dart';

class FormularioOfertaScreen extends ConsumerStatefulWidget {
  const FormularioOfertaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FormularioOfertaScreen> createState() => _FormularioOfertaScreenState();
}

class _FormularioOfertaScreenState extends ConsumerState<FormularioOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _uuid = const Uuid();

  // Paso 1: Básicos
  String? _selectedBancoId;
  final _nombreOfertaCtrl = TextEditingController();
  final _capitalCtrl = TextEditingController();
  final _plazoCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController(text: '0');
  final _tasacionCtrl = TextEditingController(text: '0');

  // Paso 2: Tramos
  final List<_TramoData> _tramosData = [];

  // Paso 3: Vinculaciones
  final List<_VinculacionData> _vinculacionesData = [];

  @override
  void initState() {
    super.initState();
    _tramosData.add(_TramoData());
  }

  @override
  void dispose() {
    _nombreOfertaCtrl.dispose();
    _capitalCtrl.dispose();
    _plazoCtrl.dispose();
    _comisionCtrl.dispose();
    _tasacionCtrl.dispose();
    for (var t in _tramosData) {
      t.dispose();
    }
    for (var v in _vinculacionesData) {
      v.dispose();
    }
    super.dispose();
  }

  void _guardarOferta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBancoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar o crear un banco.')),
      );
      return;
    }

    final ofertaId = _uuid.v4();
    final oferta = OfertaHipotecaria(
      id: ofertaId,
      bancoBrokerId: _selectedBancoId!,
      nombreOferta: _nombreOfertaCtrl.text.trim(),
      fechaOferta: DateTime.now().toIso8601String(),
      capitalSolicitado: double.tryParse(_capitalCtrl.text) ?? 0,
      plazoAnios: int.tryParse(_plazoCtrl.text) ?? 0,
      comisionAperturaPorcentaje: double.tryParse(_comisionCtrl.text) ?? 0,
      gastosTasacion: double.tryParse(_tasacionCtrl.text) ?? 0,
    );

    final tramos = _tramosData.map((t) {
      return TramoInteres(
        id: _uuid.v4(),
        ofertaId: ofertaId,
        anioInicio: int.tryParse(t.anioInicioCtrl.text) ?? 1,
        anioFin: int.tryParse(t.anioFinCtrl.text) ?? oferta.plazoAnios,
        tinBase: double.tryParse(t.tinBaseCtrl.text) ?? 0,
        esVariable: t.esVariable,
        diferencialEuribor: t.esVariable ? (double.tryParse(t.diferencialCtrl.text) ?? 0) : 0,
      );
    }).toList();

    final vinculaciones = _vinculacionesData.map((v) {
      return Vinculacion(
        id: _uuid.v4(),
        ofertaId: ofertaId,
        tipoVinculacion: v.tipoCtrl.text.trim(),
        descuentoTin: double.tryParse(v.descuentoCtrl.text) ?? 0,
        costeAnual: double.tryParse(v.costeCtrl.text) ?? 0,
        esObligatorio: false,
      );
    }).toList();

    try {
      await DatabaseHelper.instance.insertOfertaCompleta(
        oferta: oferta,
        tramos: tramos,
        vinculaciones: vinculaciones,
      );

      ref.invalidate(ofertasProvider);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta guardada correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  void _mostrarDialogoNuevoBanco() {
    final nombreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Banco/Broker'),
          content: TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nombreCtrl.text.trim();
                if (name.isNotEmpty) {
                  final newBanco = BancoBroker(
                    id: _uuid.v4(),
                    nombre: name,
                    tipoEntidad: 'Banco',
                  );
                  await DatabaseHelper.instance.insertBancoBroker(newBanco);
                  ref.invalidate(bancosProvider);
                  Navigator.pop(context);
                  setState(() {
                    _selectedBancoId = newBanco.id;
                  });
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Oferta'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep++;
              });
            } else {
              _guardarOferta();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isLastStep ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isLastStep ? 'Guardar Oferta' : 'Siguiente'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_currentStep == 0 ? 'Cancelar' : 'Atrás'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
          ],
        ),
      ),
    );
  }

  Step _buildStep1() {
    final bancosAsync = ref.watch(bancosProvider);

    return Step(
      title: const Text('Información Básica'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: bancosAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Error al cargar bancos: $e'),
                  data: (bancos) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Banco o Broker'),
                      value: bancos.any((b) => b.id == _selectedBancoId) ? _selectedBancoId : null,
                      items: bancos.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.nombre),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBancoId = val;
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona un banco' : null,
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.secondary,
                tooltip: 'Añadir Banco Nuevo',
                onPressed: _mostrarDialogoNuevoBanco,
              )
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreOfertaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Oferta',
              hintText: 'Ej. Hipoteca Fija Bonificada',
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _capitalCtrl,
                  decoration: const InputDecoration(labelText: 'Capital Solicitado (€)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Obligatorio' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _plazoCtrl,
                  decoration: const InputDecoration(labelText: 'Plazo Total (Años)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Obligatorio' : null,
                  onChanged: (val) {
                     // Auto-actualizar año fin del primer tramo si está por defecto
                     if (_tramosData.isNotEmpty && _tramosData.first.anioFinCtrl.text == '30') {
                        _tramosData.first.anioFinCtrl.text = val;
                     }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _comisionCtrl,
                  decoration: const InputDecoration(labelText: 'Comisión Apertura (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Obligatorio' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _tasacionCtrl,
                  decoration: const InputDecoration(labelText: 'Tasación (€)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Obligatorio' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Tramos de Interés'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          ..._tramosData.asMap().entries.map((entry) {
            int index = entry.key;
            _TramoData t = entry.value;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tramo ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _tramosData[index].dispose();
                                _tramosData.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(t.esVariable ? 'Interés Variable' : 'Interés Fijo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.esVariable ? 'Configura el Euríbor y diferencial' : 'Configura el TIN fijo'),
                      value: t.esVariable,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (val) {
                        setState(() {
                          t.esVariable = val;
                          if (val && (t.tinBaseCtrl.text.isEmpty || t.tinBaseCtrl.text == '0.0')) {
                             t.tinBaseCtrl.text = '3.5'; // Euríbor simulado por defecto
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: t.anioInicioCtrl,
                            decoration: const InputDecoration(labelText: 'Año Inicio'),
                            keyboardType: TextInputType.number,
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: t.anioFinCtrl,
                            decoration: const InputDecoration(labelText: 'Año Fin'),
                            keyboardType: TextInputType.number,
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: t.tinBaseCtrl,
                            decoration: InputDecoration(labelText: t.esVariable ? 'Euríbor simulado (%)' : 'TIN Fijo (%)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Inválido' : null,
                          ),
                        ),
                        if (t.esVariable) const SizedBox(width: 16),
                        if (t.esVariable)
                          Expanded(
                            child: TextFormField(
                              controller: t.diferencialCtrl,
                              decoration: const InputDecoration(labelText: 'Diferencial (%)'),
                              keyboardType: TextInputType.number,
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Inválido' : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                final newTramo = _TramoData();
                if (_tramosData.isNotEmpty) {
                  int lastAnioFin = int.tryParse(_tramosData.last.anioFinCtrl.text) ?? 1;
                  newTramo.anioInicioCtrl.text = (lastAnioFin + 1).toString();
                  newTramo.anioFinCtrl.text = _plazoCtrl.text;
                }
                _tramosData.add(newTramo);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Añadir siguiente tramo'),
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Vinculaciones y Seguros'),
      isActive: _currentStep >= 2,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vinculacionesData.isEmpty)
             Container(
               padding: const EdgeInsets.all(16.0),
               decoration: BoxDecoration(
                 color: Colors.orange.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8)
               ),
               child: const Row(
                 children: [
                   Icon(Icons.info_outline, color: Colors.orange),
                   SizedBox(width: 12),
                   Expanded(child: Text('Sin vinculaciones. Pulsa "Añadir" si quieres incluir seguros, nóminas, etc. para bonificar el TIN.')),
                 ],
               ),
             ),
          const SizedBox(height: 16),
          ..._vinculacionesData.asMap().entries.map((entry) {
            int index = entry.key;
            _VinculacionData v = entry.value;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: v.tipoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Vinculación',
                              hintText: 'Ej. Seguro de Vida',
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _vinculacionesData[index].dispose();
                              _vinculacionesData.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: v.descuentoCtrl,
                            decoration: const InputDecoration(labelText: 'Descuento TIN (%)'),
                            keyboardType: TextInputType.number,
                            validator: (val) => double.tryParse(val ?? '') == null ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: v.costeCtrl,
                            decoration: const InputDecoration(labelText: 'Coste Anual (€)'),
                            keyboardType: TextInputType.number,
                            validator: (val) => double.tryParse(val ?? '') == null ? 'Inválido' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _vinculacionesData.add(_VinculacionData());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Añadir Vinculación'),
          ),
        ],
      ),
    );
  }
}

class _TramoData {
  bool esVariable = false;
  final anioInicioCtrl = TextEditingController(text: '1');
  final anioFinCtrl = TextEditingController(text: '30');
  final tinBaseCtrl = TextEditingController();
  final diferencialCtrl = TextEditingController();

  void dispose() {
    anioInicioCtrl.dispose();
    anioFinCtrl.dispose();
    tinBaseCtrl.dispose();
    diferencialCtrl.dispose();
  }
}

class _VinculacionData {
  final tipoCtrl = TextEditingController();
  final descuentoCtrl = TextEditingController(text: '0.0');
  final costeCtrl = TextEditingController(text: '0.0');

  void dispose() {
    tipoCtrl.dispose();
    descuentoCtrl.dispose();
    costeCtrl.dispose();
  }
}
