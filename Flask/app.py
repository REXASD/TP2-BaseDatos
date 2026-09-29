from flask import Flask, render_template, request
import pyodbc

app = Flask(__name__)

# Configuración de credenciales de Azure SQL Database
DB_USER = "Maicol"
DB_PASSWORD = "Maic#2026!Maic"

def obtener_conexion():
    cadena_conexion = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=tcp:tp2-basedatos.database.windows.net;"
        "DATABASE=TP2-BaseDatos;"
        f"UID={DB_USER};"
        f"PWD={DB_PASSWORD};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )
    return pyodbc.connect(cadena_conexion)


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
            return render_template(
                "login.html", 
                mensaje=f"¡Bienvenido {datos_usuario['User']}! Inicio de sesión correcto."
            )

        # Login fallido
        return render_template(
            "login.html", 
            error="Usuario o contraseña incorrectos"
        )

    return render_template("login.html")


if __name__ == "__main__":
    app.run(debug=True)