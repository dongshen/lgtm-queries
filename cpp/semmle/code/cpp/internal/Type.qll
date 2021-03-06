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

import semmle.code.cpp.Type

/** Holds if `d` is a complete class named `name`. */
pragma[noinline]
private predicate existsCompleteWithName(string name, @usertype d) {
  isClass(d) and
  is_complete(d) and
  usertypes(d, name, _)
}

/** Holds if `c` is an incomplete class named `name`. */
pragma[noinline]
private predicate existsIncompleteWithName(string name, @usertype c) {
  isClass(c) and
  not is_complete(c) and
  usertypes(c, name, _)
}

/**
 * Holds if `c` is an imcomplete class, and there exists a complete class `d`
 * with the same name.
 */
private predicate hasCompleteTwin(@usertype c, @usertype d) {
  exists(string name |
    existsIncompleteWithName(name, c) and
    existsCompleteWithName(name, d)
  )
}

/**
 * If `c` is incomplete, and there exists a complete class with the same name,
 * then the result is that complete class. Otherwise, the result is `c`. If
 * multiple complete classes have the same name, this predicate may have
 * multiple results.
 */
@usertype resolve(@usertype c) {
  hasCompleteTwin(c, result)
  or
  (not hasCompleteTwin(c, _) and result = c)
}

/**
 * Gets a type from the database for which `t` is a complete definition.
 */
@type unresolve(Type t) {
  if isClass(t)
  then resolve(result) = t
  else result = t
}

/**
 * Holds if `t` is a struct, class, union, template, or Objective-C class,
 * protocol, or category.
 */
predicate isClass(@usertype t) {
  (usertypes(t,_,1) or usertypes(t,_,2) or usertypes(t,_,3) or usertypes(t,_,6)
  or usertypes(t,_,10) or usertypes(t,_,11) or usertypes(t,_,12))
}
