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

/** Provides a class for representing source maps. */

import javascript

/**
 * A source mapping comment associating a source map with a file.
 */
class SourceMappingComment extends Comment {
  /** The `url` is a `sourceMappingURL` embedded in this comment. */
  string url;

  SourceMappingComment() {
    exists (string sourceMappingURLRegex |
      sourceMappingURLRegex = "[@#]\\s*sourceMappingURL\\s*=\\s*(.*)\\s*" |
      // either a line comment whose entire text matches the regex...
      url = this.(SlashSlashComment).getText().regexpCapture(sourceMappingURLRegex, 1) or
      // ...or a block comment one of whose lines matches the regex
      url = this.(SlashStarComment).getLine(_).regexpCapture("//" + sourceMappingURLRegex, 1)
    )
  }

  /** Gets the URL of the source map referenced by this comment. */
  string getSourceMappingURL() {
    result = url
  }
}
