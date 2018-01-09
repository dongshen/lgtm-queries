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
 * @name Unterminated variadic call
 * @description Calling a variadic function without a sentinel value
 *              may result in a buffer overflow if the function expects
 *              a specific value to terminate the argument list.
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id cpp/unterminated-variadic-call
 * @tags reliability
 *       security
 *       external/cwe/cwe-121
 */

import cpp

/**
 * Gets a normalized textual representation of `e`'s value.
 * The result is the same as `Expr.getValue()`, except if there is a
 * trailing `".0"` then it is removed. This means that, for example,
 * the values of `-1` and `-1.0` would be considered the same.
 */
string normalisedExprValue(Expr e) {
  result = e.getValue().regexpReplaceAll("\\.0$", "")
}

/**
 * A variadic function which is not a formatting function.
 */
class VarargsFunction extends Function {
  VarargsFunction() {
    this.isVarargs() and
    not this instanceof FormattingFunction
  }

  Expr trailingArgumentIn(FunctionCall fc) {
    fc = this.getACallToThisFunction() and
    result = fc.getArgument(fc.getNumberOfArguments() - 1)
  }

  string trailingArgValue(FunctionCall fc) {
    result = normalisedExprValue(this.trailingArgumentIn(fc))
  }

  private
  int trailingArgValueCount(string value) {
    result = strictcount(FunctionCall fc | trailingArgValue(fc) = value)
  }

  string nonTrailingVarArgValue(FunctionCall fc, int index) {
    fc = this.getACallToThisFunction() and
    index >= this.getNumberOfParameters() and
    index < fc.getNumberOfArguments() - 1 and
    result = normalisedExprValue(fc.getArgument(index))
  }

  private
  int totalCount() {
    result = strictcount(FunctionCall fc | fc = this.getACallToThisFunction())
  }

  string normalTerminator(int cnt) {
    (
      result = "0" or result = "-1"
    ) and (
      cnt = trailingArgValueCount(result)
    ) and (
      2 * cnt > totalCount()
    ) and not exists(FunctionCall fc, int index |
      // terminator value is used in a non-terminating position
      nonTrailingVarArgValue(fc, index) = result
    )
  }

  predicate isWhitelisted() {
    this.hasQualifiedName("open") or
    this.hasQualifiedName("fcntl") or
    this.hasQualifiedName("ptrace")
  }
}

from VarargsFunction f, FunctionCall fc, string terminator, int cnt
where terminator = f.normalTerminator(cnt)
  and fc = f.getACallToThisFunction()
  and not normalisedExprValue(f.trailingArgumentIn(fc)) = terminator
  and not f.isWhitelisted()
select fc, "Calls to $@ should use the value " + terminator
         + " as a terminator (" + cnt + " calls do).", f, f.getQualifiedName()
