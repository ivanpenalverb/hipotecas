class Vinculacion {
  final String id;
  final String ofertaId;
  final String tipoVinculacion;
  final double descuentoTin;
  final double costeAnual;
  final bool esObligatorio;

  Vinculacion({
    required this.id,
    required this.ofertaId,
    required this.tipoVinculacion,
    required this.descuentoTin,
    required this.costeAnual,
    required this.esObligatorio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ofertaId': ofertaId,
      'tipoVinculacion': tipoVinculacion,
      'descuentoTin': descuentoTin,
      'costeAnual': costeAnual,
      'esObligatorio': esObligatorio ? 1 : 0,
    };
  }

  factory Vinculacion.fromMap(Map<String, dynamic> map) {
    return Vinculacion(
      id: map['id'],
      ofertaId: map['ofertaId'],
      tipoVinculacion: map['tipoVinculacion'],
      descuentoTin: map['descuentoTin'] is int ? (map['descuentoTin'] as int).toDouble() : map['descuentoTin'],
      costeAnual: map['costeAnual'] is int ? (map['costeAnual'] as int).toDouble() : map['costeAnual'],
      esObligatorio: map['esObligatorio'] == 1,
    );
  }
}
