/// Qué referencia del punto de recogida se le dice y se le muestra al conductor
/// ANTES de aceptar la carrera.
///
/// Gana el sector sobre la dirección exacta: es lo que el taxista necesita para
/// decidir en dos segundos si le conviene la carrera, y es mucho más corto de
/// escuchar que una dirección con número y cruce. La dirección exacta la ve
/// después de aceptar, en TripScreen, junto al botón que abre Google Maps.
///
/// Se cae a la dirección cuando no hay sector: carreras creadas antes de que el
/// campo existiera, o puntos que passenger_app no pudo resolver contra sus
/// polígonos. Devuelve `null` si no hay ninguna de las dos, y ahí quien llama
/// decide el texto genérico ("Nueva carrera").
///
/// Existe como función aparte -- y no embebida en el listener del isolate --
/// para poder testear esta decisión: el isolate del foreground service es el
/// único código del repo que no se puede montar en un test.
String? pickupLabel({required String sector, required String address}) {
  final trimmedSector = sector.trim();
  if (trimmedSector.isNotEmpty) return trimmedSector;

  final trimmedAddress = address.trim();
  if (trimmedAddress.isNotEmpty) return trimmedAddress;

  return null;
}
