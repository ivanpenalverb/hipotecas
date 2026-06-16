class MesAmortizacion {
  final int numeroMes;
  final double cuotaTotal;
  final double interesesPagados;
  final double capitalAmortizado;
  final double capitalPendiente;
  final double tinAplicado;

  MesAmortizacion({
    required this.numeroMes,
    required this.cuotaTotal,
    required this.interesesPagados,
    required this.capitalAmortizado,
    required this.capitalPendiente,
    required this.tinAplicado,
  });
}

class ResumenHipoteca {
  final double totalIntereses;
  final double costeTotalOperacion;
  final double cuotaInicial;
  final int mesesReales;
  final List<MesAmortizacion> cuadroAmortizacion;

  ResumenHipoteca({
    required this.totalIntereses,
    required this.costeTotalOperacion,
    required this.cuotaInicial,
    required this.mesesReales,
    required this.cuadroAmortizacion,
  });
}
