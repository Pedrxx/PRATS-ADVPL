//Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"
#Include "TopConn.ch"
#Include 'FWMVCDef.ch'


// http://10.1.1.70:8099/rest

/*/{Protheus.doc} WSRESTFUL zWsMNT
WS SIGAMNT Protheus
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
/*/

WSRESTFUL zWsMNT DESCRIPTION 'WS Manuten��o de Ativos'
    //Atributos
    WSDATA id         AS STRING
    WSDATA armazem    AS STRING
    WSDATA cod_inicio AS STRING
    WSDATA cod_fim    AS STRING
    WSDATA operac     AS INTEGER

    //M�todos
    WSMETHOD GET    ID     DESCRIPTION 'Retorna o registro pesquisado' WSSYNTAX '/zWsMNT/get_id?{operac,id}'                    PATH 'get_id'        PRODUCES APPLICATION_JSON
    WSMETHOD GET    ALL    DESCRIPTION 'Retorna todos os registros'    WSSYNTAX '/zWsMNT/get_all?{operac,cod_inicio,cod_fim}'   PATH 'get_all'       PRODUCES APPLICATION_JSON
    WSMETHOD POST   NEW    DESCRIPTION 'Inclus�o de registro'          WSSYNTAX '/zWsMNT/post'                                  PATH 'post'          PRODUCES APPLICATION_JSON
    WSMETHOD PUT    UPDATE DESCRIPTION 'Atualiza��o de registro'       WSSYNTAX '/zWsMNT/put'                                   PATH 'put'           PRODUCES APPLICATION_JSON
    WSMETHOD DELETE ERASE  DESCRIPTION 'Exclus�o de registro'          WSSYNTAX '/zWsMNT/delete'                                PATH 'delete'        PRODUCES APPLICATION_JSON
END WSRESTFUL

/*/{Protheus.doc} WSMETHOD GET ID
Busca registro via ID
@author PEDRO AUGUSTO BRAGHETO DA COSTA
@since 11/08/2023
@version 1.0
@param id, Caractere, String que ser� pesquisada atrav�s do MsSeek
/*/

WSMETHOD GET ID WSRECEIVE id, operac WSSERVICE zWsMNT
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cAliasWS   := ''

    If (Empty(::operac))
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID001'
            jResponse['error']    := 'Opera��o n�o informada'
            jResponse['solution'] := 'Informe a opera��o'
    ElseIf (::operac == 1)
        cAliasWs := 'ST9'
        //Se o id estiver vazio
        If Empty(::id)
            //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID002'
            jResponse['error']    := 'Cod. Bem vazio'
            jResponse['solution'] := 'Informe o Bem'
    
        Else
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbSetOrder(1))

            //Se n�o encontrar o registro
            If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
                //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
                Self:setStatus(500) 
                jResponse['errorId']  := 'ID003'
                jResponse['error']    := 'Bem n�o encontrado'
                jResponse['solution'] := 'C�digo do bem n�o encontrado na tabela ' + cAliasWS
            Else
                //Define o retorno
                jResponse['codigo_bem'] := AllTrim((cAliasWS)->T9_CODBEM)
                jResponse['codigo_familia'] := (cAliasWS)->T9_CODFAMI
                jResponse['desc_bem'] := AllTrim((cAliasWS)->T9_NOME)
                jResponse['centrocusto'] := AllTrim((cAliasWS)->T9_CCUSTO)
                jResponse['turno'] := (cAliasWS)->T9_CALENDA
            EndIf
        EndIf
    Elseif(::operac == 2) 
        cAliasWs = 'STI'

        If(Empty(::id))
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID004'
            jResponse['error']    := 'Plano vazio'
            jResponse['solution'] := 'Informe o plano de manuten��o'
        Else
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbSetOrder(1))

            If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
                Self:setStatus(500) 
                jResponse['errorId']  := 'ID005'
                jResponse['error']    := 'Plano n�o encontrado'
                jResponse['solution'] := 'C�digo do plano de manut. n�o encontrado na tabela ' + cAliasWS
            Else
                jResponse['plano'] := (cAliasWS)->TI_PLANO
                jResponse['data_plano'] := Day2Str((cAliasWS)->TI_DATAPLA) + '-' + Month2Str((cAliasWS)->TI_DATAPLA) + '-' + Year2Str((cAliasWS)->TI_DATAPLA) 
                jResponse['descricao'] := (cAliasWS)->TI_DESCRIC
                jResponse['data_inicio'] := Day2Str((cAliasWS)->TI_DATAINI) + '-' + Month2Str((cAliasWS)->TI_DATAINI) + '-' + Year2Str((cAliasWS)->TI_DATAINI) 
                jResponse['data_fim'] := Day2Str((cAliasWS)->TI_DATAFIM) + '-' + Month2Str((cAliasWS)->TI_DATAFIM) + '-' + Year2Str((cAliasWS)->TI_DATAFIM) 
            EndIf
        EndIf
    ElseIf (::operac == 3)
        cAliasWS = 'SB2'

        If(Empty(::id))
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID006'
            jResponse['error']    := 'Cod. Produto vazio'
            jResponse['solution'] := 'Informe o Cod. Produto'
        Else
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbSetOrder(1))

            cAliasSB1 := 'SB1'
            DbSelectArea(cAliasSB1)
            (cAliasSB1)->(DbSetOrder(1))
            (cAliasSB1)->(MsSeek(FWxFilial(cAliasSB1) + ::id))    

            If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id + (cAliasSB1)->B1_LOCPAD))
                Self:setStatus(500) 
                jResponse['errorId']  := 'ID007'
                jResponse['error']    := 'Cod. Produto n�o encontrado'
                jResponse['solution'] := 'Verifique o Cod. Produto'
            Else
                jResponse['cod_produto']  := (cAliasWS)->B2_COD
                jResponse['desc_produto']  := AllTrim((cAliasSB1)->B1_DESC)
                jResponse['qtd_disponivel']  := SaldoSB2()    
            EndIf
        EndIf
    EndIF

    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet


WSMETHOD POST NEW WSRECEIVE operac WSSERVICE zWsMNT
    Local lRet              := .T.
    // Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := 'C:/temp/'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    // Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := ''
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
 
    //Se n�o existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    

    //Definindo o conte�do como JSON, e pegando o content e dando um parse para ver se a estrutura est� ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)

    If (!Empty(::operac))
        //Se tiver algum erro no Parse, encerra a execu��o
        IF ! Empty(cError)
            //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'NEW002'
            jResponse['error']    := 'Parse do JSON'
            jResponse['solution'] := 'Erro ao fazer o Parse do JSON'

        Else
            If (::operac == 1)
                cAliasWS := "ST9"
                DbSelectArea(cAliasWS)

                oModel := FWLoadModel("MNTA080")
                oModel:SetOperation(3)
                oModel:Activate()

                aAdd(aDados, {'T9_CODBEM',        jJson:GetJsonObject('cod_bem'),   Nil})
                aAdd(aDados, {'T9_CODFAMI',       jJson:GetJsonObject('cod_familia'),   Nil})
                aAdd(aDados, {'T9_CCUSTO',        jJson:GetJsonObject('ccusto'),   Nil})
                aAdd(aDados, {'T9_CALENDA',       jJson:GetJsonObject('turno'),   Nil})


                oST9Mod := oModel:GetModel("ST9MASTER")
                //Adiciona os dados do ExecAuto
                oST9Mod:SetValue('T9_CODBEM' ,      ) /*THREAD ERROR ([4896], TP|HTTPREST|HTTPURI@10?101010|FALSE, 0842A0227F71AC4D93AAD488DC434064)   28/08/2023 08:50:27 variable is not an object  on REST_ZWSMNT:POST_NEW(ZWSSIGAMNT.PRW) 22/08/2023 10:01:17 line : 190*/
                oST9Mod:SetValue('T9_CODFAMI',      )
                oST9Mod:SetValue('T9_CCUSTO' ,      )
                oST9Mod:SetValue('T9_CALENDA',      )

                //Se conseguir validar as informa��es
                If oModel:VldData()
                    //Tenta realizar o Commit
                    If oModel:CommitData()
                        lMsErroAuto := .F.
                    //Se n�o deu certo, altera a vari�vel para false
                    Else
                        lMsErroAuto := .T.
                    EndIf
                //Se n�o conseguir validar as informa��es, altera a vari�vel para false
                Else
                    lMsErroAuto := .T.
                EndIf
            EndIF
            //Se houve erro, gera um arquivo de log dentro do diret�rio da protheus data
            If lMsErroAuto
                //Monta o texto do Error Log que ser� salvo
                cErrorLog   := ''
                aLogAuto    := GetAutoGrLog()
                For nLinha := 1 To Len(aLogAuto)
                    cErrorLog += aLogAuto[nLinha] + CRLF
                Next nLinha

                //Grava o arquivo de log
                cArqLog := 'zWsMNT_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
                MemoWrite(cDirLog + cArqLog, cErrorLog)

                //Define o retorno para o WebService
                //SetRestFault(500, cErrorLog) //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
            Self:setStatus(500) 
                jResponse['errorId']  := 'NEW003'
                jResponse['error']    := 'Erro na inclus�o do registro'
                jResponse['solution'] := 'Nao foi possivel incluir o registro: ' + cErrorLog + ' '
                jResponse['solution'] := 'Foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
                lRet := .F.
            //Sen�o, define o retorno
            Else
                jResponse['note'] := 'Registro incluido com sucesso'
            EndIf

        EndIf
    Else
        Self:setStatus(500) 
        jResponse['errorId']  := 'NEW001'
        jResponse['error']    := 'Opera��o n�o informada'
        jResponse['solution'] := 'Informe a opera��o'
    EndIf
    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
