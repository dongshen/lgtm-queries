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
 * Provides a dataflow taint tracking configuration for reasoning about CORS misconfiguration for credentials transfer.
 */
import javascript

module CorsMisconfigurationForCredentials {
  /**
   * A data flow source for CORS misconfiguration for credentials transfer.
   */
  abstract class Source extends DataFlow::Node { }

  /**
   * A data flow sink for CORS misconfiguration for credentials transfer.
   */
  abstract class Sink extends DataFlow::Node {

    /**
     * Gets the "Access-Control-Allow-Credentials" header definition.
     */
    abstract HTTP::HeaderDefinition getCredentialsHeader();

  }

  /**
   * A sanitizer for CORS misconfiguration for credentials transfer.
   */
  abstract class Sanitizer extends DataFlow::Node { }

  /**
   * A data flow configuration for CORS misconfiguration for credentials transfer.
   */
  class Configuration extends TaintTracking::Configuration {
    Configuration() {
      this = "CorsMisconfigurationForCredentials"
    }

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

  /** A source of remote user input, considered as a flow source for CORS misconfiguration. */
  class RemoteFlowSourceAsSource extends Source {
    RemoteFlowSourceAsSource() { this instanceof RemoteFlowSource }
  }

  /**
   * The value of an "Access-Control-Allow-Origin" HTTP
   * header with an associated "Access-Control-Allow-Credentials"
   * HTTP header with a truthy value.
   */
  class CorsOriginHeaderWithAssociatedCredentialHeader extends Sink, DataFlow::ValueNode {

    HTTP::ExplicitHeaderDefinition credentials;

    CorsOriginHeaderWithAssociatedCredentialHeader() {
      exists (HTTP::RouteHandler routeHandler, HTTP::ExplicitHeaderDefinition origin, Expr credentialsValue |
        routeHandler.getAResponseHeader(_) = origin and
        routeHandler.getAResponseHeader(_) = credentials and
        origin.definesExplicitly("Access-Control-Allow-Origin", this.asExpr()) and
        credentials.definesExplicitly("Access-Control-Allow-Credentials", credentialsValue) |
        credentialsValue.mayHaveBooleanValue(true) or
        credentialsValue.mayHaveStringValue("true")
      )
    }

    override HTTP::HeaderDefinition getCredentialsHeader() {
      result = credentials
    }

  }

  /**
   * A value that is or coerces to the string "null".
   * This is considered a source because the "null" origin is easy to obtain for an attacker.
   */
  class NullToStringValue extends Source {
    NullToStringValue() {
      this.asExpr() instanceof NullLiteral or
      this.asExpr().mayHaveStringValue("null")
    }
  }
}

/** DEPRECATED: Use `CorsMisconfigurationForCredentials::Source` instead. */
deprecated class CorsMisconfigurationForCredentialsSource = CorsMisconfigurationForCredentials::Source;

/** DEPRECATED: Use `CorsMisconfigurationForCredentials::Sink` instead. */
deprecated class CorsMisconfigurationForCredentialsSink = CorsMisconfigurationForCredentials::Sink;

/** DEPRECATED: Use `CorsMisconfigurationForCredentials::Sanitizer` instead. */
deprecated class CorsMisconfigurationForCredentialsSanitizer = CorsMisconfigurationForCredentials::Sanitizer;

/** DEPRECATED: Use `CorsMisconfigurationForCredentials::Configuration` instead. */
deprecated class CorsMisconfigurationForCredentialsDataFlowConfiguration = CorsMisconfigurationForCredentials::Configuration;
