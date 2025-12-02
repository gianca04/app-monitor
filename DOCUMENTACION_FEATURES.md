# Documentación de Features del Sistema Monitor

## 1. Feature: Autenticación (Auth)

### Propósito
El módulo de autenticación es responsable de gestionar el acceso seguro al sistema. Permite a los usuarios iniciar sesión mediante credenciales (correo electrónico y contraseña), validar su identidad contra el servidor backend, y mantener la sesión activa mediante tokens de autenticación almacenados de forma segura.

### Funcionamiento
El proceso de autenticación comienza cuando el usuario ingresa sus credenciales en la pantalla de login. El sistema valida el formato de los datos ingresados en el cliente antes de enviarlos al servidor. Una vez validados, las credenciales se envían mediante una petición HTTP POST al endpoint de login del backend.

El servidor procesa las credenciales y, si son válidas, responde con un token de autenticación JWT, información del usuario y datos del empleado asociado. El sistema almacena el token de forma segura utilizando Flutter Secure Storage, lo que garantiza que las credenciales sensibles no sean accesibles por otras aplicaciones o procesos maliciosos.

Adicionalmente, se guarda información del usuario y del empleado en SharedPreferences para acceso rápido a datos no sensibles como nombre, posición y documento de identidad. El estado de autenticación se gestiona mediante Riverpod, permitiendo que toda la aplicación reaccione a los cambios en el estado de login.

El sistema también implementa verificación de expiración de tokens al iniciar la aplicación. Si el token ha expirado, se limpia automáticamente y se requiere que el usuario inicie sesión nuevamente. Esto garantiza la seguridad y evita accesos no autorizados con tokens vencidos.

En caso de errores durante el proceso (como credenciales inválidas, problemas de red o errores del servidor), el sistema captura estas excepciones y las traduce en mensajes amigables para el usuario, mostrándolos en la interfaz para que pueda tomar las acciones correctivas necesarias.

---

## 2. Feature: Reportes de Trabajo en la Nube (Work Reports)

### Propósito
Este módulo gestiona los reportes de trabajo que se almacenan y sincronizan directamente con el servidor backend. Permite crear, visualizar, editar y eliminar reportes de trabajo en tiempo real cuando hay conectividad disponible. Es la versión "online" del sistema de reportes.

### Funcionamiento
Los reportes de trabajo en la nube son documentos digitales que registran las actividades realizadas por los empleados en diferentes proyectos. Cada reporte contiene información detallada como el proyecto asociado, el empleado que lo realiza, fecha del reporte, horarios de inicio y fin, descripciones de actividades, recursos utilizados (herramientas, personal, materiales), sugerencias y firmas digitales de supervisores y gerentes.

Cuando un usuario crea un nuevo reporte, el sistema presenta un formulario industrial donde se capturan todos los campos requeridos. El usuario selecciona el proyecto y empleado mediante búsquedas rápidas que consultan el backend. Las firmas digitales se capturan mediante un componente especializado que convierte los trazos en imágenes PNG codificadas en base64.

Al enviar el formulario, el sistema construye una petición multipart/form-data que incluye todos los campos del reporte más las imágenes de las firmas y fotografías asociadas. Esta petición se envía al servidor mediante HTTP POST. El servidor procesa la información, almacena las imágenes en su sistema de archivos y guarda los metadatos en la base de datos.

Para la visualización de reportes, el sistema implementa paginación para manejar eficientemente grandes volúmenes de datos. Los usuarios pueden filtrar reportes por rango de fechas, buscar por texto, y ordenar por diferentes criterios. La lista de reportes se carga de forma incremental conforme el usuario hace scroll, mejorando el rendimiento y la experiencia de usuario.

La edición de reportes existentes permite modificar cualquier campo excepto las relaciones básicas con proyecto y empleado. El sistema detecta si las firmas han sido modificadas o si se mantienen las originales, enviando solo las nuevas firmas al servidor para optimizar el ancho de banda.

La eliminación de reportes es un proceso que requiere confirmación del usuario y se ejecuta mediante una petición HTTP DELETE al servidor. Una vez eliminado, el reporte se remueve de la lista local y el estado se actualiza automáticamente.

El manejo de errores es robusto, diferenciando entre problemas de conectividad, errores del servidor y fallos de validación. Cada tipo de error se traduce en un mensaje apropiado para el usuario, permitiéndole entender qué sucedió y cómo resolverlo.

---

## 3. Feature: Reportes de Trabajo Locales (Work Reports Local)

### Propósito
Este módulo proporciona capacidad offline-first para la gestión de reportes de trabajo. Permite a los usuarios crear, editar y almacenar reportes localmente en el dispositivo cuando no hay conectividad, para posteriormente sincronizarlos con el servidor cuando la conexión esté disponible.

### Funcionamiento
El sistema de reportes locales utiliza Hive, una base de datos NoSQL embebida en Flutter, para almacenar los reportes directamente en el dispositivo del usuario. Esto garantiza que los trabajadores de campo puedan continuar documentando sus actividades incluso sin acceso a internet.

Cuando un usuario crea un reporte local, toda la información se serializa y almacena en una caja de Hive específica para reportes. Cada reporte recibe un identificador local único generado automáticamente. El sistema también registra metadatos de sincronización como el estado de sincronización (isSynced), identificador del servidor una vez sincronizado (syncedServerId), mensajes de error si la sincronización falla, y timestamp del último intento de sincronización.

Los reportes locales mantienen la misma estructura de datos que los reportes en la nube, incluyendo toda la información del proyecto, empleado, descripciones, recursos, firmas y fotografías. Las firmas e imágenes se almacenan como datos base64 dentro del modelo local.

El proceso de sincronización es el corazón de este módulo. Puede ser iniciado manualmente por el usuario o configurarse para ejecutarse automáticamente cuando se detecta conectividad. El sistema identifica todos los reportes que aún no han sido sincronizados (isSynced = false) y los procesa secuencialmente.

Para cada reporte no sincronizado, el sistema intenta enviarlo al servidor utilizando el mismo mecanismo que los reportes en la nube. Si la sincronización es exitosa, el reporte local se marca como sincronizado y se guarda el ID del servidor. Si falla, se registra el mensaje de error y se marca el timestamp del intento, permitiendo reintentos posteriores.

El módulo también gestiona las fotografías asociadas a los reportes locales. Estas se almacenan en el sistema de archivos del dispositivo y sus rutas se referencian en el modelo del reporte. Durante la sincronización, las fotografías locales se leen y convierten a MultipartFile para ser enviadas al servidor.

Los usuarios pueden visualizar todos sus reportes locales, identificar cuáles están pendientes de sincronización mediante indicadores visuales, editar reportes locales antes de sincronizarlos, y eliminar reportes locales que ya no sean necesarios. El sistema mantiene contadores actualizados de reportes totales y reportes no sincronizados para proporcionar feedback visual constante al usuario.

---

## 4. Feature: Proyectos (Projects)

### Propósito
Este módulo gestiona la información de los proyectos disponibles en el sistema. Proporciona funcionalidad de búsqueda rápida para que los usuarios puedan seleccionar proyectos al crear reportes de trabajo, sin necesidad de cargar listas completas de proyectos.

### Funcionamiento
El sistema de proyectos está diseñado principalmente para búsquedas rápidas y eficientes. Cuando un usuario necesita seleccionar un proyecto (por ejemplo, al crear un reporte de trabajo), el sistema presenta un modal de búsqueda rápida.

Al escribir en el campo de búsqueda, el sistema implementa debouncing para evitar hacer peticiones excesivas al servidor. Después de una breve pausa en la escritura (típicamente 300-500ms), se envía una petición al endpoint de búsqueda rápida del backend con el query ingresado.

El servidor procesa la búsqueda utilizando índices de base de datos optimizados, buscando coincidencias en campos como nombre del proyecto, código, descripción y ubicación. Los resultados se devuelven en formato JSON con información resumida de cada proyecto: ID, nombre, código, cliente, estado y ubicación.

Los resultados se presentan en una lista interactiva donde el usuario puede ver rápidamente los proyectos coincidentes y seleccionar el apropiado. Una vez seleccionado, el ID del proyecto se utiliza para vincular el reporte de trabajo.

El módulo mantiene un diseño minimalista enfocado en la búsqueda, evitando cargar listas completas de proyectos que podrían ser muy extensas y afectar el rendimiento. Aunque el datasource define métodos CRUD completos (crear, leer, actualizar, eliminar), estos están implementados como placeholders para futuras expansiones del sistema.

---

## 5. Feature: Proyectos Locales (Projects Local)

### Propósito
Este módulo proporciona sincronización y caché local de la información de proyectos. Permite que los datos de proyectos estén disponibles offline y se mantengan actualizados mediante sincronizaciones periódicas con el servidor.

### Funcionamiento
El sistema de proyectos locales implementa una estrategia de cache-first para garantizar disponibilidad de datos incluso sin conectividad. Utiliza Hive para almacenar los proyectos en el dispositivo, manteniendo una réplica local de la información del servidor.

Cuando se inicia el proceso de sincronización, el sistema realiza una petición al servidor para obtener la lista completa de proyectos activos. El servidor responde con todos los proyectos en formato JSON. El sistema procesa esta respuesta y convierte cada proyecto en un modelo Hive que puede ser almacenado localmente.

El proceso de sincronización implementa una estrategia de upsert: si un proyecto ya existe en la caché local (identificado por su ID), se actualiza con la información más reciente del servidor; si no existe, se crea un nuevo registro local. Esto garantiza que los datos locales estén siempre sincronizados con el servidor sin duplicados.

Después de completar la sincronización, el sistema guarda un timestamp en SharedPreferences registrando la fecha y hora de la última sincronización exitosa. Este timestamp se muestra al usuario para que sepa qué tan actualizados están sus datos locales.

El módulo también proporciona estadísticas en tiempo real, como el número total de proyectos almacenados localmente y la información de la última sincronización. Estos datos se exponen mediante providers de Riverpod que pueden ser observados por la interfaz de usuario.

Los proyectos locales permiten que los usuarios accedan a información de proyectos incluso sin internet, facilitando la creación de reportes locales que referencian proyectos existentes. Cuando posteriormente se sincroniza un reporte local con el servidor, las referencias a proyectos se resuelven correctamente porque ambos sistemas utilizan los mismos IDs.

El manejo de errores durante la sincronización es tolerante a fallos. Si la sincronización falla por problemas de red o errores del servidor, el sistema mantiene los datos existentes en caché y permite reintentar la sincronización más tarde sin perder información.

---

## 6. Feature: Empleados (Employees)

### Propósito
Este módulo gestiona la información de empleados del sistema. Similar al módulo de proyectos, proporciona funcionalidad de búsqueda rápida para seleccionar empleados al crear reportes de trabajo, manteniendo un diseño eficiente y orientado a búsquedas.

### Funcionamiento
El sistema de empleados implementa búsqueda rápida optimizada para selección de empleados en formularios de reportes. Cuando un usuario necesita asignar un empleado a un reporte, se abre un modal de búsqueda donde puede escribir el nombre, apellido, número de documento o posición del empleado.

El mecanismo de búsqueda utiliza debouncing para optimizar las peticiones al servidor. Una vez que el usuario deja de escribir, se envía una consulta al endpoint de búsqueda rápida del backend con el término ingresado.

El servidor ejecuta una búsqueda eficiente en la base de datos de empleados, utilizando índices en campos clave como nombres, apellidos, número de documento y posición. Los resultados se filtran para incluir solo empleados activos que pueden ser asignados a reportes.

La respuesta del servidor incluye información resumida de cada empleado: ID, nombres completos, tipo y número de documento, posición, y opcionalmente fotografía de perfil. Esta información se presenta en tarjetas visuales que facilitan la identificación rápida del empleado correcto.

Al seleccionar un empleado, su ID se captura y utiliza para vincular el reporte de trabajo. El sistema también puede mostrar información adicional del empleado como departamento, área de trabajo y datos de contacto si es necesario.

Similar al módulo de proyectos, el datasource de empleados define una interfaz completa con operaciones CRUD, pero estas están implementadas como placeholders. El enfoque actual está en la búsqueda y selección rápida, dejando la gestión completa de empleados para una futura implementación administrativa.

El módulo está diseñado para escalar eficientemente incluso con miles de empleados en la base de datos, ya que solo carga los resultados relevantes de cada búsqueda en lugar de mantener listas completas en memoria.

---

## Arquitectura General

Todos los módulos siguen los principios de Clean Architecture, separando claramente las responsabilidades en tres capas:

**Capa de Presentación**: Contiene las pantallas, widgets y providers de estado. Es responsable de la interfaz de usuario y la interacción con el usuario.

**Capa de Dominio**: Define las entidades, casos de uso y contratos de repositorios. Representa la lógica de negocio pura, independiente de frameworks y librerías externas.

**Capa de Datos**: Implementa los repositorios y datasources. Maneja la comunicación con APIs externas, bases de datos locales y almacenamiento de archivos.

Esta arquitectura permite:
- Facilidad de testing mediante inyección de dependencias
- Mantenibilidad al tener responsabilidades claramente separadas
- Escalabilidad al poder modificar capas independientemente
- Reutilización de código entre diferentes features
- Flexibilidad para cambiar implementaciones sin afectar otras capas
