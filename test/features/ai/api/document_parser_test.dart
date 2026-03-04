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

  test('extractTextFromPdf parses text operators from a text PDF', () {
    const pdf = r'''
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 80 >>
stream
BT
/F1 12 Tf
72 720 Td
(Hola desde PDF) Tj
0 -16 Td
[(Backend) 120 (Engineer)] TJ
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
trailer
<< /Root 1 0 R /Size 5 >>
startxref
0
%%EOF
''';

    final parsed = DocumentParser.extractTextFromPdf(
      Uint8List.fromList(latin1.encode(pdf)),
    );

    expect(parsed, contains('Hola desde PDF'));
    expect(parsed, contains('Backend Engineer'));
  });
}
