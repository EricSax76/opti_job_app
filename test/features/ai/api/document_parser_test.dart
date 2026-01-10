import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/ai/api/document_parser.dart';

void main() {
  test('extractTextFromDocx parses paragraphs and decodes entities', () {
    const xml = '''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:t>Hola</w:t></w:r>
      <w:r><w:t xml:space="preserve"> mundo</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Ingeniería &amp; Datos</w:t></w:r>
    </w:p>
  </w:body>
</w:document>
''';

    final xmlBytes = utf8.encode(xml);
    final archive = Archive()
      ..addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));

    final zipped = ZipEncoder().encode(archive);
    expect(zipped, isNotNull);

    final parsed = DocumentParser.extractTextFromDocx(
      Uint8List.fromList(zipped!),
    );

    expect(parsed, 'Hola mundo\nIngeniería & Datos');
  });
}

