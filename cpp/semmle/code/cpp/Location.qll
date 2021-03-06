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

import semmle.code.cpp.Element
import semmle.code.cpp.File

/**
 * A location of a C/C++ artifact.
 */
class Location extends @location {

  /** Gets the file corresponding to this location. */
  File getFile() {
    locations_default(this,result,_,_,_,_) or
    locations_stmt(this,result,_,_,_,_) or
    locations_expr(this,result,_,_,_,_)
  }

  /** Gets the start line of this location. */
  int getStartLine() {
    locations_default(this,_,result,_,_,_) or
    locations_stmt(this,_,result,_,_,_) or
    locations_expr(this,_,result,_,_,_)
  }

  /** Gets the end line of this location. */
  int getEndLine() {
    locations_default(this,_,_,_,result,_) or
    locations_stmt(this,_,_,_,result,_) or
    locations_expr(this,_,_,_,result,_)
  }

  /** Gets the start column of this location. */
  int getStartColumn() {
    locations_default(this,_,_,result,_,_) or
    locations_stmt(this,_,_,result,_,_) or
    locations_expr(this,_,_,result,_,_)
  }

  /** Gets the end column of this location. */
  int getEndColumn() {
    locations_default(this,_,_,_,_,result) or
    locations_stmt(this,_,_,_,_,result) or
    locations_expr(this,_,_,_,_,result)
  }

  /**
   * Gets a textual representation of this element.
   *
   * The format is "file://filePath:startLine:startColumn:endLine:endColumn".
   */
  string toString() {
    exists(string filepath, int startline, int startcolumn, int endline, int endcolumn
    | this.hasLocationInfo(filepath, startline, startcolumn, endline, endcolumn)
    | toUrl(filepath, startline, startcolumn, endline, endcolumn, result)
    )
  }


  /**
   * Holds if this element is at the specified location.
   * The location spans column `startcolumn` of line `startline` to
   * column `endcolumn` of line `endline` in file `filepath`.
   * For more information, see
   * [LGTM locations](https://lgtm.com/help/ql/locations).
   */
  predicate hasLocationInfo(
    string filepath, int startline, int startcolumn, int endline, int endcolumn) {
    none()
  }

  /** Holds if `this` comes on a line strictly before `l`. */
  predicate isBefore(Location l) {
    this.getFile() = l.getFile() and this.getEndLine() < l.getStartLine()
  }

  /** Holds if location `l` is completely contained within this one. */
  predicate subsumes(Location l) {
    exists(File f | f = getFile() |
      exists(int thisStart, int thisEnd | charLoc(f, thisStart, thisEnd) |
        exists(int lStart, int lEnd | l.charLoc(f, lStart, lEnd) |
          thisStart <= lStart and lEnd <= thisEnd
        )
      )
    )
  }

  /**
   * Holds if this location corresponds to file `f` and character "offsets"
   * `start..end`. Note that these are not real character offsets, because
   * we use `maxCols` to find the length of the longest line and then pretend
   * that all the lines are the same length. However, these offsets are
   * convenient for comparing or sorting locations in a file. For an example,
   * see `subsumes`.
   */
  predicate charLoc(File f, int start, int end) {
    f = getFile() and
    exists(int maxCols | maxCols = maxCols(f) |
      start = getStartLine() * maxCols + getStartColumn() and
      end = getEndLine() * maxCols + getEndColumn()
    )
  }
}

/**
 * A location of an element. Not used for expressions or statements, which
 * instead use LocationExpr and LocationStmt respectively.
 */
library class LocationDefault extends Location, @location_default {
  override predicate hasLocationInfo(
    string filepath, int startline, int startcolumn, int endline, int endcolumn) {
    exists(File f
    | locations_default(this,f,startline,startcolumn,endline,endcolumn)
    | filepath = f.getAbsolutePath())
  }
}

/** A location of a statement. */
library class LocationStmt extends Location, @location_stmt {
  override predicate hasLocationInfo(
    string filepath, int startline, int startcolumn, int endline, int endcolumn) {
    exists(File f
    | locations_stmt(this,f,startline,startcolumn,endline,endcolumn)
    | filepath = f.getAbsolutePath())
  }
}

/** A location of an expression. */
library class LocationExpr extends Location, @location_expr {
  override predicate hasLocationInfo(
    string filepath, int startline, int startcolumn, int endline, int endcolumn) {
    exists(File f
    | locations_expr(this,f,startline,startcolumn,endline,endcolumn)
    | filepath = f.getAbsolutePath())
  }
}

/**
 * Gets the length of the longest line in file `f`.
 */
pragma[nomagic]
private int maxCols(File f) {
  result = max(Location l | l.getFile() = f | l.getEndColumn())
}

/**
 * A C/C++ element that has a location in a file
 */
class Locatable extends Element {

}

/**
 * A dummy location which is used when something doesn't have a location in
 * the source code but needs to have a `Location` associated with it. There
 * may be several distinct kinds of unknown locations. For example: one for
 * expressions, one for statements and one for other program elements.
 */
class UnknownLocation extends Location {
  UnknownLocation() {
    getFile().getAbsolutePath() = ""
  }
}

/**
 * A dummy location which is used when something doesn't have a location in
 * the source code but needs to have a `Location` associated with it.
 */
class UnknownDefaultLocation extends UnknownLocation {
  UnknownDefaultLocation() {
    locations_default(this, _, 0, 0, 0, 0)
  }
}

/**
 * A dummy location which is used when an expression doesn't have a
 * location in the source code but needs to have a `Location` associated
 * with it.
 */
class UnknownExprLocation extends UnknownLocation {
  UnknownExprLocation() {
    locations_expr(this, _, 0, 0, 0, 0)
  }
}

/**
 * A dummy location which is used when a statement doesn't have a location
 * in the source code but needs to have a `Location` associated with it.
 */
class UnknownStmtLocation extends UnknownLocation {
  UnknownStmtLocation() {
    locations_stmt(this, _, 0, 0, 0, 0)
  }
}

