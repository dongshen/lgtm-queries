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
 * @name Potentially uninitialized local variable
 * @description Using a local variable before it is initialized causes an UnboundLocalError.
 * @kind problem
 * @tags reliability
 *       correctness
 * @problem.severity error
 * @sub-severity low
 * @precision medium
 * @id py/uninitialized-local-variable
 */

import python
import Undefined


predicate uninitialized_local(NameNode use) {
    exists(FastLocalVariable local |
        use.uses(local) or use.deletes(local) |
        not local.escapes()
    )
    and
    (
        any(Uninitialized uninit).taints(use)
        or
        not exists(EssaVariable var | var.getASourceUse() = use)
    )
}

predicate explicitly_guarded(NameNode u) {
    exists(Try t |
        t.getBody().contains(u.getNode()) and
        t.getAHandler().getType().refersTo(theNameErrorType())
    )
}


from NameNode u
where uninitialized_local(u) and not explicitly_guarded(u)
select u.getNode(), "Local variable '" + u.getId() + "' may be used before it is initialized."


