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
 * GigaSpaces XAP (eXtreme Application Platform) is a distributed in-memory "datagrid".
 */

import java

/**
 * Holds if `eventDrivenClass` is an event listener Class which receives events from GigaSpaces.
 */
predicate isGigaSpacesEventDrivenClass(Class eventDrivenClass) {
  exists(AnnotationType aType |
    aType = eventDrivenClass.getAnAnnotation().getType() |
    aType.hasQualifiedName("org.openspaces.events", "EventDriven") or
    aType.hasQualifiedName("org.openspaces.events.notify", "Notify") or
    aType.hasQualifiedName("org.openspaces.events.polling", "Polling")
  )
}

/**
 * Holds if `eventMethod` is a method with a GigaSpaces annotation that indicates it may be called
 * when GigaSpaces is processing events.
 */
predicate isGigaSpacesEventMethod(Method eventMethod) {
  exists(AnnotationType aType |
    aType = eventMethod.getAnAnnotation().getType() |
    aType.hasQualifiedName("org.openspaces.events.adapter", "SpaceDataEvent") or
    aType.hasQualifiedName("org.openspaces.events", "EventTemplate") or
    aType.hasQualifiedName("org.openspaces.events", "DynamicEventTemplate") or
    aType.hasQualifiedName("org.openspaces.events", "ExceptionHandler") or
    aType.hasQualifiedName("org.openspaces.events.polling", "ReceiveHandler") or
    aType.hasQualifiedName("org.openspaces.events.polling", "TriggerHandler")
  )
}

/**
 * A method called when the instance is written to a GigaSpace, to determine the unique ID of
 * the instance.
 */
class GigaSpacesSpaceIdGetterMethod extends Method {
  GigaSpacesSpaceIdGetterMethod() {
    getAnAnnotation().getType().hasQualifiedName("com.gigaspaces.annotation.pojo", "SpaceId") and
    getName().prefix(3) = "get"
  }
}

/**
 * A method called when an instance is read from a GigaSpace, to store the unique ID of the instance.
 */
class GigaSpacesSpaceIdSetterMethod extends Method {
  GigaSpacesSpaceIdSetterMethod() {
    exists(GigaSpacesSpaceIdGetterMethod getterMethod |
      getterMethod.getDeclaringType() = getDeclaringType() and
      getName().prefix(3) = "set" |
      getterMethod.getName().suffix(3) = getName().suffix(3)
    )
  }
}

/**
 * A method called when the enclosing class is written to a GigaSpace, to determine which partition
 * the enclosing class is written to.
 */
class GigaSpacesSpaceRoutingMethod extends Method {
  GigaSpacesSpaceRoutingMethod() {
    getAnAnnotation().getType().hasQualifiedName("com.gigaspaces.annotation.pojo", "SpaceRouting") and
    getName().prefix(3) = "get"
  }
}