// Copyright 2018 Semmle Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

/**
 * @name Incomplete sanitization
 * @description A sanitizer that does not replace or escape all occurrences of a
 *              problematic substring may be ineffective.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id js/incomplete-sanitization
 * @tags correctness
 *       security
 *       external/cwe/cwe-116
 *       external/cwe/cwe-20
 */

import javascript

/**
 * Gets a character that is commonly used as a meta-character.
 *
 * We heuristically assume that string replacements involving one of these
 * characters are meant to be sanitizers.
 */
string metachar() {
  result = "'\"\\&<>\n\r\t*|{}[]%$".charAt(_)
}

/** Gets a string matched by `e` in a `replace` call. */
string getAMatchedString(Expr e) {
  result = getAMatchedConstant(e.(RegExpLiteral).getRoot()).getValue()
  or
  result = e.(StringLiteral).getValue()
}

/** Gets a constant matched by `t`. */
RegExpConstant getAMatchedConstant(RegExpTerm t) {
  result = t
  or
  result = getAMatchedConstant(t.(RegExpAlt).getAlternative())
  or
  result = getAMatchedConstant(t.(RegExpGroup).getAChild())
  or
  exists (RegExpCharacterClass recc | recc = t and not recc.isInverted() |
    result = getAMatchedConstant(recc.getAChild())
  )
}

/** Holds if `t` is simple, that is, a union of constants. */
predicate isSimple(RegExpTerm t) {
  t instanceof RegExpConstant
  or
  isSimple(t.(RegExpGroup).getAChild())
  or
  (
   t instanceof RegExpAlt or
   t instanceof RegExpCharacterClass and not t.(RegExpCharacterClass).isInverted()
  ) and
  forall (RegExpTerm ch | ch = t.getAChild() | isSimple(ch))
}

/**
 * Holds if `mce` is of the form `x.replace(re, new)`, where `re` is a global
 * regular expression and `new` prefixes the matched string with a backslash.
 */
predicate isBackslashEscape(MethodCallExpr mce, RegExpLiteral re) {
  mce.getMethodName() = "replace" and
  re = mce.getArgument(0) and
  re.isGlobal() and
  exists (string new | new = mce.getArgument(1).getStringValue() |
    // `new` is `\$&`, `\$1` or similar
    new.regexpMatch("\\\\\\$(&|\\d)")
    or
    // `new` is `\c`, where `c` is a constant matched by `re`
    new.regexpMatch("\\\\\\Q" + getAMatchedString(re) + "\\E")
  )
}

/**
 * Holds if data flowing into `nd` has no unescaped backslashes.
 */
predicate allBackslashesEscaped(DataFlow::Node nd) {
  // `JSON.stringify` escapes backslashes
  nd = DataFlow::globalVarRef("JSON").getAMemberCall("stringify")
  or
  // check whether `nd` itself escapes backslashes
  exists (RegExpLiteral rel | isBackslashEscape(nd.asExpr(), rel) |
    // if it's a complex regexp, we conservatively assume that it probably escapes backslashes
    not isSimple(rel.getRoot()) or
    getAMatchedString(rel) = "\\"
  )
  or
  // flow through string methods
  exists (DataFlow::MethodCallNode mc, string m |
    m = "replace" or
    m = "slice" or m = "substr" or m = "substring" or
    m = "toLowerCase" or m = "toUpperCase" or m = "trim" |
    mc = nd and m = mc.getMethodName() and allBackslashesEscaped(mc.getReceiver())
  )
  or
  // general data flow
  allBackslashesEscaped(nd.getAPredecessor())
}

from MethodCallExpr repl, Expr old, string msg
where repl.getMethodName() = "replace" and
      old = repl.getArgument(0) and
      (
       not old.(RegExpLiteral).isGlobal() and
       msg = "This replaces only the first occurrence of " + old + "." and
       // only flag if this is likely to be a sanitizer
       getAMatchedString(old) = metachar() and
       // don't flag replace operations in a loop
       not DataFlow::valueNode(repl.getReceiver()) = DataFlow::valueNode(repl).getASuccessor+()
       or
       exists (RegExpLiteral rel |
         isBackslashEscape(repl, rel) and
         not allBackslashesEscaped(DataFlow::valueNode(repl)) and
         msg = "This does not backslash-escape the backslash character."
       )
      )
select old, msg
