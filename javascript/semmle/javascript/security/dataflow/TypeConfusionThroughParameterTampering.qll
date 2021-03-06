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
 * Provides a tracking configuration for reasoning about type confusion for HTTP request inputs.
 */
import javascript
import semmle.javascript.security.dataflow.RemoteFlowSources
private import semmle.javascript.dataflow.InferredTypes

module TypeConfusionThroughParameterTampering {

  /**
   * A data flow source for type confusion for HTTP request inputs.
   */
  abstract class Source extends DataFlow::Node { }

  /**
   * A data flow sink for type confusion for HTTP request inputs.
   */
  abstract class Sink extends DataFlow::Node { }

  /**
   * A barrier for type confusion for HTTP request inputs.
   */
  abstract class Barrier extends DataFlow::Node { }

  /**
   * A taint tracking configuration for type confusion for HTTP request inputs.
   */
  class Configuration extends DataFlow::Configuration {
    Configuration() {
      this = "TypeConfusionThroughParameterTampering"
    }

    override predicate isSource(DataFlow::Node source) {
      source instanceof Source
    }

    override predicate isSink(DataFlow::Node sink) {
      sink instanceof Sink and
      sink.analyze().getAType() = TTString() and
      sink.analyze().getAType() = TTObject()
    }

    override predicate isBarrier(DataFlow::Node node) {
      node instanceof Barrier
    }

  }

  /**
   * An HTTP request parameter that the user controls the type of.
   *
   * Node.js-based HTTP servers turn request parameters into arrays if their names are repeated.
   */
  private class TypeTamperableRequestParameter extends Source {

    TypeTamperableRequestParameter() {
      this.(HTTP::RequestInputAccess).getKind() = "parameter" and
      not exists (Express::RequestExpr request, DataFlow::PropRead base |
        // Express's `req.params.name` is always a string
        base.accesses(request.flow(), "params") and
        this = base.getAPropertyRead(_)
      )
    }

  }

  /**
   * Methods calls that behave slightly different for arrays and strings receivers.
   */
  private class StringArrayAmbiguousMethodCall extends Sink {

    StringArrayAmbiguousMethodCall() {
      exists (string name, DataFlow::MethodCallNode mc |
        name = "concat" or
        name = "includes" or
        name = "indexOf" or
        name = "lastIndexOf" or
        name = "slice" |
        mc.calls(this, name) and
        // ignore patterns that are innocent in practice
        not exists (EqualityTest cmp, Expr op |
          cmp.hasOperands(mc.asExpr(), op) |
          // prefix checking: `x.indexOf(prefix) === 0`
          name = "indexOf" and
          op.getIntValue() = 0
          or
          // suffix checking: `x.slice(-1) === '/'`
          name = "slice" and
          mc.getArgument(0).asExpr().getIntValue() = -1 and
          op.getStringValue().length() = 1
        )
      )
    }

  }

  /**
   * An access to the `length` property of an object.
   */
  private class LengthAccess extends Sink {

    LengthAccess() {
      exists (DataFlow::PropRead read |
        read.accesses(this, "length")
      )
    }

  }

}
