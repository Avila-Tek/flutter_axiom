import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// {@template flutter_axiom}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
class FlutterAxiom {
  /// {@macro flutter_axiom}
  const FlutterAxiom({
    required this.token,
    required this.dataset,
  });

  /// API Token
  final String token;

  /// Axiom Dataset
  final String dataset;
}

/// Flutter Axiom Logs service
class FlutterAxiomLogs {
  FlutterAxiomLogs._internal();
  static final FlutterAxiomLogs _instance = FlutterAxiomLogs._internal();

  /// Get instance
  static FlutterAxiomLogs get instance => _instance;

  /// Flutter Axiom Secrets
  late FlutterAxiom flutterAxiom;

  /// Initilize Flutter Axiom Logs service
  void initialize(String token, String dataset) {
    flutterAxiom = FlutterAxiom(token: token, dataset: dataset);
  }

  Future<void> _log(
    List<Map<String, dynamic>> data,
  ) async {
    final dataset = flutterAxiom.dataset;
    final token = flutterAxiom.token;
    final url = Uri.parse('https://api.axiom.co/v1/datasets/$dataset/ingest');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    };

    final body = jsonEncode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // Data successfully ingested
      developer.log('Data successfully ingested', name: 'FlutterAxiomLogs');
    } else {
      //  Error
      developer.log(
        'Error received ${response.statusCode}',
        name: 'FlutterAxiomLogs',
      );
    }
  }

  /// Ingest log to axiom dataset
  Future<void> log({
    required String message,
    String name = '',
    Object? error,
    StackTrace? stackTrace,
    Map<String, String> extra = const {},
  }) async {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
    try {
      // Create an isolate to call the future function
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn<void>(
        (_) async {
          await _log([
            {
              'message': message,
              'name': name,
              ...extra,
            }
          ]);
        },
        receivePort.sendPort,
      );

      // Receive the result from the isolate
      final result = await receivePort.first;
      // Close the receive port and isolate
      receivePort.close();
      isolate.kill();
    } catch (e) {
      developer.log(
        'Error received $e',
        name: 'FlutterAxiomLogs',
      );
    }
  }
}
