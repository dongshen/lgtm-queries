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
private import semmle.code.cpp.internal.Type

/**
 * A C/C++ enum [N4140 7.2].
 */
class Enum extends UserType, IntegralOrEnumType {
  /** Gets an enumerator of this enumeration. */
  EnumConstant getAnEnumConstant() { result.getDeclaringEnum() = this }
  EnumConstant getEnumConstant(int index) { enumconstants(result,this,index,_,_,_) }

  /**
   * Gets a descriptive string for the enum. This method is only intended to
   * be used for debugging purposes. For more information, see the comment
   * for `Type.explain`.
   */
  override string explain() { result =  "enum " + this.getName() }

  /** See `Type.isDeeplyConst` and `Type.isDeeplyConstBelow`. Internal. */
  override predicate isDeeplyConstBelow() { any() } // No subparts

  /**
   * Holds if this enum has an enum-base [N4140 7.2].
   * For example: `enum E : int`.
   */
  predicate hasExplicitUnderlyingType() {
    derivations(_, this, _, _, _)
  }

  /**
   * The type of the enum-base [N4140 7.2], if it is specified.
   * For example: `int` in `enum E : int`.
   */
  Type getExplicitUnderlyingType() {
    derivations(_, this, _, result, _)
  }
}

/**
 * A C++ enum that is directly enclosed by a function.
 */
class LocalEnum extends Enum {
  LocalEnum() {
    isLocal()
  }
}

/**
 * A C++ enum that is declared within a class.
 */
class NestedEnum extends Enum {

  NestedEnum() {
    this.isMember()
  }

  /** Holds if this member is private. */
  predicate isPrivate() { this.hasSpecifier("private") }

  /** Holds if this member is protected. */
  predicate isProtected() { this.hasSpecifier("protected") }

  /** Holds if this member is public. */
  predicate isPublic() { this.hasSpecifier("public") }

}

/**
 * A C++ scoped enum.
 *
 * For example, `enum class Color { red, blue }`.
 */
class ScopedEnum extends Enum {
  ScopedEnum() {
    usertypes(this,_,13)
  }
}

/**
 * A C/C++ enumerator [N4140 7.2].
 *
 * For example: `green` in `enum { red, green, blue }`.
 *
 * Enumerators are also knowns as enumeration constants.
 */
class EnumConstant extends @enumconstant, Declaration {
  /**
   * Gets the enumeration of which this enumerator is a member.
   */
  Enum getDeclaringEnum() { enumconstants(this,result,_,_,_,_) }

  override Class getDeclaringType() {
    result = this.getDeclaringEnum().getDeclaringType()
  }

  /**
   * Gets the name of this enumerator.
   */
  string getName() { enumconstants(this,_,_,_,result,_) }

  /**
   * Gets the value that this enumerator is initialized to, as a
   * string. This can be a value explicitly given to the enumerator, or an
   * automatically assigned value.
   */
  string getValue() { result = this.getInitializer().getExpr().getValue() }

  /** Gets the type of this enumerator. */
  Type getType() { enumconstants(this,_,_,unresolve(result),_,_) }

  /** Gets the location of a declaration of this enumerator. */
  Location getADeclarationLocation() { result = this.getDefinitionLocation() }

  /** Gets the location of the definition of this enumerator. */
  Location getDefinitionLocation() { enumconstants(this,_,_,_,_,result) }

  /** Gets the location of the definition of this enumerator. */
  override Location getLocation() { result = this.getDefinitionLocation() }

  /** Gets the initializer of this enumerator, if any. */
  Initializer getInitializer() { result.getDeclaration() = this }

  /** Gets an access of this enumerator. */
  EnumConstantAccess getAnAccess() { result.getTarget() = this }

  /** Gets a specifier of this enumerator. */
  Specifier getASpecifier() { varspecifiers(this,result) }

  /**
   * An attribute of this enumerator.
   *
   * Note that allowing attributes on enumerators is a language extension
   * which is only supported by Clang.
   */
  Attribute getAnAttribute() {
    varattributes(this, result)
  }
}
