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
 * Provides a taint tracking configuration for reasoning about password hashing with insufficient computational effort.
 */
import javascript
private import semmle.javascript.security.SensitiveActions
private import semmle.javascript.frameworks.CryptoLibraries

module InsufficientPasswordHash {
  /**
   * A data flow source for password hashing with insufficient computational effort.
   */
  abstract class Source extends DataFlow::Node {
    /** Gets a string that describes the type of this data flow source. */
    abstract string describe();
  }

  /**
   * A data flow sink for password hashing with insufficient computational effort.
   */
  abstract class Sink extends DataFlow::Node { }

  /**
   * A sanitizer for password hashing with insufficient computational effort.
   */
  abstract class Sanitizer extends DataFlow::Node { }

  /**
   * A taint tracking configuration for password hashing with insufficient computational effort.
   *
   * This configuration identifies flows from `Source`s, which are sources of
   * password data, to `Sink`s, which is an abstract class representing all
   * the places password data may be hashed with insufficient computational effort. Additional sources or sinks can be
   * added either by extending the relevant class, or by subclassing this configuration itself,
   * and amending the sources and sinks.
   */
  class Configuration extends TaintTracking::Configuration {
    Configuration() { this = "InsufficientPasswordHash" }

    override
    predicate isSource(DataFlow::Node source) {
      source instanceof Source
    }

    override
    predicate isSink(DataFlow::Node sink) {
      sink instanceof Sink
    }

    override
    predicate isSanitizer(DataFlow::Node node) {
      super.isSanitizer(node) or
      node instanceof Sanitizer
    }
  }

  /**
   * A potential clear-text password, considered as a source for password hashing
   * with insufficient computational effort.
   */
  class CleartextPasswordSource extends Source, DataFlow::ValueNode {
    override CleartextPasswordExpr astNode;

    override string describe() {
      result = astNode.describe()
    }
  }

  /**
   * An expression used by a cryptographic algorithm that is not suitable for password hashing.
   */
  class InsufficientPasswordHashAlgorithm extends Sink {
    InsufficientPasswordHashAlgorithm() {
      exists(CryptographicOperation application |
        application.getAlgorithm().isWeak() or
        not application.getAlgorithm() instanceof PasswordHashingAlgorithm |
        this.asExpr() = application.getInput()
      )
    }
  }
}

/** DEPRECATED: Use `InsufficientPasswordHash::Source` instead. */
deprecated class InsufficientPasswordHashSource = InsufficientPasswordHash::Source;

/** DEPRECATED: Use `InsufficientPasswordHash::Sink` instead. */
deprecated class InsufficientPasswordHashSink = InsufficientPasswordHash::Sink;

/** DEPRECATED: Use `InsufficientPasswordHash::Sanitizer` instead. */
deprecated class InsufficientPasswordHashSanitizer = InsufficientPasswordHash::Sanitizer;

/** DEPRECATED: Use `InsufficientPasswordHash::Configuration` instead. */
deprecated class InsufficientPasswordHashDataFlowConfiguration = InsufficientPasswordHash::Configuration;
