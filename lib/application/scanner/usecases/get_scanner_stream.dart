import 'package:crab_cakes/application/scanner/interfaces/scanner_stream_repo.dart';

class GetScannerStream {
  final ScannerStreamRepo streamRepo;

  GetScannerStream(this.streamRepo);

  Stream<String> execute() {
    return streamRepo.getStringStream();
  }
}