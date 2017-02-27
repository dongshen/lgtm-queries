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
 * @name Boxed variable is never null
 * @description Using a boxed type for a variable that is never assigned 'null'
 *              hinders readability because it implies that 'null' is a potential value.
 * @kind problem
 * @problem.severity recommendation
 * @tags readability
 *       types
 */
import java

class LocalBoxedVar extends LocalVariableDecl {
  LocalBoxedVar() {
    this.getType() instanceof BoxedType
  }

  PrimitiveType getPrimitiveType() {
    this.getType().(BoxedType).getPrimitiveType() = result
  }
}

/**
 * If a primitive value always occurs in a boxed context (and maybe more than once for each assigned value), then
 * declaring the type as a boxed type merely performs the boxing up front and is likely deliberate.
 *
 * As this pattern will never have local boxing-followed-by-unboxing sequences, and may in fact save
 * some number of boxing operations, these cases are excluded.
 */
predicate notDeliberatelyBoxed(LocalBoxedVar v) {
  not forall(RValue a | a = v.getAnAccess() |
    exists(Call c, int i |
      c.getCallee().getParameterType(i) instanceof RefType and
      c.getArgument(i) = a
    ) or
    exists(ReturnStmt ret |
      ret.getResult() = a and
      ret.getEnclosingCallable().getReturnType() instanceof RefType
    )
  )
}

/**
 * Replacing the type of a boxed variable with the corresponding primitive type may affect
 * overload resolution. If this is the case then the boxing is most likely intentional and
 * it should not be reported as a violation.
 */
predicate affectsOverload(LocalBoxedVar v) {
  exists(Call call, int i, Callable c1, Callable c2 |
    call.getCallee() = c1 and
    call.getArgument(i) = v.getAnAccess() and
    c1.getDeclaringType() = c2.getDeclaringType() and
    c1.getParameterType(i) instanceof RefType and
    c2.getParameterType(i) instanceof PrimitiveType and
    c1.getName() = c2.getName() and
    c1.getNumberOfParameters() = c2.getNumberOfParameters()
  )
}

from LocalBoxedVar v
where
  forall(Expr e | e = v.getAnAssignedValue() | e.getType() = v.getPrimitiveType()) and
  ( not v.getDeclExpr().getParent() instanceof EnhancedForStmt or
    v.getDeclExpr().getParent().(EnhancedForStmt).getExpr().getType().(Array).getComponentType() = v.getPrimitiveType()
  ) and
  notDeliberatelyBoxed(v) and
  not affectsOverload(v)
select v,
  "The variable '" + v.getName() + "' is only assigned values of primitive type and is never 'null', but it is declared with the boxed type '" +
  v.getType().toString() + "'."
