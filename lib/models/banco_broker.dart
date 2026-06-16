class BancoBroker {
  final String id;
  final String nombre;
  final String tipoEntidad; // 'Banco' o 'Broker'
  final String? contactoGestor;
  final String? notas;

  BancoBroker({
    required this.id,
    required this.nombre,
    required this.tipoEntidad,
    this.contactoGestor,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipoEntidad': tipoEntidad,
      'contactoGestor': contactoGestor,
      'notas': notas,
    };
  }

  factory BancoBroker.fromMap(Map<String, dynamic> map) {
    return BancoBroker(
      id: map['id'],
      nombre: map['nombre'],
      tipoEntidad: map['tipoEntidad'],
      contactoGestor: map['contactoGestor'],
      notas: map['notas'],
    );
  }
}
