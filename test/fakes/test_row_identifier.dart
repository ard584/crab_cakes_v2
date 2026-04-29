import 'package:ui_prototype/domain/entities/row_identifier.dart';

class TestRowIdentifier extends RowIdentifier {

  final int id;

  TestRowIdentifier(this.id);

  @override
  get identifier => id;
  
}