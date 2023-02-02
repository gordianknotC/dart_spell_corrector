import 'package:common/src/common.log.dart' show ELevel, Logger;
import 'package:common/src/common.dart' show FN;
/*
following code was re-implemented in dart borrowed from
Peter Norvig
Site  : http://norvig.com/spell-correct.html
*/

final _LETTERS = 'abcdefghijklmnopqrstuvwxyz'.split('');
final _CAPITAL_A = 'A'.codeUnitAt(0);
final _CAPITAL_Z = 'Z'.codeUnitAt(0);
final _NON_CAP_A = 'a'.codeUnitAt(0);
final _NON_CAP_Z = 'z'.codeUnitAt(0);

final _log = Logger(
   name: "common.spell",
   levels: [ELevel.critical, ELevel.error, ELevel.warning, ELevel.debug]
);


bool
_isCapitalChar(String w) {
   return w.codeUnitAt(0) >= _CAPITAL_A && w.codeUnitAt(0) <= _CAPITAL_Z;
}

bool
_isNonCapitalChar(String w) {
   return w.codeUnitAt(0) >= _NON_CAP_A && w.codeUnitAt(0) <= _NON_CAP_Z;
}

bool
_isUnderline(String w) {
   return w == '_';
}


bool
isCamelCase(String word) {
   var letters = word.split('');
   var first_test = _isCapitalChar(letters[0]) ? _isCapitalChar : _isNonCapitalChar;
   var second_test = first_test == _isCapitalChar ? _isNonCapitalChar : _isCapitalChar;
   
   if (first_test(letters[0])) {
      var altered = letters.firstWhere((l) => second_test(l), orElse: () => null);
      var idx = altered != null ? letters.indexOf(altered) : letters.length;
      if (idx < letters.length - 1) {
         if (letters.indexWhere((l) => first_test(l), idx) != -1)
            return true;
      }
      return false;
   } else {
      return false;
   }
}


class Behaviors {
   static Iterable<List<String>>
   splits(String word) {
      var alphas = word.split('');
      return FN.map(alphas, (a, [i]) {
         _log('$i, $a,  $alphas, ${alphas.take(i + 1)}', ELevel.info);
         return [alphas.take(i + 1).join(), alphas.sublist(i + 1).join()];
      });
   }
   
   static Iterable<String>
   deletes(Iterable<List<String>> _splits) {
      return _splits.where((sector) => sector[1].isNotEmpty)
         .map((sector) => sector[0] + sector[1].substring(1));
   }
   
   static Iterable<String>
   transposes(Iterable<List<String>> _splits) {
      return _splits.where((sector) => sector[1].length > 1)
         .map((sector) => sector[0] + sector[1][1] + sector[1][0] + sector[1].substring(2));
   }
   
   static List<String>
   replaces(Iterable<List<String>> _splits) {
      var s = _splits.where((sector) => sector[1].isNotEmpty).toList();
      return _LETTERS.fold([], (all, a) {
         return all + s.map((sector) => sector[0] + a + sector[1].substring(1)).toList();
      });
   }
   
   static List<String>
   inserts(Iterable<List<String>> _splits) {
      var s = _splits.where((sector) => sector[1].isNotEmpty).toList();
      return _LETTERS.fold([], (all, a) {
         return all + s.map((sector) => sector[0] + a + sector[1]).toList();
      });
   }
}

typedef TSpellMatcher = bool Function(String db, String typing);


/*

   [Description]
      about matcher
      
   [EX]
      s2 = TypoSuggest();
      s3 = TypoSuggest(matcher: (db, typing){
         return db.contains(typing) || typing.contains(db);
      });
      test('Test Spell for camelCase correction', () {
         expect(
            s2.correct('befreDestroyed'),    note: default matcher: compare whole string from Destroyed
            equals(['before'])                     to Destroy, which in turns not found any matches.
         );
         expect(
            s3.correct('befreDestroyed'),    note: custom matcher: search string of Destroy within Destroyed
            equals(['before', 'Destroy'])          or in reversed, which in turn found matches.
         );
      });
*/
class Spell {
   static Map<Set<String>, Spell> _instances;
   bool camelCase;
   bool useCache;
   bool preRender;
   Set<String> dict;
   Set<String> split_dict;
   Map<String, Set<String>> typo_split_dict;
   Map<String, Set<String>> CACHE;
   bool Function(String db, String type) matcher;
   
   factory Spell({Set<String> dict, bool camelCase = false, bool useCache = false, bool preRender = true, TSpellMatcher matcher}){
      var ret = Spell.init(dict: dict, camelCase: camelCase, useCache: useCache, preRender: preRender, matcher: matcher);
      return ret;
   }
   
   Spell.init({Set<String> dict, this.camelCase, this.useCache, this.preRender, this.matcher}){
      Spell._instances ??= {};
      this.matcher = matcher ?? (db, typo) => db == typo;
      if (Spell._instances.containsKey(dict)) {
         //pass:
      } else {
         CACHE ??= {};
         this.dict = dict.map((x) => x.toLowerCase()).toSet();
         if (camelCase) {
            this.split_dict = dict.map((x) => CamelCaseTyping(x).words).expand((list) => list).toSet();
            if (preRender)
               this.typo_split_dict = Map<String, Set<String>>.fromIterable(split_dict, key: (d) => d, value: (d) => getWordTypos(d));
         } else {
            //pass:
         }
      }
   }
   
   Iterable<String>
   _correctTypingsViaPreRenderedTypoDict(String typing) {
      return typo_split_dict.entries
         .where((typos) => typos.value.any((v) => matcher(v, typing)))
         .map((typos) => typos.key);
   }
   
   Iterable<String>
   _correctTypingsViaUserTyposSearchInKnown(String typing) {
      return filterWordsByKnown([typing].toSet())
             ?? filterWordsByKnown(getWordTypos(typing, 1))
             ?? filterWordsByKnown(getWordTypos(typing, 2))
             ?? [typing];
   }
   
   Iterable<String>
   _camelCaseCorrection(String typing) {
      var cc = CamelCaseTyping(typing);
      if (preRender) {
         if (dict.contains(typing)) return CamelCaseTyping(typing).words;
         return cc.words.expand((word) => _correctTypingsViaPreRenderedTypoDict(word));
      }
      return cc.words.expand((word) => _correctTypingsViaUserTyposSearchInKnown(word));
   }
   
   Iterable<String>
   _generalCorrection(String typing) {
      if (preRender)
         return _correctTypingsViaPreRenderedTypoDict(typing);
      return _correctTypingsViaUserTyposSearchInKnown(typing);
   }
   
   Iterable<String>
   filterWordsByKnown(Set<String> typings) {
      var ret = typings.where((typing) => dict.any((db) => matcher(db, typing)));
      return ret.length > 0 ? ret : null;
   }
   
   Iterable<String>
   correct(String typing) {
      if (camelCase)
         return _camelCaseCorrection(typing);
      return _generalCorrection(typing);
   }
   
   Set<String>
   getWordTypos(String word, [int distance = 1]) {
      if (distance == 1) {
         if (useCache && CACHE.containsKey(word)) return CACHE[word];
         var possibilities = Spell.wordTypos(word);
         if (useCache) {
            CACHE[word] = possibilities;
            possibilities.forEach((key) => CACHE[key] = possibilities);
         }
         return possibilities;
      } else if (distance == 2) {
         return getWordTypos(word, 1)
            .expand((typos) => getWordTypos(typos, 1).toList())
            .toSet();
      }
      throw Exception('Not Implemented yet');
   }
   
   static Set<String>
   wordTypos(String word) {
      var possibilities = Set<String>();
      var splits = Behaviors.splits(word).toList();
      possibilities = (
         Behaviors.deletes(splits).toList()
         + Behaviors.transposes(splits).toList()
         + Behaviors.inserts(splits)
         + Behaviors.replaces(splits)
      ).toSet();
      return possibilities;
   }
}

/*
   [Description]
      parsing a camelCase typing
      
   [EX]
      cc = CamelCaseTyping('beforeUpdate')
      cc.words == ['before', 'Update']
      cc.pos   == [0,5]
*/
class CamelCaseTyping {
   static Map<String, CamelCaseTyping> _instances = {};
   List<int> pos;
   List<String> words;
   
   factory CamelCaseTyping(String typing){
      if (_instances.containsKey(typing)) return _instances[typing];
      return CamelCaseTyping.splitInit(typing);
   }
   
   CamelCaseTyping.splitInit(String typing){
      var letters = typing.split('');
      words = <String>[];
      pos = <int>[];
      var p = 0;
      var u = 0;
      for (var i = 0; i < letters.length; ++i) {
         var ch = letters[i];
         if ((_isCapitalChar(ch) && i != 0)) {
            words.add(typing.substring(p, i - u));
            pos.add(p);
            p = i;
            u = 0;
         } else if (_isUnderline(ch)) {
            u ++;
         }
      }
      words.add(typing.substring(p));
      pos.add(p);
   }
}









