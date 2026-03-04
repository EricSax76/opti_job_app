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

  /// Extrae texto de PDFs "text-based" (no OCR) usando un parser ligero.
  /// 1) Busca operadores de texto en el contenido bruto.
  /// 2) Intenta descomprimir streams FlateDecode y vuelve a extraer.
  static String extractTextFromPdf(Uint8List bytes) {
    try {
      final raw = latin1.decode(bytes, allowInvalid: true);
      final chunks = <String>[raw, ..._decodePdfStreams(bytes, raw)];
      final extracted = <String>[];

      for (final chunk in chunks) {
        final text = _extractPdfTextOperators(chunk);
        if (text.isNotEmpty) {
          extracted.add(text);
        }
      }

      if (extracted.isEmpty) return '';
      final combined = extracted.join('\n');
      return _normalizeLines(combined);
    } catch (_) {
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

  static List<String> _decodePdfStreams(Uint8List bytes, String raw) {
    final decoded = <String>[];
    final streamHeader = RegExp(r'<<(.*?)>>\s*stream\r?\n', dotAll: true);
    for (final match in streamHeader.allMatches(raw)) {
      final dict = match.group(1) ?? '';
      final start = match.end;

      final end = _findStreamEnd(raw, start);
      if (end <= start || end > bytes.length) continue;

      final streamBytes = bytes.sublist(start, end);
      final isFlate = dict.contains('/FlateDecode');
      try {
        if (isFlate) {
          final inflated = ZLibDecoder().decodeBytes(streamBytes, verify: false);
          decoded.add(latin1.decode(inflated, allowInvalid: true));
        } else {
          decoded.add(latin1.decode(streamBytes, allowInvalid: true));
        }
      } catch (_) {
        // Ignorar streams corruptos o no decodificables.
      }
    }
    return decoded;
  }

  static int _findStreamEnd(String raw, int start) {
    final endCandidates = [
      raw.indexOf('\nendstream', start),
      raw.indexOf('\rendstream', start),
      raw.indexOf('endstream', start),
    ].where((index) => index >= 0);
    if (endCandidates.isEmpty) return -1;
    return endCandidates.reduce((a, b) => a < b ? a : b);
  }

  static String _extractPdfTextOperators(String source) {
    final buffer = StringBuffer();

    // Arrays de texto: [(Hola) 120 (mundo)] TJ
    final tjArrayRegex = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
    final literalRegex = RegExp(r'\(([^()]*(?:\\.[^()]*)*)\)', dotAll: true);
    for (final arrayMatch in tjArrayRegex.allMatches(source)) {
      final arrayBody = arrayMatch.group(1) ?? '';
      final parts = <String>[];
      for (final literal in literalRegex.allMatches(arrayBody)) {
        final value = _decodePdfEscapedString(literal.group(1) ?? '');
        if (value.isNotEmpty) parts.add(value);
      }
      if (parts.isNotEmpty) {
        buffer.writeln(parts.join(' '));
      }
    }

    // Texto directo: (Hola mundo) Tj
    final tjRegex = RegExp(r'\(([^()]*(?:\\.[^()]*)*)\)\s*Tj', dotAll: true);
    for (final match in tjRegex.allMatches(source)) {
      final value = _decodePdfEscapedString(match.group(1) ?? '');
      if (value.isNotEmpty) {
        buffer.writeln(value);
      }
    }

    // Hex strings: <486f6c61> Tj
    final hexRegex = RegExp(r'<([0-9A-Fa-f]+)>\s*Tj');
    for (final match in hexRegex.allMatches(source)) {
      final value = _decodePdfHex(match.group(1) ?? '');
      if (value.isNotEmpty) {
        buffer.writeln(value);
      }
    }

    return buffer.toString().trim();
  }

  static String _decodePdfEscapedString(String value) {
    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final current = value[i];
      if (current != r'\') {
        out.write(current);
        continue;
      }

      if (i + 1 >= value.length) break;
      final next = value[++i];
      switch (next) {
        case 'n':
          out.write('\n');
          break;
        case 'r':
          out.write('\r');
          break;
        case 't':
          out.write('\t');
          break;
        case 'b':
          out.write('\b');
          break;
        case 'f':
          out.write('\f');
          break;
        case '(':
        case ')':
        case r'\':
          out.write(next);
          break;
        default:
          // Secuencia octal \ddd
          if (_isOctalDigit(next)) {
            final octal = StringBuffer()..write(next);
            for (var k = 0; k < 2 && i + 1 < value.length; k++) {
              final peek = value[i + 1];
              if (!_isOctalDigit(peek)) break;
              octal.write(peek);
              i++;
            }
            final code = int.tryParse(octal.toString(), radix: 8);
            if (code != null) {
              out.writeCharCode(code);
            }
          } else {
            out.write(next);
          }
      }
    }
    return out.toString().trim();
  }

  static String _decodePdfHex(String hex) {
    final normalized = hex.length.isOdd ? '${hex}0' : hex;
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      final chunk = normalized.substring(i, i + 2);
      final value = int.tryParse(chunk, radix: 16);
      if (value != null) bytes.add(value);
    }
    if (bytes.isEmpty) return '';
    return latin1.decode(bytes, allowInvalid: true).trim();
  }

  static bool _isOctalDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 55;

  static String _normalizeLines(String source) {
    return source
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }
}
