import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/day_record.dart';

class ExportService {
  static Future<void> exportCsv(List<DayRecord> records) async {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Registros,Total (ml),Objetivo (ml),Cumplido');

    // Sort oldest first
    final sorted = [...records]..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    for (final r in sorted) {
      buffer.writeln(
        '${r.dateKey},${r.glasses},${r.totalMl},${r.goalMl},${r.goalMet ? "Si" : "No"}',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aguahoy_historial.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'AguaHoy - Historial de hidratacion',
    );
  }
}
