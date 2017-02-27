// Copyright 2017 Semmle Ltd.
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

/** Provides predicates for recognizing commented-out code. */

import semmle.javascript.Comments

/** Gets a line in comment `c` that looks like commented-out code. */
private string getALineOfCommentedOutCode(Comment c) {
  result = c.getLine(_) and
  // line ends with ';', '{', or '}', optionally followed by a comma,
  ((result.regexpMatch(".*[;{}],?\\s*") and
    // but it doesn't look like a JSDoc-like annotation
    not result.regexpMatch(".*@\\w+\\s*\\{.*\\}\\s*") and
    // and it does not contain three consecutive words (which is uncommon in code)
    not result.regexpMatch("[^'\\\"]*\\w\\s++\\w++\\s++\\w[^'\\\"]*")) or
  // line is part of a block comment and ends with something that looks
  // like a line comment; character before '//' must not be ':' to
  // avoid matching URLs
  (not c instanceof SlashSlashComment and
   result.regexpMatch("(.*[^:]|^)//.*[^/].*")) or
  // similar, but don't be fooled by '//// this kind of comment' and
  // '//// this kind of comment ////'
  (c instanceof SlashSlashComment and
   result.regexpMatch("/*([^/].*[^:]|[^:/])//.*[^/].*") and
   // exclude externalization comments
   not result.regexpMatch(".*\\$NON-NLS-\\d+\\$.*")))
}

/**
 * Holds if `c` is a comment containing code examples, and hence should be
 * disregarded when looking for commented-out code.
 */
private predicate containsCodeExample(Comment c) {
  exists (string text | text = c.getText() |
    text.matches("%<pre>%</pre>%") or
    text.matches("%<code>%</code>%") or
    text.matches("%@example%") or
    text.matches("%```%")
  )
}

/** Holds if comment `c` spans lines `start` to `end` (inclusive) in file `f`. */
private predicate commentOnLines(Comment c, File f, int start, int end) {
  exists (Location loc | loc = c.getLocation() |
    f = loc.getFile() and
    start = loc.getStartLine() and
    end = loc.getEndLine()
  )
}

/**
 * Gets a comment that belongs to a run of consecutive comments in file `f`
 * starting with `c`, where `c` itself contains commented-out code, but the comment
 * preceding it, if any, does not.
 */
private Comment getCommentInRun(File f, Comment c) {
  exists (int n |
    commentOnLines(c, f, n, _) and
    countCommentedOutLines(c) > 0 and
    not exists (Comment d | commentOnLines(d, f, _, n-1) |
      countCommentedOutLines(d) > 0
    )
  ) and
  (result = c or
   exists (Comment prev, int n |
     prev = getCommentInRun(f, c) and
     commentOnLines(prev, f, _, n) and
     commentOnLines(result, f, n+1, _)
   )
  )
}

/**
 * Gets a comment that follows `c` in a run of consecutive comments and
 * does not contain a code example.
 */
private Comment getRelevantCommentInRun(Comment c) {
  result = getCommentInRun(_, c) and not containsCodeExample(result)
}

/** Gets the number of lines in comment `c` that look like commented-out code. */
private int countCommentedOutLines(Comment c) {
  result = count(getALineOfCommentedOutCode(c))
}

/** Gets the number of non-blank lines in comment `c`. */
private int countNonBlankLines(Comment c) {
  result = count(string line | line = c.getLine(_) and not line.regexpMatch("\\s*"))
}

/**
 * Gets the number of lines in comment `c` and subsequent comments that look like
 * they contain commented-out code.
 */
private int countCommentedOutLinesInRun(Comment c) {
  result = sum(Comment d | d = getRelevantCommentInRun(c) | countCommentedOutLines(d))
}

/** Gets the number of non-blank lines in `c` and subsequent comments. */
private int countNonBlankLinesInRun(Comment c) {
  result = sum(Comment d | d = getRelevantCommentInRun(c) | countNonBlankLines(d))
}

/**
 * A run of consecutive comments containing a high percentage of lines
 * that look like commented-out code.
 *
 * This is represented by the comment that starts the run, with a special
 * `hasLocationInfo` implementation that assigns it the entire run as its location.
 */
class CommentedOutCode extends Comment {
  CommentedOutCode(){
    exists(int codeLines, int nonBlankLines |
      countCommentedOutLines(this) > 0 and
      not exists(Comment prev | this = getCommentInRun(_, prev) and this != prev) and
      nonBlankLines = countNonBlankLinesInRun(this) and
      codeLines = countCommentedOutLinesInRun(this) and
      nonBlankLines > 0 and
      2*codeLines > nonBlankLines
    )
  }

  /**
   * Gets the number of lines in this run of comments
   * that look like they contain commented-out code.
   */
  int getNumCodeLines() {
    result = countCommentedOutLinesInRun(this)
  }

  /**
   * Gets the number of non-blank lines in this run of comments.
   */
  int getNumNonBlankLines() {
    result = countNonBlankLinesInRun(this)
  }

  /**
   * Holds if this element is at the specified location.
   * The location spans column `startcolumn` of line `startline` to
   * column `endcolumn` of line `endline` in file `filepath`.
   * For more information, see
   * [LGTM locations](https://lgtm.com/docs/ql/locations).
   */
  predicate hasLocationInfo(string filepath, int startline, int startcolumn, int endline, int endcolumn) {
    exists (Location loc, File f | loc = getLocation() and f = loc.getFile() |
      filepath = f.getPath() and
      startline = loc.getStartLine() and
      startcolumn = loc.getStartColumn() and
      exists(Location last |
        last = getCommentInRun(f, this).getLocation() and
        last.getEndLine() = max(getCommentInRun(f, this).getLocation().getEndLine()) |
        endline = last.getEndLine() and
        endcolumn = last.getEndColumn()
      )
    )
  }
}

