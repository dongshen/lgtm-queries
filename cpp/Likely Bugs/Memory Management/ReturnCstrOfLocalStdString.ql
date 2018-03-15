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
 * @name Return c_str of local std::string
 * @description Returning the c_str of a locally allocated std::string
 *   could cause the program to crash or behave non-deterministically
 *   because the memory is deallocated when the std::string goes out of
 *   scope.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id cpp/return-c-str-of-std-string
 */

import cpp
import semmle.code.cpp.controlflow.SSA
import semmle.code.cpp.dataflow.DataFlow

/** The `std::string` class. */
class StdString extends Class {
  StdString() {
    // `std::string` is usually a typedef and the actual class
    // is called something like `string  std::__cxx11::basic_string`.
    exists (Type stdstring, Namespace std
    | stdstring.getName() = "string" and
      this = stdstring.getUnspecifiedType() and
      // Make sure that the class is in the `std` namespace.
      std = this.getNamespace().getParentNamespace*() and
      std.getName() = "std" and
      std.getParentNamespace() instanceof GlobalNamespace)
  }
}

/**
 * Holds if `e` is a direct or indirect reference to a locally
 * allocated `std::string`.
 */
predicate refToStdString(Expr e, ConstructorCall source) {
  exists (StdString stdstring
  | stdstring.getAMemberFunction() = source.getTarget() and
    e = source)
  or
  // Indirect use.
  exists(Expr prev
  | refToStdString(prev, source) and
    DataFlow::localFlowStep(DataFlow::exprNode(prev), DataFlow::exprNode(e)))
}

/**
 * Holds if the function takes a C-style string as one of its arguments and
 * includes the pointer in its result without making a copy of the
 * string. An example of this is the method `JNIEnv::NewStringUTF()` (from
 * Java's JNI), which returns a `jstring` containing a pointer to the
 * C-style string. If the C-style string is deallocated then the `jstring`
 * will also become invalid.
 */
predicate flowFunction(Function fcn, int argIndex) {
  (fcn.getQualifiedName() = "_JNIEnv::NewStringUTF" and argIndex = 0)
  or
  (fcn.getQualifiedName() = "art::JNI::NewStringUTF" and argIndex = 1)
  or
  (fcn.getQualifiedName() = "art::CheckJNI::NewStringUTF" and argIndex = 1)
  
  // Add other functions that behave like NewStringUTF here.
}

/**
 * Holds if `e` is a direct or indirect reference to the result of calling
 * `c_str` on a locally allocated `std::string`.
 */
predicate refToCStr(Expr e, ConstructorCall source) {
  exists (MemberFunction f, FunctionCall call
  | f.getName() = "c_str" and
    call = e and
    call.getTarget() = f and
    refToStdString(call.getQualifier(), source))
  or
  // Indirect use.
  exists(Expr prev
  | refToCStr(prev, source) and
    DataFlow::localFlowStep(DataFlow::exprNode(prev), DataFlow::exprNode(e)))
  or
  // Some functions, such as `JNIEnv::NewStringUTF()` (from Java's JNI)
  // embed return a structure containing a reference to the C-style string.
  exists (Function f, int argIndex
  | flowFunction(f, argIndex) and
    f = e.(Call).getTarget() and
    refToCStr(e.(Call).getArgument(argIndex), source))
}

from ReturnStmt r, ConstructorCall source
where refToCStr(r.getExpr(), source)
select
  r, "Return value may contain a dangling pointer to $@.",
  source, "this local std::string."
