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


void colour(String text,
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

   Logger.write('$string\n');
}

class Logger {
   static bool production = false;
   static void Function(String m) write = (m) => stdout.write(m);
   static IOSink file_sink;
   static close_sink() => file_sink.close();
   
   List<ELevel> levels;
   String name;
   
   Logger({this.name, this.levels = LEVELS, void writer(String m), String stream_path}) {
      if (writer != null){
         Logger.write = writer;
      }
      if (stream_path != null){
         file_sink = File(stream_path).openWrite();
         Logger.write = (String m){
           // writer(m);
           file_sink.write(m);
         };
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
      var c = Colorize('\n[$name] ');
      c.apply(Styles.DEFAULT);
      return c.toString();
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
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.DARK_GRAY, isBold: false, isItalic: false, isUnderline: false);
   }
   
   void info(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.info) || production) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.LIGHT_GRAY, isBold: false, isItalic: false, isUnderline: false);
   }
   
   void sys(Object msg, {bool show_module: true}){
      if (!levels.contains(ELevel.sys) || production) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.LIGHT_GRAY, isBold: true, isItalic: false, isUnderline: false);
   }
   
   void debug(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.debug) || production) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.LIGHT_BLUE, isBold: false, isItalic: false, isUnderline: false);
   }
   
   void critical(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.critical)) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.LIGHT_RED, isBold: true, isItalic: false, isUnderline: false);
   }
   
   void error(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.error)) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.RED, isBold: false, isItalic: false, isUnderline: false);
   }
   
   void warning(Object msg, {bool show_module: true}) {
      if (!levels.contains(ELevel.warning)) return;
      if (show_module) write(moduleText);
      colour(msg.toString(), front: Styles.YELLOW, isBold: true, isItalic: false, isUnderline: false);
   }
}

