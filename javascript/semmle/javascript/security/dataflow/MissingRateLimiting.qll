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
 * Provides classes for reasoning about rate limiting.
 *
 * We model two main concepts:
 *
 *   1. expensive route handlers, which should be rate-limited;
 *   2. rate-limited route handler expressions, that set up a route handler in such a way
 *      that it is rate-limited.
 *
 * The query then looks for expensive route handlers that are not rate-limited.
 *
 * Both concepts are modeled as abstract classes (`ExpensiveRouteHandler` and
 * `RateLimitedRouteHandlerExpr`, respectively) with a few default subclasses capturing
 * common use cases. They can be customized by adding more subclasses.
 *
 * For `ExpensiveRouteHandler`, the default subclasses recognize route handlers performing
 * expensive actions, again modeled as an abstract class `ExpensiveAction`. By default,
 * file system access, operating system command execution, and database access are considered
 * expensive; other kinds of expensive actions can be modeled by adding more subclasses.
 *
 * For `RateLimitedRouteHandlerExpr`, the default subclasses model popular npm packages;
 * other means of rate-limiting can be supported by adding more subclasses.
 */
import javascript


// main concepts

/**
 * A route handler that should be rate-limited.
 */
abstract class ExpensiveRouteHandler extends HTTP::RouteHandler {
  Express::RouteHandler impl;

  ExpensiveRouteHandler() {
    this = impl
  }

  /**
   * Holds if `explanation` is a string explaining why this route handler should be rate-limited.
   *
   * The explanation may contain a `$@` placeholder, which is replaced by `reference` labeled
   * with `referenceLabel`. If `explanation` does not contain a placeholder, `reference` and
   * `referenceLabel` are ignored and should be bound to dummy values.
   */
  abstract predicate explain(string explanation, DataFlow::Node reference, string referenceLabel);

  override HTTP::HeaderDefinition getAResponseHeader(string name) {
    result = impl.getAResponseHeader(name)
  }
}

/**
 * A route handler expression that is rate limited.
 */
abstract class RateLimitedRouteHandlerExpr extends Express::RouteHandlerExpr {
}


// default implementations

/**
 * A route handler that performs an expensive action, and hence should be rate-limited.
 */
class RouteHandlerPerformingExpensiveAction extends ExpensiveRouteHandler, DataFlow::ValueNode {
  ExpensiveAction action;

  RouteHandlerPerformingExpensiveAction() {
    astNode = action.getContainer()
  }

  override predicate explain(string explanation, DataFlow::Node reference, string referenceLabel) {
    explanation = "performs $@" and
    reference = action and referenceLabel = action.describe()
  }
}

/**
 * A data flow node that corresponds to a resource-intensive action being taken.
 */
abstract class ExpensiveAction extends DataFlow::Node {
  /**
   * Gets a description of this expensive action for use in an alert message.
   *
   * The description is prepended with "performs" in the context of the alert message.
   */
  abstract string describe();
}

/** A call to an authorization function, considered as an expensive action. */
class AuthorizationCallAsExpensiveAction extends ExpensiveAction {
  AuthorizationCallAsExpensiveAction() { this instanceof AuthorizationCall }
  override string describe() { result = "authorization" }
}

/** A file system access, considered as an expensive action. */
class FileSystemAccessAsExpensiveAction extends ExpensiveAction {
  FileSystemAccessAsExpensiveAction() { this instanceof FileSystemAccess }
  override string describe() { result = "a file system access" }
}

/** A system command execution, considered as an expensive action. */
class SystemCommandExecutionAsExpensiveAction extends ExpensiveAction {
  SystemCommandExecutionAsExpensiveAction() { this instanceof SystemCommandExecution }
  override string describe() { result = "a system command" }
}

/** A database access, considered as an expensive action. */
class DatabaseAccessAsExpensiveAction extends ExpensiveAction {
  DatabaseAccessAsExpensiveAction() { this instanceof DatabaseAccess }
  override string describe() { result = "a database access" }
}

/**
 * A route handler expression that is rate-limited by a rate-limiting middleware.
 */
class RouteHandlerExpressionWithRateLimiter extends RateLimitedRouteHandlerExpr {
  RouteHandlerExpressionWithRateLimiter() {
    getAMatchingAncestor() instanceof RateLimiter
  }
}

/**
 * A middleware that acts as a rate limiter.
 */
abstract class RateLimiter extends Express::RouteHandlerExpr {
}

/**
 * A rate limiter constructed using the `express-rate-limit` package.
 */
class ExpressRateLimit extends RateLimiter {
  ExpressRateLimit() {
    DataFlow::moduleImport("express-rate-limit").getAnInstantiation().flowsToExpr(this)
  }
}

/**
 * A rate limiter constructed using the `express-brute` package.
 */
class BruteForceRateLimit extends RateLimiter {
  BruteForceRateLimit() {
    exists (DataFlow::ModuleImportNode expressBrute, DataFlow::SourceNode prevent |
      expressBrute.getPath() = "express-brute" and
      prevent = expressBrute.getAnInstantiation().getAPropertyRead("prevent") and
      prevent.flowsToExpr(this)
    )
  }
}

/**
 * A route handler expression that is rate-limited by the `express-limiter` package.
 */
class RouteHandlerLimitedByExpressLimiter extends RateLimitedRouteHandlerExpr {
  RouteHandlerLimitedByExpressLimiter() {
    exists (DataFlow::ModuleImportNode expressLimiter |
      expressLimiter.getPath() = "express-limiter" and
      expressLimiter.getACall().getArgument(0).getALocalSource().asExpr() = this.getSetup().getRouter()
    )
  }
}
