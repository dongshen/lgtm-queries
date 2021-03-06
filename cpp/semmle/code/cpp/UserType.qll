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

import semmle.code.cpp.Declaration
import semmle.code.cpp.Type
import semmle.code.cpp.Member
import semmle.code.cpp.Function
private import semmle.code.cpp.internal.Type

/**
 * A C/C++ user-defined type. Examples include `Class`, `Struct`, `Union`,
 * `Enum`, and `TypedefType`.
 */
class UserType extends Type, Declaration, NameQualifyingElement, AccessHolder, @usertype {
  UserType() {
    isClass(this) implies this = resolve(_)
  }

  /** the name of this type */
  override string getName() { usertypes(this,result,_) }

  /** the simple name of this type, without any template parameters */
  string getSimpleName() {
    result = getName().regexpReplaceAll("<.*", "")
  }

  predicate hasName(string name) {
    usertypes(this,name,_)
  }
  predicate isAnonymous() {
    getName().matches("(unnamed%")
  }

  predicate hasSpecifier(string s) {
    Type.super.hasSpecifier(s)
  }
  Specifier getASpecifier() {
    result = Type.super.getASpecifier()
  }

  Location getLocation() {
    if isDefined() then
      result = this.getDefinitionLocation()
    else
      result = this.getADeclarationLocation()
  }

  TypeDeclarationEntry getADeclarationEntry() {
    if type_decls(_, unresolve(this), _) then
      type_decls(result, unresolve(this), _)
    else
      exists(UserType t | class_instantiation(this, t) and result = t.getADeclarationEntry())
  }

  Location getADeclarationLocation() {
    result = getADeclarationEntry().getLocation()
  }

  TypeDeclarationEntry getDefinition() {
    result = getADeclarationEntry() and
    result.isDefinition()
  }

  /** the location of the definition */
  Location getDefinitionLocation() {
    if exists(getDefinition()) then
      result = getDefinition().getLocation()
    else
      exists(UserType t | class_instantiation(this,t) and result = t.getDefinition().getLocation())
  }

  /** Gets the function that directly encloses this type (if any). */
  Function getEnclosingFunction() {
    enclosingfunction(this,result)
  }

  /** Whether this is a local type (i.e. a type that has a directly-enclosing function). */
  predicate isLocal() {
    exists(getEnclosingFunction())
  }

  // Dummy implementations of inherited methods. This class must not be
  // made abstract, because it is important that it captures the @usertype
  // type exactly - but this is not apparent from its subclasses

  Declaration getADeclaration() { none() }

  override string explain() { result = this.getName() }

  // further overridden in LocalClass
  override AccessHolder getEnclosingAccessHolder() {
    result = this.getDeclaringType()
  }
}

/**
 * A particular definition or forward declaration of a C/C++ user-defined type.
 */
class TypeDeclarationEntry extends DeclarationEntry, @type_decl {
  UserType getDeclaration() { result = getType() }
  string getName() { result = getType().getName() }

  /**
   * The type which is being declared or defined.
   */
  Type getType() { type_decls(this,unresolve(result),_) }

  Location getLocation() { type_decls(this,_,result) }
  predicate isDefinition() { type_def(this) }
  string getASpecifier() { none() }

  /**
   * A top level type declaration entry is not declared within a function, function declaration,
   * class or typedef.
   */
  predicate isTopLevel() { type_decl_top(this) }
}
