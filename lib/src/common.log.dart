import 'dart:async';
import 'dart:math';

import 'package:colorize/colorize.dart' show Colorize, Styles;
import 'dart:io';

enum ELevel {
   log,
   info,
   debug,
   warning,
   critical,
   sys,
   error,
   level0,
   level1,
   level2,
   level3,
   level4,
}

const LEVEL0 = [ELevel.log, ELevel.info, ELevel.error, ELevel.debug, ELevel.warning, ELevel.critical, ELevel.sys];
const LEVEL1 = [ELevel.info, ELevel.error, ELevel.debug, ELevel.warning, ELevel.critical, ELevel.sys];
const LEVEL2 = [ELevel.error, ELevel.debug, ELevel.warning, ELevel.critical, ELevel.sys];
const LEVEL3 = [ELevel.error, ELevel.warning, ELevel.critical, ELevel.sys];
const LEVEL4 = [ELevel.error, ELevel.critical, ELevel.sys];
const LEVELS = [
   ELevel.error, ELevel.debug, ELevel.warning, ELevel.critical, ELevel.sys
];


void colour(String text, void write(String text, bool newline),
            {Styles front,
               Styles back,
               bool isUnderline: false,
               bool isBold: false,
               bool isDark: false,
               bool isItalic: false,
               bool isReverse: false}) {
   Colorize string = new Colorize(text);
   
   if (front != null) {
      string.apply(front);
   }
   
   if (back != null) {
      string.apply(back);
   }
   
   if (isUnderline) {
      string.apply(Styles.UNDERLINE);
   }
   
   if (isBold) {
      string.apply(Styles.BOLD);
   }
   
   if (isDark) {
      string.apply(Styles.DARK);
   }
   
   if (isItalic) {
      string.apply(Styles.ITALIC);
   }
   
   if (isReverse) {
      string.apply(Styles.REVERSE);
   }
   
   write('$string', true);
}

abstract class LoggerSketch {
   String name;
   
   void log(Object logLevel, {bool show_module: true});
   
   void sys(Object logLevel, {bool show_module: true});
   
   void info(Object logLevel, {bool show_module: true});
   
   void debug(Object logLevel, {bool show_module: true});
   
   void warning(Object logLevel, {bool show_module: true});
   
   void critical(Object logLevel, {bool show_module: true});
   
   void error(Object logLevel, {bool show_module: true});
   
   void call(String msg, [ELevel level = ELevel.info, bool show_module = true]);
}


class FileLoggerSupplement {
}

// SPLITER untested:
class TimeStampFileLogger<T> {
   static String SPLITER = '\u000D\u000A';
   Completer<IOSink> completer;
   List<String> logData;
   List<String> logDataExtra;
   IOSink file_sink;
   IOSink extraFile_sink;
   String _logPath;
   
   bool duplicate;
   bool storeExtra;
   int maxrecs;
   
   TimeStampFileLogger({String path, this.duplicate = false, this.maxrecs = 100, this.storeExtra = false}) {
      _logPath = path;
      logData = [];
      logDataExtra = [];
      completer = Completer();
      fileInit();
   }
   
   String get logPath => _logPath;
   
   void set logPath(String v) {
      _logPath = v;
      fileInit();
   }
   
   List<String> _limitList(List<String> list) {
      return list.sublist(0, min(list.length, maxrecs - 10));
   }
   
   bool isReady() {
      return completer.isCompleted;
   }
   
   Future<IOSink> _sinkInit(IOSink sink, File file, void logSetter(List<String> list)) {
      completer = Completer();
      if (sink != null) {
         sink.close().then((e) {
            final data = file.readAsStringSync().trim();
            if (data.isNotEmpty) {
               logSetter(_limitList(data.split(SPLITER).where((a) =>
               a
                  .trim()
                  .isNotEmpty).toList()));
            } else {
               logSetter([]);
            }
            sink = file.openWrite();
            completer.complete(sink);
         });
      } else {
         if (!file.existsSync()) {
            print('$logPath not exists');
            file.writeAsStringSync("");
         } else {
            print('$logPath already exists');
         }
         
         final data = file.readAsStringSync().trim();
         if (data.isNotEmpty) {
            logSetter(_limitList(data.split(SPLITER).where((a) =>
            a
               .trim()
               .isNotEmpty).toList()));
         } else {
            logSetter([]);
         }
         sink = file.openWrite(mode: FileMode.append);
         completer.complete(sink);
      }
      return completer.future;
   }
   
   void fileInit() {
      _sinkInit(file_sink, File(logPath), (list) {
         logData = list;
      }).then((fsink) {
         file_sink = fsink;
         if (storeExtra) {
            _sinkInit(extraFile_sink, File(logPath + '.extra'), (list) {
               logDataExtra = list;
               final div = logDataExtra.length - logData.length;
               print('div = $div, logDataExtra: $logDataExtra');
               if (div < 0) {
                  logDataExtra += List.generate(-div, (a) => "").toList();
               } else if (logDataExtra.length > logDataExtra.length) {
                  logData += List.generate(div, (a) => "").toList();
               }
            }).then((esink) {
               extraFile_sink = esink;
            });
         } else {
         
         }
      });
   }
   
   static String getTime([DateTime time]) {
      final t = time ?? DateTime.now();
      final month = ('0' + t.month.toString()).substring(t.month
                                                            .toString()
                                                            .length - 1);
      final day = ('0' + t.day.toString()).substring(t.day
                                                        .toString()
                                                        .length - 1);
      final hour = ('0' + t.hour.toString()).substring(t.hour
                                                          .toString()
                                                          .length - 1);
      final result = '${t.year}-${month}-${day}-${hour}-${t.minute}';
      ;
      return result;
   }
   
   void log({T key, String data, String supplement}) {
      final logline = "${getTime()} $key $data".trim() + SPLITER;
      if (!duplicate && logData.contains(key)) {
      
      } else {
         if (!storeExtra) {
            logData.add(logline);
            file_sink.writeln(logline);
         } else {
            logDataExtra.add(supplement ?? "");
            extraFile_sink.writeln(supplement ?? "");
            logData.add(logline);
            file_sink.writeln(logline);
         }
      }
   }
   
   Future close() async {
      completer = null;
      await extraFile_sink?.close();
      return file_sink.close();
   }
}


class Logger implements LoggerSketch {
   static Map<String, IOSink> file_sinks = {};
   
   static bool production = false;
   static bool disableColor = false;
   static bool disableFileSink = false;
   static Set<String> disabledModules = Set.from([]);
   static void Function(String m) fileWriter = (m) => stdout.write(m);
   void Function(String m, bool newline) write;
   
   bool showOutput;
   String name;
   String stream_path;
   List<ELevel> levels;
   IOSink file_sink;
   void Function(String m, bool newline) memWriter = (m, n) => null;
   
   void close_sink() {
      file_sink.close();
      file_sinks.remove(file_sink);
      file_sinks.removeWhere((k, v) => v == file_sink);
   }
   
   void fileSinkInit() {
      if (file_sinks.containsKey(stream_path)) {
         file_sink = file_sinks[stream_path];
      } else {
         file_sink = File(stream_path).openWrite();
         file_sinks[stream_path] = file_sink;
      }
   }
   
   Logger({this.name, this.levels = LEVELS, void writer(String m, bool newline), this.stream_path, bool dumpOnMemory = false, this.showOutput = true}) {
      if (writer != null) {
         write = writer;
      }
      
      if (!showOutput)
         disabledModules.add(name);
      
      if (stream_path != null) {
         if (!dumpOnMemory) {
            fileSinkInit();
            write = (String m, bool newline) {
               // writer(m);
               file_sink.write(m);
            };
         }
      }
      
      if (dumpOnMemory) {
         write = (String m, bool newline) {
            memWriter(m, newline);
            if (disabledModules.contains(name)) {
               return;
            };
            print(m);
         };
         file_sink?.close();
      }
      var error = () {
         if (levels.length > 1)
            throw Exception("Collection levels 'level0~level4' can't be used combining with regular level 'log, info, erro...'");
      };
      if (levels.contains(ELevel.level0)) {
         error();
         levels = LEVEL0;
      } else if (levels.contains(ELevel.level1)) {
         error();
         levels = LEVEL1;
      } else if (levels.contains(ELevel.level2)) {
         error();
         levels = LEVEL2;
      } else if (levels.contains(ELevel.level3)) {
         error();
         levels = LEVEL3;
      } else if (levels.contains(ELevel.level4)) {
         error();
         levels = LEVEL4;
      }
   }
   
   get moduleText {
      if (!disableColor) {
         var c = Colorize('[$name]\t');
         c.apply(Styles.DEFAULT);
         return c.toString();
      } else {
         return '[$name]\t';
      }
   }
   
   void call(String msg, [ELevel level = ELevel.info, bool show_module = true]) {
      if (levels.contains(level)) {
         switch (level) {
            case ELevel.warning:
               warning(msg, show_module: show_module);
               break;
            case ELevel.error:
               error(msg, show_module: show_module);
               break;
            case ELevel.critical:
               error(msg, show_module: show_module);
               break;
            case ELevel.debug:
               debug(msg, show_module: show_module);
               break;
            case ELevel.info:
               info(msg, show_module: show_module);
               break;
            default:
               log(msg, show_module: show_module);
               break;
         }
      }
   }
   
   void log(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.log) || production) return;
      //if (show_module) write(moduleText);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.DARK_GRAY, isBold: false, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void info(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.info) || production) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.LIGHT_GRAY, isBold: false, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void sys(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.sys) || production) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.LIGHT_GRAY, isBold: true, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void debug(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.debug) || production) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.LIGHT_BLUE, isBold: false, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void critical(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.critical)) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.LIGHT_RED, isBold: true, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void error(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.error)) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.RED, isBold: false, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
   
   void warning(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.warning)) return;
      if (show_module) write(moduleText, false);
      if (!disableColor)
         colour(msg.toString(), write, front: Styles.YELLOW, isBold: true, isItalic: false, isUnderline: false);
      else
         write('$msg', true);
   }
}

