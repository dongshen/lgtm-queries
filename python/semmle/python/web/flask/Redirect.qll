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

/** Provides class representing the `flask.redirect` function.
 * This module is intended to be imported into a taint-tracking query
 * to extend `TaintSink`.
 */
import python

import semmle.python.security.TaintTracking
import semmle.python.security.strings.Basic

FunctionObject flask_redirect() {
    exists(ModuleObject flask |
        flask.getName() = "flask" and
        flask.getAttribute("redirect") = result
    )
}

/**
 * Represents an argument to the `flask.redirect` function.
 */
class FlaskRedirect extends TaintSink {

    string toString() {
        result = "flask.redirect"
    }

    FlaskRedirect() {
        exists(CallNode call |
            flask_redirect().getACall() = call and
            this = call.getAnArg()
        )
    }

    override predicate sinks(TaintKind kind) {
        kind instanceof ExternalStringKind
    }

}
