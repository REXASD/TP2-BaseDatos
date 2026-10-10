# TP2 — Proyecto completo preparado para Vercel

## 1. Reemplazar los archivos

Extraiga este ZIP y copie el contenido de `TP2-BaseDatos` sobre su carpeta actual
del proyecto. Acepte reemplazar los archivos e incorporar las carpetas nuevas.
Conserve la carpeta `.git` de su proyecto actual: este ZIP no incluye historial.

Los archivos completos actualizados son:

- `Flask/app.py`
- Las seis plantillas originales de `Flask/Templates/`
- `Flask/Templates/error.html` (nuevo)
- `Flask/public/static/styles/estilos.css` (nuevo, mismo diseño)
- `Flask/requirements.txt` (nuevo)
- `Flask/vercel.json` (nuevo)
- `Flask/.python-version` (nuevo)
- `Flask/.env.example` (nuevo)
- `database/02_stored_procedures.sql`
- `.gitignore`
- Este instructivo

El ZIP también contiene los demás archivos originales necesarios del proyecto.
No copie una carpeta `TP2-BaseDatos` dentro de otra carpeta con el mismo nombre.

## 2. Configurar Vercel

Suba los cambios a su repositorio de GitHub e importe el repositorio en Vercel.

| Ajuste | Valor |
| --- | --- |
| Root Directory | `Flask` (respetar la F mayúscula) |
| Framework Preset | Flask |
| Build Command | Automático; no agregar un comando personalizado |
| Output Directory | Automático; no escribir `static`, `public` ni `dist` |
| Install Command | Automático; Vercel instala `requirements.txt` |
| Python | 3.12, indicado por `.python-version` |

No configure `python app.py` como comando de construcción. Vercel importa
la variable `app` de `app.py` y ejecuta Flask como una función.
La carpeta `Flask/public/` permite que Vercel entregue el CSS en `/static/`.

Antes del primer despliegue agregue las siguientes variables en
**Settings → Environment Variables**. Aplíquelas a Production y Preview si
va a usar ambos entornos. Escriba los valores sin comillas.

| Variable | Valor |
| --- | --- |
| `SECRET_KEY` | Una clave aleatoria, generada con el comando de abajo |
| `DB_SERVER` | `tp2-basedatos.database.windows.net` |
| `DB_NAME` | `TP2-BaseDatos` |
| `DB_USER` | Su usuario SQL con acceso a esta base |
| `DB_PASSWORD` | La contraseña de ese usuario SQL |

Genere `SECRET_KEY` en su computadora:

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

Use la misma clave para todas las instancias de un entorno. Si cambia la clave,
las sesiones existentes dejan de ser válidas. No use el ejemplo de otro usuario.

El archivo original contenía credenciales SQL dentro del código. Esta versión
las elimina. Cambie esa contraseña antes de publicar, especialmente si el
código original ya se subió a GitHub. Cambiar el archivo no borra el historial.

Guarde las variables y despliegue. Si las cambia después de desplegar,
haga un **Redeploy** para aplicarlas.

## 3. Permitir la conexión en Azure SQL

Reemplazar archivos y configurar variables no cambia el firewall de Azure.
En el **servidor lógico** `tp2-basedatos` abra **Networking** y confirme que
la conexión pública y las reglas de firewall permiten al backend de Vercel
acceder al puerto TCP 1433.

La regla que permite la IP de su computadora solo habilita su computadora.
Vercel necesita autorización para sus propias IP de salida.
La opción “Allow Azure services and resources to access this server” no
autoriza por sí sola las conexiones de Vercel.

Con **Static IPs** de Vercel, agregue en Azure las IP de salida que le muestre
Vercel. Es una característica de pago; compruebe su disponibilidad y costo
en su cuenta antes de contratarla. No invente una IP fija para un despliegue
que no tiene esa función: sus IP de salida pueden cambiar.

Si usa el plan gratuito para una demostración académica con datos de prueba,
una alternativa temporal es permitir el rango IPv4 `0.0.0.0` a
`255.255.255.255` en Azure. Esa regla permite intentos de conexión desde
cualquier IP; requiere usuario y contraseña SQL y amplía la exposición del
servidor. Úsela solo si acepta ese alcance para la demostración y elimínela
al terminar. No se crea automáticamente con estos archivos.

La conexión usa TLS, valida el certificado y cifra toda la sesión.
Si Azure está configurado con Redirect y la red bloquea los puertos
adicionales, revise la política de conexión: Proxy usa el gateway por 1433.
Una base con acceso exclusivamente privado necesita una ruta de red compatible;
los archivos no crean esa ruta.

Si la base es serverless y estuvo pausada, reactívela desde SSMS antes de la
demostración y vuelva a intentar el login. Esta app no mantiene peticiones
bloqueadas durante largos ciclos de reintentos.

## 4. Corrección del script SQL

En `02_stored_procedures.sql` faltaba `GO` después de
`sp_ObtenerTiposDocumento`, antes de crear `sp_ObtenerBeneficiarioPorId`.
También se añadió el terminador del último lote.

Si los procedimientos ya están bien instalados en Azure, no necesita volver
a crear la base ni recargar datos. Si necesita actualizar los procedimientos,
ejecute **solo** `database/02_stored_procedures.sql` en SSMS conectado a
`TP2-BaseDatos`. El archivo usa `CREATE OR ALTER`; no elimina las tablas.
No ejecute el cargador de datos ni scripts de uso frecuente para desplegar.

## 5. Ejecutar en su computadora

Desde la carpeta `Flask`:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Complete las cinco variables en `.env` y ejecute:

```powershell
python app.py
```

Abra `http://127.0.0.1:5000`. El usuario y contraseña del formulario son los
usuarios de la aplicación en `dbo.Usuario`; `DB_USER` y `DB_PASSWORD`
autentican la conexión de Flask con SQL Server.

No suba `.env` a GitHub. Está excluido por `.gitignore`.
El proyecto usa `python-tds`: no necesita instalar un controlador ODBC
de Windows para esta versión.

## 6. Cambios de funcionamiento

- Conexión SQL mediante parámetros `%s`, TLS y variables de entorno.
- Una conexión por petición, con cierre garantizado al terminar.
- Lectura de todos los resultsets y del retorno de cada procedimiento.
- Plantillas con la ruta `Templates` correcta para Linux.
- Catálogo de documentos corregido para usar el campo `Id` que devuelve SQL.
- Verificación de sesión también en la ruta de nuevo beneficiario.
- Protección CSRF en todos los formularios POST, incluido el login.
- Logout mediante POST; el botón de cierre de sesión ya está actualizado.
- Permisos de cuenta y pertenencia de beneficiario comprobados en el servidor.
- Validación de números enteros, límites de campos, fechas y catálogos.
- Bloqueo de navegación con porcentajes pendientes conservado y actualizado
  antes de redirigir después de una modificación.
- Sesiones firmadas con una clave estable; cookies Secure en Vercel,
  HttpOnly y SameSite=Lax; páginas privadas sin caché.
- Mensajes de error que no muestran información interna de SQL.

## 7. Verificación después de desplegar

1. Abra `/login` y confirme que carga el diseño.
2. Pruebe credenciales inválidas y un usuario válido.
3. Compruebe las cuentas y abra sus estados de cuenta.
4. Pruebe agregar, editar, cambiar el porcentaje y eliminar un beneficiario
   en una cuenta de prueba.
5. Confirme el bloqueo cuando los porcentajes no suman 100 y su liberación
   al corregirlos.
6. Cierre sesión y confirme que no puede volver a las cuentas sin ingresar.

Se aprobaron 21 pruebas locales, incluida la validación TLS con un certificado
de prueba. Se fija `pyOpenSSL==25.3.0` porque versiones posteriores eliminan
una API de certificados que usa este driver.

Las verificaciones locales con una base simulada prueban rutas, renderizado,
permisos y adaptación del driver. No sustituyen una prueba de conexión real
con Azure ni un despliegue en su cuenta de Vercel. Aquí no se modificaron los
datos de su base ni se publicó la aplicación.

## Fuentes técnicas

- https://vercel.com/docs/frameworks/backend/flask
- https://vercel.com/docs/functions/runtimes/python
- https://vercel.com/docs/networking/static-ips
- https://python-tds.readthedocs.io/en/1.16.1/pytds.html
- https://learn.microsoft.com/en-us/azure/azure-sql/database/firewall-configure
- https://learn.microsoft.com/en-us/azure/azure-sql/database/connectivity-architecture
