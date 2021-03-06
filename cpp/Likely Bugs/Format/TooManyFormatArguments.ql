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
 * @name Too many arguments to formatting function
 * @description A printf-like function called with too many arguments will
 *              ignore the excess arguments and output less than might
 *              have been intended.
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id cpp/too-many-format-arguments
 * @tags reliability
 *       correctness
 */
import cpp

from FormatLiteral fl, FormattingFunctionCall ffc, int expected, int given
where ffc = fl.getUse()
  and expected = fl.getNumArgNeeded()
  and given = ffc.getNumFormatArgument()
  and expected < given
  and fl.specsAreKnown()
select ffc, "Format expects "+expected.toString()+" arguments but given "+given.toString()
