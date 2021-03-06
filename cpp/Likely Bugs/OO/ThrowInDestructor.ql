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
 * @name Exception thrown in destructor
 * @description Throwing an exception from a destructor may cause immediate
 *              program termination.
 * @kind problem
 * @problem.severity warning
 * @precision very-high
 * @id cpp/throw-in-destructor
 * @tags reliability
 *       readability
 *       language-features
 */
import cpp

// This predicate finds the catch block enclosing a rethrow expression.
predicate bindEnclosingCatch(ReThrowExpr te, CatchBlock cb)
{
  te.getEnclosingBlock().getEnclosingBlock*() = cb
  and not exists(CatchBlock other | te.getEnclosingBlock().getEnclosingBlock*() = other and other.getEnclosingBlock+() = cb)
}

// This predicate strips references from types, i.e. T -> T, T* -> T*, T& -> T.
predicate bindStrippedReferenceType(Type qualified, Type unqualified)
{
  (not(qualified instanceof ReferenceType) and unqualified = qualified)
  or unqualified = qualified.(ReferenceType).getBaseType()
}

// This predicate determines (to a first approximation) the type thrown by a throw or rethrow expression.
predicate bindThrownType(ThrowExpr te, Type thrown)
{
  // For normal throws, the thrown type is easily determined as the type of the throw expression.
  (not(te instanceof ReThrowExpr) and thrown = te.getActualType())

  // For rethrows, we use the unqualified version of the type caught by the enclosing catch block.
  // Note that this is not precise, but is a reasonable first approximation.
  or exists(CatchBlock cb | bindEnclosingCatch(te, cb) and bindStrippedReferenceType(cb.getParameter().getType().getUnspecifiedType(), thrown))
}

// This predicate determines the catch blocks that can catch the exceptions thrown by each throw expression.
pragma[inline]
predicate canCatch(ThrowExpr te, CatchBlock cb)
{
  exists(Type thrown, Type caught |
    bindThrownType(te, thrown)
    and caught = cb.getParameter().getType().getUnspecifiedType()
    and not bindEnclosingCatch(te, cb)

    and
    (
      // Catching primitives by value or reference
      bindStrippedReferenceType(caught, thrown)

      // Catching class types by value or reference
      or exists(Class c | c = thrown and bindStrippedReferenceType(caught, c.getABaseClass*()))
    )
  )
}

// Find throw expressions such that there is a path in the control flow graph from the expression to
// the end of the destructor without an intervening catch block that can catch the type thrown.
from Destructor d, ThrowExpr te
where
  te.getEnclosingFunction() = d
  and not exists(CatchBlock cb |
    te.getASuccessor+() = cb
    and cb.getASuccessor+() = d
  | canCatch(te, cb)
    or
    // Catch anything -- written as `catch(...)`.
    not exists(cb.getParameter())
  )
select te, "Exception thrown in destructor."

