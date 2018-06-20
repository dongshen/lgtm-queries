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

import default
import semmle.code.java.deadcode.DeadCode
import external.ExternalArtifact

/**
 * A method in a FIT fixture class, typically used in the fitnesse framework.
 */
class FitFixtureEntryPoint extends CallableEntryPoint {
  FitFixtureEntryPoint() {
    getDeclaringType().getAnAncestor().hasQualifiedName("fit", "Fixture")
  }
}

/**
 * FitNesse entry points externally defined.
 */
class FitNesseSlimEntryPointData extends ExternalData {
  FitNesseSlimEntryPointData() {
    getDataPath().matches("fitnesse.csv")
  }

  /**
   * Get the class name.
   *
   * This may be a fully qualified name, or just the name of the class. It may also be, or
   * include, a FitNesse symbol, in which case it can be ignored.
   */
  string getClassName() {
    result = getField(0)
  }

  /**
   * Get a Class that either has `getClassName()` as the fully qualified name, or as the class name.
   */
  Class getACandidateClass() {
    result.getQualifiedName().matches(getClassName()) or
    result.getName() = getClassName()
  }

  /**
   * Get the name of the callable that will be called.
   */
  string getCallableName() {
    result = getField(1)
  }

  /**
   * Get the number of parameters for the callable that will be called.
   */
  int getNumParameters() {
    result = getField(2).toInt()
  }

  /**
   * Get a callable on one of the candidate classes that matches the criteria for the method name
   * and number of arguments.
   */
  Callable getACandidateCallable() {
    result.getDeclaringType() = getACandidateClass() and
    result.getName() = getCallableName() and
    result.getNumberOfParameters() = getNumParameters()
  }
}

/**
 * A callable that is a candidate for being called by a processed Slim FitNesse test. This entry
 * point requires that the FitNesse tests are processed by the fitnesse-liveness-processor, and
 * the resulting CSV file is included in the snapshots external data.
 */
class FitNesseSlimEntryPoint extends EntryPoint {
  FitNesseSlimEntryPoint() {
    exists(FitNesseSlimEntryPointData entryPointData |
      this = entryPointData.getACandidateCallable() and
      this.(Callable).fromSource()
    )
  }

  override Callable getALiveCallable() {
    result = this
  }
}