//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} WSRESTFUL zWsProduto
WS Produtos Protheus
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
/*/

WSRESTFUL zWsProduto DESCRIPTION 'WS Produtos Protheus'
    //Atributos
    WSDATA id         AS STRING
    WSDATA cod_inicio AS STRING
    WSDATA cod_fim    AS STRING

    //Métodos
    WSMETHOD GET    ID     DESCRIPTION 'Retorna o registro pesquisado' WSSYNTAX '/zWsProduto/get_id?{id}'                       PATH 'get_id'        PRODUCES APPLICATION_JSON
    WSMETHOD GET    ALL    DESCRIPTION 'Retorna todos os registros'    WSSYNTAX '/zWsProduto/get_all?{cod_inicio,cod_fim}'      PATH 'get_all'       PRODUCES APPLICATION_JSON
    WSMETHOD POST   NEW    DESCRIPTION 'Inclusão de registro'          WSSYNTAX '/zWsProduto/new'                               PATH 'new'           PRODUCES APPLICATION_JSON
    WSMETHOD PUT    UPDATE DESCRIPTION 'Atualização de registro'       WSSYNTAX '/zWsProduto/update'                            PATH 'update'        PRODUCES APPLICATION_JSON
    WSMETHOD DELETE ERASE  DESCRIPTION 'Exclusão de registro'          WSSYNTAX '/zWsProduto/erase'                             PATH 'erase'         PRODUCES APPLICATION_JSON
END WSRESTFUL

/*/{Protheus.doc} WSMETHOD GET ID
Busca registro via ID
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
@param id, Caractere, String que será pesquisada através do MsSeek
/*/

WSMETHOD GET ID WSRECEIVE id WSSERVICE zWsProduto
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cAliasWS   := 'SB1'

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'ID001'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID002'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
            //Define o retorno
            jResponse['codigo'] := (cAliasWS)->B1_COD
            jResponse['descricao'] := AllTrim((cAliasWS)->B1_DESC)
            jResponse['tipo'] := (cAliasWS)->B1_TIPO
            jResponse['unid_medida'] := (cAliasWS)->B1_UM
            jResponse['local'] := (cAliasWS)->B1_LOCPAD
            jResponse['estoque'] := (cAliasWS)->B1_XESTOQU
            jResponse['especie'] := AllTrim((cAliasWS)->B1_XESPECI)
            jResponse['familia'] := (cAliasWS)->B1_XFAMILI
            jResponse['peso_liquido'] := (cAliasWS)->B1_PESO
            jResponse['peso_bruto'] := (cAliasWS)->B1_PESBRU
        EndIf
    EndIf

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet

/*/{Protheus.doc} WSMETHOD GET ALL
Busca todos os registros através de paginação
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0

    Poderia ser usado o FWAdapterBaseV2(), mas em algumas versões antigas não existe essa funcionalidade
    então a paginação foi feita manualmente

/*/

WSMETHOD GET ALL WSRECEIVE cod_inicio, cod_fim WSSERVICE zWsProduto
    Local jResponse  := JsonObject():New()
    Local cAliasWS   := 'SB1'
    Local lRet       := .T.
    Local cQueryTab  := ''
    Local nTotal     := 0
    Local nAtual     := 0
    Local oRegistro

    If Empty(::cod_inicio)
        Self:setStatus(500) 
        jResponse['errorId']  := 'ALL001'
        jResponse['error']    := 'Cod. Inicio não encontrado'
        jResponse['solution'] := 'Parametro Cod. Inicio não foi informado'
    ElseIf Empty(::cod_fim)
            Self:setStatus(500) 
            jResponse['errorId']  := 'ALL002'
            jResponse['error']    := 'Cod. Fim não encontrado'
            jResponse['solution'] := 'Parametro Cod. Fim não foi informado'
    Else

        //Efetua a busca dos registros
        cQueryTab := " SELECT " + CRLF
        cQueryTab += "     TAB.R_E_C_N_O_ AS TABREC " + CRLF
        cQueryTab += " FROM " + CRLF
        cQueryTab += "     " + RetSQLName(cAliasWS) + " TAB " + CRLF
        cQueryTab += " WHERE " + CRLF
        cQueryTab += "     TAB.D_E_L_E_T_ = '' " + CRLF
        cQueryTab += "     AND TAB.B1_COD >= '" + ::cod_inicio +"' " + CRLF
        cQueryTab += "     AND TAB.B1_COD <= '" + ::cod_fim + "' " + CRLF
        cQueryTab += " ORDER BY " + CRLF
        cQueryTab += "     TABREC " + CRLF
        TCQuery cQueryTab New Alias 'QRY_TAB'

        //Se não encontrar registros
        If QRY_TAB->(EoF())
            //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'ALL003'
            jResponse['error']    := 'Registro(s) não encontrado(s)'
            jResponse['solution'] := 'A consulta de registros não retornou nenhuma informação'
        Else
            jResponse['objects'] := {}

            //Conta o total de registros
            Count To nTotal
            QRY_TAB->(DbGoTop())

            //Percorre os registros
            QRY_TAB->(DbGoTop())

            While ! QRY_TAB->(EoF())
                nAtual++
                
                //Se ultrapassar o limite, encerra o laço
                If nAtual > nTotal
                    Exit
                EndIf

                //Posiciona o registro e adiciona no retorno
                DbSelectArea(cAliasWS)
                (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))

                oRegistro := JsonObject():New()

                oRegistro['codigo'] := (cAliasWS)->B1_COD
                oRegistro['descricao'] := AllTrim((cAliasWS)->B1_DESC)
                oRegistro['tipo'] := (cAliasWS)->B1_TIPO
                oRegistro['unid_medida'] := (cAliasWS)->B1_UM
                oRegistro['local'] := (cAliasWS)->B1_LOCPAD
                oRegistro['estoque'] := (cAliasWS)->B1_XESTOQU
                oRegistro['especie'] := AllTrim((cAliasWS)->B1_XESPECI)
                oRegistro['familia'] := (cAliasWS)->B1_XFAMILI
                oRegistro['peso_liquido'] := (cAliasWS)->B1_PESO
                oRegistro['peso_bruto'] := (cAliasWS)->B1_PESBRU
                aAdd(jResponse['objects'], oRegistro)

                QRY_TAB->(DbSkip())
            EndDo
        EndIf
        QRY_TAB->(DbCloseArea())
    EndIf

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())

Return lRet

/*/{Protheus.doc} WSMETHOD POST UPDATE
Atualiza o registro na tabela
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
@param id, Caractere, String que será pesquisada através do MsSeek

    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "cod": "conteudo"
    }

/*/

WSMETHOD POST NEW WSRECEIVE WSSERVICE zWsProduto
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := 'C:/temp/'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SB1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
 
    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)
 
    //Se tiver algum erro no Parse, encerra a execução
    IF ! Empty(cError)
        //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'NEW004'
        jResponse['error']    := 'Parse do JSON'
        jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

    Else
		DbSelectArea(cAliasWS)

        /*{
            "grupo": "1010",
            "subgrupo": "200",
            "tipo": "PA",
            "descricao": "Produto JSON WS",
            "unid_medida": "UN",
            "armazem": "05",
            "estoque": "N",
            "especie": "WS",
            "familia": "000001",
            "peso_liquido": 1,
            "peso_bruto": 1
        }*/
                
       
		//Adiciona os dados do ExecAuto
		// aAdd(aDados, {'B1_COD',         jJson:GetJsonObject('codigo'),   Nil})
		aAdd(aDados, {'B1_GRUPO',       jJson:GetJsonObject('grupo'),   Nil})
		aAdd(aDados, {'B1_XSUBGRP',     jJson:GetJsonObject('subgrupo'),   Nil})
		aAdd(aDados, {'B1_TIPO',        jJson:GetJsonObject('tipo'),   Nil})
		aAdd(aDados, {'B1_DESC',        jJson:GetJsonObject('descricao'),   Nil})
		aAdd(aDados, {'B1_UM',          jJson:GetJsonObject('unid_medida'),   Nil})
		aAdd(aDados, {'B1_LOCPAD',      jJson:GetJsonObject('armazem'),   Nil})
		aAdd(aDados, {'B1_XESTOQU',     jJson:GetJsonObject('estoque'),   Nil})
		aAdd(aDados, {'B1_XESPECI',     jJson:GetJsonObject('especie'),   Nil})
		aAdd(aDados, {'B1_XFAMILI',     jJson:GetJsonObject('familia'),   Nil})
		aAdd(aDados, {'B1_PESO',        jJson:GetJsonObject('peso_liquido'),   Nil})
		aAdd(aDados, {'B1_PESBRU',      jJson:GetJsonObject('peso_bruto'),   Nil})

		
		//Percorre os dados do execauto
		For nCampo := 1 To Len(aDados)
			//Se o campo for data, retira os hifens e faz a conversão
			If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
				aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
				aDados[nCampo][2] := sToD(aDados[nCampo][2])
			EndIf
		Next

		//Chama a inclusão automática
		MsExecAuto({|x, y| MATA010(x, y)}, aDados, 3)

		//Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		If lMsErroAuto
			//Monta o texto do Error Log que será salvo
			cErrorLog   := ''
			aLogAuto    := GetAutoGrLog()
			For nLinha := 1 To Len(aLogAuto)
				cErrorLog += aLogAuto[nLinha] + CRLF
			Next nLinha

			//Grava o arquivo de log
			cArqLog := 'zWsProduto_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
			MemoWrite(cDirLog + cArqLog, cErrorLog)

			//Define o retorno para o WebService
			//SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
           Self:setStatus(500) 
			jResponse['errorId']  := 'NEW005'
			jResponse['error']    := 'Erro na inclusão do registro'
			jResponse['solution'] := 'Nao foi possivel incluir o registro: ' + cErrorLog + ' '
			jResponse['solution'] := 'Foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
			lRet := .F.

		//Senão, define o retorno
		Else
			jResponse['note']     := 'Registro incluido com sucesso'
		EndIf

    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet

/*/{Protheus.doc} WSMETHOD PUT UPDATE
Atualiza o registro na tabela
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
@param id, Caractere, String que será pesquisada através do MsSeek

    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "cod": "conteudo"
    }

/*/

WSMETHOD PUT UPDATE WSRECEIVE id WSSERVICE zWsProduto
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SB1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.

    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'UPD006'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'UPD007'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
 
            //Se tiver algum erro no Parse, encerra a execução
            If ! Empty(cError)
                //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
                Self:setStatus(500) 
                jResponse['errorId']  := 'UPD008'
                jResponse['error']    := 'Parse do JSON'
                jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

            Else
		         DbSelectArea(cAliasWS)

                 /*{
                    "codigo":"1010.200.000059",
                    "grupo": "1010",
                    "subgrupo": "200",
                    "tipo": "PA",
                    "descricao": "Produto JSON WS",
                    "unid_medida": "UN",
                    "armazem": "05",
                    "estoque": "N",
                    "especie": "WS",
                    "familia": "000001",
                    "peso_liquido": 1,
                    "peso_bruto": 1
                }*/
                
		        //Adiciona os dados do ExecAuto
                aAdd(aDados, {'B1_COD',         jJson:GetJsonObject('codigo'),   Nil})
                aAdd(aDados, {'B1_GRUPO',       jJson:GetJsonObject('grupo'),   Nil})
                aAdd(aDados, {'B1_XSUBGRP',     jJson:GetJsonObject('subgrupo'),   Nil})
                aAdd(aDados, {'B1_TIPO',        jJson:GetJsonObject('tipo'),   Nil})
                aAdd(aDados, {'B1_DESC',        jJson:GetJsonObject('descricao'),   Nil})
                aAdd(aDados, {'B1_UM',          jJson:GetJsonObject('unid_medida'),   Nil})
                aAdd(aDados, {'B1_LOCPAD',      jJson:GetJsonObject('armazem'),   Nil})
                aAdd(aDados, {'B1_XESTOQU',     jJson:GetJsonObject('estoque'),   Nil})
                aAdd(aDados, {'B1_XESPECI',     jJson:GetJsonObject('especie'),   Nil})
                aAdd(aDados, {'B1_XFAMILI',     jJson:GetJsonObject('familia'),   Nil})
                aAdd(aDados, {'B1_PESO',        jJson:GetJsonObject('peso_liquido'),   Nil})
                aAdd(aDados, {'B1_PESBRU',      jJson:GetJsonObject('peso_bruto'),   Nil})
		         
		         //Percorre os dados do execauto
		         For nCampo := 1 To Len(aDados)
		         	//Se o campo for data, retira os hifens e faz a conversão
		         	If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
		         		aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
		         		aDados[nCampo][2] := sToD(aDados[nCampo][2])
		         	EndIf
		         Next

		         //Chama a atualização automática
		         MsExecAuto({|x, y| MATA010(x, y)}, aDados, 4)

		         //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		         If lMsErroAuto
		         	//Monta o texto do Error Log que será salvo
		         	cErrorLog   := ''
		         	aLogAuto    := GetAutoGrLog()
		         	For nLinha := 1 To Len(aLogAuto)
		         		cErrorLog += aLogAuto[nLinha] + CRLF
		         	Next nLinha

		            //Grava o arquivo de log
		            cArqLog := 'zWsProduto_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
		            MemoWrite(cDirLog + cArqLog, cErrorLog)

		            //Define o retorno para o WebService
		            //SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
		            Self:setStatus(500) 
		            jResponse['errorId']  := 'UPD009'
		            jResponse['error']    := 'Erro na atualização do registro'
		            jResponse['solution'] := 'Nao foi possivel alterar o registro: ' + cErrorLog+ ' '
		            jResponse['solution'] += 'Foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
		            lRet := .F.

		         //Senão, define o retorno
		         Else
		         	jResponse['note']     := 'Registro alterdo com sucesso'
		         EndIf

		     EndIf
		 EndIf
    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet


/*/{Protheus.doc} WSMETHOD DELETE ERASE
Apaga o registro na tabela
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
@param id, Caractere, String que será pesquisada através do MsSeek

    Abaixo um exemplo do JSON que deverá vir no body
    * 1: Para campos do tipo Numérico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padrão 'YYYY-MM-DD'

    {
        "cod": "conteudo"
    }

/*/

WSMETHOD DELETE ERASE WSRECEIVE id WSSERVICE zWsProduto
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SB1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.

    //Se não existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)

    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'DEL010'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))

        //Se não encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'DEL011'
            jResponse['error']    := 'ID não encontrado'
            jResponse['solution'] := 'Código ID não encontrado na tabela ' + cAliasWS
        Else
 
            //Se tiver algum erro no Parse, encerra a execução
            If ! Empty(cError)
                //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
                Self:setStatus(500) 
                jResponse['errorId']  := 'DEL012'
                jResponse['error']    := 'Parse do JSON'
                jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

            Else
		         DbSelectArea(cAliasWS)
                
		         //Adiciona os dados do ExecAuto
                aAdd(aDados, {'B1_COD',         jJson:GetJsonObject('codigo'),   Nil})
                aAdd(aDados, {'B1_GRUPO',       jJson:GetJsonObject('grupo'),   Nil})
                aAdd(aDados, {'B1_XSUBGRP',     jJson:GetJsonObject('subgrupo'),   Nil})
                aAdd(aDados, {'B1_TIPO',        jJson:GetJsonObject('tipo'),   Nil})
                aAdd(aDados, {'B1_DESC',        jJson:GetJsonObject('descricao'),   Nil})
                aAdd(aDados, {'B1_UM',          jJson:GetJsonObject('unid_medida'),   Nil})
                aAdd(aDados, {'B1_LOCPAD',      jJson:GetJsonObject('armazem'),   Nil})
                aAdd(aDados, {'B1_XESTOQU',     jJson:GetJsonObject('estoque'),   Nil})
                aAdd(aDados, {'B1_XESPECI',    jJson:GetJsonObject('especie'),   Nil})
                aAdd(aDados, {'B1_XFAMILI',     jJson:GetJsonObject('familia'),   Nil})
                aAdd(aDados, {'B1_PESO',        jJson:GetJsonObject('peso_liquido'),   Nil})
                aAdd(aDados, {'B1_PESBRU',      jJson:GetJsonObject('peso_bruto'),   Nil})
		         
		         //Percorre os dados do execauto
		         For nCampo := 1 To Len(aDados)
		         	//Se o campo for data, retira os hifens e faz a conversão
		         	If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
		         		aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
		         		aDados[nCampo][2] := sToD(aDados[nCampo][2])
		         	EndIf
		         Next

		         //Chama a exclusão automática
		         MsExecAuto({|x, y| MATA010(x, y)}, aDados, 5)

		         //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
		         If lMsErroAuto
		         	//Monta o texto do Error Log que será salvo
		         	cErrorLog   := ''
		         	aLogAuto    := GetAutoGrLog()
		         	For nLinha := 1 To Len(aLogAuto)
		         		cErrorLog += aLogAuto[nLinha] + CRLF
		         	Next nLinha

		            //Grava o arquivo de log
		            cArqLog := 'zWsProduto_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
		            MemoWrite(cDirLog + cArqLog, cErrorLog)

		            //Define o retorno para o WebService
		            //SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
		            Self:setStatus(500) 
		            jResponse['errorId']  := 'DEL013'
		            jResponse['error']    := 'Erro na exclusão do registro'
		            jResponse['solution'] := 'Nao foi possivel excluir o registro: ' + cErrorLog + ' ' + CRLF
		            jResponse['solution'] += 'Foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
		            lRet := .F.

		         //Senão, define o retorno
		         Else
                    jResponse['note']     := 'Registro excluido com sucesso'
		         EndIf

		     EndIf
		 EndIf
    EndIf

    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
