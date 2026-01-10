import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class DocumentParser {
  /// Extrae texto plano de un archivo .docx (Word)
  static String extractTextFromDocx(Uint8List bytes) {
    try {
      // 1. Descomprimir el archivo (docx es un zip)
      final archive = ZipDecoder().decodeBytes(bytes);

      // 2. Buscar el archivo principal 'word/document.xml'
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml == null) return '';

      // 3. Decodificar bytes a string XML
      final xmlContent = utf8.decode(
        documentXml.content as List<int>,
        allowMalformed: true,
      );

      // 4. Extraer texto limpiando tags XML
      // Buscamos los tags <w:t> (texto) y <w:p> (párrafos)
      return _parseDocxXml(xmlContent);
    } catch (e) {
      return '';
    }
  }

  static String _parseDocxXml(String xml) {
    final buffer = StringBuffer();

    // Método simple usando Regex para evitar dependencia pesada de XML.
    // Importante: `document.xml` suele contener saltos de línea/indentación,
    // así que necesitamos `dotAll: true` para capturar contenido multilínea.
    final paragraphRegex = RegExp(r'<w:p\b.*?>.*?<\/w:p>', dotAll: true);
    final textRegex = RegExp(r'<w:t\b.*?>(.*?)<\/w:t>', dotAll: true);

    final paragraphs = paragraphRegex.allMatches(xml);

    for (final p in paragraphs) {
      final pContent = p.group(0) ?? '';
      final texts = textRegex.allMatches(pContent);

      if (texts.isNotEmpty) {
        for (final t in texts) {
          buffer.write(_decodeXmlEntities(t.group(1) ?? ''));
        }
        buffer.write('\n'); // Salto de línea por párrafo
      }
    }

    return buffer.toString().trim();
  }

  static String _decodeXmlEntities(String value) {
    var decoded = value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    decoded = decoded.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (m) {
      final codePoint = int.tryParse(m.group(1)!, radix: 16);
      return codePoint == null ? m.group(0)! : String.fromCharCode(codePoint);
    });

    decoded = decoded.replaceAllMapped(RegExp(r'&#([0-9]+);'), (m) {
      final codePoint = int.tryParse(m.group(1)!);
      return codePoint == null ? m.group(0)! : String.fromCharCode(codePoint);
    });

    return decoded;
  }
}
