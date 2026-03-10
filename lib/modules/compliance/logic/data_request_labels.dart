import 'package:opti_job_app/modules/compliance/models/data_request.dart';

class DataRequestLabels {
  const DataRequestLabels._();

  static String typeLabel(DataRequestType type) {
    return switch (type) {
      DataRequestType.access => 'ACCESO',
      DataRequestType.rectification => 'RECTIFICACIÓN',
      DataRequestType.deletion => 'SUPRESIÓN',
      DataRequestType.limitation => 'LIMITACIÓN',
      DataRequestType.portability => 'PORTABILIDAD',
      DataRequestType.opposition => 'OPOSICIÓN',
      DataRequestType.aiExplanation => 'EXPLICACIÓN IA',
      DataRequestType.salaryComparison => 'COMPARATIVA SALARIAL',
    };
  }

  static String dialogTitle(DataRequestType type) {
    return switch (type) {
      DataRequestType.aiExplanation => 'Explicación humana de IA',
      DataRequestType.salaryComparison => 'Comparativa salarial por sexo',
      _ => 'Ejercicio de ${typeLabel(type)}',
    };
  }

  static String dialogDescription(DataRequestType type) {
    return switch (type) {
      DataRequestType.aiExplanation =>
        'Indica qué decisión asistida por IA quieres que revise una persona.',
      DataRequestType.salaryComparison =>
        'Solicita niveles retributivos medios desglosados por sexo para puestos de igual valor.',
      _ => 'Describe brevemente tu solicitud de ${typeLabel(type)}.',
    };
  }
}
