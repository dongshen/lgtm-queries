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
import semmle.code.java.frameworks.spring.SpringXMLElement

/** A `<meta>` element in Spring XML files. */
class SpringMeta extends SpringXMLElement {
  SpringMeta() {
    this.getName() = "meta"
  }

  /** The value of the `key` attribute. */
  string getMetaKey() {
    result = this.getAttributeValue("key")
  }

  /** The value of the `value` attribute. */
  string getMetaValue() {
    result = this.getAttributeValue("value")
  }
}
