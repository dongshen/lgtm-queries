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
 * Provides a set of QL clcasses for indicating dataflows through a particular
 * parameter, return value, or qualifier, as well as flows at one level of
 * pointer indirection.
 */

import semmle.code.cpp.Parameter

/**
 * An `int` that is a parameter index for some function.  This is needed for binding in certain cases.
 */
class ParameterIndex extends int {
  ParameterIndex() { exists(Parameter p | this = p.getIndex()) }
}

newtype TFunctionInput =
  TInParameter(ParameterIndex i)
  or
  TInParameterPointer(ParameterIndex i)
  or
  TInQualifier()

class FunctionInput extends TFunctionInput {
  abstract string toString();
  
  predicate isInParameter(ParameterIndex index) {
    none()
  }
  
  predicate isInParameterPointer(ParameterIndex index) {
    none()
  }
  
  predicate isInQualifier() {
    none()
  }
}

class InParameter extends FunctionInput, TInParameter {
  ParameterIndex index;
  
  InParameter() {
    this = TInParameter(index)
  }
  
  string toString() {
    result = "InParameter " + index.toString()
  }
  
  ParameterIndex getIndex() {
    result = index
  }
  
  override predicate isInParameter(ParameterIndex i) {
    i = index
  }
}

class InParameterPointer extends FunctionInput, TInParameterPointer {
  ParameterIndex index;
  
  InParameterPointer() {
    this = TInParameterPointer(index)
  }
  
  string toString() {
    result = "InParameterPointer " + index.toString()
  }
  
  ParameterIndex getIndex() {
    result = index
  }

  override predicate isInParameterPointer(ParameterIndex i) {
    i = index
  }
}

class InQualifier extends FunctionInput, TInQualifier {
  string toString() {
    result = "InQualifier"
  }
  
  override predicate isInQualifier() {
    any()
  }
}

newtype TFunctionOutput =
  TOutParameterPointer(ParameterIndex i)
  or
  TOutQualifier()
  or
  TOutReturnValue()
  or
  TOutReturnPointer()


class FunctionOutput extends TFunctionOutput {
  abstract string toString();
  
  predicate isOutParameterPointer(ParameterIndex i) {
    none()
  }
  
  predicate isOutQualifier() {
    none()
  }
  
  predicate isOutReturnValue() {
    none()
  }
  
  predicate isOutReturnPointer() {
    none()
  }
}

class OutParameterPointer extends FunctionOutput, TOutParameterPointer {
  ParameterIndex index;
  
  OutParameterPointer() {
    this = TOutParameterPointer(index)
  }
  
  string toString() {
    result = "OutParameterPointer " + index.toString()
  }
  
  ParameterIndex getIndex() {
    result = index
  }
  
  override predicate isOutParameterPointer(ParameterIndex i) {
    i = index
  }
}

class OutQualifier extends FunctionOutput, TOutQualifier {
  string toString() {
    result = "OutQualifier"
  }
  
  override predicate isOutQualifier() {
    any()
  }
}

class OutReturnValue extends FunctionOutput, TOutReturnValue {
  string toString() {
    result = "OutReturnValue"
  }
  
  override predicate isOutReturnValue() {
    any()
  }
}

class OutReturnPointer extends FunctionOutput, TOutReturnPointer {
  string toString() {
    result = "OutReturnPointer"
  }
  
  override predicate isOutReturnPointer() {
    any()
  }
}