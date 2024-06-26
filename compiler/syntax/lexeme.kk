import std/text/regex
import std/os/path
import std/text/unicode
import compiler/common/name
import compiler/common/range
import std/num/float64
import compiler/common/id

val typeVarRegex = "^[a-z][0-9]*$".regex();

pub fun isTypeVar(n: name): bool
  !typeVarRegex.exec(n.nameStem).is-empty

pub struct lexeme ( pub range: range, pub lex: lex )

pub type lex
  LexInt(i: int, s: string)
  LexFloat(f: float64, s: string)
  LexChar(c: char)
  LexString(s: string)
  LexId(n: name)
  LexCons(n: name)
  LexOp(n: name)
  LexPrefix(n: name)
  LexIdOp(n: name)
  LexWildCard(n: name)
  LexKeyword(s: string, k: string)
  LexSpecial(s: string)
  LexComment(s: string)
  LexWhite(s: string)
  // Special for highlighting
  LexModule(alias_: name, full: name)
  LexTypeId(n: name, s: string)
  LexInsLCurly
  LexInsRCurly
  LexInsSemi
  LexError(s: string)

fun is-lcurly(l: lex): bool
  match l
    LexInsLCurly -> True
    LexSpecial("{") -> True
    _ -> False

fun is-rcurly(l: lex): bool
  match l
    LexInsRCurly -> True
    LexSpecial("}") -> True
    _ -> False

fun is-rparen(l: lex): bool
  match l
    LexSpecial(")") -> True
    _ -> False

fun is-lparen(l: lex): bool
  match l
    LexSpecial("(") -> True
    _ -> False

fun is-rangle(l: lex): bool
  match l
    LexSpecial(">") -> True
    LexOp(nm) | nm.show-plain == ">" -> True
    _ -> False

fun is-langle(l: lex): bool
  match l
    LexSpecial("<") -> True
    LexOp(nm) | nm.show-plain == "<" -> True
    _ -> False

fun is-rbracket(l: lex): bool
  match l
    LexSpecial("]") -> True
    _ -> False

fun is-lbracket(l: lex): bool
  match l
    LexSpecial("[") -> True
    _ -> False

pub fun lexeme/(==)(l1: lexeme, l2: lexeme): bool
  l1.range == l2.range && l1.lex == l2.lex

pub fun lex/(==)(l1: lex, l2: lex): bool
  match (l1, l2)
    (LexInt(i1, s1), LexInt(i2, s2)) -> i1 == i2 && s1 == s2
    (LexFloat(f1, s1), LexFloat(f2, s2)) -> f1 == f2 && s1 == s2
    (LexChar(c1), LexChar(c2)) -> c1 == c2
    (LexString(s1), LexString(s2)) -> s1 == s2
    (LexId(n1), LexId(n2)) -> n1 == n2
    (LexCons(n1), LexCons(n2)) -> n1 == n2
    (LexOp(n1), LexOp(n2)) -> n1 == n2
    (LexPrefix(n1), LexPrefix(n2)) -> n1 == n2
    (LexIdOp(n1), LexIdOp(n2)) -> n1 == n2
    (LexWildCard(n1), LexWildCard(n2)) -> n1 == n2
    (LexKeyword(s1, k1), LexKeyword(s2, k2)) -> s1 == s2 && k1 == k2
    (LexSpecial(s1), LexSpecial(s2)) -> s1 == s2
    (LexComment(s1), LexComment(s2)) -> s1 == s2
    (LexWhite(s1), LexWhite(s2)) -> s1 == s2
    (LexModule(a1, f1), LexModule(a2, f2)) -> a1 == a2 && f1 == f2
    (LexTypeId(n1, s1), LexTypeId(n2, s2)) -> n1 == n2 && s1 == s2
    (LexInsLCurly, LexInsLCurly) -> True
    (LexInsRCurly, LexInsRCurly) -> True
    (LexInsSemi, LexInsSemi) -> True
    (LexError(s1), LexError(s2)) -> s1 == s2
    _ -> False

pub fun lex/is-error(l: lex)
  match l
    LexError(_) -> True
    _ -> False

pub fun lexeme/is-white(l: lexeme): <> bool
  l.lex.is-white

pub fun lexeme/is-whitespace(l: lexeme): <> bool
  l.lex.is-whitespace

pub fun lex/is-white(l: lex): <> bool
  match l
    LexWhite(_) -> True
    LexComment(_) -> True
    _ -> False

pub fun lex/is-whitespace(l: lex): <> bool
  match l
    LexWhite(_) -> True
    _ -> False

pub fun is-semicolon(l: lexeme): bool
  match l.lex
    LexInsSemi -> True
    LexSpecial(";") -> True
    _ -> False

pub fun same-lexeme(l1: lexeme, l2: lexeme): <> bool
  match (l1.lex, l2.lex)
    (LexKeyword(n1, _), LexKeyword(n2, _)) -> n1 == n2 
    (LexSpecial(n1), LexSpecial(n2)) -> n1 == n2
    (_, _) -> l1.lex.from-enum == l2.lex.from-enum

pub fun from-enum(l: lex): <> int
  match l
    LexInt(_, __) -> 0
    LexFloat(_, __) -> 1
    LexChar(_) -> 2
    LexString(_) -> 3
    LexId(_) -> 4
    LexOp(_) -> 5
    LexPrefix(_) -> 19
    LexIdOp(_) -> 20
    LexWildCard(_) -> 6
    LexModule(_, _) -> 7
    LexKeyword(_, _) -> 8
    LexSpecial(_) -> 9
    LexComment(_) -> 10
    LexWhite(_) -> 11
    LexInsLCurly -> 13
    LexInsRCurly -> 14
    LexInsSemi -> 15
    LexError(_) -> 16
    LexCons(_) -> 17
    LexTypeId(_, _) -> 18

pub fun lexeme/show(l: lexeme): <> string
  l.range.show-full-range("".path) ++ ": " ++ l.lex.show

pub fun lex/show(l: lex): <> string
  match l
    LexInt(_, s) -> "int " ++ s.show
    LexFloat(_, s) -> "float " ++ s.show
    LexChar(c) -> "char " ++ c.show
    LexString(s) -> "string \"" ++ s ++ "\""
    LexId(n) -> "identifier \"" ++ n.show ++ "\""
    LexOp(n) -> "operator \"" ++ n.show ++ "\""
    LexPrefix(n) -> "prefix operator \"" ++ n.show ++ "\""
    LexIdOp(n) -> "identifier (operator) \"" ++ n.show ++ "\""
    LexWildCard(n) -> "wildcard \"" ++ n.show ++ "\""
    LexModule(n, _) -> "module \"" ++ n.show ++ "\""
    LexKeyword(k, d) -> "keyword \"" ++ k.show ++ "\"" ++ (if d.is-empty then "" else " (" ++ d ++ ")")
    LexSpecial(s) -> "special \"" ++ s ++ "\""
    LexComment(s) -> "comment \"" ++ s.show ++ "\""
    LexWhite(x) -> "white" ++ x.show ++ ""
    LexInsLCurly -> "start of statements ('{')"
    LexInsRCurly -> "end of statements ('}')"
    LexInsSemi -> "end of statement (';')"
    LexError(s) -> "error: " ++ s ++ ""
    LexCons(n) -> "constructor \"" ++ n.show ++ "\""
    LexTypeId(n, s) -> "typedid " ++ n.show ++ ":" ++ s
