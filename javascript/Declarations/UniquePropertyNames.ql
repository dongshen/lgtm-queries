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
 * @name Overwritten property
 * @description If an object literal has two properties with the same name,
 *              the second property overwrites the first one,
 *              which makes the code hard to understand and error-prone.
 * @kind problem
 * @problem.severity error
 * @id js/overwritten-property
 * @tags reliability
 *       correctness
 *       external/cwe/cwe-563
 * @precision very-high
 */

import Expressions.Clones

/**
 * Holds if `p` is the `i`th property of object expression `o`, and its
 * kind is `kind`.
 *
 * The kind is an integer value indicating whether `p` is a value property (0),
 * a getter (1) or a setter (2).
 */
predicate hasProperty(ObjectExpr o, Property p, string name, int kind, int i) {
  p = o.getProperty(i) and
  name = p.getName() and
  kind = p.getKind()
}

/**
 * Holds if property `p` appears before property `q` in the same object literal and
 * both have the same name and kind, but are not structurally identical.
 */
predicate overwrittenBy(Property p, Property q) {
  exists (ObjectExpr o, string name, int i, int j, int kind |
    hasProperty(o, p, name, kind, i) and
    hasProperty(o, q, name, kind, j) and
    i < j
  ) and
  // exclude structurally identical properties: they are flagged by
  // the DuplicateProperty query
  not p.getInit().(DuplicatePropertyInitDetector).same(q.getInit())
}

from Property p, Property q
where overwrittenBy(p, q) and
      // ensure that `q` is the last property with the same name as `p`
      not overwrittenBy(q, _)
select p, "This property is overwritten by $@ in the same object literal.", q, "another property"