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
 * @name Incomplete ordering
 * @description Class defines one or more ordering method but does not define all 4 ordering comparison methods
 * @kind problem
 * @tags reliability
 *       correctness
 * @problem.severity warning
 * @sub-severity low
 * @precision very-high
 * @id py/incomplete-ordering
 */

import python

predicate total_ordering(Class cls) {
    exists(Attribute a | a = cls.getADecorator() |
           a.getName() = "total_ordering")
    or
    exists(Name n | n = cls.getADecorator() |
           n.getId() = "total_ordering")
}

string ordering_name(int n) {
    result = "__lt__" and n = 1 or 
    result = "__le__" and n = 2 or 
    result = "__gt__" and n = 3 or 
    result = "__ge__" and n = 4
}

predicate overrides_ordering_method(ClassObject c, string name) {
    name = ordering_name(_) and
    (
        c.declaresAttribute(name)
        or
        exists(ClassObject sup | 
            sup = c.getASuperType() and not sup = theObjectType() |
            sup.declaresAttribute(name)
        )
    )
}

string unimplemented_ordering(ClassObject c, int n) {
    not c = theObjectType() and
    not overrides_ordering_method(c, result) and 
    result = ordering_name(n)
}

string unimplemented_ordering_methods(ClassObject c, int n) {
    n = 0 and result = "" and exists(unimplemented_ordering(c, _))
    or
    exists(string prefix, int nm1 |
        n = nm1 + 1 and prefix = unimplemented_ordering_methods(c, nm1) |
        prefix = "" and result = unimplemented_ordering(c, n)
        or
        result = prefix and not exists(unimplemented_ordering(c, n)) and n < 5
        or
        prefix != "" and result = prefix + " or " + unimplemented_ordering(c, n)
    )
}

Object ordering_method(ClassObject c, string name) {
    /* If class doesn't declare a method then don't blame this class (the superclass will be blamed). */
   name = ordering_name(_) and result = c.declaredAttribute(name)
}

from ClassObject c, Object ordering, string name
where not c.unknowableAttributes() and  
not total_ordering(c.getPyClass())
and ordering = ordering_method(c, name) and
exists(unimplemented_ordering(c, _))

select c, "Class " + c.getName() + " implements $@, but does not implement " + unimplemented_ordering_methods(c, 4) + ".", 
ordering, name


