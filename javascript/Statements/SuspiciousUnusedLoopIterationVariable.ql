// Copyright 2017 Semmle Ltd.
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
 * @name Unused loop iteration variable
 * @description A loop iteration variable is unused, which suggests an error.
 * @kind problem
 * @problem.severity error
 * @tags maintainability
 *       correctness
 * @precision high
 */

import javascript
private import semmle.javascript.SSA

/**
 * An expression that adds a value to a variable.
 *
 * This includes `+=` expressions, pre- and post-increment expressions,
 * and expressions of the form `x = x + e`.
 */
class IncrementExpr extends Expr {
  IncrementExpr() {
    // x += e
    this instanceof AssignAddExpr or
    // ++x or x++
    this instanceof PreIncExpr or this instanceof PostIncExpr or
    // x = x + e
    exists (AssignExpr assgn, Variable v | assgn = this |
      assgn.getTarget() = v.getAnAccess() and
      assgn.getRhs().(AddExpr).getAnOperand().stripParens() = v.getAnAccess()
    )
  }
}

/**
 * Holds if `efl` is a loop whose body increments a variable and does nothing else.
 */
predicate countingLoop(EnhancedForLoop efl) {
  exists (ExprStmt inc | inc.getExpr().stripParens() instanceof IncrementExpr |
    inc = efl.getBody() or
    inc = efl.getBody().(BlockStmt).getAStmt()
  )
}

from EnhancedForLoop efl, PurelyLocalVariable iter
where iter = efl.getAnIterationVariable() and
      not exists (SSAExplicitDefinition ssa | ssa.defines(efl.getIteratorExpr(), iter)) and
      exists (ReachableBasicBlock body | body.getANode() = efl.getBody() |
        body.getASuccessor+() = body
      ) and
      not countingLoop(efl) and
      not iter.getName().toLowerCase().regexpMatch("(_|dummy|unused).*")
select efl.getIterator(), "For loop variable " + iter.getName() + " is not used in the loop body."