from datetime import date, timedelta
from ipaddress import ip_address
from pathlib import Path
import os
import re

import certifi
import pytds
from dotenv import load_dotenv
from flask import Flask, abort, g, redirect, render_template, request, session, url_for
from flask_wtf.csrf import CSRFProtect, CSRFError

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / '.env', override=False)
EN_VERCEL = os.getenv('VERCEL') == '1'
secret_key = os.getenv('SECRET_KEY', '')
if len(secret_key) < 32:
    raise RuntimeError('Configure SECRET_KEY con al menos 32 caracteres en .env o Vercel.')

# Templates conserva el nombre original, incluyendo la mayúscula.
# public/static funciona tanto en Flask local como en el CDN de Vercel.
app = Flask(__name__, root_path=str(BASE_DIR), template_folder='Templates',
            static_folder='public/static', static_url_path='/static')
app.config.update(
    SECRET_KEY=secret_key,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SECURE=EN_VERCEL,
    SESSION_COOKIE_SAMESITE='Lax',
    PERMANENT_SESSION_LIFETIME=timedelta(hours=2),
    MAX_CONTENT_LENGTH=64 * 1024,
)
csrf = CSRFProtect(app)


def obtener_conexion():
    """Una conexión por petición, cerrada automáticamente al terminar."""
    if 'conexion' not in g:
        claves = ('DB_SERVER', 'DB_NAME', 'DB_USER', 'DB_PASSWORD')
        if any(not os.getenv(clave) for clave in claves):
            raise RuntimeError('Faltan variables de conexión a Azure SQL.')
        try:
            g.conexion = pytds.connect(
                server=os.environ['DB_SERVER'], database=os.environ['DB_NAME'],
                user=os.environ['DB_USER'], password=os.environ['DB_PASSWORD'],
                port=1433, autocommit=True, login_timeout=10, timeout=15,
                cafile=certifi.where(), validate_host=True, enc_login_only=False,
                disable_connect_retry=True, appname='TP2-BaseDatos',
            )
        except OSError:
            raise pytds.OperationalError('No se pudo conectar al servidor SQL.') from None
    return g.conexion


@app.teardown_appcontext
def cerrar_conexion(error=None):
    conexion = g.pop('conexion', None)
    if conexion is not None:
        conexion.close()


def ejecutar_sp(nombre, parametros=None):
    """Ejecuta un SP parametrizado y lee todos sus conjuntos de resultados."""
    # Los nombres de SP y parámetros se definen en el código, no en formularios.
    if not re.fullmatch(r'sp_[A-Za-z0-9_]+', nombre):
        raise ValueError('Nombre de procedimiento inválido.')
    parametros = parametros or {}
    if any(not re.fullmatch(r'[A-Za-z0-9_]+', clave) for clave in parametros):
        raise ValueError('Nombre de parámetro inválido.')
    argumentos = ', '.join(f'@{clave}=%s' for clave in parametros)
    consulta = ('DECLARE @Resultado INT; '
                f'EXEC @Resultado = dbo.{nombre} {argumentos}; '
                'SELECT @Resultado AS __resultado_sp;')
    resultado, conjuntos = None, []
    with obtener_conexion().cursor() as cursor:
        cursor.execute(consulta, tuple(parametros.values()))
        while True:
            if cursor.description:
                columnas = [columna[0] for columna in cursor.description]
                filas = [dict(zip(columnas, fila)) for fila in cursor.fetchall()]
                if columnas == ['__resultado_sp']:
                    resultado = filas[0]['__resultado_sp'] if filas else None
                else:
                    conjuntos.append(filas)
            if not cursor.nextset():
                break
    if resultado is None:
        raise RuntimeError('El procedimiento no devolvió su código de resultado.')
    return resultado, conjuntos


def consultar_sp(nombre, **parametros):
    _, conjuntos = ejecutar_sp(nombre, parametros)
    return conjuntos[0] if conjuntos else []


def obtener_cuenta_autorizada(id_cuenta):
    cuentas = consultar_sp('sp_ObtenerCuentasUsuario', IdUsuario=session['id_usuario'])
    for cuenta in cuentas:
        if cuenta['IdCuenta'] == id_cuenta:
            return cuenta
    abort(403)


def usuario_puede_ver_cuenta(id_usuario, id_cuenta):
    return any(cuenta['IdCuenta'] == id_cuenta for cuenta in
               consultar_sp('sp_ObtenerCuentasUsuario', IdUsuario=id_usuario))


def obtener_beneficiario(id_cuenta, id_beneficiario):
    filas = consultar_sp('sp_ObtenerBeneficiarioPorId',
                         IdBeneficiario=id_beneficiario, IdCuenta=id_cuenta)
    if not filas:
        abort(404)
    return filas[0]


def actualizar_pendiente(id_cuenta):
    # Actualizar antes de redirigir mantiene el bloqueo tras una modificación.
    lista = consultar_sp('sp_ObtenerBeneficiarios', IdCuenta=id_cuenta)
    porcentajes = consultar_sp('sp_VerificarPorcentajeBeneficiarios', IdCuenta=id_cuenta)
    if not porcentajes:
        raise RuntimeError('No se recibió la suma de porcentajes.')
    porcentaje = porcentajes[0]
    if lista and not porcentaje['PorcentajeCorrecto']:
        session['cuenta_porcentaje_pendiente'] = id_cuenta
    elif session.get('cuenta_porcentaje_pendiente') == id_cuenta:
        session.pop('cuenta_porcentaje_pendiente', None)
    return lista, porcentaje


ENDPOINTS_BENEFICIARIOS = {
    'beneficiarios', 'nuevo_beneficiario', 'editar_beneficiario',
    'eliminar_beneficiario', 'actualizar_porcentaje_beneficiario',
}


@app.before_request
def verificar_sesion_y_porcentajes():
    if request.endpoint in (None, 'static', 'login', 'logout'):
        return None
    if 'id_usuario' not in session:
        return redirect(url_for('login'))
    pendiente = session.get('cuenta_porcentaje_pendiente')
    if pendiente is not None:
        solicitada = (request.view_args or {}).get('id_cuenta')
        if request.endpoint not in ENDPOINTS_BENEFICIARIOS or solicitada != pendiente:
            return redirect(url_for('beneficiarios', id_cuenta=pendiente))
    return None


@app.after_request
def configurar_cache(respuesta):
    if request.endpoint != 'static':
        respuesta.headers['Cache-Control'] = 'no-store'
    return respuesta


@app.errorhandler(CSRFError)
def formulario_expirado(error):
    return render_template('error.html', mensaje='El formulario expiró. Recargue la página e intente de nuevo.'), 400


@app.errorhandler(403)
def sin_permiso(error):
    return render_template('error.html', mensaje='No tiene permiso para acceder a esta cuenta.'), 403


@app.errorhandler(404)
def no_encontrado(error):
    return render_template('error.html', mensaje='La página o el beneficiario no existe.'), 404


@app.errorhandler(pytds.Error)
@app.errorhandler(TimeoutError)
def error_base_datos(error):
    # Mostrar el diagnóstico en la terminal, conservando el mensaje genérico
    # del navegador. Ocultar contraseñas si aparecen en el texto del error.
    detalle = str(error)
    for secreto in (os.getenv('DB_PASSWORD', ''), request.form.get('password', '')):
        if secreto:
            detalle = detalle.replace(secreto, '[oculto]')
    app.logger.error(
        'Error SQL: %s | número=%s | procedimiento=%s | línea=%s | detalle=%s',
        type(error).__name__, getattr(error, 'number', '?'),
        getattr(error, 'procname', '?'), getattr(error, 'line', '?'), detalle,
    )
    return render_template('error.html', mensaje='No se pudo completar la operación con la base de datos. Intente nuevamente.'), 503


@app.errorhandler(500)
def error_interno(error):
    return render_template('error.html', mensaje='No se pudo completar la operación. Revise la configuración del servidor.'), 500


def ip_cliente():
    valor = request.remote_addr or ''
    if EN_VERCEL:
        valor = request.headers.get('x-forwarded-for', valor).split(',')[0].strip()
    try:
        return str(ip_address(valor))
    except ValueError:
        return '0.0.0.0'


@app.route('/', methods=['GET', 'POST'])
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        usuario = request.form.get('usuario', '').strip()
        password = request.form.get('password', '')
        if not usuario or not password or len(usuario) > 64 or len(password) > 255:
            return render_template('login.html', error='Ingrese un usuario y contraseña válidos.'), 400
        resultado, conjuntos = ejecutar_sp('sp_ValidarLogin', {
            'Usuario': usuario, 'Password': password, 'IP': ip_cliente(),
        })
        datos = next((filas[0] for filas in conjuntos
                      if filas and 'IdUsuario' in filas[0]), None)
        if resultado == 0 and datos:
            session.clear()
            session.permanent = True
            session['id_usuario'] = datos['IdUsuario']
            session['usuario'] = datos['User']
            session['es_administrador'] = bool(datos['EsAdministrador'])
            return redirect(url_for('inicio'))
        return render_template('login.html', error='Usuario o contraseña incorrectos')
    if 'id_usuario' in session:
        pendiente = session.get('cuenta_porcentaje_pendiente')
        if pendiente is not None:
            return redirect(url_for('beneficiarios', id_cuenta=pendiente))
        return redirect(url_for('inicio'))
    return render_template('login.html')


@app.route('/inicio')
def inicio():
    cuentas = consultar_sp('sp_ObtenerCuentasUsuario', IdUsuario=session['id_usuario'])
    return render_template('inicio.html', usuario=session['usuario'], cuentas=cuentas)


@app.route('/cuenta/<int:id_cuenta>/beneficiarios')
def beneficiarios(id_cuenta):
    cuenta = obtener_cuenta_autorizada(id_cuenta)
    lista, porcentaje = actualizar_pendiente(id_cuenta)
    return render_template('beneficiarios.html', beneficiarios=lista,
                           id_cuenta=id_cuenta, numero_cuenta=cuenta['NumeroCuenta'],
                           total_porcentaje=porcentaje['TotalPorcentaje'],
                           porcentaje_correcto=bool(porcentaje['PorcentajeCorrecto']))


def leer_porcentaje():
    try:
        porcentaje = int(request.form.get('porcentaje', ''))
    except ValueError:
        raise ValueError('El porcentaje debe ser un número entero entre 0 y 100.') from None
    if not 0 <= porcentaje <= 100:
        raise ValueError('El porcentaje debe estar entre 0 y 100.')
    return porcentaje


def leer_datos_beneficiario(nuevo=False):
    campos = {'Nombre': ('nombre', 64), 'ValorDocumentoIdentidad': ('documento', 64),
              'Email': ('email', 100), 'Telefono1': ('telefono1', 20),
              'Telefono2': ('telefono2', 20)}
    datos = {}
    for parametro, (campo, limite) in campos.items():
        valor = request.form.get(campo, '').strip()
        if (not valor and campo != 'telefono2') or len(valor) > limite:
            raise ValueError(f'Revise el campo {campo}; admite hasta {limite} caracteres.')
        datos[parametro] = valor
    try:
        datos['FechaNacimiento'] = date.fromisoformat(request.form.get('fecha_nacimiento', ''))
        datos['IdParentezco'] = int(request.form.get('id_parentezco', ''))
        if nuevo:
            datos['IdTipoDocuIdentidad'] = int(request.form.get('id_tipo_documento', ''))
    except ValueError:
        raise ValueError('Revise la fecha de nacimiento y los catálogos seleccionados.') from None
    if not any(p['Id'] == datos['IdParentezco'] for p in consultar_sp('sp_ObtenerParentescos')):
        raise ValueError('Seleccione un parentesco válido.')
    if nuevo and not any(t['Id'] == datos['IdTipoDocuIdentidad'] for t in consultar_sp('sp_ObtenerTiposDocumento')):
        raise ValueError('Seleccione un tipo de documento válido.')
    datos['Porcentaje'] = leer_porcentaje()
    return datos


@app.route('/cuenta/<int:id_cuenta>/beneficiarios/nuevo', methods=['GET', 'POST'])
def nuevo_beneficiario(id_cuenta):
    obtener_cuenta_autorizada(id_cuenta)
    error = None
    if request.method == 'POST':
        try:
            datos = leer_datos_beneficiario(nuevo=True)
            resultado, _ = ejecutar_sp('sp_InsertarBeneficiario', {
                'IdUsuario': session['id_usuario'], 'IdCuenta': id_cuenta, **datos,
            })
            if resultado == 0:
                actualizar_pendiente(id_cuenta)
                return redirect(url_for('beneficiarios', id_cuenta=id_cuenta))
            error = {1: 'La cuenta ya tiene 3 beneficiarios activos.',
                     2: 'El porcentaje debe estar entre 0 y 100.'}.get(
                         resultado, 'No se pudo agregar el beneficiario.')
        except ValueError as exc:
            error = str(exc)
    return render_template('nuevo_beneficiario.html', id_cuenta=id_cuenta, error=error,
                           parentescos=consultar_sp('sp_ObtenerParentescos'),
                           tipos_documento=consultar_sp('sp_ObtenerTiposDocumento'))


@app.route('/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/editar', methods=['GET', 'POST'])
def editar_beneficiario(id_cuenta, id_beneficiario):
    obtener_cuenta_autorizada(id_cuenta)
    beneficiario = obtener_beneficiario(id_cuenta, id_beneficiario)
    error = None
    if request.method == 'POST':
        try:
            datos = leer_datos_beneficiario()
            resultado, _ = ejecutar_sp('sp_ActualizarBeneficiario', {
                'IdUsuario': session['id_usuario'], 'IdBeneficiario': id_beneficiario, **datos,
            })
            if resultado == 0:
                actualizar_pendiente(id_cuenta)
                return redirect(url_for('beneficiarios', id_cuenta=id_cuenta))
            error = {1: 'El beneficiario no existe o está inactivo.',
                     2: 'El porcentaje debe estar entre 0 y 100.'}.get(
                         resultado, 'No se pudo actualizar el beneficiario.')
        except ValueError as exc:
            error = str(exc)
    return render_template('editar_beneficiario.html', beneficiario=beneficiario,
                           parentescos=consultar_sp('sp_ObtenerParentescos'),
                           id_cuenta=id_cuenta, error=error)


@app.route('/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/eliminar', methods=['POST'])
def eliminar_beneficiario(id_cuenta, id_beneficiario):
    obtener_cuenta_autorizada(id_cuenta)
    obtener_beneficiario(id_cuenta, id_beneficiario)
    resultado, _ = ejecutar_sp('sp_EliminarBeneficiario', {
        'IdUsuario': session['id_usuario'], 'IdBeneficiario': id_beneficiario,
    })
    if resultado == 1:
        abort(404)
    if resultado != 0:
        abort(500)
    actualizar_pendiente(id_cuenta)
    return redirect(url_for('beneficiarios', id_cuenta=id_cuenta))


@app.route('/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/porcentaje', methods=['POST'])
def actualizar_porcentaje_beneficiario(id_cuenta, id_beneficiario):
    obtener_cuenta_autorizada(id_cuenta)
    obtener_beneficiario(id_cuenta, id_beneficiario)
    try:
        porcentaje = leer_porcentaje()
    except ValueError as exc:
        return render_template('error.html', mensaje=str(exc)), 400
    resultado, _ = ejecutar_sp('sp_ActualizarPorcentajeBeneficiario', {
        'IdUsuario': session['id_usuario'], 'IdBeneficiario': id_beneficiario,
        'Porcentaje': porcentaje,
    })
    if resultado == 1:
        abort(404)
    if resultado == 2:
        return render_template('error.html', mensaje='El porcentaje debe estar entre 0 y 100.'), 400
    if resultado != 0:
        abort(500)
    actualizar_pendiente(id_cuenta)
    return redirect(url_for('beneficiarios', id_cuenta=id_cuenta))


@app.route('/cuenta/<int:id_cuenta>/estados')
def estados_cuenta(id_cuenta):
    cuenta = obtener_cuenta_autorizada(id_cuenta)
    estados = consultar_sp('sp_ObtenerEstadosCuenta',
                           IdUsuario=session['id_usuario'], IdCuenta=id_cuenta)
    return render_template('estados_cuenta.html', estados=estados,
                           id_cuenta=id_cuenta, numero_cuenta=cuenta['NumeroCuenta'])


@app.route('/logout', methods=['POST'])
def logout():
    try:
        if 'id_usuario' in session:
            ejecutar_sp('sp_LogoutUsuario', {'IdUsuario': session['id_usuario']})
    finally:
        session.clear()
    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=False)
