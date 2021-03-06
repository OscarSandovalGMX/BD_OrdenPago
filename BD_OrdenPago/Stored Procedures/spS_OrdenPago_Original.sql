USE [DESA]
GO
/****** Object:  StoredProcedure [dbo].[spS_OrdenPago]    Script Date: 28/03/2017 11:37:17 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--spS_OrdenPago_T1 107805
--spS_OrdenPagoFP 0,'','''F000052083'',''F000051740'''
--spS_OrdenPago 0,'','','','','71'
--spS_OrdenPago 0,'','','','','','''OSANDOVAL''',''
--spS_OrdenPago_T1 0,'','','','','','''MAGUIRRE''',''
--spS_OrdenPago 0,'','','','','','','3'
--spS_OrdenPago 0,'','','''1-13-7000250-2-0''','','','',''
--spS_OrdenPago_T1 0,'','','',' AND fec_pago BETWEEN ''12/01/2016'' AND ''12/09/2016'' ','','',''
--spS_OrdenPago 0,'','','''1-13-7000250-1-0'',''1-13-7000250-2-0''','','','',''


ALTER PROCEDURE [dbo].[spS_OrdenPago](
	@nro_orden INT,
	@FiltroBrokerCia  VARCHAR(8000)='',
	@FiltroContrato   VARCHAR(8000)='',
	@FiltroPoliza     VARCHAR(8000)='',
	@FiltroFecPago    VARCHAR(8000)='',
	@FiltroRamoCont   VARCHAR(8000)='',
	@FiltroUsuario    VARCHAR(8000)='',
	@FiltroEstatus    VARCHAR(8000)='',
	@FiltroFecGen     VARCHAR(8000)=''
)
AS
BEGIN
DECLARE @FiltroOp		   VARCHAR(300)  = ''
DECLARE @strEstatus		   VARCHAR(8000) = ''
DECLARE @Condicion		   VARCHAR(1000) = ''
DECLARE @FiltroPolizaMR    VARCHAR(8000) = ''

 --Por Orden de Pago
 IF @nro_orden <> 0 
	BEGIN
		SET @FiltroOp = ' AND nro_op = ' + CAST(@nro_orden AS VARCHAR)
	END

 --Por BrokerCia
 IF LEN(@FiltroBrokerCia) > 0 
	BEGIN
		SET @FiltroBrokerCia = ' AND ( cod_broker IN ('+ @FiltroBrokerCia +') OR cod_cia IN (' + @FiltroBrokerCia + ') )'
	END

 --Por Contrato
 IF LEN(@FiltroContrato) > 0 
	BEGIN
		SET @FiltroContrato = ' AND id_contrato IN ('+ @FiltroContrato +')'
	END

 --Por Poliza
 IF LEN(@FiltroPoliza) > 0 
	BEGIN
		SET @FiltroPoliza = ' AND CAST(MR.cod_suc AS VARCHAR) +''-''+ 
								  CAST(ramo_pol AS VARCHAR) +''-''+ 
								  CAST(nro_pol AS VARCHAR) +''-''+ 
								  CAST(aaaa_endoso AS VARCHAR) +''-''+ 
								  CAST(nro_endoso AS VARCHAR) IN ('+ @FiltroPoliza +')'

		SET @FiltroPolizaMR = REPLACE(@FiltroPoliza,'ramo_pol','cod_ramo')
	END

 --Por Ramo Contable
 IF LEN(@FiltroRamoCont) > 0 
	BEGIN
	    SET @FiltroRamoCont = ' AND cod_ramo_contable IN ('+ @FiltroRamoCont +')'
	END
	
 --Por Usuario
 IF LEN(@FiltroUsuario) > 0 
	BEGIN
		SET @FiltroUsuario = ' AND txt_nombre_modifica IN ('+ @FiltroUsuario +')'
	END

 --Por Estatus
 IF LEN(@FiltroEstatus) > 0		
	BEGIN
		SELECT Condicion,
			   Consec = IDENTITY(INT,1,1) 
		INTO #PreFiltro
		FROM tautoriza_op where CHARINDEX(CAST(cod_autoriza AS VARCHAR),@FiltroEstatus,0) > 0  

		DECLARE cCondiciones CURSOR FOR

		SELECT 
				Condicion = CASE WHEN Consec = 1 THEN ' '  ELSE ' OR ' END + Condicion
		FROM
			#PreFiltro

		-- Apertura del cursor
		OPEN cCondiciones

		-- Lectura de la primera fila del cursor
		FETCH cCondiciones INTO @Condicion

		WHILE (@@FETCH_STATUS = 0 )
			BEGIN
				SET @strEstatus = @strEstatus + @Condicion
				FETCH cCondiciones INTO @Condicion
			END

		-- Cierre del cursor
		CLOSE cCondiciones

		-- Liberar los recursos
		DEALLOCATE cCondiciones

		SET @strEstatus = ' AND (' + @strEstatus + ' )'
	END
  
   


EXEC('   	
			---Checar id_imputacion repetidos--------------------
			SELECT cod_sector,cod_abona,nro_op,id_imputacion INTO #Repetidos FROM mop where id_imputacion IN
			(SELECT id_imputacion as Num FROM mop WHERE id_imputacion IN (SELECT id_imputacion FROM mop WHERE cod_sector=32 and cod_abona= 13)
			 GROUP By id_imputacion
			 HAVING COUNT(id_imputacion) > 1 ) 
			------------------------------------------------------

			SELECT 
				   tSEl_Val = CAST(0 As bit),
				   OP.nro_op,
				   fec_estim_pago, 
				   OP.cod_suc, 
				   SucEmision = SUCEm.txt_nom_suc,
				   OP.cod_sector,
				   Sector = SEC.txt_desc,
				   OP.cod_moneda, 
				   SigMon = MON.txt_desc_redu,
				   Moneda = MON.txt_desc,	
				   OP.imp_cambio,  
				   OP.cod_abona,
				   Abona = TAB.txt_desc,
				   OP.cod_tipo_agente, 
				   OP.cod_agente, 
				   --OP.cod_cia, 
				   cod_cobrador, 
				   cod_abona_vrs, 
				   OP.id_imputacion, 
				   txt_otros, 
				   CI.nro_nit, 
				   fec_baja = ISNULL(CONVERT(VARCHAR(10),OP.fec_baja,103),''''),  
				   OP.txt_cheque_a_nom, 
				   nro_ch, 
				   txt_nombre_modifica, 
				   Solicitante = USU.txt_nombre,
				   txt_nombre_autoriz_sector, 
				   Tesoreria = USU2.txt_nombre,
				   txt_nombre_autoriz_contab, 
				   Contabilidad = USU3.txt_nombre,
				   txt_nombre_baja,
				   Baja = USU4.txt_nombre,
				   OP.nro_doc, 
				   OP.cod_tipo_doc, 
				   cod_concepto_anulacion, 
				   OP.cod_origen_pago, 
				   OrigenPago = desc_origen_pago,
				   OP.id_persona, 
				   id_cuenta_bancaria, 
				   OP.sn_transferencia, 
				   OP.cod_suc_pago, 
				   SucPago = SUCPa.txt_nom_suc,
				   nro_cuenta_transferencia, 
				   cod_banco_transferencia, 
				   Banco = BAN.txt_nombre,
				   nro_recibo_imputacion, 
				   Monto = imp_total,
				   fec_generacion = CONVERT(VARCHAR(10),fec_generacion,103),
				   Solicitud = CASE WHEN OP.sn_transferencia = -1 THEN ''TRANSFERENCIA'' ELSE ''CHEQUE'' END,
				   fec_autoriz_cobranzas = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_cobranzas,103),''''),
				   fec_autoriz_sector = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_sector,103),''''),
				   fec_autoriz_contab = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_contab,103),''''), 
				   fec_pago = ISNULL(CONVERT(VARCHAR(10),fec_pago,103),''''), 
				   cod_estatus_op = ISNULL(OP.cod_estatus_op,0),
				   estatus = ISNULL(descripcion,''Por Aplicar Contabilidad''),
				   Texto = MAX(CAST(ISNULL(txt_observacion,'''') AS VARCHAR(8000))),
				   Cheque = MAX(CAST(ISNULL(txt_cheque_a_nom_det,'''') AS VARCHAR(8000))),
				   PVH.cod_Aseg,
				   Asegurado = PER.txt_apellido1,
				   id_pv = MAX(PVH.id_pv)
			 INTO
				   #Salida 
			 From				
				   mop OP		 
			 LEFT JOIN
				   testatus_op ST
				ON
				   OP.cod_estatus_op = ST.cod_estatus_op '
					+@strEstatus+'
			INNER JOIN
				   mcias_reas CI				
				ON
				   OP.cod_abona_vrs = CI.cod_cia_reas AND
				   cod_abona = 13
				   '+@FiltroFecPago+
				     @FiltroFecGen+
				     @FiltroUsuario+'
			INNER JOIN
				  tsuc SUCEm
				ON
				   OP.cod_suc = SUCEm.cod_suc
			INNER JOIN
				  tsuc SUCPa
				ON
				   OP.cod_suc = SUCPa.cod_suc
			INNER JOIN
				  tmoneda MON
				ON
				   OP.cod_moneda = MON.cod_moneda
			INNER JOIN
				  tusuario USU
				ON
				   OP.txt_nombre_modifica = USU.cod_usuario
			LEFT JOIN
				  tusuario USU2
				ON
				   OP.txt_nombre_autoriz_sector = USU2.cod_usuario
			LEFT JOIN
				  tusuario USU3
				ON
				   OP.txt_nombre_autoriz_contab = USU3.cod_usuario
			LEFT JOIN
				  tusuario USU4
				ON
				   OP.txt_nombre_baja = USU4.cod_usuario
			INNER JOIN
				  tsector SEC
				ON
				   OP.cod_sector = SEC.cod_sector
			INNER JOIn
				  tabona TAB
				ON
				   OP.cod_abona = TAB.cod_abona
			INNER JOIN
				  torigen_pago TOR
				ON
				   OP.cod_origen_pago = TOR.cod_origen_pago
				   '+@FiltroOp+'
			LEFT JOIN 
				   (SELECT * FROM tmp_imputacion_reas MR			
				    WHERE cod_modulo = 8
					'+@FiltroBrokerCia+
					  @FiltroContrato+
					  @FiltroPoliza+
					  @FiltroRamoCont+'
					) IMP	
				ON
				  OP.id_imputacion = IMP.id_imputacion 
			LEFT JOIN
				   pv_header PVH
				ON
				   IMP.cod_suc = PVH.cod_suc AND
				   IMP.ramo_pol = PVH.cod_ramo AND
				   IMP.nro_pol = PVH.nro_pol AND
				   IMP.aaaa_endoso = PVH.aaaa_endoso AND
				   IMP.nro_endoso = PVH.nro_endoso 
			INNER JOIN
				   maseg_header ASG
				ON
				   PVH.cod_aseg = ASG.cod_aseg
			INNER JOIN 
				  mpersona PER		
				ON
				  ASG.id_persona = PER.id_persona
			LEFT JOIN
				  tbanco BAN
				ON
				   OP.cod_banco_transferencia = BAN.cod_banco
			LEFT JOIN
				   mop_texto MT
				ON
				   OP.nro_op = MT.nro_op 
			GROUP BY
				OP.nro_op,
				fec_estim_pago, 
				OP.cod_suc, 
				SUCEm.txt_nom_suc,
				OP.cod_sector,
				SEC.txt_desc,
				OP.cod_moneda, 
				MON.txt_desc_redu,
				MON.txt_desc,	
				OP.imp_cambio,  
				OP.cod_abona,
				TAB.txt_desc,
				OP.cod_tipo_agente, 
				OP.cod_agente, 
				--OP.cod_cia, 
				cod_cobrador, 
				cod_abona_vrs, 
				OP.id_imputacion, 
				txt_otros, 
				CI.nro_nit, 
				OP.fec_baja,  
				OP.txt_cheque_a_nom, 
				nro_ch, 
				txt_nombre_modifica, 
				USU.txt_nombre,
				txt_nombre_autoriz_sector, 
				USU2.txt_nombre,
				txt_nombre_autoriz_contab, 
				USU3.txt_nombre,
				txt_nombre_baja,
				USU4.txt_nombre,
				OP.nro_doc, 
				OP.cod_tipo_doc, 
				cod_concepto_anulacion, 
				OP.cod_origen_pago, 
				desc_origen_pago,
				OP.id_persona, 
				id_cuenta_bancaria, 
				OP.sn_transferencia, 
				OP.cod_suc_pago, 
				SUCPa.txt_nom_suc,
				nro_cuenta_transferencia, 
				cod_banco_transferencia, 
				BAN.txt_nombre,
				nro_recibo_imputacion, 
				imp_total,
				fec_generacion,
				fec_autoriz_cobranzas,
				fec_autoriz_sector,
				fec_autoriz_contab, 
				fec_pago, 
				OP.cod_estatus_op,
				descripcion,
				PVH.cod_Aseg,
				PER.txt_apellido1--,
				--PVH.id_pv
UNION ALL
			SELECT 
				   tSEl_Val = CAST(0 As bit),
				   OP.nro_op,
				   fec_estim_pago, 
				   OP.cod_suc, 
				   SucEmision = SUCEm.txt_nom_suc,
				   OP.cod_sector,
				   Sector = SEC.txt_desc,
				   OP.cod_moneda, 
				   SigMon = MON.txt_desc_redu,
				   Moneda = MON.txt_desc,	
				   OP.imp_cambio,  
				   OP.cod_abona,
				   Abona = TAB.txt_desc,
				   OP.cod_tipo_agente, 
				   OP.cod_agente, 
				   --OP.cod_cia, 
				   cod_cobrador, 
				   cod_abona_vrs, 
				   OP.id_imputacion, 
				   txt_otros, 
				   CI.nro_nit, 
				   fec_baja = ISNULL(CONVERT(VARCHAR(10),OP.fec_baja,103),''''),  
				   OP.txt_cheque_a_nom, 
				   nro_ch, 
				   txt_nombre_modifica, 
				   Solicitante = USU.txt_nombre,
				   txt_nombre_autoriz_sector, 
				   Tesoreria = USU2.txt_nombre,
				   txt_nombre_autoriz_contab, 
				   Contabilidad = USU3.txt_nombre,
				   txt_nombre_baja,
				   Baja = USU4.txt_nombre,
				   OP.nro_doc, 
				   OP.cod_tipo_doc, 
				   cod_concepto_anulacion, 
				   OP.cod_origen_pago, 
				   OrigenPago = desc_origen_pago,
				   OP.id_persona, 
				   id_cuenta_bancaria, 
				   OP.sn_transferencia, 
				   OP.cod_suc_pago, 
				   SucPago = SUCPa.txt_nom_suc,
				   nro_cuenta_transferencia, 
				   cod_banco_transferencia, 
				   Banco = BAN.txt_nombre,
				   nro_recibo_imputacion, 
				   Monto = imp_total,
				   fec_generacion = CONVERT(VARCHAR(10),fec_generacion,103),
				   Solicitud = CASE WHEN OP.sn_transferencia = -1 THEN ''TRANSFERENCIA'' ELSE ''CHEQUE'' END,
				   fec_autoriz_cobranzas = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_cobranzas,103),''''),
				   fec_autoriz_sector = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_sector,103),''''),
				   fec_autoriz_contab = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_contab,103),''''), 
				   fec_pago = ISNULL(CONVERT(VARCHAR(10),fec_pago,103),''''), 
				   cod_estatus_op = ISNULL(OP.cod_estatus_op,0),
				   estatus = ISNULL(descripcion,''Por Aplicar Contabilidad''),
				   Texto = MAX(CAST(ISNULL(txt_observacion,'''') AS VARCHAR(8000))),
				   Cheque = MAX(CAST(ISNULL(txt_cheque_a_nom_det,'''') AS VARCHAR(8000))),
				   PVH.cod_Aseg,
				   Asegurado = PER.txt_apellido1,
				   id_pv = MAX(PVH.id_pv)
			 From				
				   mop OP
			 LEFT JOIN
				   testatus_op ST
				ON
				   OP.cod_estatus_op = ST.cod_estatus_op '
					+@strEstatus+'
			INNER JOIN
				   mcias_reas CI				
				ON
				   OP.cod_abona_vrs = CI.cod_cia_reas AND
				   cod_abona = 13
				   '+@FiltroFecPago+
				     @FiltroFecGen+
				     @FiltroUsuario+'
			INNER JOIN
				  tsuc SUCEm
				ON
				   OP.cod_suc = SUCEm.cod_suc
			INNER JOIN
				  tsuc SUCPa
				ON
				   OP.cod_suc = SUCPa.cod_suc
			INNER JOIN
				  tmoneda MON
				ON
				   OP.cod_moneda = MON.cod_moneda
			INNER JOIN
				  tusuario USU
				ON
				   OP.txt_nombre_modifica = USU.cod_usuario
			LEFT JOIN
				  tusuario USU2
				ON
				   OP.txt_nombre_autoriz_sector = USU2.cod_usuario
			LEFT JOIN
				  tusuario USU3
				ON
				   OP.txt_nombre_autoriz_contab = USU3.cod_usuario
			LEFT JOIN
				  tusuario USU4
				ON
				   OP.txt_nombre_baja = USU4.cod_usuario
			INNER JOIN
				  tsector SEC
				ON
				   OP.cod_sector = SEC.cod_sector
			INNER JOIn
				  tabona TAB
				ON
				   OP.cod_abona = TAB.cod_abona
			INNER JOIN
				  torigen_pago TOR
				ON
				   OP.cod_origen_pago = TOR.cod_origen_pago
				   '+@FiltroOp+'
			LEFT JOIN 
				   (SELECT mr.* FROM mr MR
				    INNER JOIN pv_header PVH
					ON
						MR.id_pv = PVH.id_pv AND
						MR.id_pv <> 0
					   '+@FiltroBrokerCia+
						 @FiltroContrato+
						 @FiltroPolizaMR+
						 @FiltroRamoCont+') IMP
				ON
				  OP.nro_recibo_imputacion = IMP.nro_recibo 
			LEFT JOIN
				   pv_header PVH
				ON
				   IMP.id_pv = PVH.id_pv 
			INNER JOIN
				   maseg_header ASG
				ON
				   PVH.cod_aseg = ASG.cod_aseg
			INNER JOIN 
				  mpersona PER		
				ON
				  ASG.id_persona = PER.id_persona
			LEFT JOIN
				  tbanco BAN
				ON
				   OP.cod_banco_transferencia = BAN.cod_banco
			LEFT JOIN
				   mop_texto MT
				ON
				   OP.nro_op = MT.nro_op 
			GROUP BY
				OP.nro_op,
				fec_estim_pago, 
				OP.cod_suc, 
				SUCEm.txt_nom_suc,
				OP.cod_sector,
				SEC.txt_desc,
				OP.cod_moneda, 
				MON.txt_desc_redu,
				MON.txt_desc,	
				OP.imp_cambio,  
				OP.cod_abona,
				TAB.txt_desc,
				OP.cod_tipo_agente, 
				OP.cod_agente, 
				--OP.cod_cia, 
				cod_cobrador, 
				cod_abona_vrs, 
				OP.id_imputacion, 
				txt_otros, 
				CI.nro_nit, 
				OP.fec_baja,  
				OP.txt_cheque_a_nom, 
				nro_ch, 
				txt_nombre_modifica, 
				USU.txt_nombre,
				txt_nombre_autoriz_sector, 
				USU2.txt_nombre,
				txt_nombre_autoriz_contab, 
				USU3.txt_nombre,
				txt_nombre_baja,
				USU4.txt_nombre,
				OP.nro_doc, 
				OP.cod_tipo_doc, 
				cod_concepto_anulacion, 
				OP.cod_origen_pago, 
				desc_origen_pago,
				OP.id_persona, 
				id_cuenta_bancaria, 
				OP.sn_transferencia, 
				OP.cod_suc_pago, 
				SUCPa.txt_nom_suc,
				nro_cuenta_transferencia, 
				cod_banco_transferencia, 
				BAN.txt_nombre,
				nro_recibo_imputacion, 
				imp_total,
				fec_generacion,
				fec_autoriz_cobranzas,
				fec_autoriz_sector,
				fec_autoriz_contab, 
				fec_pago, 
				OP.cod_estatus_op,
				descripcion,
				PVH.cod_Aseg,
				PER.txt_apellido1--,
				--PVH.id_pv
 UNION ALL
		   SELECT 
				  tSEl_Val = CAST(0 As bit),
				   OP.nro_op,
				   fec_estim_pago, 
				   OP.cod_suc, 
				   SucEmision = SUCEm.txt_nom_suc,
				   OP.cod_sector,
				   Sector = SEC.txt_desc,
				   OP.cod_moneda, 
				   SigMon = MON.txt_desc_redu,
				   Moneda = MON.txt_desc,	
				   OP.imp_cambio,  
				   OP.cod_abona,
				   Abona = TAB.txt_desc,
				   OP.cod_tipo_agente, 
				   OP.cod_agente, 
				   --OP.cod_cia, 
				   cod_cobrador, 
				   cod_abona_vrs, 
				   OP.id_imputacion, 
				   txt_otros, 
				   CI.nro_nit, 
				   fec_baja = ISNULL(CONVERT(VARCHAR(10),OP.fec_baja,103),''''),  
				   OP.txt_cheque_a_nom, 
				   nro_ch, 
				   txt_nombre_modifica, 
				   Solicitante = USU.txt_nombre,
				   txt_nombre_autoriz_sector, 
				   Tesoreria = USU2.txt_nombre,
				   txt_nombre_autoriz_contab, 
				   Contabilidad = USU3.txt_nombre,
				   txt_nombre_baja,
				   Baja = USU4.txt_nombre,
				   nro_doc, 
				   cod_tipo_doc, 
				   cod_concepto_anulacion, 
				   OP.cod_origen_pago, 
				   OrigenPago = desc_origen_pago,
				   OP.id_persona, 
				   id_cuenta_bancaria, 
				   OP.sn_transferencia, 
				   OP.cod_suc_pago, 
				   SucPago = SUCPa.txt_nom_suc,
				   nro_cuenta_transferencia, 
				   cod_banco_transferencia, 
				   Banco = BAN.txt_nombre,
				   nro_recibo_imputacion, 
				   Monto = imp_total,
				   fec_generacion = CONVERT(VARCHAR(10),fec_generacion,103),
				   Solicitud = CASE WHEN OP.sn_transferencia = -1 THEN ''TRANSFERENCIA'' ELSE ''CHEQUE'' END,
				   fec_autoriz_cobranzas = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_cobranzas,103),''''),
				   fec_autoriz_sector = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_sector,103),''''),
				   fec_autoriz_contab = ISNULL(CONVERT(VARCHAR(10),fec_autoriz_contab,103),''''), 
				   fec_pago = ISNULL(CONVERT(VARCHAR(10),fec_pago,103),''''), 
				   cod_estatus_op = ISNULL(OP.cod_estatus_op,0),
				   estatus = ISNULL(descripcion,''Por Aplicar Contabilidad''),
				   Texto = MAX(CAST(ISNULL(txt_observacion,'''') AS VARCHAR(8000))),
				   Cheque = MAX(CAST(ISNULL(txt_cheque_a_nom_det,'''') AS VARCHAR(8000))),
				   cod_aseg = 0,
				   Asegurado = '''',
				   id_pv = 0
			 From				
				   mop OP
			 LEFT JOIN
				   testatus_op ST
				ON
				   OP.cod_estatus_op = ST.cod_estatus_op '
				   +@strEstatus+'
			INNER JOIN
				   mcias_reas CI				
				ON
				   OP.cod_abona_vrs = CI.cod_cia_reas AND
				   --fec_baja IS NOT NULL AND					
				   cod_abona = 13
				   '+@FiltroFecPago+
				     @FiltroFecGen+
				     @FiltroUsuario+'
			INNER JOIN
				  tsuc SUCEm
				ON
				   OP.cod_suc = SUCEm.cod_suc
			INNER JOIN
				  tsuc SUCPa
				ON
				   OP.cod_suc = SUCPa.cod_suc
			INNER JOIN
				  tmoneda MON
				ON
				   OP.cod_moneda = MON.cod_moneda
			INNER JOIN
				  tusuario USU
				ON
				   OP.txt_nombre_modifica = USU.cod_usuario
			LEFT JOIN
				  tusuario USU2
				ON
				   OP.txt_nombre_autoriz_sector = USU2.cod_usuario
			LEFT JOIN
				  tusuario USU3
				ON
				   OP.txt_nombre_autoriz_contab = USU3.cod_usuario
			LEFT JOIN
				  tusuario USU4
				ON
				   OP.txt_nombre_baja = USU4.cod_usuario
			INNER JOIN
				  tsector SEC
				ON
				   OP.cod_sector = SEC.cod_sector
			INNER JOIn
				  tabona TAB
				ON
				   OP.cod_abona = TAB.cod_abona
			INNER JOIN
				  torigen_pago TOR
				ON
				   OP.cod_origen_pago = TOR.cod_origen_pago AND
				   id_imputacion NOT IN (SELECT id_imputacion FROM  tmp_imputacion_reas GROUP BY id_imputacion) AND   --que no este en temporal
				   nro_recibo_imputacion IS NULL  --ni en mr
				   '+@FiltroOp+'
			LEFT JOIN
				  tbanco BAN
				ON
				   OP.cod_banco_transferencia = BAN.cod_banco
			LEFT JOIN
				   mop_texto MT
				ON
				   OP.nro_op = MT.nro_op 
			GROUP BY
				OP.nro_op,
				fec_estim_pago, 
				OP.cod_suc, 
				SUCEm.txt_nom_suc,
				OP.cod_sector,
				SEC.txt_desc,
				OP.cod_moneda, 
				MON.txt_desc_redu,
				MON.txt_desc,	
				OP.imp_cambio,  
				OP.cod_abona,
				TAB.txt_desc,
				OP.cod_tipo_agente, 
				OP.cod_agente, 
				--OP.cod_cia, 
				cod_cobrador, 
				cod_abona_vrs, 
				OP.id_imputacion, 
				txt_otros, 
				CI.nro_nit, 
				fec_baja,  
				OP.txt_cheque_a_nom, 
				nro_ch, 
				txt_nombre_modifica, 
				USU.txt_nombre,
				txt_nombre_autoriz_sector, 
				USU2.txt_nombre,
				txt_nombre_autoriz_contab, 
				USU3.txt_nombre,
				txt_nombre_baja,
				USU4.txt_nombre,
				nro_doc, 
				cod_tipo_doc, 
				cod_concepto_anulacion, 
				OP.cod_origen_pago, 
				desc_origen_pago,
				OP.id_persona, 
				id_cuenta_bancaria, 
				OP.sn_transferencia, 
				OP.cod_suc_pago, 
				SUCPa.txt_nom_suc,
				nro_cuenta_transferencia, 
				cod_banco_transferencia, 
				BAN.txt_nombre,
				nro_recibo_imputacion, 
				imp_total,
				fec_generacion,
				fec_autoriz_cobranzas,
				fec_autoriz_sector,
				fec_autoriz_contab, 
				fec_pago, 
				OP.cod_estatus_op,
				descripcion
		ORDER BY OP.nro_op 


		SELECT 
			   nro_op,
			   RamoContable = CAST(ISNULL(ISNULL(TMP.cod_ramo_contable,MR.cod_ramo_contable),0) AS VARCHAR) + ''.-'' + ISNULL(RAC.txt_desc,''N/A'')
		INTO
			   #RamosContables
		FROM 
			   #Salida SAL
		LEFT JOIN
			   tmp_imputacion_reas TMP
			   ON
				 SAL.id_imputacion = TMP.id_imputacion AND
				 SAL.nro_recibo_imputacion IS NULL
		LEFT JOIN
			   mr MR
			   ON
				 SAL.nro_recibo_imputacion = MR.nro_recibo
		LEFT JOIN
			   tramo_contable RAC
			   ON
			     ISNULL(ISNULL(TMP.cod_ramo_contable,MR.cod_ramo_contable),0) = RAC.cod_ramo_contable
		GROUP BY
			   nro_op,
			   CAST(ISNULL(ISNULL(TMP.cod_ramo_contable,MR.cod_ramo_contable),0) AS VARCHAR) + ''.-'' + ISNULL(RAC.txt_desc,''N/A'')

		
		-------CURSOR PARA RAMOS CONTABLES----------------------
		CREATE TABLE #ListaRamos(nro_op INT,Ramos VARCHAR(8000)) 
		DECLARE @nro_op INT = 0
		DECLARE @nro_opAux INT = 0
		DECLARE @RamoContable VARCHAR(150)
		DECLARE @strRamos VARCHAR(8000) = ''''

		DECLARE cRamos CURSOR FOR
		SELECT 
				nro_op,RamoContable
		FROM
				#RamosContables
		ORDER BY 
				nro_op,RamoContable
		
		-- Apertura del cursor
		OPEN cRamos

		-- Lectura de la primera fila del cursor
		FETCH cRamos INTO @nro_op,@RamoContable
		SET @strRamos = @strRamos + ''|'' + @RamoContable
		SET @nro_opAux = @nro_op

		WHILE (@@FETCH_STATUS = 0 )
			BEGIN
				FETCH cRamos INTO @nro_op,@RamoContable

				IF @nro_op <> @nro_opAux 
				   BEGIN
						INSERT INTO #ListaRamos SELECT @nro_opAux,@strRamos
						SET @nro_opAux = @nro_op
						SET @strRamos = ''''
				   END
				   
				SET @strRamos = @strRamos + ''|'' + @RamoContable
			END

			IF @nro_op = @nro_opAux 
				   BEGIN
						INSERT INTO #ListaRamos SELECT @nro_opAux,@strRamos
				   END

		-- Cierre del cursor
		CLOSE cRamos

		-- Liberar los recursos
		DEALLOCATE cRamos
		
		SELECT S.*,Ramos,
			   sn_impresion = CAST(0 AS bit),
			   sn_Solicita = ISNULL(sn_Solicita,CAST(0 AS bit)),                             
			   cod_usuario_solicita = ISNULL(cod_usuario_solicita,''''),           
			   sn_JefeDirecto = ISNULL(sn_JefeDirecto,CAST(0 AS bit)),                          
			   cod_usuario_jefe = ISNULL(cod_usuario_jefe,''''),               
			   sn_DireccionArea = ISNULL(sn_DireccionArea,CAST(0 AS bit)),                        
			   cod_usuario_director = ISNULL(cod_usuario_director,''''),           
			   sn_Contabilidad = ISNULL(sn_Contabilidad,CAST(0 AS bit)),                         
			   cod_usuario_contabilidad = ISNULL(cod_usuario_contabilidad,''''),
			   Duplicado = CASE WHEN R.id_imputacion IS NULL THEN 0 ELSE 1 END
		FROM 
				#Salida S
		INNER JOIN
				#ListaRamos L
		ON
				S.nro_op = L.nro_op
		LEFT JOIN
				rFirmasXmop F
		ON
				S.nro_op = F.nro_op
		LEFT JOIN
				#Repetidos R
		ON	
				S.nro_op = R.nro_op
		ORDER BY S.nro_op DESC

				 ')
END



