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
 * @name Insecure URL whitelist
 * @description URL whitelists that are too permissive can cause security vulnerabilities.
 * @kind problem
 * @problem.severity warning
 * @precision very-high
 * @id js/angular/insecure-url-whitelist
 * @tags security
 *       frameworks/angularjs
 *       external/cwe/cwe-183
 *       external/cwe/cwe-625
 */

import javascript

/**
 * Holds if `setupCall` is a call to `$sceDelegateProvider.resourceUrlWhitelist` with
 * argument `list`.
 */
predicate isResourceUrlWhitelist(DataFlow::MethodCallNode setupCall, DataFlow::ArrayLiteralNode list) {
  exists (AngularJS::ServiceReference service |
    service.getName() = "$sceDelegateProvider" and
    setupCall.asExpr() = service.getAMethodCall("resourceUrlWhitelist") and
    list.flowsTo(setupCall.getArgument(0))
  )
}

/**
 * An entry in a resource URL whitelist.
 */
class ResourceUrlWhitelistEntry extends Expr {
  DataFlow::MethodCallNode setupCall;
  string pattern;

  ResourceUrlWhitelistEntry() {
    exists (DataFlow::ArrayLiteralNode whitelist |
      isResourceUrlWhitelist(setupCall, whitelist) and
      this = whitelist.getAnElement().asExpr() and
      this.mayHaveStringValue(pattern)
    )
  }

  /**
   * Gets the method call that sets up this whitelist.
   */
  DataFlow::MethodCallNode getSetupCall() {
    result = setupCall
  }

  /**
   * Holds if this expression is insecure to use in an URL pattern whitelist due
   * to the reason given by `explanation`.
   */
  predicate isInsecure(string explanation) {
    exists (string componentName, string component |
      exists (int componentNumber |
        componentName = "scheme" and componentNumber = 1
        or
        componentName = "domain" and componentNumber = 2
        or
        componentName = "TLD" and componentNumber = 4
        |
        component = pattern.regexpCapture("(.*?)://(.*?(\\.(.*?))?)(:\\d+)?(/.*)?", componentNumber)
      )
      and
      explanation = "the " + componentName + " '" + component + "' is insecurely specified"
      |
      componentName = "scheme" and component.matches("%*%")
      or
      componentName = "domain" and component.matches("%**%")
      or
      componentName = "TLD" and component = "*"
    )
  }
}

from ResourceUrlWhitelistEntry entry, DataFlow::MethodCallNode setupCall, string explanation
where entry.isInsecure(explanation) and
      setupCall = entry.getSetupCall()
select setupCall, "'$@' is not a secure whitelist entry, because " + explanation + ".",
                  entry, entry.toString()
