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
 * Provides a data flow configuration for reasoning about hardcoded credentials.
 */
import javascript
private import semmle.javascript.security.SensitiveActions

module HardcodedCredentials {
  /**
   * A data flow source for hardcoded credentials.
   */
  abstract class Source extends DataFlow::Node { }

  /**
   * A data flow sink for hardcoded credentials.
   */
  abstract class Sink extends DataFlow::Node {
    abstract string getKind();
  }

  /**
   * A sanitizer for hardcoded credentials.
   */
  abstract class Sanitizer extends DataFlow::Node { }

  /**
   * A data flow tracking configuration for hardcoded credentials.
   */
  class Configuration extends DataFlow::Configuration {
    Configuration() { this = "HardcodedCredentials" }

    override
    predicate isSource(DataFlow::Node source) {
      source instanceof Source
    }

    override
    predicate isSink(DataFlow::Node sink) {
      sink instanceof Sink
    }
  }

  /** A constant string, considered as a source of hardcoded credentials. */
  class ConstantStringSource extends Source, DataFlow::ValueNode {
    override ConstantString astNode;
  }

  /**
   * A subclass of `Sink` that includes every `CredentialsExpr`
   * as a credentials sink.
   */
  class DefaultCredentialsSink extends Sink {
    DefaultCredentialsSink() {
      this.asExpr() instanceof CredentialsExpr
    }

    override string getKind() {
      result = this.asExpr().(CredentialsExpr).getCredentialsKind()
    }
  }
}

/** DEPRECATED: Use `HardcodedCredentials::Source` instead. */
deprecated class HardcodedCredentialsSource = HardcodedCredentials::Source;

/** DEPRECATED: Use `HardcodedCredentials::Sink` instead. */
deprecated class HardcodedCredentialsSink = HardcodedCredentials::Sink;

/** DEPRECATED: Use `HardcodedCredentials::Sanitizer` instead. */
deprecated class HardcodedCredentialsSanitizer = HardcodedCredentials::Sanitizer;

/** DEPRECATED: Use `HardcodedCredentials::Configuration` instead. */
deprecated class HardcodedCredentialsTrackingConfiguration = HardcodedCredentials::Configuration;
