class ImportRequest {
  ImportRequest({
    required this.provider,
    required this.query,
  });

  final String provider;
  final String query;
}

class ImportService {
  final List<ImportRequest> _requests = <ImportRequest>[];

  List<ImportRequest> get requests => List<ImportRequest>.unmodifiable(_requests);

  void queueImport({required String provider, required String query}) {
    _requests.add(ImportRequest(provider: provider, query: query));
  }
}
