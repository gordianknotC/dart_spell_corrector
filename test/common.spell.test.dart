import 'dart:io';
import 'package:test/test.dart';
import 'package:common/src/common.spell.dart' as SP;
import 'package:common/src/common.spell.dart';

const VUE_BEFORE_CREATED = ['beforeCreate'],
   VUE_CREATED        = ['created'],
   VUE_BEFORE_MOUNTED = ['beforeMounte'],
   VUE_MOUNTED        = ['mounted'],
   VUE_BEFORE_UPDATED = ['beforeUpdate'],
   VUE_UPDATED        = ['updated'],
   VUE_BEFORE_DESTROY = ['beforeDestroy'],
   VUE_DESTROYED      = ['destroyed'];

final VUE_HOOKS          = VUE_BEFORE_CREATED + VUE_CREATED + VUE_BEFORE_MOUNTED
                           + VUE_MOUNTED + VUE_BEFORE_UPDATED + VUE_UPDATED
                           + VUE_BEFORE_DESTROY + VUE_DESTROYED;
final DICT = VUE_HOOKS.map((x) => x).toSet();

class TypoSuggest extends SP.Spell {
   SP.TSpellMatcher matcher;
   bool camelCase;
   bool useCache;
   bool preRender;
   
   factory TypoSuggest({bool camelCase = true, bool useCache = true, bool preRender = true, SP.TSpellMatcher matcher}){
      var ret = TypoSuggest.init(dict: DICT, camelCase: camelCase, useCache: useCache, preRender: preRender, matcher: matcher);
      return ret;
   }
   
   TypoSuggest.init({Set<String> dict, this.camelCase, this.useCache, this.preRender, this.matcher})
      :super.init(dict: dict, camelCase: camelCase, useCache: useCache, preRender: preRender, matcher: matcher);
   
   Iterable<String>
   correct(String typing) {
      return super.correct(typing);
   }
   
   bool
   isCamelCase(String name){
      return SP.isCamelCase(name);
   }
}

void main() {
   var s = Behaviors.splits("hello").toList();
   group("simple spell correction test", () {
      test('split("hello")', () {
         expect(
            s,
            equals([['h', 'ello'], ['he', 'llo'], ['hel', 'lo'], ['hell', 'o'], ['hello', '']]));
      });
      
      test('deletes("hello")', () {
         print(Behaviors.deletes(Behaviors.splits("hello")).toList());
         expect(
            Behaviors.deletes(s).toList(),
            equals(['hllo', 'helo', 'helo', 'hell']),
            reason: "compare to [['h', 'ello'], ['he', 'llo'], ['hel', 'lo'], ['hell', 'o'], ['hello', '']]"
         );
      });
      
      test('transposes("hello")', () {
         var result = [['h', 'lelo'], ['he', 'llo'], ['hel', 'ol']];
         print(Behaviors.transposes(Behaviors.splits("hello")).toList());
         expect(
            Behaviors.transposes(Behaviors.splits('hello')).toList(),
            equals(['hlelo', 'hello', 'helol']),
            reason: "compare to [['h', 'ello'], ['he', 'llo'], ['hel', 'lo'], ['hell', 'o'], ['hello', '']]"
         );
      });
      test('camelCase SpliterA', () {
         expect(
            CamelCaseTyping("HelloWorldStevenHowking").words,
            orderedEquals(['Hello', 'World', 'Steven', 'Howking'])
         );
      });
      test('camelCase SpliterB', () {
         expect(
            CamelCaseTyping("Helloworldsefwoiejf").words,
            equals(["Helloworldsefwoiejf"])
         );
      });
      test('camelCase SpliterC', () {
         expect(
            CamelCaseTyping("felloworldsefwoiejf").words,
            equals(["felloworldsefwoiejf"])
         );
      });
      test('hybrit camelCase Spliter', () {
         expect(
            CamelCaseTyping("HelloWorld_Steven_Hawking").words,
            orderedEquals(["Hello", 'World', 'Steven', 'Hawking'])
         );
      });
      test('splitDict', () {
         var s = TypoSuggest();
         expect(
            s.split_dict,
            unorderedEquals([
               'before',
               'Create',
               'created',
               'Mounte',
               'mounted',
               'Update',
               'updated',
               'Destroy',
               'destroyed'
            ])
         );
      });
      test('isCamelCase', () {
         expect(
            isCamelCase('helloWorld'),
            isTrue
         );
         expect(
            isCamelCase('HelloWorld'),
            isTrue
         );
         expect(
            isCamelCase('HelloWORLD'),
            isTrue
         );
         expect(
            isCamelCase('helloWORLD'),
            isFalse
         );
      });
      
      test('camelCaseEdit("beforUpdaet")', () {
         var s = TypoSuggest();
         expect(
            s.correct("beforUpdaet").toList(),
            equals(['before', 'Update'])
         );
      });
   });

   group("Test Spell module", () {
      Spell s1;
      TypoSuggest s2, s3;
      setUp((){
         var d1 = ['hello', 'world'];
         var d2 = DICT;
         s1 = Spell(dict:d1.toSet(), camelCase: false, useCache: false, preRender: false);
         s2 = TypoSuggest();
         s3 = TypoSuggest(matcher: (db, typing){
            return db.contains(typing) || typing.contains(db);
         });
      });

      test('Pre-Test Spell for general correction', () {
         var ret1 = s1.filterWordsByKnown(['helol'].toSet());
         var ret2 = s1.filterWordsByKnown(s1.getWordTypos('helol', 1)).toList();
         var ret3 = s1.filterWordsByKnown(s1.getWordTypos('helol', 2)) ;
         expect(
           ret1,
           equals(null),
           reason: 'a typo word "helol" should not contains in dictionary'
         );

         expect(
            ret2,
            equals(['hello']),
            reason: 'a typo word "helol" should be lookup within typo possibilities of hello'
         );

         expect(
            ret3,
            equals(['hello']),
            reason: 'a typo word "helol" should be lookup within typo possibilities of hello'
         );
         
      });
      
      test('Test Spell for general correction', () {
         expect(
            s1.correct('helol'),
            equals(['hello'])
         );
         expect(
           s1.correct('wordl'),
            equals(['world'])
         );
      });
      test('Test Spell for camelCase correction', () {
         expect(
            s2.correct('updaetd'),
            equals(['updated'])
         );
         expect(
            s2.correct('beforUpdaet'),
            equals(['before', 'Update'])
         );
         expect(
            s2.correct('beforeUpdate'),
            equals(['before', 'Update'])
         );
         expect(
            s2.correct('beforedestroyed'),
            equals([])
         );
         expect(
            s2.correct('befreDestroyed'),
            equals(['before'])
         );
         expect(
            s3.correct('befreDestroyed'),
            equals(['before', 'Destroy'])
         );
      });
   });
}