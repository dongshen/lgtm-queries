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

import semmle.code.cpp.models.interfaces.FormattingFunction

/**
 * The standard functions `printf`, `wprintf` and their glib variants.
 */
class Printf extends FormattingFunction {
  Printf() {
    this instanceof TopLevelFunction and 
    (
      hasGlobalName("printf") or
      hasGlobalName("printf_s") or
      hasGlobalName("wprintf") or
      hasGlobalName("wprintf_s") or
      hasGlobalName("g_printf")
    )
  }

  override int getFormatParameterIndex() { result=0 }
  override predicate isWideCharDefault() {
    hasGlobalName("wprintf") or
    hasGlobalName("wprintf_s")
  }
}

/**
 * The standard functions `fprintf`, `fwprintf` and their glib variants.
 */
class Fprintf extends FormattingFunction {
  Fprintf() { this instanceof TopLevelFunction and (hasGlobalName("fprintf") or hasGlobalName("fwprintf") or hasGlobalName("g_fprintf"))}

  override int getFormatParameterIndex() { result=1 }
  override predicate isWideCharDefault() { hasGlobalName("fwprintf") }
  override int getOutputParameterIndex() { result=0 }
}

/**
 * The standard function `sprintf` and its Microsoft and glib variants.
 */
class Sprintf extends FormattingFunction {
  Sprintf() {
    this instanceof TopLevelFunction and
    (
      hasGlobalName("sprintf") or
      hasGlobalName("_sprintf_l") or
      hasGlobalName("__swprintf_l") or
      hasGlobalName("wsprintf") or
      hasGlobalName("g_strdup_printf") or
      hasGlobalName("g_sprintf") or
      hasGlobalName("__builtin___sprintf_chk")
    )
  }

  override predicate isWideCharDefault() {
    getParameter(getFormatParameterIndex()).getType().getUnspecifiedType().(PointerType).getBaseType().getSize() > 1
  }

  override int getFormatParameterIndex() {
    if hasGlobalName("g_strdup_printf") then result = 0
    else if hasGlobalName("__builtin___sprintf_chk") then result = 3
    else result = 1
  }
  override int getOutputParameterIndex() {
    not hasGlobalName("g_strdup_printf") and result = 0
  }
  
  override int getFirstFormatArgumentIndex() {
    if hasGlobalName("__builtin___sprintf_chk") then result = 4
    else result = getNumberOfParameters()
  }
}

/**
 * The standard functions `snprintf` and `swprintf`, and their
 * Microsoft and glib variants.
 */
class Snprintf extends FormattingFunction {
  Snprintf() {
    this instanceof TopLevelFunction and (
      hasGlobalName("snprintf") // C99 defines snprintf
      or hasGlobalName("swprintf") // The s version of wide-char printf is also always the n version
      // Microsoft has _snprintf as well as several other variations
      or hasGlobalName("sprintf_s")
      or hasGlobalName("snprintf_s")
      or hasGlobalName("swprintf_s")
      or hasGlobalName("_snprintf")
      or hasGlobalName("_snprintf_s")
      or hasGlobalName("_snprintf_l")
      or hasGlobalName("_snprintf_s_l")
      or hasGlobalName("_snwprintf")
      or hasGlobalName("_snwprintf_s")
      or hasGlobalName("_snwprintf_l")
      or hasGlobalName("_snwprintf_s_l")
      or hasGlobalName("_sprintf_s_l")
      or hasGlobalName("_swprintf_l")
      or hasGlobalName("_swprintf_s_l")
      or hasGlobalName("g_snprintf")
      or hasGlobalName("wnsprintf")
      or hasGlobalName("__builtin___snprintf_chk")
    )
  }

  override int getFormatParameterIndex() {
    if getName().matches("%\\_l")
      then result = getFirstFormatArgumentIndex() - 2 
      else result = getFirstFormatArgumentIndex() - 1
  }

  override predicate isWideCharDefault() {
    getParameter(getFormatParameterIndex()).getType().getUnspecifiedType().(PointerType).getBaseType().getSize() > 1
  }
  override int getOutputParameterIndex() { result=0 }
  
  override int getFirstFormatArgumentIndex() {
    if hasGlobalName("__builtin___snprintf_chk") then result = 5
    else result = getNumberOfParameters()
  }

  /**
   * Holds if this function returns the length of the formatted string
   * that would have been output, regardless of the amount of space
   * in the buffer.
   */
  predicate returnsFullFormatLength() {
    hasGlobalName("snprintf") or
    hasGlobalName("g_snprintf") or
    hasGlobalName("__builtin___snprintf_chk") or
    hasGlobalName("snprintf_s")
  }

  override int getSizeParameterIndex() {
    result = 1
  }
}

/**
 * The Microsoft `StringCchPrintf` function and variants.
 */
class StringCchPrintf extends FormattingFunction {
  StringCchPrintf() {
    this instanceof TopLevelFunction and (
      hasGlobalName("StringCchPrintf")
      or hasGlobalName("StringCchPrintfEx")
      or hasGlobalName("StringCchPrintf_l")
      or hasGlobalName("StringCchPrintf_lEx")
      or hasGlobalName("StringCbPrintf")
      or hasGlobalName("StringCbPrintfEx")
      or hasGlobalName("StringCbPrintf_l")
      or hasGlobalName("StringCbPrintf_lEx")
    )
  }

  override int getFormatParameterIndex() {
    if getName().matches("%Ex")
      then result = 5
      else result = 2
  }

  override predicate isWideCharDefault() {
    getParameter(getFormatParameterIndex()).getType().getUnspecifiedType().(PointerType).getBaseType().getSize() > 1
  }

  override int getOutputParameterIndex() {
    result = 0
  }

  override int getSizeParameterIndex() {
    result = 1
  }
}

/**
 * The standard function `syslog`.
 */
class Syslog extends FormattingFunction {
  Syslog() {
    this instanceof TopLevelFunction and (
      hasGlobalName("syslog")
    )
  }

  override int getFormatParameterIndex() { result=1 }
}
