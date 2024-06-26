import newstd/text/parse
import std/data/linearmap
import std/text/regex
import std/num/float64

type jsValue
  JsNull
  JsBool(b: bool)
  JsInt(s: string, i:int = s.std/num/parse)
  JsDouble(s: string, d:float64 = s.std/num/float64/parse)
  JsString(s: string)
  JsArray(l: list<jsValue>)
  JsObject(o: jsObject<jsValue>)

alias jsObject<a> = linearMap<string, a, <>>

fun toString(v: jsValue)
  match v
    JsString(s) -> s
    _ -> v.show

fun show(v: jsValue)
  match v
    JsNull -> "null"
    JsBool(b) -> if b then "true" else "false"
    JsInt(i) -> i.std/core/show
    JsDouble(d) -> d.std/core/show
    JsString(s) -> s.std/core/show
    JsArray(l) -> "[" ++ l.map(show).join(", ") ++ "]"
    JsObject(o) -> "{" ++ o.list.map(fn ((k, v1)) k ++ ": " ++ v1.show).join(",\n ") ++ "}"

fun jsLookup(v: jsValue, keys: list<string>): jsValue
  match keys
    Nil -> v
    Cons(k, ks) ->
      match v
        JsObject(o) -> 
          match o.maybeGet(k)
            Just(v1) -> jsLookup(v1, ks)
            Nothing -> JsNull
        JsArray(vs) -> 
          match k.std/core/parse-int
            Just(i) -> 
              match vs[i]
                Just(v1) -> jsLookup(v1, ks)
                Nothing -> JsNull
            Nothing -> JsNull
        _ -> JsNull

fun jsFind(v: jsValue, def: jsValue, keys: list<string>): jsValue
  match v.jsLookup(keys)
    JsNull -> def
    v1 -> v1

val hexLeadRegex = r"0[xX]".regex();
fun hexadecimal()
  takePattern(leadingRegex) ++ takePattern(hexLeadRegex) ++ takePattern(integerRegex)

val leadingHexDotRegex = r"^.[0-9a-fA-F_]+([eEpP][+-]?[0-9a-fA-F_]+)?".regex() 
val wholeHexFloatRegex = r"^[0-9a-fA-F_]+(\.[0-9a-fA-F_]+)?([eEpP][+-]?[0-9a-fA-F_]+)?".regex() 
val integerRegex = r"^[0-9a-fA-F_]+".regex() 
fun integer()
  takePattern(leadingRegex) ++ takePattern(integerRegex)

val leadingRegex = r"[+-]".regex()
fun exp()
  takePattern(leadingRegex) ++ integer()
  
fun decfloat()
  takePattern(leadingRegex) ++ (fn() takePattern(wholeHexFloatRegex)).or({takePattern(leadingHexDotRegex)})

fun hexfloat()
  takePattern(leadingRegex) ++ hexadecimal() ++ (fn() takePattern(wholeHexFloatRegex)).or({takePattern(leadingHexDotRegex)})

fun pLit()
  with scope("plit")
  ors([{text("true"); JsBool(True)},{text("false"); JsBool(False)},{text("null"); JsNull}])

fun pFloat()
  with atomic
  val d = or({decfloat().split("_").join}, {hexfloat().split("_").join})
  JsDouble(d)

fun pInteger()
  with atomic
  val d = integer().split("_").join
  JsInt(d)

val stringRegex = "^\"[^\\\\\"]*(?:\\\\.[^\"\\\\]*)*\"".regex()

inline fun takeString()
  takePattern(stringRegex)

fun pString()
  with scope("pstring")
  val s = takeString()
  JsString(s.slice.substr(1, s.count - 1).string)

fun pArray()
  with scope("parray")
  pToken("[")
  val xs = separatedTrailing(pValue,{pToken(",")})
  optional(pWhitespace)
  pToken("]")
  JsArray(xs)

fun pMember()
  with scope("pmember")
  val k = takeString()
  optional(pWhitespace)
  pToken(":")
  val v = pValue()
  (k, v)

fun pObject()
  with scope("pobject")
  pToken("{")
  val members = separatedTrailing(pMember, {pToken(",")})
  optional(pWhitespace)
  val o = JsObject(linearMap(members, fn(s: string, s1: string) s == s1))
  pToken("}")
  o

fun pValue()
  with scope("pvalue")
  val v = ors([pArray,pObject,pLit,pFloat,pInteger,pString])
  optional(pWhitespace)
  v

val spacesRegex = r"^([ \n\t\r]|\/\/[^\n]+)+".regex()
fun pWhitespace()
  spacesRegex.takePattern()

fun pToken(s: string)
  text(s)
  optional(pWhitespace)

fun parse(s: string)
  s.println
  val x = match pValue.run(s)
    Right(e) -> e.show
    Left(err) -> "Error:\n" ++ err.show(fn(x: string) x, s)
  x.println
  
fun parse2(p, s: string, rshow)
  s.println
  val x = match p.run(s)
    Right(e) -> e.rshow
    Left(err) -> "Error:\n" ++ err.show(fn(x: string) x, s)
  x.println
  
fun main()
  parse(r#"{
  "hello":"world", // Something here
}"#
  )
  