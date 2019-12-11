import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:common/src/common.log.dart';
import 'package:colorize/colorize.dart' show Colorize, Styles;


typedef _TEndsStartsWith = bool Function(String source, String end);
typedef _TSubstring = String Function(String source, int start, int end);


final _D = Logger(name: 'common', levels: [ELevel.level3]);
final _UPPERCACE_A = 'A'.codeUnitAt(0);
final _UPPERCASE_Z = 'Z'.codeUnitAt(0);
final _LOWERCASE_A = 'a'.codeUnitAt(0);
final _LOWERCASE_Z = 'z'.codeUnitAt(0);

String ename<T>(T e) {
	return e.toString().split('.')[1];
}

void tryRaise(Function expression, [Object message]) {
	try {
		try {
			expression();
		} catch (e, s) {
			_D("[AnError] $message\n$e \n$s", ELevel.error);
			rethrow;
		}
	} catch (e) {}
}

T guard<T>(T expression(), Object message, {bool raiseOnly: true, String error = 'AnError'}) {
	if (raiseOnly) {
		try {
			return expression();
		} catch (e, s) {
			try {
				var trace = StackTrace.fromString(message.toString());
				_D("\n[$error] $trace\n$e \n$s", ELevel.error);
				rethrow;
			} catch (e) {
				//untested: unbolock this if ...
				//rethrow;
				return null;
			}
		}
	} else {
		try {
			return expression();
		} catch (e, s) {
			_D("[ERROR]\n$e \n$s", ELevel.error);
			rethrow;
		}
	}
}

T Function(C) observerGuard<T, C>(T expression(), Object message) {
	return (C _) {
		try {
			return expression();
		} catch (e, s) {
			_D.debug("[ERROR] $message\n$e\n$s");
			rethrow;
		}
	};
}

void raise(Object message, {String error = 'AnError', ELevel level}) {
	try {
		try {
			throw(message);
		} catch (e, s) {
			_D("\n[$error] $message\n$e \n$s", level ?? ELevel.error);
			rethrow;
		}
	} catch (e) {}
}

String ignoreWhiteSpace(String x) {
	return x.split('\n')
			.where((x) => x.trim() != '')
			.map((x) => x.trim())
			.join(' ');
}

void GP(String message, Function(String _) cb, [int level = 1]) {
	const String H = '-';
	const String S = ' ';
	final int TITLE_L = message.length;
	final int MIN_COL = TITLE_L <= 36
			? TITLE_L % 2 == 0
			? TITLE_L
			: 36 + 1
			: TITLE_L;
	final HEADING = (MIN_COL - TITLE_L) ~/ 2; //note: ~/2 indicates divide by 2 and transform it into int;
	final HORIZONTAL = H * MIN_COL;
	final TITLE = S * HEADING + message;
	_D.debug(HORIZONTAL);
	_D.debug(TITLE);
	_D.debug(HORIZONTAL);
	cb('\t' * level);
}

class Tuple<K, V> {
	K key;
	V value;
	
	String toString() => [key, value].toString();
	
	Tuple(this.key, [this.value]);
}

/*class Triple<K, M, V> {
   K father;
   V mother;
   M child;
   Triple(this.father, this.mother, this.child);
}*/

Map<K, V>
Dict<K, V>(List<MapEntry<K, V>> data) {
	var ret = <K, V>{};
	for (var i = 0; i < data.length; ++i) {
		var d = data[i];
		ret[d.key] = d.value;
	}
	return ret;
}

class Triple<F, M, C> {
	F father;
	M mother;
	C child;
	
	String toString() => [father, mother, child].toString();
	
	Triple(this.father, this.mother, this.child);
}

//@formatter:off
class _singletonIS {
	bool set(Set set) => !IS.set(set);
	
	bool string(String s) => !IS.string(s);
	
	bool array(List<dynamic> arr) => !IS.array(arr);
	
	bool number(String n) => !IS.number(n);
	
	bool Int(String n) => !IS.Int(n);
	
	bool Null(dynamic a) => !IS.Null(a);
	
	bool present(dynamic a) => !IS.present(a);
	
	bool empty(dynamic s) => !IS.empty(s);
}

final IS = singletonIS();

class singletonIS {
	_singletonIS _not;
	
	get not {
		_not ??= _singletonIS();
		return _not;
	}
	
	bool
	empty(dynamic s) {
		if (s is Set) return s.isEmpty;
		if (s is String) return s.length <= 0;
		if (s is List) return s.length <= 0;
		return s == null || s == 0;
	}
	
	bool
	set(Set<dynamic> set) => set is Set;
	
	bool
	string(String text) => text is String;
	
	bool
	array(List<dynamic> arr) => arr is List;
	
	bool
	Null(dynamic a) => a == null;
	
	bool
	present(dynamic a) => a != null;
	
	
	bool
	number(dynamic text) =>
			text is String
					? double.tryParse(text) != null
					: text is num;
	
	bool
	Int(dynamic text) =>
			text is String
					? int.tryParse(text) != null
					: text is int;
	
	bool
	union<E>(List<E> master_set, List<E> sub_set) {
		return sub_set.every((sub) => master_set.any((master) => master == sub));
	}
	
	bool
	alphabetic(String w) {
		return w.codeUnitAt(0) >= _UPPERCACE_A && w.codeUnitAt(0) <= _LOWERCASE_Z;
	}
	
	bool
	upperCaseChar(String w) {
		return w.codeUnitAt(0) >= _UPPERCACE_A && w.codeUnitAt(0) <= _UPPERCASE_Z;
	}
	
	bool
	lowerCaseChar(String w) {
		return w.codeUnitAt(0) >= _LOWERCASE_A && w.codeUnitAt(0) <= _LOWERCASE_Z;
	}
	
	bool
	underlineChar(String w) {
		return w == '_';
	}
	
	bool
	camelCase(String word) {
		var letters = word.split('');
		var first_test = IS.upperCaseChar(letters[0]) ? IS.upperCaseChar : IS.lowerCaseChar;
		var second_test = first_test == IS.upperCaseChar ? IS.lowerCaseChar : IS.upperCaseChar;
		
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
	
	bool
	snakeCase(String word) {
		var letters = word.split('');
		var first_test = IS.alphabetic(letters[0]) ? IS.alphabetic : IS.underlineChar;
		var second_test = first_test == IS.alphabetic ? IS.underlineChar : IS.alphabetic;
		
		if (first_test(letters[0])) {
			var altered_char = letters.firstWhere((l) => second_test(l), orElse: () => null);
			var idx = altered_char != null
					? letters.indexOf(altered_char)
					: letters.length;
			if (idx < letters.length - 1) {
				if (letters.indexWhere((l) => first_test(l), idx) != -1)
					return true;
			}
			return false;
		} else {
			return false;
		}
	}
	
	bool
	odd(int num) => num != 0 && ((num - 1) % 2 == 0);
	
	bool
	even(int num) => num != 0 && (num % 2 == 0);
	
	
}

String _keepIndent(String source, int level) {
	const tab = '\t';
	var ol = source.length;
	var _source = FN.stripLeft(source, tab);
	var initial_indent = ol - _source.length + level;
	if (initial_indent > 0) {
		return _source.split('\n').map((String line) {
			return (tab * initial_indent) + line;
		}).join('\n');
	}
	return source;
}

class TLinked<T> {
	void Function(T arg) master;
	void Function(void Function()) slaveSetter;
	void Function() _slave;
	
	void Function() get slave {
		if (_slave == null)
			throw Exception('slave has not been set');
		return _slave;
	}
	
	set slave(void cb()) => _slave = cb;
	
	TLinked(this.master, this.slaveSetter);
}

/*abstract class IsolateParamSketch<T>{
   SendPort get sendport => receivePort.sendPort;
   ReceivePort receivePort;
   Isolate _isolate;
   T data;
   
   void Function()         onIsolateCompleted;
   void Function(Object)   onIsolateError;

   IsolateParamSketch(this.receivePort, this.data, {this.onIsolateCompleted, this.onIsolateError});
   
   void _onReceive(T s){
   
   }
   void _onIsolateExecute(T s){
      onIsolateExecute(s).then((e){
         sendport.send();
         onIsolateCompleted();
      }).catchError((e){
         onIsolateError(e);
      });
   }
   
   Future onIsolateExecute(T s);
   void stopIsolate(){
      if (_isolate != null) {
         _isolate.kill(priority: Isolate.immediate);
         _isolate = null;
      }
   }
   Future<Isolate> execute() async {
      _isolate = await Isolate.spawn<T>(_onIsolateExecute, data);
      receivePort.listen((response) {
         _D.debug('receive isolate response: ${response.runtimeType}');
         _onReceive(response as T);
      });
      return _isolate;
   }
}*/

class Sort<T> {
	List<T> ntagRecords;
	
	Sort(this.ntagRecords);
	
	int Function(T a, T b)
	dateDec(DateTime date(T a)) {
		return (T a, T b) =>
		date(b)
				.difference(date(a))
				.inMilliseconds;
	}
	
	int Function(T a, T b)
	dateAcc(DateTime date(T a)) {
		return (T a, T b) =>
		date(a)
				.difference(date(b))
				.inMilliseconds;
	}
	
	int Function(T a, T b)
	XDec(int getter(T a)) {
		return (T a, T b) => getter(b) - getter(a);
	}
	
	int Function(T a, T b)
	XAcc(int getter(T a)) {
		return (T a, T b) => getter(a) - getter(b);
	}
	
	Map<DateTime, List<T>> byDateDec(bool isDiff(T a, T b), DateTime date(T a), bool filterDuplicate(List<T> a, T b)) {
		try {
			T a, b;
			List<T> linearStack = [];
			Map<DateTime, List<T>> cate = {};
			ntagRecords.sort((a, b) =>
			date(b).difference(date(a)).inMilliseconds);
			
			for (var i = 0; i < ntagRecords.length; i ++) {
				b = ntagRecords[i];
				if (a != null) {
					if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, a)) {
						linearStack.add(a);
						cate[date(a)] ??= [];
						cate[date(a)].add(a);
					} else {
						if (filterDuplicate != null && filterDuplicate(cate[date(linearStack.last)], a)) {
							cate[date(linearStack.last)].add(a);
						} else
							_D.debug('blocked record: $a');
					}
					
					if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, b)) {
						linearStack.add(b);
						cate[date(b)] ??= [];
						cate[date(b)].add(b);
					} else {
						if (filterDuplicate != null && filterDuplicate(cate[date(linearStack.last)], b)) {
							cate[date(linearStack.last)].add(b);
						} else
							_D.debug('blocked record: $b');
					}
				}
				a = b;
			}
			return cate;
		} catch (e, s) {
			_D.debug('[ERROR] Sort.byDateDec failed: \n$s');
			rethrow;
		}
	}
	
	Map<DateTime, List<T>> byDateAcc(bool isDiff(T a, T b), DateTime date(T a), bool filterDuplicate(List<T> a, T b)) {
		T a, b;
		List<T> linearStack = [];
		Map<DateTime, List<T>> cate = {};
		//bool Function() isNotFirstRecord = () => a != null;
		ntagRecords.sort((a, b) => date(a).difference(date(b)).inMilliseconds);
		
		for (var i = ntagRecords.length - 1; i >= 0; i --) {
			b = ntagRecords[i];
			if (a != null) {
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, a)) {
					linearStack.add(a);
					cate[date(a)] ??= [];
					cate[date(a)].add(a);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[date(linearStack.last)], a)) {
						cate[date(linearStack.last)].add(a);
					} else
						_D.debug('blocked record: $a');
				}
				
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, b)) {
					linearStack.add(b);
					cate[date(b)] ??= [];
					cate[date(b)].add(b);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[date(linearStack.last)], a)) {
						cate[date(linearStack.last)].add(b);
					} else
						_D.debug('blocked record: $b');
				}
			}
			a = b;
		}
		return cate;
	}
	
	Map<int, List<T>> byCustomDec(bool isDiff(T a, T b), DateTime date(T a), int custom(T a), bool filterDuplicate(List<T> a, T b)) {
		T a, b;
		List<T> linearStack = [];
		Map<int, List<T>> cate = {};
		ntagRecords.sort((a, b) => custom(b) - custom(a));
		
		for (var i = 0; i < ntagRecords.length; i ++) {
			b = ntagRecords[i];
			if (a != null) {
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, a)) {
					linearStack.add(a);
					cate[custom(a)] ??= [];
					cate[custom(a)].add(a);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[custom(linearStack.last)], a)) {
						if (!cate[custom(linearStack.last)].contains(a))
							cate[custom(linearStack.last)].add(a);
					} else
						_D.debug('blocked record: $a');
				}
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, b)) {
					linearStack.add(b);
					cate[custom(b)] ??= [];
					cate[custom(b)].add(b);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[custom(linearStack.last)], b)) {
						if (!cate[custom(linearStack.last)].contains(b))
							cate[custom(linearStack.last)].add(b);
					} else
						_D.debug('blocked record: $b');
				}
			}
			a = b;
		}
		return cate;
	}
	
	Map<int, List<T>> byCustomAcc(bool isDiff(T a, T b), DateTime date(T a), int custom(T a), bool filterDuplicate(List<T> a, T b)) {
		T a, b;
		List<T> linearStack = [];
		Map<int, List<T>> cate = {};
		ntagRecords.sort((a, b) => custom(a) - custom(b));
		for (var i = ntagRecords.length - 1; i >= 0; i --) {
			b = ntagRecords[i];
			if (a != null) { // a == null => first record, a != null => prev record
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, a)) {
					linearStack.add(a);
					cate[custom(a)] ??= [];
					cate[custom(a)].add(a);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[custom(linearStack.last)], a)) {
						if (!cate[custom(linearStack.last)].contains(a))
							cate[custom(linearStack.last)].add(a);
					} else
						_D.debug('blocked record: $a');
				}
				if (isDiff(linearStack.isNotEmpty ? linearStack.last : null, b)) {
					linearStack.add(b);
					cate[custom(b)] ??= [];
					cate[custom(b)].add(b);
				} else {
					if (filterDuplicate != null && filterDuplicate(cate[custom(linearStack.last)], b)) {
						if (!cate[custom(linearStack.last)].contains(b))
							cate[custom(linearStack.last)].add(b);
					} else
						_D.debug('blocked record: $b');
				}
			}
			a = b;
		}
		_D.debug('cate.keys  : ${cate.keys}');
		_D.debug('cate.values: ${cate.values}');
		return cate;
	}
}


class FN {
	static void callEither(Function a, Function b){
		assert(a != null || b != null);
		if   (a != null) a();
		else 					   b();
	}
	
	static bool orderedEqualBy<E>(List<E> a, List<E> b, bool eq(E a, E b)){
		if ((a?.isEmpty ?? true) && (b?.isEmpty ?? true))
			return true;
		
		if (a?.length != b?.length)
			return false;
		
		for (var i = 0; i < a.length; ++i) {
			final _a = a[i];
			final _b = b[i];
			if (!eq(_a, _b))
				return false;
		}
		return true;
	}
	
	static bool orderedTheSame<E>(List<E> a, List<E> b){
		return orderedEqualBy<E>(a, b, (_a, _b) => _a == _b);
	}
	
	static assertEitherNotBoth(bool a, bool b) {
		assert((a || b) == true);
		assert((a && b) == false);
	}
	
	static Iterable<T> uniqueBy<T>(Iterable<T> data, bool isDuplicate(T a, T b)) {
		return data.fold<List<T>>([], (initial, b) {
			if (initial.any((a) => isDuplicate(a, b)))
				return initial;
			return initial + [b];
		});
	}
	
	static Map<Type, Tuple<Isolate, StreamSubscription>> _ISOLATES = {};
	
	static Future<Tuple<Isolate, StreamSubscription>>
	createIsolate<T>(void onIsolate(T s), T data) async {
		if (_ISOLATES.containsKey(T))
			return _ISOLATES[T];
		final isolate =  await Isolate.spawn<T>(onIsolate, data);
		return _ISOLATES[T] = Tuple(isolate, null);
	}
	
	static Future<Isolate>
	startIsolate<T>(void onIsolate(T s), T data, void onReceived(dynamic s), ReceivePort receivePort) async {
		final completer = Completer<Isolate>();
		final isolate = await createIsolate<T>(onIsolate, data);
		if (isolate.value == null){
			isolate.value = receivePort.listen((response) {
				_D.debug('receive isolate response: ${response.runtimeType}');
				onReceived(response);
			});
		}else{
			_D.debug('stop isolate...');
			stopIsolate<T>(isolate.key);
			return startIsolate<T>(onIsolate, data, onReceived, receivePort);
		}
		completer.complete(isolate.key);
		return completer.future;
	}
	
	static void stopIsolate<T>(Isolate isolate) {
		if (isolate != null) {
			if (_ISOLATES.containsKey(T))	{
				isolate.kill(priority: Isolate.immediate);
				_ISOLATES[T].value.cancel();
				_ISOLATES.remove(T);
			}else{
				final entry = _ISOLATES.entries.firstWhere((entry) => entry.value.key == isolate, orElse: () => null);
				entry?.value?.key?.kill?.call(priority: Isolate.immediate);
				entry?.value?.value?.cancel?.call();
				_ISOLATES.remove(entry?.key);
			}
		}
	}
	
	T getMapKeyByWhereValue<T, V>(Map<T, V> map, V value) {
		return map.entries
				.firstWhere((e) => e.value == value, orElse: () => null)
				.key;
	}
	
	/*static String
   toString(dynamic source){
   
   }
   static num
   toNum(String source){
   
   }
   static int
   toInt(String source){
   
   }*/
	
	/*static List<E>
   repeat<E>({E fn(), E material ,int t}){
      if (fn != null){
         return List.generate(t, fn);
      }
      return List.filled(t, material);
   }*/
	
	/// --------------------------------------
	/// link master function to slave
	static TLinked<T>
	linkCoupleByCallback<T>(void master(T arg), void slaveSetter(void slave())) {
		TLinked<T> result;
		void Function() relinked_slave;
		void linked_slave(void slave()) {
			slaveSetter(slave);
			relinked_slave = slave;
			result.slave = slave;
		};
		void newMaster(T arg) {
			master(arg);
			relinked_slave();
		}
		return result = TLinked(newMaster, linked_slave);
	}
	
	static T getEltOrNull<T>(List<T> elements, int id) {
		final l = elements.length;
		if (id < l) return elements[id];
		return null;
	}
	
	static List<List<T>>
	dimensionList<T>(List<T> list, int dimension) {
		final result = <List<T>>[];
		for (var i = 0; i < list.length; ++i) {
			var o = list[i];
			var reorder = (i / dimension).floor();
//         _D.debug('i: $i, reorder:$reorder');
			if (i % dimension == 0)
				result.add(<T>[]);
			result[reorder].add(o);
		}
		return result;
	}
	
	static E
	range<E>(E s, [int start, int end]) {
		if (E == String) {
			var source = s as String;
			if (start != null && start < 0)
				start = source.length + start;
			if (end != null && end < 0)
				end = source.length + end;
			return source.substring(start, end) as E;
		} else if (E == List) {
			var source = s as List;
			if (start != null && start < 0)
				start = source.length + start;
			if (end != null && end < 0)
				end = source.length + end;
			return source.sublist(start, end) as E;
		} else {
			throw Exception('Invalid type. Only support for string or list');
		}
	}
	
	static Iterable<E>
	head<E>(List<E> array) {
		return array.sublist(0, array.length - 1);
	}
	
	static Iterable<E>
	tail<E>(List<E> array) {
		return array.sublist(1, array.length);
	}
	
	static E
	last<E>(List<E> array) {
		return array.last;
	}
	
	static E
	first<E>(List<E> array) {
		return array.first;
	}
	
	static T
	remove<T>(List<T> array, T element) {
		return array.removeAt(array.indexOf(element));
	}
	
	static List<String>
	split(String data, String ptn, [int max = 1]) {
		String d = data, pre, suf;
		var ret = <String>[];
		for (var i = 0; i < max; ++i) {
			var idx = d.indexOf(ptn);
			if (idx == -1) {
				ret.add(d);
				return ret;
			}
			pre = d.substring(0, idx);
			suf = d.substring(pre.length + 1);
			d = suf;
			ret.add(pre);
		}
		ret.add(suf);
		return ret;
	}
	
	static int
	findIndex<T>(List<T> data, bool search(T element)) {
		int result;
		FN.forEach(data, (T el, [i]) {
			if (search(el)) {
				result = i;
				return true;
			}
			return false;
		});
		return result;
	}
	
	
	static int
	count<E>(List<E> A, E B, bool comp(E a, E b)) {
		var counter = 0;
		var len = A.length;
		for (var ia = 0; ia < len; ++ia) {
			var ra = A[ia];
			if (comp(ra, B))
				counter ++;
		}
		return counter;
	}
	
	static int
	countBy<E>(List<E> data, int comp(E a)){
		return data.fold<int>(0, (initial, b){
			return initial + comp(b);
		});
		
	}
	
	static List<E>
	unique<E>(List<E> A, bool filter(List<E> acc, E b)) {
		List<E> result = [];
		filter ??= (acc, b) => acc.contains(b);
		for (var i = 0; i < A.length; ++i) {
			var a = A[i];
			if (filter(result, a))
				result.add(a);
		}
		return result;
	}
	
	static Iterable<List<T>>
	zip<T>(Iterable<Iterable<T>> iterables) sync* {
		if (iterables.isEmpty) return;
		//note: without toList(growable: false) - causes infinite loop ???
		final iterators = iterables.map((e) => e.iterator).toList(growable: false);
		while (iterators.every((e) => e.moveNext())) {
			yield iterators.map((e) => e.current).toList(growable: false);
		}
	}
	
	static Iterable<E>
	union_1dlist<E>(List<E> left, List<E> right, [bool comp(List<E> a, E b)]) {
		var already_in_r = false;
		var ret = left;
		comp ??= (a, b) => a.contains(b);
		
		for (var i = 0; i < right.length; ++i) {
			var r_member = right[i];
			already_in_r = left.any((l_member) => l_member == r_member);
			if (already_in_r) {} else {
				ret.add(r_member);
			};
		}
		return ret;
	}
	
	static List<List<E>>
	union_2dlist<E>(List<List<E>> left, List<List<E>> right, [bool comp(List<E> a, E b)]) {
		var already_in_r = false;
		var all = <List<E>>[];
		comp ??= (a, b) => a.contains(b);
		
		for (var i = 0; i < right.length; ++i) {
			var r_member = right[i];
			already_in_r = r_member.every((ref) =>
					left.any((l_member) =>
							comp(l_member, ref)));
			if (already_in_r) {} else {
				all.add(r_member);
			};
		}
		return all;
	}
	
	static List<T>
	sorted<T>(List<T> data, [int compare(T a, T b)]) {
		if (data.isEmpty) return data;
		final iterators = data.toList(growable: false);
		iterators.sort(compare);
		return iterators;
	}
	
	static void
	forEach<T>(List<T> list, bool Function(T member, [int index]) cb) {
		var length = list.length;
		for (var i = 0; i < length; ++i) {
			if (cb(list[i], i)) return;
		}
	}
	
	static Iterable<T>
	map<T, E>(List<E> list, T Function(E member, [int index]) cb) {
		var i = -1;
		return list.map((e) {
			i ++;
			return cb(e, i);
		});
	}
	
	
	static String
	_strip(String source, List<String> stripper,
			int srlen, int stlen,
			_TEndsStartsWith conditioning, _TSubstring substring) {
		var strip_counter = -1;
		while (strip_counter != 0) {
			strip_counter = 0;
			_D.debug('[strip]$source, ${conditioning == source.endsWith}, ${conditioning == source.startsWith}');
			for (var i = 0; i < stlen; ++i) {
				_D.debug('   1) ends with ${stripper[i]} ${conditioning(source, stripper[i])}');
				
				if (conditioning(source, stripper[i])) {
					source = substring(source, 0, source.length - 1);
					strip_counter ++;
				}
			}
		}
		return source;
	}
	
	static String
	_stripRight(String source, List<String> stripper, int srlen, int stlen, _TEndsStartsWith conditioning, _TSubstring substring) {
		return _strip(source, stripper, srlen, stlen, conditioning, substring);
	}
	
	static String
	_stripLeft(String source, List<String> stripper, int srlen, int stlen, _TEndsStartsWith conditioning, _TSubstring substring) {
		return _strip(source, stripper, srlen, stlen, conditioning, substring);
	}
	
	static String
	_stripLR(String source, String stripper,
			String Function(String source, List<String> stripper, int srlen, int stlen, _TEndsStartsWith conditioning, _TSubstring substring) pathway,
			_TEndsStartsWith conditioning, _TSubstring substring) {
		var l = stripper.length;
		if (l == 0) return source;
		if (l == 1) {
			if (conditioning(source, stripper)) {
				return substring(source, 0, source.length - 1);
			}
		} else {
			return pathway(source, stripper.split(''), source.length, stripper.length, conditioning, substring);
		}
		return source;
	} //@fmt:on
	
	static String
	stripLeft(String source, [String stripper = " "]) {
		return _stripLR(source, stripper, _stripLeft,
						(String s, String end) => s.startsWith(end),
						(String s, int start, int end) => s.substring(s.length - end));
	}
	
	static String
	stripRight(String source, [String stripper = " "]) {
		return _stripLR(source, stripper, _stripRight,
						(String s, String end) => s.endsWith(end),
						(String s, int start, int end) => s.substring(start, end));
	}
	
	static String
	strip(String source, [String stripper = " "]) {
		return stripLeft(stripRight(source, stripper), stripper);
	}
	
	static String
	dePrefix(String prefixed_name, String prefix, [String suffix = '', bool to_camelcase = false]) {
		var l = prefix.length;
		var r = suffix.length;
		var name = prefixed_name.substring(l, prefixed_name.length - r);
		if (to_camelcase)
			return '${name.substring(0, 1).toLowerCase()}${name.substring(1)}';
		return '${name.substring(0, 1)}${name.substring(1)}';
	}
	
	static String
	toCamelCase(String word) {
		var current_under = IS.upperCaseChar(word[0]),
				last_under = null,
				altered = false;
		if (IS.snakeCase(word)) {
			word = word.split('').map((w) {
				current_under = IS.underlineChar(w);
				altered = last_under != current_under;
				last_under = current_under;
				if (altered && current_under == true)
					return '';
				if (altered)
					return w.toUpperCase();
				return w;
			}).join('');
			return '${word.substring(0, 1).toLowerCase()}${word.substring(1)}';
		}
		return word;
	}
	
	static String
	toSnakeCase(String word) {
		var current_upper = IS.upperCaseChar(word[0]),
				last_upper = null,
				altered = false;
		if (IS.camelCase(word))
			return word.split('').map((w) {
				current_upper = IS.upperCaseChar(w);
				altered = last_upper != current_upper;
				last_upper = current_upper;
				if (altered && current_upper == true)
					return '_' + w.toLowerCase();
				return w;
			}).join('');
		return word;
	}
	
	
	static void
	prettyPrint(dynamic source, [int level = 0, bool colorized = true]) {
		_D.debug(FN.stringPrettier(source, level, colorized));
	}
	
	static Object
	stringPrettier(dynamic node, [int level = 0, bool colorized = true]) {
		var output = '';
		if (node is Map) {
			Map _node = node;
			output += "\t" * level + "{" + '\n';
			_node.forEach((n, value) {
				var keyname = "\t" * (level + 1) + n.toString();
				var val = FN.stringPrettier(value, level + 1, colorized).toString().trim();
				output += '$keyname: ${val},\n';
			});
			return output + "\t" * level + '}';
		}
		if (node is List) {
			List _node = node;
			output += "\t" * level + "[" + '\n';
			_node.forEach((value) {
				var val = FN.stringPrettier(value, level + 1, colorized);
				output += '${val}, \n';
			});
			return output + "\t" * level + ']';
		}
		output += node.toString();
		String vstring; //value string
		String tstring; //type string
		if (colorized) {
			var t = Colorize(node.runtimeType.toString());
			var v = Colorize(output);
			v.apply(Styles.LIGHT_GREEN);
			v.apply(Styles.BOLD);
			t.apply(Styles.LIGHT_MAGENTA);
			vstring = v.toString();
			tstring = t.toString();
		} else {
			vstring = output;
			tstring = '';
		}
//      var vstring = v.toString();
		var clines = vstring
				.split('\n')
				.length;
		vstring = clines > 1
				? _keepIndent(vstring, level)
				: vstring;
		return "\t" * (level) + '$tstring $vstring';
	}
	
	static void ensureKeys<T>(Map<T, dynamic> map, List<T> keys) {
		final result = <T>[];
		for (final key in map.keys) {
			if (!keys.contains(key) || map[key] == null) {
				result.add(key);
			}
		}
		if (result.length > 0) {
			throw Exception('Map keys missmatched. following keys are missing:\n ${result.map((m) => m.toString()).toList()}');
		}
	}
	
	static void updateMembers(Map<String, dynamic> target, Map<String, dynamic> source, {List<String> members, bool removeFromSource = false}) {
		members.forEach((m) {
			if (source.containsKey(m)) {
				target[m] = source[m];
				if (removeFromSource)
					source.remove(m);
			}
		});
	}
	
	static int countOn<T>(List<T> data, bool Function(T d) condition) {
		int result = 0;
		for (var i = 0; i < data.length; ++i) {
			var o = data[i];
			if (condition(o))
				result ++;
		}
		return result;
	}
	
	//fixme:
	static List<int> difference(List<int> list, List<int> list2) {
		if (list == null || list2 == null)
			throw Exception('list should not be null');
		final longest = list.length > list2.length ? list : list2;
		final shortest = list.length > list2.length ? list2 : list;
		final result = <int>[];
		for (var i = 0; i < longest.length; ++i) {
			var rec = longest[i];
			if (!shortest.contains(rec))
				result.add(rec);
		}
		return result;
	}
}


// fixme: size overflow detection (bigger than 4 bytes)
class TwoDBytes {
	Uint8List bytes;
	int lengthByes = 4;
	
	TwoDBytes(List<List<int>> twoD_list, {this.lengthByes = 4}) {
		bytes = twoDtoOneDList(twoD_list, lengthByes);
	}
	
	TwoDBytes.fromOneD(this.bytes);
	
	static Uint8List twoDtoOneDList(List<List<int>> tdim, [int lengthByes = 4]) {
		List<int> ret = [tdim.length];
		_D.debug('convert ${tdim.length} lists into one list');
		for (var i = 0; i < tdim.length; ++i) {
			final Uint8List rec_data = Uint8List.fromList(tdim[i]);
			final rec_data_length = rec_data.lengthInBytes;
			final length_in_bytes = intToBytes(rec_data_length, lengthBytes: lengthByes);
			_D.debug('flag: $i');
			_D.debug('rec_data: ${rec_data.sublist(0, 20)}...');
			_D.debug('rec_data_legnth in bytes: $rec_data_length');
			_D.debug('num_of_length_bytes: $length_in_bytes, ${bytesToInt(length_in_bytes)}');
			ret.add(lengthByes);
			ret.addAll(length_in_bytes);
			ret.addAll(rec_data);
		}
		return Uint8List.fromList(ret);
	}
	
	static num bytesToInt(Uint8List bytes) {
		num number = 0;
		for (var i = 0; i < bytes.length; ++i) {
			var n = bytes[i];
			if (i == 0)
				number += n;
			else
				number += (n * pow(256, i));
		}
		return number;
	}
	
	static Uint8List intToBytes(int number, {int lengthBytes = 4}) {
		final list = Uint64List.fromList([number]);
		return Uint8List.view(list.buffer).sublist(0, lengthBytes);
	}
	
	int get length {
		return bytes.lengthInBytes;
	}
	
	int get recordsLength {
		return bytes[0];
	}
	
	Stream<Uint8List> get records async* {
		var r = 2;
		var l = 2;
		Uint8List data_length;
		int numberof_data_length;
		try {
			for (var flag = 0; flag < recordsLength; ++flag) {
				l = r;
				data_length = Uint8List.fromList(bytes.sublist(l, l + lengthByes));
				numberof_data_length = bytesToInt(data_length) as int;
				l += lengthByes;
				r = l + numberof_data_length + 1;
				yield Uint8List.fromList(bytes.sublist(l, r - 1));
			}
		} on RangeError catch (e) {
			throw Exception(
					'lbound:$l, rbound:$r, data_length:$data_length, numberof_data_length: $numberof_data_length'
							'\n${StackTrace.fromString(e.toString())}');
		} catch (e) {
			throw Exception(e);
		}
	}
}


void main([arguments]) {
	if (arguments.length == 1 && arguments[0] == '-directRun') {
		var a = 'helloWorld';
		var b = 'hello_world';
		
		assert(IS.camelCase(a), '$a expect to be a camel case' );
		assert(IS.snakeCase(b), '$b expect to be a snake case');
		
		var ta = FN.toSnakeCase(a);
		var tb = FN.toCamelCase(b);
		
		assert(ta == b, '$ta expect to be snake case');
		assert(tb == a, '$tb expect to be camel case');
		
		var pa = 'onSumChanged';
		
		assert(
		FN.dePrefix(pa, 'on', 'changed') == 'Sum',
		'''\nexpect $pa to be Sum, got: ${FN.dePrefix(pa, 'on', 'changed')}'''
		);
		assert(
		FN.dePrefix(pa, 'on', 'changed', true) == 'sum',
		'''\nexpect $pa to be sum, got: ${FN.dePrefix(pa, 'on', 'changed', true)}'''
		);
	}
}


