class OfertaHipotecaria {
  final String id;
  final String bancoBrokerId;
  final String nombreOferta;
  final String fechaOferta; // ISO8601
  final double capitalSolicitado;
  final int plazoAnios;
  final double comisionAperturaPorcentaje;
  final double gastosTasacion;

  OfertaHipotecaria({
    required this.id,
    required this.bancoBrokerId,
    required this.nombreOferta,
    required this.fechaOferta,
    required this.capitalSolicitado,
    required this.plazoAnios,
    required this.comisionAperturaPorcentaje,
    required this.gastosTasacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bancoBrokerId': bancoBrokerId,
      'nombreOferta': nombreOferta,
      'fechaOferta': fechaOferta,
      'capitalSolicitado': capitalSolicitado,
      'plazoAnios': plazoAnios,
      'comisionAperturaPorcentaje': comisionAperturaPorcentaje,
      'gastosTasacion': gastosTasacion,
    };
  }

  factory OfertaHipotecaria.fromMap(Map<String, dynamic> map) {
    return OfertaHipotecaria(
      id: map['id'],
      bancoBrokerId: map['bancoBrokerId'],
      nombreOferta: map['nombreOferta'],
      fechaOferta: map['fechaOferta'],
      capitalSolicitado: map['capitalSolicitado'] is int ? (map['capitalSolicitado'] as int).toDouble() : map['capitalSolicitado'],
      plazoAnios: map['plazoAnios'],
      comisionAperturaPorcentaje: map['comisionAperturaPorcentaje'] is int ? (map['comisionAperturaPorcentaje'] as int).toDouble() : map['comisionAperturaPorcentaje'],
      gastosTasacion: map['gastosTasacion'] is int ? (map['gastosTasacion'] as int).toDouble() : map['gastosTasacion'],
    );
  }
}
