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

import cpp
import semmle.code.cpp.controlflow.Dominance
import SSAUtils

library class StandardSSA extends SSAHelper {
    StandardSSA() { this = 0 }
}

/**
 * A definition of one or more SSA variables, including phi node definitions.
 * An _SSA variable_, as defined in the literature, is effectively the pair of
 * an `SsaDefinition d` and a `LocalScopeVariable v`, written `(d, v)` in this
 * documentation. Note that definitions and uses can be coincident due to the
 * presence of parameter definitions and phi nodes.
 *
 * Not all `LocalScopeVariable`s of a function have SSA definitions. If the variable
 * has its address taken, either explicitly or implicitly, then it is excluded
 * from analysis. `SsaDefinition`s are not generated in locations that are
 * statically seen to be unreachable.
 */
class SsaDefinition extends @cfgnode {

    SsaDefinition() {
        exists(StandardSSA x | x.ssa_defn(_, (ControlFlowNode)this, _, _))
    }

    /**
     * Gets a variable corresponding to an SSA LocalScopeVariable defined by
     * this definition.
     */
    LocalScopeVariable getAVariable() {
        exists(StandardSSA x | x.ssa_defn(result, (ControlFlowNode)this, _, _))
    }

    /** Gets a textual representation of this element. */
    string toString() {
        result = "SSA definition"
    }

    /**
     * Gets a string representation of the SSA variable represented by the pair
     * (this, v).
     */
    string toString(LocalScopeVariable v) {
        exists(StandardSSA x | result = x.toString((ControlFlowNode)this, v))
    }

    /** Gets a use of the SSA variable represented by the pair (this, v). */
    VariableAccess getAUse(LocalScopeVariable v) {
        exists(StandardSSA x | result = x.getAUse((ControlFlowNode)this, v))
    }

    /**
     * Gets the control-flow node for this definition. This will usually be the
     * control-flow node that assigns to this variable as a side effect, but
     * there are some exceptions. If `this` is defined by initialization, the
     * result is the value of `Initializer.getExpr()` for that initialization.
     * If `this` is a function parameter (see `definedByParameter`), the result
     * will be the function entry point. If `this` variable is defined by being
     * passed as a reference in a function call, including overloaded
     * operators, the result will be the `VariableAccess` expression for this
     * parameter. If `this` is a phi node (see `isPhiNode`), the result will be
     * the node where control flow is joined from multiple paths.
     */
    ControlFlowNode getDefinition() {
        result = this
    }

    BasicBlock getBasicBlock() {
        result.contains(getDefinition())
    }

    /** Holds if this definition is a phi node for variable `v`. */
    predicate isPhiNode(LocalScopeVariable v) {
        exists(StandardSSA x | x.phi_node(v, (BasicBlock)this))
    }

    Location getLocation() {
        result = this.(ControlFlowNode).getLocation()
    }

    /** Holds if the SSA variable `(this, p)` is defined by parameter `p`. */
    predicate definedByParameter(Parameter p) {
        this = p.getFunction().getEntryPoint()
    }

    /**
     * Holds if the SSA variable `(result, v)` is an input to the phi definition
     * `(this, v)`.
     */
    SsaDefinition getAPhiInput(LocalScopeVariable v) {
       this.isPhiNode(v)
       and
       result.reachesEndOfBB(v, this.(BasicBlock).getAPredecessor())
    }

    /**
     * Gets the expression assigned to the SSA variable `(this, v)`, if any,
     * when it is not a phi definition. The following is an exhaustive list of
     * expressions that may be the result of this predicate.
     *
     * - The contained expression of an `Initializer`.
     * - The right-hand side of an `AssignExpr`.
     * - An `AssignOperation`.
     * - A `CrementOperation`.
     *
     * In all cases except `PostfixCrementOperation`, the variable `v` will be
     * equal to the result of this predicate after evaluation of
     * `this.getDefinition()`.
     *
     * If the SSA variable is defined in other ways than those four (such as
     * function parameters or `f(&x)`) there is no result. These cases are
     * instead covered via `definedByParameter` and `getDefinition`,
     * respectively.
     */
    Expr getDefiningValue(LocalScopeVariable v) {
        exists(ControlFlowNode def | def = this.getDefinition() |
            def = v.getInitializer().getExpr() and def = result
            or
            exists(AssignExpr assign | def = assign and
                assign.getLValue() = v.getAnAccess() and result = assign.getRValue()
            )
            or
            exists(AssignOperation assign | def = assign and
                assign.getLValue() = v.getAnAccess() and result = assign
            )
            or
            exists(CrementOperation crement | def = crement and
                crement.getOperand() = v.getAnAccess() and result = crement
            )
        )
    }

    /** Holds if `(this, v)` reaches the end of basic block `b`. */
    predicate reachesEndOfBB(LocalScopeVariable v, BasicBlock b) {
        exists(StandardSSA x | x.ssaDefinitionReachesEndOfBB(v, (ControlFlowNode)this, b))
    }

    /**
     * Gets a definition that ultimately defines this variable and is not
     * itself a phi node.
     */
    SsaDefinition getAnUltimateSsaDefinition(LocalScopeVariable v) {
        result = this.getAPhiInput(v).getAnUltimateSsaDefinition(v)
        or
        v = this.getAVariable() and
        not this.isPhiNode(v) and
        result = this
    }

    /**
     * Gets a possible defining expression for `v` at this SSA definition,
     * recursing backwards through phi definitions. Not all definitions have a
     * defining expression---see the documentation for `getDefiningValue`.
     */
    Expr getAnUltimateDefiningValue(LocalScopeVariable v) {
        result = this.getAnUltimateSsaDefinition(v).getDefiningValue(v)
    }

    /**
     * DEPRECATED: this is the old name for `getAnUltimateDefiningValue`. The
     * name was confusing as it seemed analogous to `getDefinition` rather than
     * `getDefiningValue`. The SSA libraries for other languages use the name
     * `getAnUltimateSsaDefinition` to refer to a predicate named
     * `getAnUltimateSsaDefinition` in this class.
     */
    deprecated Expr getAnUltimateDefinition(LocalScopeVariable v) {
        result = this.getAnUltimateDefiningValue(v)
    }
}
