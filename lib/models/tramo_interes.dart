class TramoInteres {
  final String id;
  final String ofertaId;
  final int anioInicio;
  final int anioFin;
  final double tinBase;
  final bool esVariable;
  final double diferencialEuribor;

  TramoInteres({
    required this.id,
    required this.ofertaId,
    required this.anioInicio,
    required this.anioFin,
    required this.tinBase,
    required this.esVariable,
    required this.diferencialEuribor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ofertaId': ofertaId,
      'anioInicio': anioInicio,
      'anioFin': anioFin,
      'tinBase': tinBase,
      'esVariable': esVariable ? 1 : 0,
      'diferencialEuribor': diferencialEuribor,
    };
  }

  factory TramoInteres.fromMap(Map<String, dynamic> map) {
    return TramoInteres(
      id: map['id'],
      ofertaId: map['ofertaId'],
      anioInicio: map['anioInicio'],
      anioFin: map['anioFin'],
      tinBase: map['tinBase'] is int ? (map['tinBase'] as int).toDouble() : map['tinBase'],
      esVariable: map['esVariable'] == 1,
      diferencialEuribor: map['diferencialEuribor'] is int ? (map['diferencialEuribor'] as int).toDouble() : map['diferencialEuribor'],
    );
  }
}
