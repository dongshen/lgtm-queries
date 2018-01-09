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

import python

/** A Python property:
 *     @property
 *     def f():
 *         ....
 *
 *  Also any instances of types.GetSetDescriptorType (which are equivalent, but implemented in C)
 */
abstract class PropertyObject extends Object {
  
    PropertyObject() {
        property_getter(this, _)
        or
        py_cobjecttypes(this, theBuiltinPropertyType())
    }
  
    /** Gets the name of this property */
    abstract string getName();
    
    /** Gets the getter of this property */
    abstract Object getGetter();
        
    /** Gets the setter of this property */
    abstract Object getSetter();
    
    /** Gets the deleter of this property */
    abstract Object getDeleter();
    
    string toString() {
        result = "Property " + this.getName() 
    }
    
    /** Whether this property is read-only. */
    predicate isReadOnly() {
        not exists(this.getSetter()) 
    }
    
    /** Gets an inferred type of this property.
     * That is the type returned by its getter function,
     * not the type of the property object which is types.PropertyType. */
    abstract ClassObject getInferredPropertyType();

}


class PythonPropertyObject extends PropertyObject {
  
    PythonPropertyObject() {
        property_getter(this, _)
    }
    
    string getName() {
        result = this.getGetter().getName()
    }
    
    /** Gets the getter function of this property */
    FunctionObject getGetter() {
         property_getter(this, result)
    }
    
    ClassObject getInferredPropertyType() {
        result = this.getGetter().getAnInferredReturnType()
    }
        
    /** Gets the setter function of this property */
    FunctionObject getSetter() {
         property_setter(this, result)
    }
    
    /** Gets the deleter function of this property */
    FunctionObject getDeleter() {
         property_deleter(this, result)
    }
    
}

class BuiltinPropertyObject extends PropertyObject {
  
    BuiltinPropertyObject() {
        py_cobjecttypes(this, theBuiltinPropertyType())
    }

    string getName() {
        py_cobjectnames(this, result)
    }

    /** Gets the getter method wrapper of this property */
    Object getGetter() {
         py_cmembers_versioned(this, "__get__", result, major_version().toString())
    }

    ClassObject getInferredPropertyType() {
        none()
    }

    /** Gets the setter method wrapper of this property */
    Object getSetter() {
         py_cmembers_versioned(this, "__set__", result, major_version().toString())
    }

    /** Gets the deleter method wrapper of this property */
    Object getDeleter() {
         py_cmembers_versioned(this, "__delete__", result, major_version().toString())
    }

}

private predicate property_getter(CallNode decorated, FunctionObject getter) {
    decorated.getFunction().refersTo(thePropertyType())
    and
    decorated.getArg(0).refersTo(getter)
}

private predicate property_setter(CallNode decorated, FunctionObject setter) {
    property_getter(decorated, _)
    and
    exists(CallNode setter_call, AttrNode prop_setter |
        prop_setter.getObject("setter").refersTo((Object)decorated) |
        setter_call.getArg(0).refersTo(setter)
        and
        setter_call.getFunction() = prop_setter
    )
    or
    decorated.getFunction().refersTo(thePropertyType())
    and
    decorated.getArg(1).refersTo(setter)
}

private predicate property_deleter(CallNode decorated, FunctionObject deleter) {
    property_getter(decorated, _)
    and
    exists(CallNode deleter_call, AttrNode prop_deleter |
        prop_deleter.getObject("deleter").refersTo((Object)decorated) |
        deleter_call.getArg(0).refersTo(deleter)
        and
        deleter_call.getFunction() = prop_deleter
    )
    or
    decorated.getFunction().refersTo(thePropertyType())
    and
    decorated.getArg(2).refersTo(deleter)
}

