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
 * @name Multiplication result converted to larger type
 * @description A multiplication result that is converted to a larger type can
 *              be a sign that the result can overflow the type converted from.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id cpp/integer-multiplication-cast-to-long
 * @tags reliability
 *       security
 *       correctness
 *       types
 *       external/cwe/cwe-190
 *       external/cwe/cwe-192
 *       external/cwe/cwe-197
 *       external/cwe/cwe-681
 */
import cpp
import semmle.code.cpp.controlflow.SSA

/**
 * Holds if `e` is either:
 *  - a constant
 *  - an array access to an array of constants
 *  - flows from one of the above
 * In these cases the value of `e` is likely to be small and
 * controlled, so we consider it less likely to cause an overflow.
 */
predicate effectivelyConstant(Expr e) {
  e.isConstant() or
  e.(ArrayExpr).getArrayBase().getType().(ArrayType).getBaseType().isConst() or
  exists(SsaDefinition def, Variable v |
    def.getAUse(v) = e and
    effectivelyConstant(def.getDefiningValue(v))
  )
}

/**
 * Gets an operand of a multiply expression (we need the restriction
 * to multiply expressions to get the correct transitive closure).
 */
Expr getMulOperand(MulExpr me) {
  result = me.getAnOperand()
}

/**
 * Gets the number of non-constant operands of a multiply expression,
 * exploring into child multiply expressions rather than counting them
 * as an operand directly.  For example the top level multiply here
 * effectively has two non-constant operands:
 * ```
 *   (x * y) * 2
 * ```
 */
int getEffectiveMulOperands(MulExpr me) {
  result = count(Expr op |
    op = getMulOperand*(me) and
    not op instanceof MulExpr and
    not effectivelyConstant(op)
  )
}

from MulExpr me, Type t1, Type t2
where t1 = me.getType().getUnderlyingType() and
      t2 = me.getConversion().getType().getUnderlyingType() and
      t1.getSize() < t2.getSize() and
      (
        (
          t1.getUnspecifiedType() instanceof IntegralType and
          t2.getUnspecifiedType() instanceof IntegralType
        ) or (
          t1.getUnspecifiedType() instanceof FloatingPointType and
          t2.getUnspecifiedType() instanceof FloatingPointType
        )
      ) and

      // exclude explicit conversions
      me.getConversion().isCompilerGenerated() and

      // require the multiply to have two non-constant operands
      // (the intuition here is that multiplying two unknowns is
      // much more likely to produce a result that needs significantly
      // more bits than the operands did, and thus requires a larger
      // type).
      getEffectiveMulOperands(me) >= 2 and

      // exclude varargs promotions
      not exists(FunctionCall fc, int vararg |
        fc.getArgument(vararg) = me and
        vararg >= fc.getTarget().getNumberOfParameters()
      ) and

      // exclude cases where the type was made bigger by a literal
      // (compared to other cases such as assignment, this is more
      // likely to be a trivial accident rather than suggesting a
      // larger type is needed for the result).
      not exists(Expr other, Expr e |
        other = me.getParent().(BinaryOperation).getAnOperand() and
        not other = me and
        (
          e = other or
          e = other.(BinaryOperation).getAnOperand*()
        ) and
        e.(Literal).getType().getSize() = t2.getSize()
      )
select me, "Cast to '" + me.getFullyConverted().getType().toString() + "' before multiplication to avoid potential overflow."
