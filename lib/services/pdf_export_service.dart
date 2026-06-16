import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/oferta_hipotecaria.dart';
import '../models/calculo_models.dart';

class PdfExportService {
  static Future<Uint8List> generateHipotecaPdf(OfertaHipotecaria oferta, ResumenHipoteca resumen) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(oferta),
            pw.SizedBox(height: 20),
            _buildResumenFinanciero(resumen),
            pw.SizedBox(height: 20),
            pw.Text('Cuadro de Amortización (Resumido)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildAmortizationTable(resumen.cuadroAmortizacion),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(OfertaHipotecaria oferta) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Oferta Hipotecaria: ${oferta.nombreOferta}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 8),
        pw.Text('Capital Solicitado: ${oferta.capitalSolicitado.toStringAsFixed(2)} €', style: const pw.TextStyle(fontSize: 14)),
        pw.Text('Plazo Total: ${oferta.plazoAnios} años', style: const pw.TextStyle(fontSize: 14)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildResumenFinanciero(ResumenHipoteca resumen) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Resumen Financiero', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cuota Mensual (Inicial):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${resumen.cuotaInicial.toStringAsFixed(2)} €'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total de Intereses a Pagar:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${resumen.totalIntereses.toStringAsFixed(2)} €'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Coste Total de la Operación:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${resumen.costeTotalOperacion.toStringAsFixed(2)} €'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAmortizationTable(List<MesAmortizacion> cuadro) {
    // Para no saturar el PDF, mostramos solo los primeros 12 meses y cada hito anual, y el último mes.
    List<MesAmortizacion> resumido = [];
    for (int i = 0; i < cuadro.length; i++) {
      if (i < 12 || (i + 1) % 12 == 0 || i == cuadro.length - 1) {
        resumido.add(cuadro[i]);
      }
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Mes', 'Cuota (€)', 'Intereses (€)', 'Amortizado (€)', 'Pendiente (€)'],
      data: resumido.map((m) {
        return [
          m.numeroMes.toString(),
          m.cuotaTotal.toStringAsFixed(2),
          m.interesesPagados.toStringAsFixed(2),
          m.capitalAmortizado.toStringAsFixed(2),
          m.capitalPendiente.toStringAsFixed(2),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellAlignment: pw.Alignment.centerRight,
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
    );
  }
}
