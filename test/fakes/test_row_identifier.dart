import 'package:crab_cakes/domain/entities/row_identifier.dart';

class TestRowIdentifier extends RowIdentifier {

  final int id;

  TestRowIdentifier(this.id);

  @override
  get identifier => id;
  
}