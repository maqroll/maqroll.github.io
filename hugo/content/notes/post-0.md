---
title: Transformando Avro en Kafka Connect sin generar nuevos esquemas
date: 2021-10-25
publishdate: 2021-10-25
draft: true
---

Es la segunda vez que nos enfrentamos al mismo problema: *procesar mensajes Avro con [Kafka Connect](https://docs.confluent.io/platform/current/connect/index.html) cuya salida ha de respetar un esquema previamente definido en el Schema Registry*.

Lo sé, parece el típico problema de entrevista alejado de la vida real pero lo cierto es que se nos ha planteado más de una vez en la vida real.

Más que proporcionar una respuesta, el interes de esta nota es reflexionar porque la segunda vez lo resolvimos de forma diferente.

---

Kafka Connect es un framework genérico de procesamiento de mensajes Kafka. Te permite procesar mensajes almacenados en topics Kafka, cualquier transformación, cualquier formato. Tal y como está diseñado incluso puedes reutilizar la transformación si cambia el formato (p.e. si antes almacenabas tus mensajes en json y ahora decides almacenarlos en Avro).

Puedes porque la transformación no depende del formato. Para conseguirlo Kafka Connect tiene una capa de conversión (similar a los serializadores/deserializadores de Kafka Streams). Esto tiene matices pero simplificando un poco podemos decir que esa capa transforma el mensaje que viene de Kafka a un formato neutro que es sobre el que se define la transformación. Si cambia el formato de los mensajes solo tienes que cambiar la capa de conversión.

Ese formato neutro puede (o no) tener esquema. Si lo tiene, el conversor convierte el mensaje y el esquema.

La conversión es bi-direccional: la capa de conversión en la entrada existe también en la salida. En la salida se ocupa de transformar el formato neutro de Kafka Connect en el formato específico que se almacena en Kafka (p.e. json o Avro). 

En el ejemplo que nos ocupa el formato de entrada/salida era Avro, los esquemas tanto de entrada como de salida ya estaban almacenados en Schema Registry (y eran iguales) y nuestro proceso (por razones que no son solo difíciles de explicar, sino incluso de entender) no tenía permisos de escritura en el Schema Registry.

Kafka Connect incluye una suite de conversores para los formatos típicos (Json, Protobuf, Avro, etc...) y habitualmente no creas nuevos conversores, utilizas uno de los disponibles.

A la hora de transformar **de forma genérica** mensajes y esquemas entre dos formatos (p.e. Avro y el formato neutro de Kafka Connect) ricos y genéricos siempre hay **mismatch** (o limitaciones). Esos conversores cubren la inmensa mayoría de los casos pero en concreto **no se diseñaron para respetar el esquema original (no tendría sentido)**. ¿Qué quiero decir? Imagina la transformación identidad aplicada sobre mensajes Avro en la entrada y generando mensajes Avro en la salida (utilizando los conversores genéricos). No vas a perder información y el mensaje en la salida va a ser reconocible pero nada garantiza que el mensaje y el esquema sean 100% iguales.

Esa capa de conversión se diseño para aislar las transformaciones de los formatos específicos y facilitar el desarrollo de transformaciones sin tener en cuenta las interioridades de los formatos de entrada/salida. Y lo hacen bien. No para cubrir **corner-cases** como este.

---

La primera vez lo resolvimos definiendo un nuevo conversor Avro (a partir del suyo). El conversor Avro no es trivial, por eso optamos por hacer "vendoring". Funciona bien pero tiene una limitación: en sucesivas versiones Confluent optó por refactorizar sensiblemente ese conector y eso provocó que nuestro conversor dejará de funcionar. ¿Cómo es posible? Ese conversor depende de varias librerías. Nosotros no las incluimos porque eran las mismas que utiliza su conversor y ya estaban disponibles. Su refactorización eliminó algunas de las librerias de las que dependíamos. 

La segunda vez que nos encontramos este problema eramos conscientes de las limitaciones de robustez de la solución anterior. 

En esta ocasión prescindimos enteramente de los conversores Avro. La transformación se encargaba de gestionar el parsing del mensaje Avro y su serialización utilizando los [serializadores/deserializadores](https://docs.confluent.io/platform/current/schema-registry/serdes-develop/serdes-avro.html) estándar. Esta solución pierde la generalidad del formato (la transformación solo funciona sobre mensajes Avro) tiene la ventaja de que es genérica (es robusta ante cambios en el esquema Avro) y más eficiente (la transformación hacia/desde el formato neutro no es necesaria).