DECLARE @xmlData XML = N'<DatosPrueba>

	<Tipo_Doc>
		<TipoDocuIdentidad Id="1" Nombre="Cedula Nacional"/>
		<TipoDocuIdentidad Id="2" Nombre="Cedula Residente"/>
		<TipoDocuIdentidad Id="3" Nombre="Pasaporte"/>
		<TipoDocuIdentidad Id="4" Nombre="Cedula Juridica"/>
		<TipoDocuIdentidad Id="5" Nombre="Permiso de Trabajo"/>
		<TipoDocuIdentidad Id="6" Nombre="Cedula Extranjera"/>
	</Tipo_Doc>

	<Tipo_Moneda>
		<TipoMoneda Id="1" Nombre="Colones" Simbolo="₡"/>
		<TipoMoneda Id="2" Nombre="Dolares" Simbolo="$"/>
		<TipoMoneda Id="3" Nombre="Euros" Simbolo="€"/>
	</Tipo_Moneda>

	<Parentezcos>
		<Parentezco Id="1" Nombre="Padre"/>
		<Parentezco Id="2" Nombre="Madre"/>
		<Parentezco Id="3" Nombre="Hijo"/>
		<Parentezco Id="4" Nombre="Hija"/>
		<Parentezco Id="5" Nombre="Hermano"/>
		<Parentezco Id="6" Nombre="Hermana"/>
		<Parentezco Id="7" Nombre="amigo"/>
		<Parentezco Id="8" Nombre="amiga"/>
	</Parentezcos>

	<Tipo_Cuenta_Ahorros>
		<TipoCuentaAhorro
			Id="1"
			Nombre="Proletario"
			IdTipoMoneda="1"
			SaldoMinimo="25000.00"
			MultaSaldoMin="3000.00"
			CargoAnual="5000"
			NumRetirosHumano="5"
			NumRetirosAutomatico="8"
			comisionHumano="300"
			comisionAutomatico="300"
			interes="10"/>
		<TipoCuentaAhorro
			Id="2"
			Nombre="Profesional"
			IdTipoMoneda="1"
			SaldoMinimo="50000.00"
			MultaSaldoMin="3000.00"
			CargoAnual="15000"
			NumRetirosHumano="5"
			NumRetirosAutomatico="8"
			comisionHumano="500"
			comisionAutomatico="500"
			interes="15"/>
		<TipoCuentaAhorro
			Id="3"
			Nombre="Exclusivo"
			IdTipoMoneda="1"
			SaldoMinimo="100000.00"
			MultaSaldoMin="3000.00"
			CargoAnual="30000"
			NumRetirosHumano="5"
			NumRetirosAutomatico="8"
			comisionHumano="1000"
			comisionAutomatico="1000"
			interes="20"/>
	</Tipo_Cuenta_Ahorros>

	<TipoOperaciones>
		<TipoOperacion id="1" nombre="Login"/>
		<TipoOperacion id="2" nombre="Logout"/>
		<TipoOperacion id="3" nombre="Agregar beneficiario"/>
		<TipoOperacion id="4" nombre="Actualizar beneficiario"/>
		<TipoOperacion id="5" nombre="Eliminar beneficiario"/>
		<TipoOperacion id="6" nombre="Actualizar porcentaje de beneficiario"/>
		<TipoOperacion id="7" nombre="Consultar estado de cuenta"/>
	</TipoOperaciones>

	<Personas>
		<Persona TipoDocuIdentidad="1" Nombre="Javith Aguero Hernandez" ValorDocumentoIdentidad="117370445" FechaNacimiento="1999-03-20" Email="aguerojavith@gmail.com" telefono1="85343403" telefono2="24197636"/>
		<Persona TipoDocuIdentidad="1" Nombre="Maria Fernanda Rojas Solano" ValorDocumentoIdentidad="205680123" FechaNacimiento="1988-07-14" Email="mfrojas@gmail.com" telefono1="88451236" telefono2="22451236"/>
		<Persona TipoDocuIdentidad="1" Nombre="Carlos Andres Vindas Mora" ValorDocumentoIdentidad="304521987" FechaNacimiento="1975-01-30" Email="cavindas@hotmail.com" telefono1="87001122" telefono2="22334455"/>
		<Persona TipoDocuIdentidad="1" Nombre="Ana Lucia Chacon Vargas" ValorDocumentoIdentidad="401239876" FechaNacimiento="1995-05-11" Email="analucia.chacon@gmail.com" telefono1="89112233" telefono2="24551122"/>
		<Persona TipoDocuIdentidad="1" Nombre="Luis Diego Monge Alvarado" ValorDocumentoIdentidad="502398761" FechaNacimiento="1990-09-25" Email="luisdiego.monge@yahoo.com" telefono1="86223344" telefono2="22778899"/>
		<Persona TipoDocuIdentidad="1" Nombre="Sofia Jimenez Castro" ValorDocumentoIdentidad="603214578" FechaNacimiento="2000-12-02" Email="sofia.jimenez@gmail.com" telefono1="84556677" telefono2="22990011"/>
		<Persona TipoDocuIdentidad="1" Nombre="Jose Pablo Gomez Fallas" ValorDocumentoIdentidad="704512369" FechaNacimiento="1982-04-18" Email="jp.gomez@gmail.com" telefono1="83667788" telefono2="22112233"/>
		<Persona TipoDocuIdentidad="1" Nombre="Karla Vanessa Solis Umana" ValorDocumentoIdentidad="805632147" FechaNacimiento="1993-08-09" Email="karla.solis@hotmail.com" telefono1="88778899" telefono2="24003300"/>
		<Persona TipoDocuIdentidad="1" Nombre="Roberto Carlos Araya Leiva" ValorDocumentoIdentidad="906741852" FechaNacimiento="1978-11-27" Email="rcarlos.araya@gmail.com" telefono1="87889900" telefono2="22445566"/>
		<Persona TipoDocuIdentidad="1" Nombre="Daniela Patricia Mendez Rojas" ValorDocumentoIdentidad="107852963" FechaNacimiento="1997-02-14" Email="daniela.mendez@gmail.com" telefono1="85990011" telefono2="24667788"/>
		<Persona TipoDocuIdentidad="1" Nombre="Fernando Jose Ramirez Quesada" ValorDocumentoIdentidad="208963741" FechaNacimiento="1985-06-30" Email="fernando.ramirez@gmail.com" telefono1="86001122" telefono2="22889900"/>
		<Persona TipoDocuIdentidad="1" Nombre="Gabriela Isabel Salas Cordero" ValorDocumentoIdentidad="309874652" FechaNacimiento="1992-10-05" Email="gabriela.salas@gmail.com" telefono1="89223344" telefono2="24112233"/>
		<Persona TipoDocuIdentidad="1" Nombre="Manuel Antonio Herrera Zuniga" ValorDocumentoIdentidad="410985763" FechaNacimiento="1970-03-22" Email="manuel.herrera@gmail.com" telefono1="87334455" telefono2="22556677"/>
		<Persona TipoDocuIdentidad="1" Nombre="Paola Andrea Villalobos Nunez" ValorDocumentoIdentidad="512096874" FechaNacimiento="1998-07-19" Email="paola.villalobos@gmail.com" telefono1="88445566" telefono2="24778899"/>
		<Persona TipoDocuIdentidad="1" Nombre="Diego Alonso Barrantes Cruz" ValorDocumentoIdentidad="613107985" FechaNacimiento="1991-01-08" Email="diego.barrantes@gmail.com" telefono1="84556677" telefono2="22001122"/>
		<Persona TipoDocuIdentidad="1" Nombre="Natalia Ines Vega Carmona" ValorDocumentoIdentidad="714218096" FechaNacimiento="1987-09-16" Email="natalia.vega@gmail.com" telefono1="85667788" telefono2="24334455"/>
		<Persona TipoDocuIdentidad="1" Nombre="Esteban Josue Rodriguez Acuna" ValorDocumentoIdentidad="815329107" FechaNacimiento="1994-12-24" Email="esteban.rodriguez@gmail.com" telefono1="86778899" telefono2="22667788"/>
		<Persona TipoDocuIdentidad="1" Nombre="Camila Fiorella Segura Brenes" ValorDocumentoIdentidad="916430218" FechaNacimiento="1996-04-03" Email="camila.segura@gmail.com" telefono1="87889011" telefono2="24990011"/>
		<Persona TipoDocuIdentidad="2" Nombre="Andres Felipe Chinchilla Soto" ValorDocumentoIdentidad="117541329" FechaNacimiento="1980-08-28" Email="andres.chinchilla@gmail.com" telefono1="88990122" telefono2="22112244"/>
		<Persona TipoDocuIdentidad="1" Nombre="Melissa Yendry Alfaro Duran" ValorDocumentoIdentidad="218652430" FechaNacimiento="1999-11-11" Email="melissa.alfaro@gmail.com" telefono1="89001233" telefono2="24223355"/>
		<Persona TipoDocuIdentidad="1" Nombre="Kevin Josue Marin Obando" ValorDocumentoIdentidad="319763541" FechaNacimiento="1993-05-06" Email="kevin.marin@gmail.com" telefono1="84112344" telefono2="22334466"/>
		<Persona TipoDocuIdentidad="1" Nombre="Wendy Priscilla Quesada Elizondo" ValorDocumentoIdentidad="420874652" FechaNacimiento="1989-02-17" Email="wendy.quesada@gmail.com" telefono1="85223455" telefono2="24445577"/>
		<Persona TipoDocuIdentidad="3" Nombre="Alvaro Enrique Cascante Rios" ValorDocumentoIdentidad="521985763" FechaNacimiento="1976-10-21" Email="alvaro.cascante@gmail.com" telefono1="86334566" telefono2="22556688"/>
		<Persona TipoDocuIdentidad="1" Nombre="Tatiana Marcela Porras Guzman" ValorDocumentoIdentidad="622096874" FechaNacimiento="1990-03-15" Email="tatiana.porras@gmail.com" telefono1="87445677" telefono2="24667799"/>
	</Personas>

	<Cuentas>
		<Cuenta ValorDocumentoIdentidadDelCliente="117370445" TipoCuentaId="1" NumeroCuenta="11000001" FechaCreacion="2020-10-13" Saldo="1205600.00"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="205680123" TipoCuentaId="2" NumeroCuenta="11000002" FechaCreacion="2021-03-05" Saldo="599200.00"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="304521987" TipoCuentaId="3" NumeroCuenta="11000003" FechaCreacion="2019-07-20" Saldo="3387500.00"/>
	</Cuentas>

	<Beneficiarios>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="401239876" ParentezcoId="4" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="502398761" ParentezcoId="3" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="603214578" ParentezcoId="6" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000002" ValorDocumentoIdentidadBeneficiario="704512369" ParentezcoId="1" Porcentaje="50"/>
		<Beneficiario NumeroCuenta="11000002" ValorDocumentoIdentidadBeneficiario="805632147" ParentezcoId="2" Porcentaje="50"/>
		<Beneficiario NumeroCuenta="11000003" ValorDocumentoIdentidadBeneficiario="117370445" ParentezcoId="7" Porcentaje="100"/>
	</Beneficiarios>

	<Estados_de_Cuenta>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2020-10-13" fechafin="2020-11-12" saldoinicial="1000000.00" saldo_final="1025000.00" interesesAcumulados="4200.00" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2020-11-13" fechafin="2020-12-12" saldoinicial="1025000.00" saldo_final="1052300.00" interesesAcumulados="4300.00" cantidadDepositos="2" cantidadRetiros="3"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2020-12-13" fechafin="2021-01-12" saldoinicial="1052300.00" saldo_final="1078900.00" interesesAcumulados="4400.00" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2021-01-13" fechafin="2021-02-12" saldoinicial="1078900.00" saldo_final="1102450.00" interesesAcumulados="4500.00" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2021-02-13" fechafin="2021-03-12" saldoinicial="1102450.00" saldo_final="1130200.00" interesesAcumulados="4600.00" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2021-03-13" fechafin="2021-04-12" saldoinicial="1130200.00" saldo_final="1155700.00" interesesAcumulados="4700.00" cantidadDepositos="2" cantidadRetiros="3"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2021-04-13" fechafin="2021-05-12" saldoinicial="1155700.00" saldo_final="1180900.00" interesesAcumulados="4800.00" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2021-05-13" fechafin="2021-06-12" saldoinicial="1180900.00" saldo_final="1205600.00" interesesAcumulados="4900.00" cantidadDepositos="2" cantidadRetiros="2"/>

		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-03-05" fechafin="2021-04-04" saldoinicial="500000.00" saldo_final="512300.00" interesesAcumulados="2200.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-04-05" fechafin="2021-05-04" saldoinicial="512300.00" saldo_final="524800.00" interesesAcumulados="2250.00" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-05-05" fechafin="2021-06-04" saldoinicial="524800.00" saldo_final="537500.00" interesesAcumulados="2300.00" cantidadDepositos="1" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-06-05" fechafin="2021-07-04" saldoinicial="537500.00" saldo_final="549200.00" interesesAcumulados="2350.00" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-07-05" fechafin="2021-08-04" saldoinicial="549200.00" saldo_final="561900.00" interesesAcumulados="2400.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-08-05" fechafin="2021-09-04" saldoinicial="561900.00" saldo_final="574300.00" interesesAcumulados="2450.00" cantidadDepositos="1" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-09-05" fechafin="2021-10-04" saldoinicial="574300.00" saldo_final="586700.00" interesesAcumulados="2500.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2021-10-05" fechafin="2021-11-04" saldoinicial="586700.00" saldo_final="599200.00" interesesAcumulados="2550.00" cantidadDepositos="2" cantidadRetiros="2"/>

		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-07-20" fechafin="2019-08-19" saldoinicial="3000000.00" saldo_final="3045000.00" interesesAcumulados="12500.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-08-20" fechafin="2019-09-19" saldoinicial="3045000.00" saldo_final="3091200.00" interesesAcumulados="12700.00" cantidadDepositos="1" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-09-20" fechafin="2019-10-19" saldoinicial="3091200.00" saldo_final="3138700.00" interesesAcumulados="12900.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-10-20" fechafin="2019-11-19" saldoinicial="3138700.00" saldo_final="3186900.00" interesesAcumulados="13100.00" cantidadDepositos="1" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-11-20" fechafin="2019-12-19" saldoinicial="3186900.00" saldo_final="3235800.00" interesesAcumulados="13300.00" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2019-12-20" fechafin="2020-01-19" saldoinicial="3235800.00" saldo_final="3285600.00" interesesAcumulados="13500.00" cantidadDepositos="1" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2020-01-20" fechafin="2020-02-19" saldoinicial="3285600.00" saldo_final="3336200.00" interesesAcumulados="13700.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2020-02-20" fechafin="2020-03-19" saldoinicial="3336200.00" saldo_final="3387500.00" interesesAcumulados="13900.00" cantidadDepositos="1" cantidadRetiros="2"/>
	</Estados_de_Cuenta>

	<Usuarios>
		<Usuario User="jaguero" Pass="LaFacil" EsAdministrador="0"/>
		<Usuario User="mfrojas" Pass="Rojas2024*" EsAdministrador="0"/>
		<Usuario User="cavindas" Pass="Vindas2024*" EsAdministrador="0"/>
		<Usuario User="fquiros" Pass="MyPass123*" EsAdministrador="1"/>
	</Usuarios>

	<Usuarios_Ver>
		<UsuarioPuedeVer User="jaguero" NumeroCuenta="11000001"/>
		<UsuarioPuedeVer User="mfrojas" NumeroCuenta="11000002"/>
		<UsuarioPuedeVer User="cavindas" NumeroCuenta="11000003"/>
	</Usuarios_Ver>

</DatosPrueba>';

EXEC dbo.sp_CargarDatosPrueba @xmlData = @xmlData;