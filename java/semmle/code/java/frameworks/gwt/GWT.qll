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

import java
import GwtXml
import GwtUiBinder

/** The `com.google.gwt.core.client.EntryPoint` interface. */
class GwtEntryPointInterface extends Interface {
  GwtEntryPointInterface() {
    this.hasQualifiedName("com.google.gwt.core.client", "EntryPoint")
  }
}

/** A GWT class that implements the `EntryPoint` interface. */
class GwtEntryPointClass extends Class {
  GwtEntryPointClass() {
    this.getAnAncestor() instanceof GwtEntryPointInterface
  }

  /** The method serving as a GWT entry-point. */
  Method getOnModuleLoadMethod() {
    result = this.getACallable() and
    result.hasName("onModuleLoad") and
    result.hasNoParameters()
  }

  /** A GWT module XML file that specifies this class as an entry-point. */
  GwtXmlFile getAGwtXmlFile() {
    exists(GwtXmlFile f |
      result = f and
      this.getQualifiedName() = f.getModuleElement().getAnEntryPointElement().getClassName()
    )
  }

  /**
   * Holds if this entry point is live - that is, whether it is referred to within an XML element.
   */
  predicate isLive() {
    /*
     * We must have a `*.gwt.xml` in order to determine whether a particular `EntryPoint` is enabled.
     * In the absence of such a file, we cannot guarantee that `EntryPoint`s without annotations
     * are live.
     */
    isGwtXmlIncluded() implies
    (
      /*
       * The entry point is live if it is specified in a `*.gwt.xml` file.
       */
      exists(getAGwtXmlFile())
    )
  }
}

/**
 * A compilation unit within a folder that contains
 * a GWT module XML file with a matching source path.
 */
class GwtCompilationUnit extends CompilationUnit {
  GwtCompilationUnit() {
    exists(GwtXmlFile f |
      getRelativePath().matches(f.getARelativeSourcePath() + "%")
    )
  }
}

/** A GWT compilation unit that is not referenced from any known non-GWT `CompilationUnit`. */
class ClientSideGwtCompilationUnit extends GwtCompilationUnit {
  ClientSideGwtCompilationUnit() {
    not exists(RefType origin, RefType target |
      target.getCompilationUnit() = this and
      not origin.getCompilationUnit() instanceof GwtCompilationUnit and
      depends(origin, target)
    )
  }
}

/** Auxiliary predicate: `jsni` is a JSNI comment associated with method `m`. */
private predicate jsniComment(Javadoc jsni, Method m) {
  // The comment must start with `-{` ...
  jsni.getChild(0).getText().matches("-{%") and
  // ... and it must end with `}-`.
  jsni.getChild(jsni.getNumChild()-1).getText().matches("%}-") and
  // The associated callable must be marked as `native` ...
  m.isNative() and
  // ... and the comment has to be contained in `m`.
  jsni.getFile() = m.getFile() and
  jsni.getLocation().getStartLine() in [m.getLocation().getStartLine()..m.getLocation().getEndLine()]
}

/**
 * A JavaScript Native Interface (JSNI) comment that contains JavaScript code
 * implementing a native method.
 */
class JSNIComment extends Javadoc {
  JSNIComment() {
    jsniComment(this, _)
  }

  /** The method implemented by this comment. */
  Method getImplementedMethod() {
    jsniComment(this, result)
  }
}

/**
 * A JavaScript Native Interface (JSNI) method.
 */
class JSNIMethod extends Method {
  JSNIMethod() {
    jsniComment(_, this)
  }

  /** The comment containing the JavaScript code for this method. */
  JSNIComment getImplementation() {
    jsniComment(result, this)
  }
}
