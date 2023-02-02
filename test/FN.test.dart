


import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:common/common.dart';
import 'package:common/src/common.log.dart';
import 'package:test/test.dart';

final sep = Path.separator;
final rsep = sep == r'\'
             ? r'/'
             : r'\';
String rectifyPathSeparator(String path) {
   if (!path.contains(sep))
      path = path.replaceAll(rsep, sep);
   return path;
   //return combinePath(path, sep);
}

String getScriptPath(Uri uri, [String script_name]) {
   if (script_name == null)
      return rectifyPathSeparator(
         Path.dirname(uri.toString()).split('file:///')[1]
      );
   return Path.join(rectifyPathSeparator(
      Path.dirname(uri.toString()).split('file:///')[1]
   ), script_name);
}



void main(){
   final list = List.generate(12, (i) => i+1).toList();
   group("FN.dimensionList", (){
      test("transform one dimension into one dimension", (){
         expect(FN.asTwoDimensionList(list, 1), equals(
            [[1], [2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]]
         ));
      });
      test("transform one dimension into two dimension", (){
         expect(FN.asTwoDimensionList(list, 2), orderedEquals(
            [[1,2], [3,4],[5,6],[7,8],[9,10],[11,12]]
         ));
      });
      test("transform one dimension into three dimension", (){
         expect(FN.asTwoDimensionList(list, 3), orderedEquals(
            [[1,2,3], [4,5,6],[7,8,9],[10,11,12]]
         ));
      });
      test("transform one dimension into four dimension", (){
         expect(FN.asTwoDimensionList(list, 3), orderedEquals(
            [[1,2,3,4], [5,6,7,8],[9,10,11,12]]
         ));
      });
   });
   
   group("TimeStampFileLogger", (){
      TimeStampFileLogger logger;
      String path;
      String initialLog;
      List<String> initialContent;
      List<String> record1 = [
        'hello', 'wolrd', 'I have', 'a dream'
      ];
      bool emptyLog;
      
      
      setUpAll(() {
         path = Path.join(getScriptPath(Platform.script), "log.log");
         initialLog = File(path).readAsStringSync();
         initialContent = initialLog.split('\n').where((x) => x.isNotEmpty).toList();
         emptyLog = initialLog.isEmpty;
         logger = TimeStampFileLogger(path: path, duplicate: false, storeExtra: true);
      });
      
//      tearDownAll((){
//         logger.close();
//      });
      
      test('init test expect previous log to be stored or completedly a new one', (){
         if (emptyLog){
            print('rawdata isEmpty..');
            print('initialLog: $initialLog');
            print('logData: ${logger.logData}');
            expect(emptyLog, isTrue);
            expect(logger.logData.isEmpty, isTrue);
         } else {
            print('rawdata isNotEmpty..');
            print('initialLog: $initialLog');
            print('logData: ${logger.logData}');
            expect(logger.logData.isEmpty, isFalse);
            expect(logger.logData, unorderedEquals(initialContent));
            expect(emptyLog, isFalse);
         }
      });
      
      test('log record 1', (){
         final l = logger.logData.length;
         int counter = -1;
         print('logData before: ${logger.logData}');
         record1.forEach((log){
            counter ++;
            logger.log( key:  'read', data: log, supplement: 'bookmark:$counter');
         });
         logger.close();
         print('logData after: ${logger.logData}');
         print('extra        : ${logger.logDataExtra}');

         expect(logger.logData.length, equals(l + record1.length));
         expect(logger.logDataExtra.length, logger.logData.length);
      });
   });
}