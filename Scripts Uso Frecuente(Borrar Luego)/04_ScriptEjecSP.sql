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
		<Cuenta ValorDocumentoIdentidadDelCliente="117370445" TipoCuentaId="1" NumeroCuenta="11000001" FechaCreacion="2018-01-10" Saldo="338135.51"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="205680123" TipoCuentaId="2" NumeroCuenta="11000002" FechaCreacion="2018-02-26" Saldo="377570.89"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="304521987" TipoCuentaId="3" NumeroCuenta="11000003" FechaCreacion="2018-04-14" Saldo="417006.26"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="401239876" TipoCuentaId="1" NumeroCuenta="11000004" FechaCreacion="2018-05-31" Saldo="456441.64"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="502398761" TipoCuentaId="2" NumeroCuenta="11000005" FechaCreacion="2018-07-17" Saldo="495877.02"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="603214578" TipoCuentaId="3" NumeroCuenta="11000006" FechaCreacion="2018-09-02" Saldo="535312.39"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="704512369" TipoCuentaId="1" NumeroCuenta="11000007" FechaCreacion="2018-10-19" Saldo="574747.77"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="805632147" TipoCuentaId="2" NumeroCuenta="11000008" FechaCreacion="2018-12-05" Saldo="614183.15"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="906741852" TipoCuentaId="3" NumeroCuenta="11000009" FechaCreacion="2019-01-21" Saldo="653618.51"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="107852963" TipoCuentaId="1" NumeroCuenta="11000010" FechaCreacion="2019-03-09" Saldo="693053.89"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="208963741" TipoCuentaId="2" NumeroCuenta="11000011" FechaCreacion="2019-04-25" Saldo="732489.26"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="309874652" TipoCuentaId="3" NumeroCuenta="11000012" FechaCreacion="2019-06-11" Saldo="771924.64"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="410985763" TipoCuentaId="1" NumeroCuenta="11000013" FechaCreacion="2019-07-28" Saldo="811360.02"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="512096874" TipoCuentaId="2" NumeroCuenta="11000014" FechaCreacion="2019-09-13" Saldo="850795.38"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="613107985" TipoCuentaId="3" NumeroCuenta="11000015" FechaCreacion="2019-10-30" Saldo="890230.77"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="714218096" TipoCuentaId="1" NumeroCuenta="11000016" FechaCreacion="2019-12-16" Saldo="929666.15"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="815329107" TipoCuentaId="2" NumeroCuenta="11000017" FechaCreacion="2020-02-01" Saldo="969101.52"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="916430218" TipoCuentaId="3" NumeroCuenta="11000018" FechaCreacion="2020-03-19" Saldo="1008536.90"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="117541329" TipoCuentaId="1" NumeroCuenta="11000019" FechaCreacion="2020-05-05" Saldo="1047972.27"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="218652430" TipoCuentaId="2" NumeroCuenta="11000020" FechaCreacion="2020-06-21" Saldo="1087407.66"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="319763541" TipoCuentaId="3" NumeroCuenta="11000021" FechaCreacion="2020-08-07" Saldo="1126843.02"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="420874652" TipoCuentaId="1" NumeroCuenta="11000022" FechaCreacion="2020-09-23" Saldo="1166278.40"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="521985763" TipoCuentaId="2" NumeroCuenta="11000023" FechaCreacion="2020-11-09" Saldo="1205713.77"/>
		<Cuenta ValorDocumentoIdentidadDelCliente="622096874" TipoCuentaId="3" NumeroCuenta="11000024" FechaCreacion="2020-12-26" Saldo="1245149.15"/>
	</Cuentas>

	<Beneficiarios>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="205680123" ParentezcoId="1" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="304521987" ParentezcoId="2" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000001" ValorDocumentoIdentidadBeneficiario="401239876" ParentezcoId="3" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000002" ValorDocumentoIdentidadBeneficiario="304521987" ParentezcoId="2" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000002" ValorDocumentoIdentidadBeneficiario="401239876" ParentezcoId="3" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000003" ValorDocumentoIdentidadBeneficiario="401239876" ParentezcoId="3" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000004" ValorDocumentoIdentidadBeneficiario="502398761" ParentezcoId="4" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000004" ValorDocumentoIdentidadBeneficiario="603214578" ParentezcoId="5" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000004" ValorDocumentoIdentidadBeneficiario="704512369" ParentezcoId="6" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000005" ValorDocumentoIdentidadBeneficiario="603214578" ParentezcoId="5" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000005" ValorDocumentoIdentidadBeneficiario="704512369" ParentezcoId="6" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000006" ValorDocumentoIdentidadBeneficiario="704512369" ParentezcoId="6" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000007" ValorDocumentoIdentidadBeneficiario="805632147" ParentezcoId="7" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000007" ValorDocumentoIdentidadBeneficiario="906741852" ParentezcoId="8" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000007" ValorDocumentoIdentidadBeneficiario="107852963" ParentezcoId="1" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000008" ValorDocumentoIdentidadBeneficiario="906741852" ParentezcoId="8" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000008" ValorDocumentoIdentidadBeneficiario="107852963" ParentezcoId="1" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000009" ValorDocumentoIdentidadBeneficiario="107852963" ParentezcoId="1" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000010" ValorDocumentoIdentidadBeneficiario="208963741" ParentezcoId="2" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000010" ValorDocumentoIdentidadBeneficiario="309874652" ParentezcoId="3" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000010" ValorDocumentoIdentidadBeneficiario="410985763" ParentezcoId="4" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000011" ValorDocumentoIdentidadBeneficiario="309874652" ParentezcoId="3" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000011" ValorDocumentoIdentidadBeneficiario="410985763" ParentezcoId="4" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000012" ValorDocumentoIdentidadBeneficiario="410985763" ParentezcoId="4" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000013" ValorDocumentoIdentidadBeneficiario="512096874" ParentezcoId="5" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000013" ValorDocumentoIdentidadBeneficiario="613107985" ParentezcoId="6" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000013" ValorDocumentoIdentidadBeneficiario="714218096" ParentezcoId="7" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000014" ValorDocumentoIdentidadBeneficiario="613107985" ParentezcoId="6" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000014" ValorDocumentoIdentidadBeneficiario="714218096" ParentezcoId="7" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000015" ValorDocumentoIdentidadBeneficiario="714218096" ParentezcoId="7" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000016" ValorDocumentoIdentidadBeneficiario="815329107" ParentezcoId="8" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000016" ValorDocumentoIdentidadBeneficiario="916430218" ParentezcoId="1" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000016" ValorDocumentoIdentidadBeneficiario="117541329" ParentezcoId="2" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000017" ValorDocumentoIdentidadBeneficiario="916430218" ParentezcoId="1" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000017" ValorDocumentoIdentidadBeneficiario="117541329" ParentezcoId="2" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000018" ValorDocumentoIdentidadBeneficiario="117541329" ParentezcoId="2" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000019" ValorDocumentoIdentidadBeneficiario="218652430" ParentezcoId="3" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000019" ValorDocumentoIdentidadBeneficiario="319763541" ParentezcoId="4" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000019" ValorDocumentoIdentidadBeneficiario="420874652" ParentezcoId="5" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000020" ValorDocumentoIdentidadBeneficiario="319763541" ParentezcoId="4" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000020" ValorDocumentoIdentidadBeneficiario="420874652" ParentezcoId="5" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000021" ValorDocumentoIdentidadBeneficiario="420874652" ParentezcoId="5" Porcentaje="100"/>
		<Beneficiario NumeroCuenta="11000022" ValorDocumentoIdentidadBeneficiario="521985763" ParentezcoId="6" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000022" ValorDocumentoIdentidadBeneficiario="622096874" ParentezcoId="7" Porcentaje="35"/>
		<Beneficiario NumeroCuenta="11000022" ValorDocumentoIdentidadBeneficiario="117370445" ParentezcoId="8" Porcentaje="25"/>
		<Beneficiario NumeroCuenta="11000023" ValorDocumentoIdentidadBeneficiario="622096874" ParentezcoId="7" Porcentaje="60"/>
		<Beneficiario NumeroCuenta="11000023" ValorDocumentoIdentidadBeneficiario="117370445" ParentezcoId="8" Porcentaje="40"/>
		<Beneficiario NumeroCuenta="11000024" ValorDocumentoIdentidadBeneficiario="117370445" ParentezcoId="8" Porcentaje="100"/>
	</Beneficiarios>

	<Estados_de_Cuenta>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-01-10" fechafin="2018-02-08" saldoinicial="300000.00" saldo_final="302400.00" interesesAcumulados="2400.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-02-09" fechafin="2018-03-10" saldoinicial="302400.00" saldo_final="306319.20" interesesAcumulados="2419.20" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-03-11" fechafin="2018-04-09" saldoinicial="306319.20" saldo_final="311769.75" interesesAcumulados="2450.55" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-04-10" fechafin="2018-05-09" saldoinicial="311769.75" saldo_final="318763.91" interesesAcumulados="2494.16" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-05-10" fechafin="2018-06-08" saldoinicial="318763.91" saldo_final="321314.02" interesesAcumulados="2550.11" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-06-09" fechafin="2018-07-08" saldoinicial="321314.02" saldo_final="325384.53" interesesAcumulados="2570.51" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-07-09" fechafin="2018-08-07" saldoinicial="325384.53" saldo_final="330987.61" interesesAcumulados="2603.08" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000001" fechaInicio="2018-08-08" fechafin="2018-09-06" saldoinicial="330987.61" saldo_final="338135.51" interesesAcumulados="2647.90" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-02-26" fechafin="2018-03-27" saldoinicial="337000.00" saldo_final="339696.00" interesesAcumulados="2696.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-03-28" fechafin="2018-04-26" saldoinicial="339696.00" saldo_final="343913.57" interesesAcumulados="2717.57" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-04-27" fechafin="2018-05-26" saldoinicial="343913.57" saldo_final="349664.88" interesesAcumulados="2751.31" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-05-27" fechafin="2018-06-25" saldoinicial="349664.88" saldo_final="356962.20" interesesAcumulados="2797.32" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-06-26" fechafin="2018-07-25" saldoinicial="356962.20" saldo_final="359817.90" interesesAcumulados="2855.70" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-07-26" fechafin="2018-08-24" saldoinicial="359817.90" saldo_final="364196.44" interesesAcumulados="2878.54" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-08-25" fechafin="2018-09-23" saldoinicial="364196.44" saldo_final="370110.01" interesesAcumulados="2913.57" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000002" fechaInicio="2018-09-24" fechafin="2018-10-23" saldoinicial="370110.01" saldo_final="377570.89" interesesAcumulados="2960.88" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-04-14" fechafin="2018-05-13" saldoinicial="374000.00" saldo_final="376992.00" interesesAcumulados="2992.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-05-14" fechafin="2018-06-12" saldoinicial="376992.00" saldo_final="381507.94" interesesAcumulados="3015.94" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-06-13" fechafin="2018-07-12" saldoinicial="381507.94" saldo_final="387560.00" interesesAcumulados="3052.06" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-07-13" fechafin="2018-08-11" saldoinicial="387560.00" saldo_final="395160.48" interesesAcumulados="3100.48" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-08-12" fechafin="2018-09-10" saldoinicial="395160.48" saldo_final="398321.76" interesesAcumulados="3161.28" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-09-11" fechafin="2018-10-10" saldoinicial="398321.76" saldo_final="403008.33" interesesAcumulados="3186.57" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-10-11" fechafin="2018-11-09" saldoinicial="403008.33" saldo_final="409232.40" interesesAcumulados="3224.07" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000003" fechaInicio="2018-11-10" fechafin="2018-12-09" saldoinicial="409232.40" saldo_final="417006.26" interesesAcumulados="3273.86" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-05-31" fechafin="2018-06-29" saldoinicial="411000.00" saldo_final="414288.00" interesesAcumulados="3288.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-06-30" fechafin="2018-07-29" saldoinicial="414288.00" saldo_final="419102.30" interesesAcumulados="3314.30" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-07-30" fechafin="2018-08-28" saldoinicial="419102.30" saldo_final="425455.12" interesesAcumulados="3352.82" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-08-29" fechafin="2018-09-27" saldoinicial="425455.12" saldo_final="433358.76" interesesAcumulados="3403.64" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-09-28" fechafin="2018-10-27" saldoinicial="433358.76" saldo_final="436825.63" interesesAcumulados="3466.87" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-10-28" fechafin="2018-11-26" saldoinicial="436825.63" saldo_final="441820.24" interesesAcumulados="3494.61" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-11-27" fechafin="2018-12-26" saldoinicial="441820.24" saldo_final="448354.80" interesesAcumulados="3534.56" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000004" fechaInicio="2018-12-27" fechafin="2019-01-25" saldoinicial="448354.80" saldo_final="456441.64" interesesAcumulados="3586.84" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-07-17" fechafin="2018-08-15" saldoinicial="448000.00" saldo_final="451584.00" interesesAcumulados="3584.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-08-16" fechafin="2018-09-14" saldoinicial="451584.00" saldo_final="456696.67" interesesAcumulados="3612.67" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-09-15" fechafin="2018-10-14" saldoinicial="456696.67" saldo_final="463350.24" interesesAcumulados="3653.57" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-10-15" fechafin="2018-11-13" saldoinicial="463350.24" saldo_final="471557.04" interesesAcumulados="3706.80" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-11-14" fechafin="2018-12-13" saldoinicial="471557.04" saldo_final="475329.50" interesesAcumulados="3772.46" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2018-12-14" fechafin="2019-01-12" saldoinicial="475329.50" saldo_final="480632.14" interesesAcumulados="3802.64" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2019-01-13" fechafin="2019-02-11" saldoinicial="480632.14" saldo_final="487477.20" interesesAcumulados="3845.06" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000005" fechaInicio="2019-02-12" fechafin="2019-03-13" saldoinicial="487477.20" saldo_final="495877.02" interesesAcumulados="3899.82" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2018-09-02" fechafin="2018-10-01" saldoinicial="485000.00" saldo_final="488880.00" interesesAcumulados="3880.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2018-10-02" fechafin="2018-10-31" saldoinicial="488880.00" saldo_final="494291.04" interesesAcumulados="3911.04" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2018-11-01" fechafin="2018-11-30" saldoinicial="494291.04" saldo_final="501245.37" interesesAcumulados="3954.33" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2018-12-01" fechafin="2018-12-30" saldoinicial="501245.37" saldo_final="509755.33" interesesAcumulados="4009.96" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2018-12-31" fechafin="2019-01-29" saldoinicial="509755.33" saldo_final="513833.37" interesesAcumulados="4078.04" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2019-01-30" fechafin="2019-02-28" saldoinicial="513833.37" saldo_final="519444.04" interesesAcumulados="4110.67" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2019-03-01" fechafin="2019-03-30" saldoinicial="519444.04" saldo_final="526599.59" interesesAcumulados="4155.55" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000006" fechaInicio="2019-03-31" fechafin="2019-04-29" saldoinicial="526599.59" saldo_final="535312.39" interesesAcumulados="4212.80" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2018-10-19" fechafin="2018-11-17" saldoinicial="522000.00" saldo_final="526176.00" interesesAcumulados="4176.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2018-11-18" fechafin="2018-12-17" saldoinicial="526176.00" saldo_final="531885.41" interesesAcumulados="4209.41" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2018-12-18" fechafin="2019-01-16" saldoinicial="531885.41" saldo_final="539140.49" interesesAcumulados="4255.08" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2019-01-17" fechafin="2019-02-15" saldoinicial="539140.49" saldo_final="547953.61" interesesAcumulados="4313.12" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2019-02-16" fechafin="2019-03-17" saldoinicial="547953.61" saldo_final="552337.24" interesesAcumulados="4383.63" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2019-03-18" fechafin="2019-04-16" saldoinicial="552337.24" saldo_final="558255.94" interesesAcumulados="4418.70" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2019-04-17" fechafin="2019-05-16" saldoinicial="558255.94" saldo_final="565721.99" interesesAcumulados="4466.05" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000007" fechaInicio="2019-05-17" fechafin="2019-06-15" saldoinicial="565721.99" saldo_final="574747.77" interesesAcumulados="4525.78" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2018-12-05" fechafin="2019-01-03" saldoinicial="559000.00" saldo_final="563472.00" interesesAcumulados="4472.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-01-04" fechafin="2019-02-02" saldoinicial="563472.00" saldo_final="569479.78" interesesAcumulados="4507.78" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-02-03" fechafin="2019-03-04" saldoinicial="569479.78" saldo_final="577035.62" interesesAcumulados="4555.84" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-03-05" fechafin="2019-04-03" saldoinicial="577035.62" saldo_final="586151.90" interesesAcumulados="4616.28" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-04-04" fechafin="2019-05-03" saldoinicial="586151.90" saldo_final="590841.12" interesesAcumulados="4689.22" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-05-04" fechafin="2019-06-02" saldoinicial="590841.12" saldo_final="597067.85" interesesAcumulados="4726.73" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-06-03" fechafin="2019-07-02" saldoinicial="597067.85" saldo_final="604844.39" interesesAcumulados="4776.54" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000008" fechaInicio="2019-07-03" fechafin="2019-08-01" saldoinicial="604844.39" saldo_final="614183.15" interesesAcumulados="4838.76" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-01-21" fechafin="2019-02-19" saldoinicial="596000.00" saldo_final="600768.00" interesesAcumulados="4768.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-02-20" fechafin="2019-03-21" saldoinicial="600768.00" saldo_final="607074.14" interesesAcumulados="4806.14" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-03-22" fechafin="2019-04-20" saldoinicial="607074.14" saldo_final="614930.73" interesesAcumulados="4856.59" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-04-21" fechafin="2019-05-20" saldoinicial="614930.73" saldo_final="624350.18" interesesAcumulados="4919.45" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-05-21" fechafin="2019-06-19" saldoinicial="624350.18" saldo_final="629344.98" interesesAcumulados="4994.80" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-06-20" fechafin="2019-07-19" saldoinicial="629344.98" saldo_final="635879.74" interesesAcumulados="5034.76" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-07-20" fechafin="2019-08-18" saldoinicial="635879.74" saldo_final="643966.78" interesesAcumulados="5087.04" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000009" fechaInicio="2019-08-19" fechafin="2019-09-17" saldoinicial="643966.78" saldo_final="653618.51" interesesAcumulados="5151.73" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-03-09" fechafin="2019-04-07" saldoinicial="633000.00" saldo_final="638064.00" interesesAcumulados="5064.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-04-08" fechafin="2019-05-07" saldoinicial="638064.00" saldo_final="644668.51" interesesAcumulados="5104.51" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-05-08" fechafin="2019-06-06" saldoinicial="644668.51" saldo_final="652825.86" interesesAcumulados="5157.35" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-06-07" fechafin="2019-07-06" saldoinicial="652825.86" saldo_final="662548.47" interesesAcumulados="5222.61" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-07-07" fechafin="2019-08-05" saldoinicial="662548.47" saldo_final="667848.86" interesesAcumulados="5300.39" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-08-06" fechafin="2019-09-04" saldoinicial="667848.86" saldo_final="674691.65" interesesAcumulados="5342.79" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-09-05" fechafin="2019-10-04" saldoinicial="674691.65" saldo_final="683089.18" interesesAcumulados="5397.53" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000010" fechaInicio="2019-10-05" fechafin="2019-11-03" saldoinicial="683089.18" saldo_final="693053.89" interesesAcumulados="5464.71" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-04-25" fechafin="2019-05-24" saldoinicial="670000.00" saldo_final="675360.00" interesesAcumulados="5360.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-05-25" fechafin="2019-06-23" saldoinicial="675360.00" saldo_final="682262.88" interesesAcumulados="5402.88" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-06-24" fechafin="2019-07-23" saldoinicial="682262.88" saldo_final="690720.98" interesesAcumulados="5458.10" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-07-24" fechafin="2019-08-22" saldoinicial="690720.98" saldo_final="700746.75" interesesAcumulados="5525.77" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-08-23" fechafin="2019-09-21" saldoinicial="700746.75" saldo_final="706352.72" interesesAcumulados="5605.97" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-09-22" fechafin="2019-10-21" saldoinicial="706352.72" saldo_final="713503.54" interesesAcumulados="5650.82" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-10-22" fechafin="2019-11-20" saldoinicial="713503.54" saldo_final="722211.57" interesesAcumulados="5708.03" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000011" fechaInicio="2019-11-21" fechafin="2019-12-20" saldoinicial="722211.57" saldo_final="732489.26" interesesAcumulados="5777.69" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-06-11" fechafin="2019-07-10" saldoinicial="707000.00" saldo_final="712656.00" interesesAcumulados="5656.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-07-11" fechafin="2019-08-09" saldoinicial="712656.00" saldo_final="719857.25" interesesAcumulados="5701.25" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-08-10" fechafin="2019-09-08" saldoinicial="719857.25" saldo_final="728616.11" interesesAcumulados="5758.86" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-09-09" fechafin="2019-10-08" saldoinicial="728616.11" saldo_final="738945.04" interesesAcumulados="5828.93" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-10-09" fechafin="2019-11-07" saldoinicial="738945.04" saldo_final="744856.60" interesesAcumulados="5911.56" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-11-08" fechafin="2019-12-07" saldoinicial="744856.60" saldo_final="752315.45" interesesAcumulados="5958.85" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2019-12-08" fechafin="2020-01-06" saldoinicial="752315.45" saldo_final="761333.97" interesesAcumulados="6018.52" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000012" fechaInicio="2020-01-07" fechafin="2020-02-05" saldoinicial="761333.97" saldo_final="771924.64" interesesAcumulados="6090.67" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-07-28" fechafin="2019-08-26" saldoinicial="744000.00" saldo_final="749952.00" interesesAcumulados="5952.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-08-27" fechafin="2019-09-25" saldoinicial="749952.00" saldo_final="757451.62" interesesAcumulados="5999.62" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-09-26" fechafin="2019-10-25" saldoinicial="757451.62" saldo_final="766511.23" interesesAcumulados="6059.61" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-10-26" fechafin="2019-11-24" saldoinicial="766511.23" saldo_final="777143.32" interesesAcumulados="6132.09" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-11-25" fechafin="2019-12-24" saldoinicial="777143.32" saldo_final="783360.47" interesesAcumulados="6217.15" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2019-12-25" fechafin="2020-01-23" saldoinicial="783360.47" saldo_final="791127.35" interesesAcumulados="6266.88" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2020-01-24" fechafin="2020-02-22" saldoinicial="791127.35" saldo_final="800456.37" interesesAcumulados="6329.02" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000013" fechaInicio="2020-02-23" fechafin="2020-03-23" saldoinicial="800456.37" saldo_final="811360.02" interesesAcumulados="6403.65" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2019-09-13" fechafin="2019-10-12" saldoinicial="781000.00" saldo_final="787248.00" interesesAcumulados="6248.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2019-10-13" fechafin="2019-11-11" saldoinicial="787248.00" saldo_final="795045.98" interesesAcumulados="6297.98" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2019-11-12" fechafin="2019-12-11" saldoinicial="795045.98" saldo_final="804406.35" interesesAcumulados="6360.37" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2019-12-12" fechafin="2020-01-10" saldoinicial="804406.35" saldo_final="815341.60" interesesAcumulados="6435.25" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2020-01-11" fechafin="2020-02-09" saldoinicial="815341.60" saldo_final="821864.33" interesesAcumulados="6522.73" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2020-02-10" fechafin="2020-03-10" saldoinicial="821864.33" saldo_final="829939.24" interesesAcumulados="6574.91" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2020-03-11" fechafin="2020-04-09" saldoinicial="829939.24" saldo_final="839578.75" interesesAcumulados="6639.51" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000014" fechaInicio="2020-04-10" fechafin="2020-05-09" saldoinicial="839578.75" saldo_final="850795.38" interesesAcumulados="6716.63" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2019-10-30" fechafin="2019-11-28" saldoinicial="818000.00" saldo_final="824544.00" interesesAcumulados="6544.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2019-11-29" fechafin="2019-12-28" saldoinicial="824544.00" saldo_final="832640.35" interesesAcumulados="6596.35" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2019-12-29" fechafin="2020-01-27" saldoinicial="832640.35" saldo_final="842301.47" interesesAcumulados="6661.12" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2020-01-28" fechafin="2020-02-26" saldoinicial="842301.47" saldo_final="853539.88" interesesAcumulados="6738.41" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2020-02-27" fechafin="2020-03-27" saldoinicial="853539.88" saldo_final="860368.20" interesesAcumulados="6828.32" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2020-03-28" fechafin="2020-04-26" saldoinicial="860368.20" saldo_final="868751.15" interesesAcumulados="6882.95" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2020-04-27" fechafin="2020-05-26" saldoinicial="868751.15" saldo_final="878701.16" interesesAcumulados="6950.01" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000015" fechaInicio="2020-05-27" fechafin="2020-06-25" saldoinicial="878701.16" saldo_final="890230.77" interesesAcumulados="7029.61" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2019-12-16" fechafin="2020-01-14" saldoinicial="855000.00" saldo_final="861840.00" interesesAcumulados="6840.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-01-15" fechafin="2020-02-13" saldoinicial="861840.00" saldo_final="870234.72" interesesAcumulados="6894.72" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-02-14" fechafin="2020-03-14" saldoinicial="870234.72" saldo_final="880196.60" interesesAcumulados="6961.88" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-03-15" fechafin="2020-04-13" saldoinicial="880196.60" saldo_final="891738.17" interesesAcumulados="7041.57" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-04-14" fechafin="2020-05-13" saldoinicial="891738.17" saldo_final="898872.08" interesesAcumulados="7133.91" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-05-14" fechafin="2020-06-12" saldoinicial="898872.08" saldo_final="907563.06" interesesAcumulados="7190.98" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-06-13" fechafin="2020-07-12" saldoinicial="907563.06" saldo_final="917823.56" interesesAcumulados="7260.50" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000016" fechaInicio="2020-07-13" fechafin="2020-08-11" saldoinicial="917823.56" saldo_final="929666.15" interesesAcumulados="7342.59" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-02-01" fechafin="2020-03-01" saldoinicial="892000.00" saldo_final="899136.00" interesesAcumulados="7136.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-03-02" fechafin="2020-03-31" saldoinicial="899136.00" saldo_final="907829.09" interesesAcumulados="7193.09" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-04-01" fechafin="2020-04-30" saldoinicial="907829.09" saldo_final="918091.72" interesesAcumulados="7262.63" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-05-01" fechafin="2020-05-30" saldoinicial="918091.72" saldo_final="929936.45" interesesAcumulados="7344.73" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-05-31" fechafin="2020-06-29" saldoinicial="929936.45" saldo_final="937375.94" interesesAcumulados="7439.49" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-06-30" fechafin="2020-07-29" saldoinicial="937375.94" saldo_final="946374.95" interesesAcumulados="7499.01" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-07-30" fechafin="2020-08-28" saldoinicial="946374.95" saldo_final="956945.95" interesesAcumulados="7571.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000017" fechaInicio="2020-08-29" fechafin="2020-09-27" saldoinicial="956945.95" saldo_final="969101.52" interesesAcumulados="7655.57" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-03-19" fechafin="2020-04-17" saldoinicial="929000.00" saldo_final="936432.00" interesesAcumulados="7432.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-04-18" fechafin="2020-05-17" saldoinicial="936432.00" saldo_final="945423.46" interesesAcumulados="7491.46" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-05-18" fechafin="2020-06-16" saldoinicial="945423.46" saldo_final="955986.85" interesesAcumulados="7563.39" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-06-17" fechafin="2020-07-16" saldoinicial="955986.85" saldo_final="968134.74" interesesAcumulados="7647.89" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-07-17" fechafin="2020-08-15" saldoinicial="968134.74" saldo_final="975879.82" interesesAcumulados="7745.08" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-08-16" fechafin="2020-09-14" saldoinicial="975879.82" saldo_final="985186.86" interesesAcumulados="7807.04" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-09-15" fechafin="2020-10-14" saldoinicial="985186.86" saldo_final="996068.35" interesesAcumulados="7881.49" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000018" fechaInicio="2020-10-15" fechafin="2020-11-13" saldoinicial="996068.35" saldo_final="1008536.90" interesesAcumulados="7968.55" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-05-05" fechafin="2020-06-03" saldoinicial="966000.00" saldo_final="973728.00" interesesAcumulados="7728.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-06-04" fechafin="2020-07-03" saldoinicial="973728.00" saldo_final="983017.82" interesesAcumulados="7789.82" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-07-04" fechafin="2020-08-02" saldoinicial="983017.82" saldo_final="993881.96" interesesAcumulados="7864.14" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-08-03" fechafin="2020-09-01" saldoinicial="993881.96" saldo_final="1006333.02" interesesAcumulados="7951.06" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-09-02" fechafin="2020-10-01" saldoinicial="1006333.02" saldo_final="1014383.68" interesesAcumulados="8050.66" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-10-02" fechafin="2020-10-31" saldoinicial="1014383.68" saldo_final="1023998.75" interesesAcumulados="8115.07" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-11-01" fechafin="2020-11-30" saldoinicial="1023998.75" saldo_final="1035190.74" interesesAcumulados="8191.99" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000019" fechaInicio="2020-12-01" fechafin="2020-12-30" saldoinicial="1035190.74" saldo_final="1047972.27" interesesAcumulados="8281.53" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-06-21" fechafin="2020-07-20" saldoinicial="1003000.00" saldo_final="1011024.00" interesesAcumulados="8024.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-07-21" fechafin="2020-08-19" saldoinicial="1011024.00" saldo_final="1020612.19" interesesAcumulados="8088.19" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-08-20" fechafin="2020-09-18" saldoinicial="1020612.19" saldo_final="1031777.09" interesesAcumulados="8164.90" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-09-19" fechafin="2020-10-18" saldoinicial="1031777.09" saldo_final="1044531.31" interesesAcumulados="8254.22" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-10-19" fechafin="2020-11-17" saldoinicial="1044531.31" saldo_final="1052887.56" interesesAcumulados="8356.25" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-11-18" fechafin="2020-12-17" saldoinicial="1052887.56" saldo_final="1062810.66" interesesAcumulados="8423.10" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2020-12-18" fechafin="2021-01-16" saldoinicial="1062810.66" saldo_final="1074313.15" interesesAcumulados="8502.49" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000020" fechaInicio="2021-01-17" fechafin="2021-02-15" saldoinicial="1074313.15" saldo_final="1087407.66" interesesAcumulados="8594.51" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2020-08-07" fechafin="2020-09-05" saldoinicial="1040000.00" saldo_final="1048320.00" interesesAcumulados="8320.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2020-09-06" fechafin="2020-10-05" saldoinicial="1048320.00" saldo_final="1058206.56" interesesAcumulados="8386.56" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2020-10-06" fechafin="2020-11-04" saldoinicial="1058206.56" saldo_final="1069672.21" interesesAcumulados="8465.65" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2020-11-05" fechafin="2020-12-04" saldoinicial="1069672.21" saldo_final="1082729.59" interesesAcumulados="8557.38" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2020-12-05" fechafin="2021-01-03" saldoinicial="1082729.59" saldo_final="1091391.43" interesesAcumulados="8661.84" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2021-01-04" fechafin="2021-02-02" saldoinicial="1091391.43" saldo_final="1101622.56" interesesAcumulados="8731.13" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2021-02-03" fechafin="2021-03-04" saldoinicial="1101622.56" saldo_final="1113435.54" interesesAcumulados="8812.98" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000021" fechaInicio="2021-03-05" fechafin="2021-04-03" saldoinicial="1113435.54" saldo_final="1126843.02" interesesAcumulados="8907.48" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2020-09-23" fechafin="2020-10-22" saldoinicial="1077000.00" saldo_final="1085616.00" interesesAcumulados="8616.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2020-10-23" fechafin="2020-11-21" saldoinicial="1085616.00" saldo_final="1095800.93" interesesAcumulados="8684.93" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2020-11-22" fechafin="2020-12-21" saldoinicial="1095800.93" saldo_final="1107567.34" interesesAcumulados="8766.41" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2020-12-22" fechafin="2021-01-20" saldoinicial="1107567.34" saldo_final="1120927.88" interesesAcumulados="8860.54" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2021-01-21" fechafin="2021-02-19" saldoinicial="1120927.88" saldo_final="1129895.30" interesesAcumulados="8967.42" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2021-02-20" fechafin="2021-03-21" saldoinicial="1129895.30" saldo_final="1140434.46" interesesAcumulados="9039.16" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2021-03-22" fechafin="2021-04-20" saldoinicial="1140434.46" saldo_final="1152557.94" interesesAcumulados="9123.48" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000022" fechaInicio="2021-04-21" fechafin="2021-05-20" saldoinicial="1152557.94" saldo_final="1166278.40" interesesAcumulados="9220.46" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2020-11-09" fechafin="2020-12-08" saldoinicial="1114000.00" saldo_final="1122912.00" interesesAcumulados="8912.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2020-12-09" fechafin="2021-01-07" saldoinicial="1122912.00" saldo_final="1133395.30" interesesAcumulados="8983.30" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-01-08" fechafin="2021-02-06" saldoinicial="1133395.30" saldo_final="1145462.46" interesesAcumulados="9067.16" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-02-07" fechafin="2021-03-08" saldoinicial="1145462.46" saldo_final="1159126.16" interesesAcumulados="9163.70" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-03-09" fechafin="2021-04-07" saldoinicial="1159126.16" saldo_final="1168399.17" interesesAcumulados="9273.01" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-04-08" fechafin="2021-05-07" saldoinicial="1168399.17" saldo_final="1179246.36" interesesAcumulados="9347.19" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-05-08" fechafin="2021-06-06" saldoinicial="1179246.36" saldo_final="1191680.33" interesesAcumulados="9433.97" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000023" fechaInicio="2021-06-07" fechafin="2021-07-06" saldoinicial="1191680.33" saldo_final="1205713.77" interesesAcumulados="9533.44" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2020-12-26" fechafin="2021-01-24" saldoinicial="1151000.00" saldo_final="1160208.00" interesesAcumulados="9208.00" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-01-25" fechafin="2021-02-23" saldoinicial="1160208.00" saldo_final="1170989.66" interesesAcumulados="9281.66" cantidadDepositos="3" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-02-24" fechafin="2021-03-25" saldoinicial="1170989.66" saldo_final="1183357.58" interesesAcumulados="9367.92" cantidadDepositos="4" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-03-26" fechafin="2021-04-24" saldoinicial="1183357.58" saldo_final="1197324.44" interesesAcumulados="9466.86" cantidadDepositos="2" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-04-25" fechafin="2021-05-24" saldoinicial="1197324.44" saldo_final="1206903.04" interesesAcumulados="9578.60" cantidadDepositos="3" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-05-25" fechafin="2021-06-23" saldoinicial="1206903.04" saldo_final="1218058.26" interesesAcumulados="9655.22" cantidadDepositos="4" cantidadRetiros="2"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-06-24" fechafin="2021-07-23" saldoinicial="1218058.26" saldo_final="1230802.73" interesesAcumulados="9744.47" cantidadDepositos="2" cantidadRetiros="1"/>
		<Estado_de_Cuenta NumeroCuenta="11000024" fechaInicio="2021-07-24" fechafin="2021-08-22" saldoinicial="1230802.73" saldo_final="1245149.15" interesesAcumulados="9846.42" cantidadDepositos="3" cantidadRetiros="2"/>
	</Estados_de_Cuenta>

	<Usuarios>
		<Usuario User="jhernandez" Pass="Hernandez2024*" EsAdministrador="0"/>
		<Usuario User="mrojas" Pass="Rojas2024*" EsAdministrador="0"/>
		<Usuario User="cvindas" Pass="Vindas2024*" EsAdministrador="0"/>
		<Usuario User="achacon" Pass="Chacon2024*" EsAdministrador="0"/>
		<Usuario User="lmonge" Pass="Monge2024*" EsAdministrador="0"/>
		<Usuario User="scastro" Pass="Castro2024*" EsAdministrador="0"/>
		<Usuario User="jgomez" Pass="Gomez2024*" EsAdministrador="0"/>
		<Usuario User="ksolis" Pass="Solis2024*" EsAdministrador="0"/>
		<Usuario User="raraya" Pass="Araya2024*" EsAdministrador="0"/>
		<Usuario User="dmendez" Pass="Mendez2024*" EsAdministrador="0"/>
		<Usuario User="framirez" Pass="Ramirez2024*" EsAdministrador="0"/>
		<Usuario User="gsalas" Pass="Salas2024*" EsAdministrador="0"/>
		<Usuario User="mherrera" Pass="Herrera2024*" EsAdministrador="0"/>
		<Usuario User="pvillalobos" Pass="Villalobos2024*" EsAdministrador="0"/>
		<Usuario User="dbarrantes" Pass="Barrantes2024*" EsAdministrador="0"/>
		<Usuario User="nvega" Pass="Vega2024*" EsAdministrador="0"/>
		<Usuario User="erodriguez" Pass="Rodriguez2024*" EsAdministrador="0"/>
		<Usuario User="csegura" Pass="Segura2024*" EsAdministrador="0"/>
		<Usuario User="achinchilla" Pass="Chinchilla2024*" EsAdministrador="0"/>
		<Usuario User="malfaro" Pass="Alfaro2024*" EsAdministrador="0"/>
		<Usuario User="kmarin" Pass="Marin2024*" EsAdministrador="0"/>
		<Usuario User="wquesada" Pass="Quesada2024*" EsAdministrador="0"/>
		<Usuario User="acascante" Pass="Cascante2024*" EsAdministrador="0"/>
		<Usuario User="tporras" Pass="Porras2024*" EsAdministrador="0"/>
		<Usuario User="fquiros" Pass="MyPass123*" EsAdministrador="1"/>
	</Usuarios>

	<Usuarios_Ver>
		<UsuarioPuedeVer User="jhernandez" NumeroCuenta="11000001"/>
		<UsuarioPuedeVer User="mrojas" NumeroCuenta="11000002"/>
		<UsuarioPuedeVer User="cvindas" NumeroCuenta="11000003"/>
		<UsuarioPuedeVer User="achacon" NumeroCuenta="11000004"/>
		<UsuarioPuedeVer User="lmonge" NumeroCuenta="11000005"/>
		<UsuarioPuedeVer User="scastro" NumeroCuenta="11000006"/>
		<UsuarioPuedeVer User="jgomez" NumeroCuenta="11000007"/>
		<UsuarioPuedeVer User="ksolis" NumeroCuenta="11000008"/>
		<UsuarioPuedeVer User="raraya" NumeroCuenta="11000009"/>
		<UsuarioPuedeVer User="dmendez" NumeroCuenta="11000010"/>
		<UsuarioPuedeVer User="framirez" NumeroCuenta="11000011"/>
		<UsuarioPuedeVer User="gsalas" NumeroCuenta="11000012"/>
		<UsuarioPuedeVer User="mherrera" NumeroCuenta="11000013"/>
		<UsuarioPuedeVer User="pvillalobos" NumeroCuenta="11000014"/>
		<UsuarioPuedeVer User="dbarrantes" NumeroCuenta="11000015"/>
		<UsuarioPuedeVer User="nvega" NumeroCuenta="11000016"/>
		<UsuarioPuedeVer User="erodriguez" NumeroCuenta="11000017"/>
		<UsuarioPuedeVer User="csegura" NumeroCuenta="11000018"/>
		<UsuarioPuedeVer User="achinchilla" NumeroCuenta="11000019"/>
		<UsuarioPuedeVer User="malfaro" NumeroCuenta="11000020"/>
		<UsuarioPuedeVer User="kmarin" NumeroCuenta="11000021"/>
		<UsuarioPuedeVer User="wquesada" NumeroCuenta="11000022"/>
		<UsuarioPuedeVer User="acascante" NumeroCuenta="11000023"/>
		<UsuarioPuedeVer User="tporras" NumeroCuenta="11000024"/>
	</Usuarios_Ver>

</DatosPrueba>';

EXEC dbo.sp_CargarDatosPrueba @xmlData = @xmlData;