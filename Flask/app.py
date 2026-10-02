from flask import Flask, render_template, request, redirect, url_for, session
import pyodbc

app = Flask(__name__)
app.secret_key = "tp2-base-datos-2026"

# Configuración de credenciales de Azure SQL Database
DB_USER = "Maicol"
DB_PASSWORD = "Maic#2026!Maic"

def obtener_conexion():
    cadena_conexion = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=tcp:tp2-basedatos.database.windows.net,1433;"
        "DATABASE=TP2-BaseDatos;"
        f"UID={DB_USER};"
        f"PWD={DB_PASSWORD};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )
    return pyodbc.connect(cadena_conexion)

def usuario_puede_ver_cuenta(id_usuario, id_cuenta):
    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        """
        EXEC dbo.sp_ObtenerCuentasUsuario
            @IdUsuario=?;
        """,
        id_usuario
    )

    filas = cursor.fetchall()

    puede_ver = False

    for fila in filas:
        if fila.IdCuenta == id_cuenta:
            puede_ver = True
            break

    cursor.close()
    conexion.close()

    return puede_ver


@app.route("/", methods=["GET", "POST"])
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        usuario = request.form["usuario"].strip()
        password = request.form["password"]
        ip = request.remote_addr

        conexion = obtener_conexion()
        cursor = conexion.cursor()

        cursor.execute(
            """
            DECLARE @Resultado INT;
            EXEC @Resultado = dbo.sp_ValidarLogin
                @Usuario=?,
                @Password=?,
                @IP=?;
            SELECT @Resultado AS Resultado;
            """,
            usuario, password, ip
        )

        resultado = None
        datos_usuario = None

        while True:
            if cursor.description:
                columnas = [c[0] for c in cursor.description]
                filas = cursor.fetchall()
                if "Resultado" in columnas:
                    resultado = filas[0][0]
                elif filas:
                    datos_usuario = dict(zip(columnas, filas[0]))
            if not cursor.nextset():
                break

        conexion.commit()
        cursor.close()
        conexion.close()

        # Login exitoso
        if resultado == 0 and datos_usuario is not None:
            session["id_usuario"] = datos_usuario["IdUsuario"]
            session["usuario"] = datos_usuario["User"]
            session["es_administrador"] = datos_usuario["EsAdministrador"]

            return redirect(url_for("inicio"))

        # Login fallido
        return render_template(
            "login.html", 
            error="Usuario o contraseña incorrectos"
        )

    return render_template("login.html")

@app.route("/inicio")
def inicio():
    if "id_usuario" not in session:
        return redirect(url_for("login"))

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        """
        EXEC dbo.sp_ObtenerCuentasUsuario
            @IdUsuario=?;
        """,
        session["id_usuario"]
    )

    columnas = [c[0] for c in cursor.description]
    filas = cursor.fetchall()

    cuentas = []

    for fila in filas:
        cuentas.append(dict(zip(columnas, fila)))

    cursor.close()
    conexion.close()

    return render_template(
        "inicio.html",
        usuario=session["usuario"],
        cuentas=cuentas
    )

@app.route("/cuenta/<int:id_cuenta>/beneficiarios")
def beneficiarios(id_cuenta):

    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
        ):
        return "No tiene permiso para acceder a esta cuenta", 403

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    # Obtener beneficiarios
    cursor.execute(
        """
        EXEC dbo.sp_ObtenerBeneficiarios
            @IdCuenta=?;
        """,
        id_cuenta
    )

    columnas = [c[0] for c in cursor.description]
    filas = cursor.fetchall()

    lista_beneficiarios = []

    for fila in filas:
        lista_beneficiarios.append(dict(zip(columnas, fila)))

    # Verificar porcentaje total
    cursor.execute(
        """
        EXEC dbo.sp_VerificarPorcentajeBeneficiarios
            @IdCuenta=?;
        """,
        id_cuenta
    )

    porcentaje = cursor.fetchone()

    total_porcentaje = porcentaje.TotalPorcentaje
    porcentaje_correcto = porcentaje.PorcentajeCorrecto

    cursor.close()
    conexion.close()

    return render_template(
        "beneficiarios.html",
        beneficiarios=lista_beneficiarios,
        id_cuenta=id_cuenta,
        total_porcentaje=total_porcentaje,
        porcentaje_correcto=porcentaje_correcto
    )

@app.route("/cuenta/<int:id_cuenta>/beneficiarios/nuevo", methods=["GET", "POST"])
def nuevo_beneficiario(id_cuenta):

    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
        ):
        return "No tiene permiso para acceder a esta cuenta", 403

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    if request.method == "POST":

        id_tipo_documento = request.form["id_tipo_documento"]
        documento = request.form["documento"].strip()
        nombre = request.form["nombre"].strip()
        fecha_nacimiento = request.form["fecha_nacimiento"]
        email = request.form["email"].strip()
        telefono1 = request.form["telefono1"].strip()
        telefono2 = request.form["telefono2"].strip()
        id_parentezco = request.form["id_parentezco"]
        porcentaje = request.form["porcentaje"]

        cursor.execute(
            """
            DECLARE @Resultado INT;

            EXEC @Resultado = dbo.sp_InsertarBeneficiario
                @IdUsuario=?,
                @IdCuenta=?,
                @IdTipoDocuIdentidad=?,
                @ValorDocumentoIdentidad=?,
                @Nombre=?,
                @FechaNacimiento=?,
                @Email=?,
                @Telefono1=?,
                @Telefono2=?,
                @IdParentezco=?,
                @Porcentaje=?;

            SELECT @Resultado AS Resultado;
            """,
            session["id_usuario"],
            id_cuenta,
            id_tipo_documento,
            documento,
            nombre,
            fecha_nacimiento,
            email,
            telefono1,
            telefono2,
            id_parentezco,
            porcentaje
        )

        resultado = None

        while True:
            if cursor.description:
                columnas = [c[0] for c in cursor.description]
                filas = cursor.fetchall()

                if "Resultado" in columnas and filas:
                    resultado = filas[0][0]

            if not cursor.nextset():
                break

        conexion.commit()

        if resultado == 0:
            cursor.close()
            conexion.close()

            return redirect(
                url_for("beneficiarios", id_cuenta=id_cuenta)
            )

        if resultado == 1:
            error = "La cuenta ya tiene 3 beneficiarios activos."

        elif resultado == 2:
            error = "El porcentaje debe estar entre 0 y 100."

        else:
            error = "Ocurrió un error al agregar el beneficiario."

    else:
        error = None

    # Obtener parentescos
    cursor.execute("EXEC dbo.sp_ObtenerParentescos;")

    columnas = [c[0] for c in cursor.description]
    parentescos = [
        dict(zip(columnas, fila))
        for fila in cursor.fetchall()
    ]

    # Obtener tipos de documento
    cursor.execute("EXEC dbo.sp_ObtenerTiposDocumento;")

    columnas = [c[0] for c in cursor.description]
    tipos_documento = [
        dict(zip(columnas, fila))
        for fila in cursor.fetchall()
    ]

    cursor.close()
    conexion.close()

    return render_template(
        "nuevo_beneficiario.html",
        id_cuenta=id_cuenta,
        parentescos=parentescos,
        tipos_documento=tipos_documento,
        error=error
    )

@app.route(
    "/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/editar",
    methods=["GET", "POST"]
)
def editar_beneficiario(id_cuenta, id_beneficiario):

    # Verificar sesión
    if "id_usuario" not in session:
        return redirect(url_for("login"))

    # Verificar que el usuario pueda ver esa cuenta
    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
    ):
        return "No tiene permiso para acceder a esta cuenta", 403

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    # Obtener beneficiario y confirmar que pertenece a esa cuenta
    cursor.execute(
        """
        EXEC dbo.sp_ObtenerBeneficiarioPorId
            @IdBeneficiario=?,
            @IdCuenta=?;
        """,
        id_beneficiario,
        id_cuenta
    )

    fila = cursor.fetchone()

    if fila is None:
        cursor.close()
        conexion.close()

        return "Beneficiario no encontrado", 404

    columnas = [c[0] for c in cursor.description]
    beneficiario = dict(zip(columnas, fila))

    error = None

    # ==========================
    # ACTUALIZAR
    # ==========================

    if request.method == "POST":

        nombre = request.form["nombre"].strip()
        documento = request.form["documento"].strip()
        fecha_nacimiento = request.form["fecha_nacimiento"]
        email = request.form["email"].strip()
        telefono1 = request.form["telefono1"].strip()
        telefono2 = request.form["telefono2"].strip()
        id_parentezco = request.form["id_parentezco"]
        porcentaje = request.form["porcentaje"]

        cursor.execute(
            """
            DECLARE @Resultado INT;

            EXEC @Resultado = dbo.sp_ActualizarBeneficiario
                @IdUsuario=?,
                @IdBeneficiario=?,
                @Nombre=?,
                @ValorDocumentoIdentidad=?,
                @FechaNacimiento=?,
                @Email=?,
                @Telefono1=?,
                @Telefono2=?,
                @IdParentezco=?,
                @Porcentaje=?;

            SELECT @Resultado AS Resultado;
            """,
            session["id_usuario"],
            id_beneficiario,
            nombre,
            documento,
            fecha_nacimiento,
            email,
            telefono1,
            telefono2,
            id_parentezco,
            porcentaje
        )

        resultado = None

        while True:
            if cursor.description:

                columnas_resultado = [
                    c[0] for c in cursor.description
                ]

                filas = cursor.fetchall()

                if "Resultado" in columnas_resultado and filas:
                    resultado = filas[0][0]

            if not cursor.nextset():
                break

        conexion.commit()

        if resultado == 0:

            cursor.close()
            conexion.close()

            return redirect(
                url_for(
                    "beneficiarios",
                    id_cuenta=id_cuenta
                )
            )

        elif resultado == 1:
            error = "El beneficiario no existe o está inactivo."

        elif resultado == 2:
            error = "El porcentaje debe estar entre 0 y 100."

        else:
            error = "Ocurrió un error al actualizar el beneficiario."

    # ==========================
    # CARGAR PARENTESCOS
    # ==========================

    cursor.execute("EXEC dbo.sp_ObtenerParentescos;")

    columnas = [c[0] for c in cursor.description]

    parentescos = [
        dict(zip(columnas, fila))
        for fila in cursor.fetchall()
    ]

    cursor.close()
    conexion.close()

    return render_template(
        "editar_beneficiario.html",
        beneficiario=beneficiario,
        parentescos=parentescos,
        id_cuenta=id_cuenta,
        error=error
    )

@app.route(
    "/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/eliminar",
    methods=["POST"]
)
def eliminar_beneficiario(id_cuenta, id_beneficiario):

    # Verificar sesión
    if "id_usuario" not in session:
        return redirect(url_for("login"))

    # Verificar que el usuario tenga acceso a la cuenta
    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
    ):
        return "No tiene permiso para acceder a esta cuenta", 403

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    # Verificar que el beneficiario realmente pertenezca a esa cuenta
    cursor.execute(
        """
        EXEC dbo.sp_ObtenerBeneficiarioPorId
            @IdBeneficiario=?,
            @IdCuenta=?;
        """,
        id_beneficiario,
        id_cuenta
    )

    beneficiario = cursor.fetchone()

    if beneficiario is None:
        cursor.close()
        conexion.close()
        return "Beneficiario no encontrado", 404

    # Eliminar beneficiario
    cursor.execute(
        """
        DECLARE @Resultado INT;

        EXEC @Resultado = dbo.sp_EliminarBeneficiario
            @IdUsuario=?,
            @IdBeneficiario=?;

        SELECT @Resultado AS Resultado;
        """,
        session["id_usuario"],
        id_beneficiario
    )

    resultado = None

    while True:
        if cursor.description:
            columnas = [c[0] for c in cursor.description]
            filas = cursor.fetchall()

            if "Resultado" in columnas and filas:
                resultado = filas[0][0]

        if not cursor.nextset():
            break

    conexion.commit()

    cursor.close()
    conexion.close()

    if resultado == 0:
        return redirect(
            url_for(
                "beneficiarios",
                id_cuenta=id_cuenta
            )
        )

    if resultado == 1:
        return "El beneficiario no existe o ya está inactivo", 404

    return "Ocurrió un error al eliminar el beneficiario", 500

@app.route(
    "/cuenta/<int:id_cuenta>/beneficiarios/<int:id_beneficiario>/porcentaje",
    methods=["POST"]
)
def actualizar_porcentaje_beneficiario(id_cuenta, id_beneficiario):

    if "id_usuario" not in session:
        return redirect(url_for("login"))

    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
    ):
        return "No tiene permiso para acceder a esta cuenta", 403

    porcentaje = request.form["porcentaje"]

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    # Comprobar que pertenece a esta cuenta
    cursor.execute(
        """
        EXEC dbo.sp_ObtenerBeneficiarioPorId
            @IdBeneficiario=?,
            @IdCuenta=?;
        """,
        id_beneficiario,
        id_cuenta
    )

    if cursor.fetchone() is None:
        cursor.close()
        conexion.close()
        return "Beneficiario no encontrado", 404

    cursor.execute(
        """
        DECLARE @Resultado INT;

        EXEC @Resultado = dbo.sp_ActualizarPorcentajeBeneficiario
            @IdUsuario=?,
            @IdBeneficiario=?,
            @Porcentaje=?;

        SELECT @Resultado AS Resultado;
        """,
        session["id_usuario"],
        id_beneficiario,
        porcentaje
    )

    resultado = None

    while True:
        if cursor.description:
            columnas = [c[0] for c in cursor.description]
            filas = cursor.fetchall()

            if "Resultado" in columnas and filas:
                resultado = filas[0][0]

        if not cursor.nextset():
            break

    conexion.commit()
    cursor.close()
    conexion.close()

    if resultado == 0:
        return redirect(
            url_for("beneficiarios", id_cuenta=id_cuenta)
        )

    if resultado == 1:
        return "El beneficiario no existe o está inactivo", 404

    if resultado == 2:
        return "El porcentaje debe estar entre 0 y 100", 400

    return "Ocurrió un error al actualizar el porcentaje", 500

@app.route("/cuenta/<int:id_cuenta>/estados")
def estados_cuenta(id_cuenta):

    if "id_usuario" not in session:
        return redirect(url_for("login"))

    if not usuario_puede_ver_cuenta(
        session["id_usuario"],
        id_cuenta
    ):
        return "No tiene permiso para acceder a esta cuenta", 403

    conexion = obtener_conexion()
    cursor = conexion.cursor()

    cursor.execute(
        """
        EXEC dbo.sp_ObtenerEstadosCuenta
            @IdUsuario=?,
            @IdCuenta=?;
        """,
        session["id_usuario"],
        id_cuenta
    )

    columnas = [c[0] for c in cursor.description]
    filas = cursor.fetchall()

    estados = []

    for fila in filas:
        estados.append(dict(zip(columnas, fila)))

    conexion.commit()

    cursor.close()
    conexion.close()

    return render_template(
        "estados_cuenta.html",
        estados=estados,
        id_cuenta=id_cuenta
    )

@app.route("/logout")
def logout():

    if "id_usuario" in session:

        conexion = obtener_conexion()
        cursor = conexion.cursor()

        cursor.execute(
            """
            EXEC dbo.sp_LogoutUsuario
                @IdUsuario=?;
            """,
            session["id_usuario"]
        )

        conexion.commit()

        cursor.close()
        conexion.close()

    session.clear()

    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)