class AmortizacionAnticipada {
  final String id;
  final String ofertaId;
  final int mesNumero;
  final double cantidad;
  final String tipoAmortizacion; // 'ReducirCuota' o 'ReducirPlazo'

  AmortizacionAnticipada({
    required this.id,
    required this.ofertaId,
    required this.mesNumero,
    required this.cantidad,
    required this.tipoAmortizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ofertaId': ofertaId,
      'mesNumero': mesNumero,
      'cantidad': cantidad,
      'tipoAmortizacion': tipoAmortizacion,
    };
  }

  factory AmortizacionAnticipada.fromMap(Map<String, dynamic> map) {
    return AmortizacionAnticipada(
      id: map['id'],
      ofertaId: map['ofertaId'],
      mesNumero: map['mesNumero'],
      cantidad: map['cantidad'] is int ? (map['cantidad'] as int).toDouble() : map['cantidad'],
      tipoAmortizacion: map['tipoAmortizacion'],
    );
  }
}
