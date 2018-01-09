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
 * @name Lines of comments in files
 * @kind treemap
 * @description Measures the number of lines of comments in each file (including docstrings,
 *              and ignoring lines that contain only code or are blank).
 * @treemap.warnOn lowValues
 * @metricType file
 * @metricAggregate avg sum max
 * @precision very-high
 * @id py/lines-of-comments-in-files
 */
import python

from Module m, int n
where n = m.getMetrics().getNumberOfLinesOfComments() + m.getMetrics().getNumberOfLinesOfDocStrings()
select m, n
order by n desc
