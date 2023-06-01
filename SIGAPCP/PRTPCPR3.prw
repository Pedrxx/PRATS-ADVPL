//Bibliotecas
#Include "Totvs.ch"
#Include "Protheus.ch"
#include "TopConn.ch"

/*/{Protheus.doc} User Function TSTPCPR2
Relatório de condição de OPs
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 12/05/2023
@version 1.0
@type function

/*/

User Function PRTPCPR3()
	Local aArea := FWGetArea()
	Local oReport
	Local aPergs   := {}
	Local xPar0 := sToD("")
	Local xPar1 := sToD("")
	Local xPar2 := Space(6)
	Local xPar3 := Space(6)
	Local xPar4 := 1
	
	//Adicionando os parametros do ParamBox
	aAdd(aPergs, {1, "Data de", xPar0,  "", ".T.", "", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Data ate", xPar1,  "", ".T.", "", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "OP de", xPar2,  "", ".T.", "SC2", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "OP ate", xPar3,  "", ".T.", "SC2", ".T.", 80,  .F.})
	aAdd(aPergs, {2, "Imprime Consumo", xPar4, {"1 = Sim", "2 = Não"}, 80,".T.", .F.})
	
	//Se a pergunta for confirma, cria as definicoes do relatorio
	If ParamBox(aPergs, "Informe os parametros")
		oReport := fReportDef()
		oReport:PrintDialog()
	EndIf
	
	FWRestArea(aArea)
Return

/*/{Protheus.doc} Static Function fRepPrint
Imprime as OPs e os Consumos 
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 12/05/2023
@version 1.0
@type function

/*/
Static Function fRepPrint(oReport)
	Local oSecao1  := oReport:Section(1)
	Local oSecao2 := oReport:Section(2)
	Local cQryReport := ""
	Local cNumCod	 := ""
	Local cOpAnt	 := ""

	cQryReport := "SELECT * FROM TSTPCPR2 " 
	cQryReport += "WHERE C2_EMISSAO BETWEEN '" + DTOS( MV_PAR01 ) + "' AND '" + DTOS( MV_PAR02 ) + "' " 
	cQryReport += "AND C2_NUM BETWEEN '" + MV_PAR03+ "' AND '" + MV_PAR04 + "' " 

	//Verifica se a tabela ja está aberta.
	If Select("TEMP") <> 0
		DbSelectArea("TEMP")
		DbCloseArea()
	EndIf

	TCQUERY cQryReport NEW ALIAS "TEMP"
			
	DbSelectArea("TEMP")
	TEMP->(dbGoTop())

	oReport:SetMeter(TEMP->(LastRec()))

	While !EOF()
		If oReport:Cancel()
			Exit
		EndIf

		If  Iif(ValType(MV_PAR05)=='N',MV_PAR05,Val(MV_PAR05)) == 2	.And. AllTrim(cOpAnt) == AllTrim(TEMP->C2_NUM)
			TEMP->(dbSkip())
			Loop
		Endif

	//Iniciando a primeira seção
		oSecao1:Init()
		oReport:IncMeter()
		
		cNumCod := TEMP->C2_NUM
		cOpAnt	:= TEMP->C2_NUM

		IncProc("Imprimindo OPs "+ Alltrim(TEMP->C2_NUM))

	//Imprimindo primeira seção:
		oSecao1:Cell("C2_FILIAL"):SetValue(TEMP->C2_FILIAL)
		oSecao1:Cell("C2_NUM"):SetValue(TEMP->C2_NUM)
		oSecao1:Cell("C2_PRODUTO"):SetValue(TEMP->C2_PRODUTO)
		oSecao1:Cell("B1_DESCOP"):SetValue(TEMP->B1_DESCOP)
		oSecao1:Cell("C2_UM"):SetValue(TEMP->C2_UM)
		oSecao1:Cell("C2_EMISSAO"):SetValue(Stod(TEMP->C2_EMISSAO))
		oSecao1:Cell("C2_DATRF"):SetValue(StoD(TEMP->C2_DATRF))
		oSecao1:Cell("C2_QUJE"):SetValue(TEMP->C2_QUJE)
		oSecao1:Cell("CondBaixa"):SetValue(TEMP->CondBaixa)
		oSecao1:Cell("CondOperac"):SetValue(TEMP->CondOperac)
		
		oSecao1:Printline()
		
	If Iif(ValType(MV_PAR05)=='N',MV_PAR05,Val(MV_PAR05)) == 1	

		oSecao2:Init()
		//verifica se o codigo do cliente é o mesmo, se sim, imprime os dados do pedido
			While TEMP->C2_NUM == cNumCod
				oReport:IncMeter()
				IncProc("Imprimindo Consumos..."+ Alltrim(TEMP->D3_COD))
					oSecao2:Cell("D3_COD"):SetValue(TEMP->D3_COD)
					oSecao2:Cell("B1_DESCCON"):SetValue(TEMP->B1_DESCCON)
					oSecao2:Cell("D3_QUANT"):SetValue(TEMP->D3_QUANT)
					oSecao2:Cell("D3_UM"):SetValue(TEMP->D3_UM)
					oSecao2:Cell("D3_OP"):SetValue(TEMP->D3_OP)
					oSecao2:Cell("D3_EMISSAO"):SetValue(SToD(TEMP->D3_EMISSAO))
					oSecao2:Cell("D3_CUSTO1"):SetValue(TEMP->D3_CUSTO1)
					oSecao2:Cell("D3_LOTECTL"):SetValue(TEMP->D3_LOTECTL)
					oSecao2:Cell("D3_USUARIO"):SetValue(TEMP->D3_USUARIO)
					oSecao2:Printline()
					
					TEMP->(dbSkip())

			EndDo

			oSecao2:Finish()
			oReport:ThinLine()
			
			oSecao1:Finish()
	EndIf

		TEMP->(dbSkip())

	EndDo
	
Return .T.

Static Function fReportDef()

	
	//Criacao do componente de impressao
	oReport := TReport():New( "PRTPCPR3",;
		"Condição de OPs",;
		,;
		{|oReport| fRepPrint(oReport),};
	)
	
	//Inicia o relatório como paisagem. 
	oReport:oPage:lLandScape := .T. 
	oReport:oPage:lPortRait := .F. 

	oReport:SetTotalInLine(.F.)

	oSecao1  := TRSection():New(oReport,"OP"  ,"Q_QRY",{})
	oSecao2 := TRSection():New(oReport,"CONS","Q_QRY",{})

	//Colunas do relatorio - Secao 1
	TRCell():New(oSecao1, "C2_FILIAL",   "Q_QRY", "Filial ", /*cPicture*/, 12, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_NUM",  	"Q_QRY", "OP", /*cPicture*/, 12, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_PRODUTO",  "Q_QRY", "Produto", /*cPicture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "B1_DESCOP", 	"Q_QRY", "Desc. Produto", /*cPicture*/, 40, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_UM", 		"Q_QRY", "UM", /*cPicture*/, 12, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_EMISSAO",  "Q_QRY", "Data Emis.", /*cPicture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_DATRF",    "Q_QRY", "Data Prod.", /*cPicture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "C2_QUJE", 	"Q_QRY", "Qtd. Prod.", /*cPicture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "CondBaixa",  "Q_QRY", "Cond. Baixa", /*cPicture*/, 15, /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao1, "CondOperac",  "Q_QRY", "Cond. Operação", /*cPicture*/, 22, /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// Secao 2
	TRCell():New(oSecao2, "D3_COD", 	"Q_QRY", "Prod. Cons.", /*cPicture*/, 20, /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "B1_DESCCON",   "Q_QRY", "Descrição", /*cPicture*/, 40,/*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_QUANT",   "Q_QRY", "Quant. Cons", /*cPicture*/, 12,/*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_UM",   "Q_QRY", "UM", /*cPicture*/, 12,/*lPixel*/, /*{|| code-block de impressao }*/, "CENTER", /*lLineBreak*/, "CENTER", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_OP",   "Q_QRY", "Ordem Produção", /*cPicture*/, 12,/*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_EMISSAO",   "Q_QRY", "Emissão", /*cPicture*/, 18,/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_CUSTO1",   "Q_QRY", "Custo", /*cPicture*/, 18,/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_LOTECTL",   "Q_QRY", "Lote", /*cPicture*/, 20,/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	TRCell():New(oSecao2, "D3_USUARIO",   "Q_QRY", "Usuário", /*cPicture*/, 20,/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	
	oReport:SetTotalInLine(.F.)


return oReport


// //Colunas do relatorio - Secao 1
	// TRCell():New(oSecao1, "C2_FILIAL",   "Q_QRY", "Filial ", 		/*cPicture*/, 		TamSX3("C2_FILIAL"),  /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_NUM",  	 "Q_QRY", "OP",      		/*cPicture*/, 		TamSX3("C2_NUM"),     /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_PRODUTO",  "Q_QRY", "Produto", 		/*cPicture*/, 		TamSX3("C2_PRODUTO"), /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "B1_DESCOP", 	 "Q_QRY", "Desc. Produto",  /*cPicture*/, 		TamSX3("B1_DESC"),    /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_UM", 		 "Q_QRY", "UM", 			/*cPicture*/, 		TamSX3("C2_UM"), 	  /*lPixel*/, /*{|| code-block de impressao }*/, "CENTER", /*lLineBreak*/, "CENTER", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_EMISSAO",  "Q_QRY", "Data Emis.", 	/*cPicture*/, 		TamSX3("C2_EMISSAO"), /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_DATRF",    "Q_QRY", "Data Prod.", 	/*cPicture*/, 		TamSX3("C2_DATRF"),   /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "C2_QUJE", 	 "Q_QRY", "Qtd. Prod.", 	"@999.999.999,99",  TamSX3("C2_QUJE"),    /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "CondBaixa",   "Q_QRY", "Cond. Baixa", 	/*cPicture*/, 		15, 				  /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao1, "CondOperac",  "Q_QRY", "Cond. Operação", /*cPicture*/, 		15,                   /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// // Secao 2
	// TRCell():New(oSecao2, "D3_COD", 	"Q_QRY", "Prod. Cons.", 	/*cPicture*/,      TamSX3("D3_COD"),    /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "B1_DESCCON", "Q_QRY", "Descrição", 		/*cPicture*/, 	   TamSX3("B1_DESC"),   /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_QUANT",   "Q_QRY", "Quant. Cons", 	"@999.999.999,99", TamSX3("D3_QUANT"),  /*lPixel*/, /*{|| code-block de impressao }*/, "LEFT", /*lLineBreak*/, "LEFT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_UM",      "Q_QRY", "UM",				/*cPicture*/, 	   TamSX3("D3_UM"),     /*lPixel*/, /*{|| code-block de impressao }*/, "CENTER", /*lLineBreak*/, "CENTER", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_OP",      "Q_QRY", "Ordem Produção",  /*cPicture*/,	   TamSX3("D3_OP"),     /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_EMISSAO", "Q_QRY", "Emissão", 		/*cPicture*/,      TamSX3("D3_EMISSAO"),/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_CUSTO1",  "Q_QRY", "Custo", 			"@999.999.999,99", TamSX3("D3_CUSTO1"), /*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_LOTECTL", "Q_QRY", "Lote", 			/*cPicture*/,      TamSX3("D3_LOTECTL"),/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)
	// TRCell():New(oSecao2, "D3_USUARIO", "Q_QRY", "Usuário", 		/*cPicture*/,      TamSX3("D3_USUARIO"),/*lPixel*/, /*{|| code-block de impressao }*/, "RIGHT", /*lLineBreak*/, "RIGHT", /*lCellBreak*/, /*nColSpace*/, /*lAutoSize*/, /*nClrBack*/, /*nClrFore*/, .F.)


