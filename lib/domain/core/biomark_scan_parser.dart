import 'package:ui_prototype/domain/entities/scan_event.dart';
import 'package:ui_prototype/domain/value_objects/parse_result.dart';


class BiomarkScanParser {

  final _expectedMinTokens = 5;
  final _expectedMaxTokens = 7;



  ParseResult<ScanEvent> parse(String rawLine) {

    //variables that will be used to build the ScanEvent object.
    String? date;
    String? time;
    String? readerId;
    String? id;
    bool isDownloaded = false;
    double? temp;


    var expectedField = 0; //we are expecting the first field to be DATE

    //EXPECTED FIELDS:
    // Index ... Field
    // 0 ....... Date
    // 1 ....... Time
    // 2 ....... Reader Id
    // 3 ....... TAG keyword (just ignored)
    // 4 ....... Asterisk or ID (depending on whether or not its downloaded)
    // 5 ....... ID or Temp (depending on previous field)
    // 6 ....... Temperature
    

    //splitting the line on every whitespace
    List<String> tokens = rawLine.trim().split(RegExp(r'\s+'));

    //verifying the number of tokens is correct
    if(tokens.length > _expectedMaxTokens || tokens.length < _expectedMinTokens) {
      return ParseErr("Invalid PIT Tag Format Detected!");
    }

    for(final token in tokens) {
      switch(expectedField) {
        case 0:
          date = token;
          break;

        case 1:
          time = token;
          break;

        case 2:
          readerId = token;
          break;

        case 3:
          //verifying the TAG keyword is present (verifying BioMark format)
          if(token.trim() != "TAG") {
            return ParseErr("Invalid Tag Format");
          }
          break;

        case 4:
          if(token == "*") {
            isDownloaded = true;
          } else {
            //if the token isn't an asterisk, it is definitely the PIT id
            id = token;
          }
          break;

        case 5:
          // if the tag is downloaded, then THIS is the PIT id 
          // (because the last token was the asterisk)
          // However, if it WASN'T downloaded, then the id was already captured 
          // and this is the temperature value
          if(isDownloaded) {
            id = token;
          } else {
            temp = double.tryParse(token);
          }
          break;
        
        case 6:
          temp = double.tryParse(token);
          break;

        default:
          //extra tokens detected, flag the error
          //TODO: LOG THE ERROR
          break;
      }
      //move on to the next expected data field
      expectedField++;
    }
  
  //verifying important parameters weren't left empty
  if(date == null || time == null || id == null) {
    return ParseErr("Missing Required Fields");
  }

  //constructing the NewScan object containing 
  final newScan = ScanEvent(
    rawLine,
    date,
    time,
    readerId,
    isDownloaded,
    id,
    temp
  );

  return ParseOk(newScan);
  }
}