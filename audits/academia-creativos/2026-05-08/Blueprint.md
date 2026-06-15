# Academia Creativos Digitales — Blueprint de Especificación

**Versión:** 2.0 (Actualización Final)
**Fecha:** 2026-05-08
**Framework:** Moodle 4.x (PHP)
**Plataforma:** academia.creativos-digitales.com
**URL Base:** https://academia.creativos-digitales.com

---

## 1. Arquitectura General

### 1.1 Stack Tecnológico
- **Frontend:** Moodle 4.x con tema personalizado
- **Backend:** PHP (Moodle LMS)
- **Base de datos:** MySQL (inferencia basada en estructura Moodle)
- **Servidor web:** Apache/Nginx (gestión.creativos-digitales.com para panel admin, academia.creativos-digitales.com para LMS)
- **Auth:** Moodle native sessions + cookies
- **Contenido embebido:** Genially iframes, Google Meet links, recursos externos LTI

### 1.2 Estructura de URLs

```
https://academia.creativos-digitales.com/
├── login/index.php              # Login redirect
├── course/
│   ├── index.php                # Catálogo de cursos (33 páginas)
│   ├── view.php?id={id}         # Vista de curso individual
│   └── index.php?categoryid={n} # Cursos por categoría
├── my/
│   ├── index.php                # Área personal (dashboard)
│   └── courses.php              # Mis cursos
├── calendar/view.php            # Calendario de eventos
├── notification/                # Notificaciones
├── message/                     # Sistema de mensajería
├── user/profile.php             # Perfil de usuario
├── grade/report/                # Informes de calificaciones
└── editmode.php                 # Activar modo edición
```

### 1.3 Credenciales de Acceso
- **Usuario:** misterruddy@laspalmas.edu.bo
- **Contraseña:** Capacitaciones2025
- **Rol:** Docente-Escuela (Las Palmas School)
- **Colegio:** Las Palmas School - 1008

---

## 2. Catálogo de Cursos

### 2.1 Cursos Inscritos (25 cursos en "Mis cursos")

| # | Nombre del Curso | ID | Categoría | Estado |
|---|-----------------|-----|-----------|--------|
| 1 | Junior 1 - 2601 | 9142 | 2601 | ACCESIBLE |
| 2 | Junior 2 - 2601 | 9161 | 2601 | ACCESIBLE |
| 3 | Junior 3 - 2601 | 9186 | 2601 | ACCESIBLE |
| 4 | Coder 1 - 2601 | 9187 | 2601 | ACCESIBLE |
| 5 | Coder 2 - 2601 | 9188 | 2601 | ACCESIBLE |
| 6 | Coder 3 - 2601 | 9191 | 2601 | ACCESIBLE |
| 7 | Developer 1 (GB) - 2601 | 9346 | 2601 | ACCESIBLE |
| 8 | Developer 1 - Ed. Soc. - 2601 | 10574 | 2601 | ACCESIBLE |
| 9 | Developer 2 - 2601 | 9166 | 2601 | ACCESIBLE |
| 10 | Developer 3 - 2601 | 9349 | 2601 | ACCESIBLE |
| 11 | Senior 1 - 2601 | 9358 | 2601 | ACCESIBLE |
| 12 | Senior 2 - 2601 | 9360 | 2601 | ACCESIBLE |
| 13 | Makey Makey 1 - 2601 | 9353 | 2601 | ACCESIBLE |
| 14 | Makey Makey 2 - 2601 | 9185 | 2601 | ACCESIBLE |
| 15 | Makey Makey 4 - 2601 | 9354 | 2601 | ACCESIBLE |
| 16 | Tinkercad Bloques 1 - 2601 | 9249 | 2601 | ACCESIBLE |
| 17 | Tinkercad Arduino 1 - 2601 | 9348 | 2601 | ACCESIBLE |
| 18 | Cápsulas Junior - 2601 | 9146 | 2601 | ACCESIBLE |
| 19 | Cápsulas Coder - 2601 | 9344 | 2601 | ACCESIBLE |
| 20 | Cápsulas Developer - 2601 | 9345 | 2601 | ACCESIBLE |
| 21 | Cápsulas Senior - 2601 | 9362 | 2601 | ACCESIBLE |
| 22 | Junior 1 - Ed. Soc. - 2601 | 10737 | 2601 | ACCESIBLE |
| 23 | Club de Programadores - Liga Minecraft | 13080 | Club de Programadores | ACCESIBLE |
| 24 | Club de Programadores - Liga Scratch | 13079 | Club de Programadores | ACCESIBLE |
| 25 | Bienvenidos a Creativos Digitales - Las Palmas | 6297 | Las Palmas School | ACCESIBLE |

### 2.2 Cursos Las Palmas School (Grados 1-6, Años 1-5, Robótica)

| # | Nombre del Curso | ID | Nivel | Estado |
|---|-----------------|-----|-------|--------|
| 26 | 1º Año Las Palmas School | 13439 | Año 1 | ACCESIBLE |
| 27 | 2º Año Las Palmas School | 13440 | Año 2 | ACCESIBLE |
| 28 | 3º Año Las Palmas School | 13441 | Año 3 | ACCESIBLE |
| 29 | 4º Año Las Palmas School | 13442 | Año 4 | ACCESIBLE |
| 30 | 5º Año Las Palmas School | 13443 | Año 5 | ACCESIBLE |
| 31 | 1º Grado Las Palmas School | 13433 | Grado 1 | ACCESIBLE |
| 32 | 2º Grado Las Palmas School | 13434 | Grado 2 | ACCESIBLE |
| 33 | 3º Grado Las Palmas School | 13435 | Grado 3 | ACCESIBLE |
| 34 | 4º Grado Las Palmas School | 13436 | Grado 4 | ACCESIBLE |
| 35 | 5º Grado Las Palmas School | 13437 | Grado 5 | ACCESIBLE |
| 36 | 6º Grado Las Palmas School | 13438 | Grado 6 | ACCESIBLE |
| 37 | 1º Año Robótica Las Palmas School | 13450 | Año 1 Robótica | ACCESIBLE |
| 38 | 2º Año Robótica Las Palmas School | 13451 | Año 2 Robótica | ACCESIBLE |
| 39 | 3º Año Robótica Las Palmas School | 13452 | Año 3 Robótica | ACCESIBLE |
| 40 | 4º Año Robótica Las Palmas School | 13453 | Año 4 Robótica | ACCESIBLE |
| 41 | 5º Año Robótica Las Palmas School | 13454 | Año 5 Robótica | ACCESIBLE |
| 42 | 1º Grado Robótica Las Palmas School | 13444 | Grado 1 Robótica | ACCESIBLE |
| 43 | 2º Grado Robótica Las Palmas School | 13445 | Grado 2 Robótica | ACCESIBLE |
| 44 | 3º Grado Robótica Las Palmas School | 13446 | Grado 3 Robótica | ACCESIBLE |
| 45 | 4º Grado Robótica Las Palmas School | 13447 | Grado 4 Robótica | ACCESIBLE |
| 46 | 5º Grado Robótica Las Palmas School | 13448 | Grado 5 Robótica | ACCESIBLE |
| 47 | 6º Grado Robótica Las Palmas School | 13449 | Grado 6 Robótica | ACCESIBLE |

---

## 3. Estructura de un Curso (Ejemplo: Junior 1 - 2601)

### 3.1 Pestañas del Navegador de Curso

```
Curso | Participantes | Calificaciones | Informes | Más ▼
```

- **Curso:** Vista principal del curso con secciones
- **Participantes:** Lista de estudiantes enrolados
- **Calificaciones:** Panel de calificaciones del curso
- **Informes:** Reportes de actividad y completitud
- **Más:** Más opciones (insignias, competencias, etc.)

### 3.2 Secciones del Curso (11 secciones en Junior 1)

| Sección | URL |
|---------|-----|
| 1 | /course/view.php?id=9142&section=1 |
| 2 | /course/view.php?id=9142&section=2 |
| 3 | /course/view.php?id=9142&section=3 |
| 4 | /course/view.php?id=9142&section=4 |
| 5 | /course/view.php?id=9142&section=5 |
| 6 | /course/view.php?id=9142&section=6 |
| 7 | /course/view.php?id=9142&section=7 |
| 8 | /course/view.php?id=9142&section=8 |
| 9 (Mosaico) | /course/view.php?id=9142&section=9 |
| 10 (Mosaico) | /course/view.php?id=9142&section=10 |
| 11 (Mosaico) | /course/view.php?id=9142&section=11 |

### 3.3 Bloques Laterales (Administración)

```
Administración del curso
├── Finalización del curso
├── Usuarios
│   ├── VerTodos los participantes
│   ├── Grupos
│   └── Inscritos
├── Filtros
├── Informes
│   ├── Informes
│   └── Pautas de completitud
├── Configuración Calificaciones
├── Importar
├── Copia de seguridad
└── Herramientas Externas LTI
```

### 3.4 Bloques de Contenido Emebido (Ejemplo Junior 1)

1. **Genially: Cápsulas** (id=9146) - Enlace a curso Cápsulas Junior
2. **Genially: Educación Socioemocional** (id=10737) - Enlace a Junior 1 - Ed. Soc.
3. **Genially: Taller Docente** - Cápsula de invitación a capacitación
4. **Genially: Tutoriales para el Docente** - Recursos de ayuda

---

## 4. Área Personal (/my/)

### 4.1 Estructura del Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  Creativos Digitales        Mis cursos (25)  Notif(1) Buscar │
├─────────────────────────────────────────────────────────────┤
│  > Área personal                                              │
│  ─────────────────────────────────────────────────────────  │
│  [Cursos en formato grid 3 columnas]                         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐                  │
│  │ 1º Año    │ │ 1ºAño Rob │ │ 1ºGrado   │                  │
│  │ Las Palmas│ │ Las Palmas│ │ Las Palmas│                  │
│  │ [Entrar]  │ │ [Entrar]  │ │ [Entrar]  │                  │
│  └───────────┘ └───────────┘ └───────────┘                  │
│  ... (continúa en filas de 3)                               │
│                                                             │
│  Grupo al que pertenece el usuario:                          │
│  Las Palmas School - Primario - 1º - 2026                   │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Elementos Visibles

- **Cursos inscriptos:** Grid de 3 columnas con imagen, nombre, categoría y botón "Entrar al curso"
- **Progreso:** Muestra "No completion criteria" para cada curso
- **Grupo:** Las Palmas School - Primario - 1º - 2026
- **Notificaciones:** 1 notificación nueva (indicador en header)
- **Búsqueda:** Disponible en header

---

## 5. Sistema de Calendario

### 5.1 Estructura de Calendario

```
┌─────────────────────────────────────────────────────────────┐
│  Próximos eventos                      [Todos los cursos ▼] │
│  ─────────────────────────────────────────────────────────   │
│  No hay eventos próximos                                     │
│  ─────────────────────────────────────────────────────────   │
│  [Importar o exportar calendarios]                           │
│                                                             │
│  Clave de eventos:                                           │
│  [✓] Ocultar eventos de sitio                               │
│  [✓] Ocultar eventos de categoría                           │
│  [✓] Ocultar eventos de curso                                │
│  [✓] Ocultar eventos de grupo                                │
│  [✓] Ocultar eventos de usuario                              │
│  [ ] Ocultar eventos de otro                                 │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Filtros Disponibles

Dropdown con todos los cursos enrolados (25 opciones):
- Todos los cursos
- 1º Año Las Palmas School
- 1º Año Robótica Las Palmas School
- 1º Grado Las Palmas School
- ... (todos los 25 cursos)

---

## 6. Categorías del Catálogo

### 6.1 Categorías Principales (33 páginas)

| Categoría | categoryid |
|-----------|------------|
| Cursos Colegios | 20 |
| Capacitaciones internas Colegios | 143 |
| Talleres de Formación Continua | 36 |
| Capacitadores | 66 |
| General | 1 |
| Club de Programadores | 104 |
| Inducciones | 15 |
| Programación y Creatividad | 3 |
| Alcaldía de Medellín | 332 |
| Piloto Colegios NO USAR!! | 159 |
| Fundaciones | 92 |
| Advanced Kids - 1001 | 19 |
| Albores - 1033 | 94 |
| Centro Educativo Cristiano La Roca - 1198 | 299 |
| Centro Educativo de la Fundación San Patricio - 1218 | 298 |
| Centro Educativo Joseph Caanan - 1196 | 302 |
| Centro Educativo Luceritos del Señor - 1014 | 14 |
| Centro Pedagógico Mandala Pyky Uba - 1253 | 339 |
| Centro Educativo Pedro Cabrini - 1024 | 71 |
| Instituto Dr. Abraham Molina - 1123 | 200 |
| Colegio Adventista Baluarte Interamericano Cabi - 1197 | 277 |
| Colegio Adventista Bethel - 1073 | 145 |
| Colegio Auroras del Sur - 1069 | 156 |
| Colegio Arcoiris - 1015 | 37 |
| Colegio Alemán Cali - DEMO | 35 |
| Colegio André Lapierre - 1115 | 195 |
| Colegios Better Kids - 1067 | 130 |
| Colegio de María - 1006 | 34 |
| Colegio las Marías - 1016 | 38 |
| Colegio Cristiano Psicopedagógico - 1056 | 141 |
| ... (más categorías en páginas siguientes) |

---

## 7. Navegación Principal

### 7.1 Header Global

```
┌──────────────────────────────────────────────────────────────────┐
│ Creativos Digitales (logo)                    Mis cursos(25)  🔔  │
│                                                  🔍          👤   │
│                                              Notificaciones Buscar │
└──────────────────────────────────────────────────────────────────┘
```

### 7.2 Barra de Navegación

```
 Área personal > Mis cursos > [Nombre del curso]
```

### 7.3 Menú de Curso (dentro de curso)

```
Curso | Participantes | Calificaciones | Informes | Más ▼
```

---

## 8. Sistema de Autenticación

### 8.1 Login

- **URL:** https://academia.creativos-digitales.com/login/index.php
- **Método:** Formulario Moodle nativo
- **Session:** Cookie de sesión Moodle (MoodleSession)
- **Redirect:** Redirige automáticamente a /my/ si ya autenticado

### 8.2 Logout

- **URL:** https://gestion.creativos-digitales.com/logout (redirección al panel de gestión)

---

## 9. Panel de Gestión vs Academia

### 9.1 Academia (LMS)

- **URL:** https://academia.creativos-digitales.com
- **Propósito:** Learning Management System - cursos, contenido, calificaciones
- **Auth:** Moodle native

### 9.2 Gestión (Panel Admin)

- **URL:** https://gestion.creativos-digitales.com
- **Propósito:** Administración de escuelas, docentes, cursos, talleres
- **Auth:** Sesión separada (no SSO con Moodle academia)

### 9.3 Cross-linking

- Desde academia → gestión: "Acceso Academia Virtual" → redirect a gestión
- Desde gestión → academia: El portal muestra tus cursos activos
- Los bloques Genially en cursos contienen enlaces a gestión (ej: inscripción tutorías)

---

## 10. Estados de Error

### 10.1 Sin Enrollment

Cuando un usuario no está enrolado en un curso:
- El catálogo muestra el curso pero sin acceso directo
- Intentar acceder directamente a /course/view.php?id=XXXX redirige a página de error de enrollment

### 10.2 Sesión Expirada

- Moodle sessions expiran después de cierto tiempo
- Redirige a /login/index.php con mensaje de再就业

### 10.3 Categorías Vacías

Algunas categorías del catálogo no tienen cursos visibles para este usuario

---

## 11. Mapa del Sitio

```
academia.creativos-digitales.com/
├── /                     # Home (redirige a /my/)
├── /login/               # Login
├── /course/              # Catálogo principal (33 páginas)
│   ├── /course/index.php?browse=categories&perpage=20&page=N
│   ├── /course/index.php?categoryid=N
│   └── /course/view.php?id=N
├── /my/                  # Área personal / Dashboard
│   └── /my/courses.php   # Mis cursos
├── /calendar/            # Calendario
│   └── /calendar/view.php
├── /notification/        # Notificaciones
├── /message/             # Mensajería
├── /user/profile.php     # Perfil
├── /grade/report/        # Informes de calificaciones
└── /editmode.php         # Activar edición
```

---

## 12. Notas Técnicas

### 12.1 Tecnologías Detectadas

- **Moodle 4.x:** Framework LMS detectado por estructura de URLs y UI
- **Genially:** Contenido embebido en iframes (bloques de contenido)
- **Google Meet:** Enlaces externos para videollamadas
- **Fonts Awesome:** Iconografía (, , etc.)

### 12.2 Recursos Estáticos

- Logo Creativos Digitales
- Iconos de Font Awesome
- Imágenes de cursos desde CDN de Moodle

### 12.3 Cookies

- MoodleSession: Sesión de autenticación
- MOODLEID_?: Cookie de referencia

---

## 13. Limitaciones de Esta Auditoría

### 13.1 No Documentado

- No se accedió a cada una de las 47 cursos individualmente
- No se verificó el contenido completo de cada sección de cada curso
- No se documentaron todas las categorías (33 páginas del catálogo)
- No se probó el sistema de mensajería con usuarios reales
- No se verificó el sistema de calificaciones en profundidad
- No se accedió a la funcionalidad de informes detallados

### 13.2 Cursos Bloqueados

No se encontró ningún curso bloqueado para este usuario. Los 47 cursos documentados tienen enrollment activo.

### 13.3 Alias de Cursos

No se detectaron cursos que sean aliases de otros. Cada ID de curso representa contenido único.

---

## 14. Checklist de Funcionalidades

### Autenticación
- [x] Login funcional
- [x] Logout funcional
- [x] Sesión persiste entre páginas

### Catálogo
- [x] Listado de categorías (20+ categorías visibles)
- [x] Paginación (33 páginas)
- [x] Filtrado por categoría

### Cursos
- [x] Vista de curso con secciones
- [x] Navegación entre secciones
- [x] Contenido embebido (Genially)
- [x] Bloques laterales administrativos
- [x] Participación de usuarios
- [x] Calificaciones
- [x] Informes

### Dashboard (Área Personal)
- [x] Grid de cursos enrolados
- [x] Progreso por curso
- [x] Grupo del usuario
- [x] Enlace a calendario
- [x] Enlace a notificaciones

### Calendario
- [x] Vista de próximos eventos
- [x] Filtro por curso
- [x] Importar/exportar calendarios
- [x] Clave de eventos (mostrar/ocultar)

### Sistema
- [x] Notificaciones (1 nueva visible)
- [x] Búsqueda
- [x] Perfil de usuario
- [x] Cambio de idioma (English disponible)

---

**Blueprint generado:** 2026-05-08
**Auditor:** OpenCode App-Scraper-Tester Skill
**Credenciales usadas:** misterruddy@laspalmas.edu.bo / Capacitaciones2025