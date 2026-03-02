class ScanEvent {
  final String raw;
  final String? date;
  final String? time;
  final String? readerId;
  final bool? downloaded;
  final String? id;
  final double? temp;

  ScanEvent(
    this.raw,
    this.date,
    this.time,
    this.readerId,
    this.downloaded,
    this.id,
    this.temp,
  );

}