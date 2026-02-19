import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final projectId =
      Platform.environment['FIREBASE_PROJECT_ID'] ?? 'infojobs-dev';
  final firestoreHost =
      Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? 'localhost:8080';

  final firestoreUri = _buildBaseUri(firestoreHost, defaultPort: 8080);

  stdout.writeln(
    'Seeding Firestore emulator (project=$projectId, firestore=$firestoreUri)',
  );

  final seeder = FirestoreSeeder(
    firestoreBaseUri: firestoreUri,
    projectId: projectId,
  );
  await seeder.seed();
  stdout.writeln('Firestore seed completed successfully.');
}

Uri _buildBaseUri(String host, {required int defaultPort}) {
  final parts = host.split(':');
  final hostname = parts.first;
  final port = parts.length > 1
      ? int.tryParse(parts[1]) ?? defaultPort
      : defaultPort;
  return Uri(scheme: 'http', host: hostname, port: port);
}

class FirestoreSeeder {
  FirestoreSeeder({required this.firestoreBaseUri, required this.projectId});

  final Uri firestoreBaseUri;
  final String projectId;

  Future<void> seed() async {
    await _seedLocationCatalog();

    stdout.writeln(
      '\nCatálogo geográfico sembrado: catalog/provincias_es y catalog_municipios/{provinciaId}',
    );
  }

  Future<void> _seedLocationCatalog() async {
    await _createDoc(
      collection: 'catalog',
      docId: 'provincias_es',
      data: {
        'updated_at': DateTime.now().toUtc(),
        'items': [
          {'id': '08', 'name': 'Barcelona', 'slug': 'barcelona'},
          {'id': '28', 'name': 'Madrid', 'slug': 'madrid'},
          {'id': '46', 'name': 'Valencia', 'slug': 'valencia'},
        ],
      },
    );

    await Future.wait([
      _createDoc(
        collection: 'catalog_municipios',
        docId: '08',
        data: {
          'updated_at': DateTime.now().toUtc(),
          'provincia_id': '08',
          'provincia_name': 'Barcelona',
          'items': [
            {'id': '08019', 'name': 'Barcelona', 'norm': 'barcelona'},
            {'id': '08015', 'name': 'Badalona', 'norm': 'badalona'},
            {
              'id': '08101',
              'name': 'L Hospitalet de Llobregat',
              'norm': 'l hospitalet de llobregat',
            },
            {'id': '08266', 'name': 'Sabadell', 'norm': 'sabadell'},
            {'id': '08279', 'name': 'Terrassa', 'norm': 'terrassa'},
            {'id': '08056', 'name': 'Castelldefels', 'norm': 'castelldefels'},
            {'id': '08113', 'name': 'Manresa', 'norm': 'manresa'},
            {'id': '08121', 'name': 'Mataró', 'norm': 'mataro'},
            {
              'id': '08169',
              'name': 'El Prat de Llobregat',
              'norm': 'el prat de llobregat',
            },
            {
              'id': '08245',
              'name': 'Santa Coloma de Gramenet',
              'norm': 'santa coloma de gramenet',
            },
            {
              'id': '08263',
              'name': 'Sant Cugat del Vallès',
              'norm': 'sant cugat del valles',
            },
            {'id': '08200', 'name': 'Granollers', 'norm': 'granollers'},
            {
              'id': '08904',
              'name': 'Vilanova i la Geltrú',
              'norm': 'vilanova i la geltru',
            },
          ],
        },
      ),
      _createDoc(
        collection: 'catalog_municipios',
        docId: '28',
        data: {
          'updated_at': DateTime.now().toUtc(),
          'provincia_id': '28',
          'provincia_name': 'Madrid',
          'items': [
            {'id': '28079', 'name': 'Madrid', 'norm': 'madrid'},
            {'id': '28005', 'name': 'Alcorcón', 'norm': 'alcorcon'},
            {
              'id': '28007',
              'name': 'Alcalá de Henares',
              'norm': 'alcala de henares',
            },
            {'id': '28013', 'name': 'Aranjuez', 'norm': 'aranjuez'},
            {'id': '28045', 'name': 'Coslada', 'norm': 'coslada'},
            {
              'id': '28049',
              'name': 'Collado Villalba',
              'norm': 'collado villalba',
            },
            {'id': '28058', 'name': 'Fuenlabrada', 'norm': 'fuenlabrada'},
            {'id': '28065', 'name': 'Getafe', 'norm': 'getafe'},
            {'id': '28074', 'name': 'Leganés', 'norm': 'leganes'},
            {'id': '28115', 'name': 'Majadahonda', 'norm': 'majadahonda'},
            {'id': '28148', 'name': 'Móstoles', 'norm': 'mostoles'},
            {'id': '28134', 'name': 'Parla', 'norm': 'parla'},
            {
              'id': '28161',
              'name': 'Pozuelo de Alarcón',
              'norm': 'pozuelo de alarcon',
            },
            {
              'id': '28181',
              'name': 'San Sebastián de los Reyes',
              'norm': 'san sebastian de los reyes',
            },
            {
              'id': '28130',
              'name': 'Paracuellos de Jarama',
              'norm': 'paracuellos de jarama',
            },
          ],
        },
      ),
      _createDoc(
        collection: 'catalog_municipios',
        docId: '46',
        data: {
          'updated_at': DateTime.now().toUtc(),
          'provincia_id': '46',
          'provincia_name': 'Valencia',
          'items': [
            {'id': '46250', 'name': 'València', 'norm': 'valencia'},
            {'id': '46013', 'name': 'Alzira', 'norm': 'alzira'},
            {'id': '46070', 'name': 'Burjassot', 'norm': 'burjassot'},
            {'id': '46094', 'name': 'Cullera', 'norm': 'cullera'},
            {'id': '46131', 'name': 'Gandia', 'norm': 'gandia'},
            {'id': '46102', 'name': 'Mislata', 'norm': 'mislata'},
            {'id': '46184', 'name': 'Ontinyent', 'norm': 'ontinyent'},
            {'id': '46190', 'name': 'Paterna', 'norm': 'paterna'},
            {'id': '46202', 'name': 'Requena', 'norm': 'requena'},
            {'id': '46214', 'name': 'Sagunt', 'norm': 'sagunt'},
            {'id': '46220', 'name': 'Torrent', 'norm': 'torrent'},
            {'id': '46223', 'name': 'Sueca', 'norm': 'sueca'},
            {'id': '46244', 'name': 'Xàtiva', 'norm': 'xativa'},
            {'id': '46145', 'name': 'Llíria', 'norm': 'lliria'},
            {'id': '46147', 'name': 'Manises', 'norm': 'manises'},
          ],
        },
      ),
    ]);
  }

  Future<void> _createDoc({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final uri = firestoreBaseUri.replace(
      path: '/v1/projects/$projectId/databases/(default)/documents/$collection',
      queryParameters: {'documentId': docId},
    );
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );

    if (response.statusCode >= 300) {
      stderr.writeln(
        'Failed to seed $collection/$docId: ${response.statusCode} ${response.body}',
      );
      throw Exception('Firestore seed failed');
    }
  }

  Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is int) {
      return {'integerValue': value.toString()};
    }
    if (value is double) {
      return {'doubleValue': value};
    }
    if (value is bool) {
      return {'booleanValue': value};
    }
    if (value is DateTime) {
      return {'timestampValue': value.toIso8601String()};
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()},
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': _encodeFields(value)},
      };
    }
    return {'stringValue': value.toString()};
  }
}
