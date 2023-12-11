#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE 'RESTFUL.CH'
#INCLUDE 'XMLXFUN.CH'
#INCLUDE "TBICONN.CH"

User Function PRWSEST1()

    local cURL as char
    local cHeadRet as char
    local i
    local _cMsgBody
    local _cBodyMail 
    cHeadRet    := ""
    nTimeOut    := 15
    aChildren := {} 

    If Select("SX2") == 0
        Prepare Environment Empresa '10' Filial '101010' 
    EndIf

    cURL := GETMV("PR_BMBCONS") + GETMV("PR_BMBTKN") + "&tipo_produto=0"
    cNumDoc := GetSxeNum("SD3","D3_DOC")
    cGetRet := HTTPSGet( cURL, "", "", "", "", 15,/*aHeadOut*/,@cHeadRet)


    If !Empty( cGetRet )

        oXML := TXMLManager():New()
        oXML:Parse(cGetRet)
        If Empty(cErro := oXml:Error())

            cCountArray := oXML:XPathChildCount( "/CTAPLUS/ABASTECIMENTOS" )
            _cBodyMail := ""

            If cCountArray > 0
                For i := 1 to cCountArray
                    aChildren := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]" )
                    aChildrenVeic := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]/VEICULO" )
                    aChildrenProd := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]/COMBUSTIVEL" )


                    VARINFO("aChildren", aChildren)
                    VARINFO("aChildrenVeic", aChildrenVeic)

                    _cMsgBody := PRTMOVIN("101010","501",cNumDoc,STRZERO(RANDOMIZE( 1, 99999 ),5),CToD(aChildren[3][3]),,VAL(StrTran(aChildren[7][3],",",".")),aChildrenProd[1][3],"01",,,aChildren[1][3],aChildrenVeic[2][3])
                    
                    If _cMsgBody == Nil .OR. _cMsgBody == ""
                        _cBodyMail += fMontaLog(aChildren[1][3],"Registro incluido com sucesso",aChildrenVeic[2][3],aChildren[3][3])
                    Else
                        _cBodyMail += fMontaLog(aChildren[1][3],_cMsgBody,aChildrenVeic[2][3],aChildren[3][3])
                    EndIf

                    If aChildrenVeic[2][3] == GETMV("PR_PLCCAL")
                        PRTMOVIN("101010","020",cNumDoc,STRZERO(RANDOMIZE( 1, 99999 ),5),CToD(aChildren[3][3]),,VAL(StrTran(aChildren[7][3],",",".")),aChildrenProd[1][3],"01",,,aChildren[1][3],aChildrenVeic[2][3])
                    EndIf
                Next

                zEnviaEmail(_cBodyMail)
            Else
                zEnviaEmail(fMontaLog("XXXXXX","Não existem registros a serem integrados","XXXXXX"))

            EndIF
        Endif

    Endif

    RESET ENVIRONMENT 
Return 

Static Function PRTMOVIN(_cFilial, cCodTM, _cDocumento, _cSeqSD3, _dData, _cOP, _nQtdO, _cCodProF, _cLocalO, _cEndO, _cLoteO, _cIdAbst, _cPlaca)
    Local _aArea		:= GetArea()

    Local _aCabSD3 		:= {}
    Local _aItSD3 		:= {}
    Local _aTotItem		:= {}

    Local _cRet         := ""
    // Local _cErro 		:= ""
    Local cModAtu       := cModulo
    Local nModAtu       := nModulo
    Local BkpDbase		:= dDataBase
    Local cFunBkp 		:= FunName()

    //->Origem 
    Local _cUM1ProO		:= ""
    Local _cUM2ProO		:= ""
    Local _cTpConvO		:= ""
    Local _nConverO		:= 0
    Local _lLocalizO    := .F.

    Local _cCodProP

    Local nTipoCusto	:= 2 //-> 1-Custo Standard;2-Custo Medio;3-Preco Compra
    Local _nCusto		:= 0
    Local _lDebVal		:= .F.
    Local _nCusOri		:= 0
    Local _nCusDes		:= 0
    // Local cPath         := AllTrim(GetTempPath())
    // Local _cTmpPath	    := GetNewPar("PR_FIN1PT","C:\TEMP\")
    Local _lCustoFixo	:= GetNewPar("PR_PCP23C0",.T.) //->Custo Zero

    Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help
    Private lMsErroAuto := .f. //necessario a criacao

    DEFAULT _cOP := ""
    DEFAULT _cLoteO := ""
    DEFAULT _cEndO := ""
    DEFAULT _cCodForn:= "15001448"
    DEFAULT _cCodLoja := "0001"


    // If !ExistDir(cPath)
    //     MakeDir(cPath)
    //     If !ExistDir(cPath)
    //         RestArea(_aArea)
    //         Return('PRTMOVIN_ERR_023-Pasta Padrao ' + cPath + ' nao existe.' + " [PRTMOVIN]")
    //     Endif
    // EndIf

    // If !ExistDir(_cTmpPath)
    //     MakeDir(_cTmpPath)
    //     If !ExistDir(_cTmpPath)
    //         RestArea(_aArea)
    //         Return('PRTMOVIN_ERR_024-Pasta Padrao ' + _cTmpPath + ' nao existe.' + " [PRTMOVIN]")
    //     Endif
    // EndIf

    _cLogErro:= 'Operação: Movimentação Interna'


    If _nQtdO == 0
        // DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_001-Qtd. Original Zerada.[" + 'Movimentação Interna') + ']'
    Endif

    SD3->(dbSetOrder(19))
    If cCodTM == '501'
        If SD3->(dbSeek(xFilial('SD3') + _cIdAbst))
            // DisarmTransaction()
            RestArea(_aArea)
            Return("PRTMOVIN_ERR_002-Abastecimento ja incluso[" + 'Movimentação Interna') + ']'
        EndIf
    EndIf

    DA3->(DbSetOrder(3))
    If DA3->(DbSeek(xFilial("DA3") + _cPlaca))
        CTT->(DbSetOrder(1))
        If !CTT->(DbSeek(xFilial("CTT") + DA3->DA3_XCC))
            // DisarmTransaction()
            RestArea(_aArea)
            Return("PRTMOVIN_ERR_003- Centro de Custos Não Encontrado.[" + 'Movimentação Interna') + ']'
        Else
            _cCC := CTT->CTT_CUSTO
        EndIf
    Else
        // DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_004- Veiculo Não Encontrado.[" + 'Movimentação Interna') + ']'
    EndIf

    SA5->(dbSetOrder(14))
    If SA5->(dbSeek(xFilial('SA5') + _cCodForn + _cCodLoja + _cCodProF))

        _cCodProP := SA5->A5_PRODUTO
    Else
        // DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_005-Produto x Forencedor Não Encontrado.[" + 'Movimentação Interna') + ']'
    EndIf

    SB1->(dbSetOrder(1))
    If !SB1->(dbSeek(xFilial("SB1") + _cCodProP))
        // DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_006-Produto de Origem Não Encontrado.[" + 'Movimentação Interna') + ']'
    Else
        If SB1->B1_LOCALIZ == 'S'
            _lLocalizO:=.T.
            //->Cria Saldo de Endereço de Origem
            SBF->(dbSetOrder(1)) //->BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
            If !SBF->(dbSeek( xFilial("SBF") + _cLocalO + Padr(_cEndO,TamSx3("BF_LOCALIZ")[1]) + _cCodProF))
                U_VTFUNCSE(_cLocalO, Padr(_cEndO,TamSx3("BF_LOCALIZ")[1]), _cCodProF, "", 0 )
            EndIf
        Endif
        _cUM1ProO	:= SB1->B1_UM
        _cUM2ProO	:= SB1->B1_SEGUM
        _cTpConvO	:= SB1->B1_TIPCONV
        _nConverO	:= SB1->B1_CONV
        If nTipoCusto == 1 //-> 1-Custo Standard;2-Custo Medio;3-Preco Compra
            _nCusto := RetFldProd(SB1->B1_COD,"B1_CUSTD")
            cStr:="1"
        ElseIf nTipoCusto == 2 //-> 1-Custo Standard;2-Custo Medio;3-Preco Compra
            _nCusto := PegaCmAtu(SB1->B1_COD, RetFldProd(SB1->B1_COD,"B1_LOCPAD"))[1]
            cStr:="2"
        ElseIf nTipoCusto == 3 //-> 1-Custo Standard;2-Custo Medio;3-Preco Compra
            _nCusto := RetFldProd(SB1->B1_COD,"B1_UPRC")
            cStr:="3"
        EndIf
    Endif

    //->Cria Armazén de Origem
    SB2->(dbSetOrder(1))
    If !SB2->(dbSeek(cFilAnt + _cCodProP + _cLocalO))
        CriaSB2(_cCodProP,_cLocalO)
    Endif

    If _lLocalizO	
        //->Saldos endereço de destino
        SBF->(dbSetOrder(1)) //->BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
        If !SBF->(dbSeek( xFilial("SBF") + _cLocalO + Padr(_cEndO,TamSx3("BF_LOCALIZ")[1]) + _cCodProF))
            // DisarmTransaction()
            RestArea(_aArea)
            Return("PRTMOVIN_ERR_007-Sld. de End. Nao Encontrado.[" + 'Movimentação Interna') + ']'
        EndIf
    Endif

    SF5->(dbSetOrder(1))
    If SF5->(dbSeek(xFilial("SF5") + cCodTM))
        If SF5->F5_VAL == 'S'
            _lDebVal:=.T.
        Endif
    Endif

    //Custo//
    If _lCustoFixo
        _nCusOri:= 0.000001 //->Custo de Origem
    Else
        _nCusOri:= _nCusto * _nQtdO //->Custo de Origem
    Endif
    _nCusDes:= _nCusOri //->Custo de Destino
    _aCabSD3	:= {}
    _aTotItem	:= {}
    _aItSD3		:= {}

    _aCabSD3 := {{"D3_DOC" ,_cDocumento, NIL},;
        {"D3_TM" ,cCodTM , NIL},;
        {"D3_CC" ,_cCC, NIL},;
        {"D3_OP" ,_cOP, NIL},;
        {"D3_EMISSAO" ,_dData, NIL}}
    If _lDebVal //->Lançamento Valorizado
        _aItSD3:={{"D3_COD" ,_cCodProP ,NIL},;
            {"D3_UM" ,_cUM1ProO ,NIL},; 
            {"D3_QUANT" ,_nQtdO ,NIL},;
            {"D3_LOCAL" ,_cLocalO ,NIL},;
            {"D3_CUSTO1" ,_nCusOri,NIL},;
            {"D3_LOTECTL" ,_cLoteO,NIL},;
            {"D3_LOCALIZ" , _cEndO,NIL}}
    Else
        _aItSD3:={{"D3_COD" ,_cCodProP ,NIL},;
            {"D3_UM" ,_cUM1ProO ,NIL},; 
            {"D3_QUANT" ,_nQtdO ,NIL},;
            {"D3_LOCAL" ,_cLocalO ,NIL},;
            {"D3_XIDABST", _cIdAbst, NIL}}
    Endif

    aadd(_aTotItem,_aItSD3)

    cModulo := "PCP"
    nModulo := 10
    SBE->(dbSetOrder(1))
    MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCabSD3,_aTotItem,3)
    cModulo := cModAtu
    nModulo := nModAtu
    dDataBase:=BkpDbase
    SetFunName(cFunBkp)

    If lMsErroAuto 
        _cErro := MostraErro("\prats_log\", 'ERROX.LOG')
        PostSSL(CriaXMLRet(_cIdAbst,.F.))
    else
        PostSSL(CriaXMLRet(_cIdAbst,.T.))
    Endif

RestArea(_aArea)
Return(_cRet)

Static Function CriaXMLRet(_cID,_lSync) 

    local _cXML

    If _lSync := .T.
        _cXML := "%3CABASTECIMENTOS%3E%20%0A%3CABASTECIMENTO%3E%0A%3CID%3E"+_cID
        _cXML += "%3C%2FID%3E%0A%3CSTATUS%3ESucesso%3C%2FSTATUS%3E%0A
        _cXML += "%3CMOTIVO_ERRO%3EInserido%20com%20sucesso%3C%2FMOTIVO_ERRO%3E
        _cXML += "%0A%3C%2FABASTECIMENTO%3E%0A%3C%2FABASTECIMENTOS%3E"
    Else
        _cXML := "%3CABASTECIMENTOS%3E%20%0A%3CABASTECIMENTO%3E%0A%3CID%3E"+_cID
        _cXML += "%3C%2FID%3E%0A%3CSTATUS%3EErro%3C%2FSTATUS%3E%0A
        _cXML += "%3CMOTIVO_ERRO%3ENao%20inserido%3C%2FMOTIVO_ERRO%3E%0A%3C%2FABASTECIMENTO%3E%0A%"
        _cXML += "3C%2FABASTECIMENTOS%3E
    EndIf
    
Return _cXML 


static function PostSSL(_cXML)
  Local nTimeOut := 120
  Local aHeadOut := {}
  Local cHeadRet := ""
  Local cPostRet := ""  
  Local _cURL    

  _cURL  := GETMV("PR_BMBENV") + GETMV("PR_BMBTKN") +"&xml=" + _cXML + "&formato=xml"


  AAdd( aHeadOut, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')' )
  cPostRet := HTTPSPost( _cUrl, "","","","","", nTimeOut, aHeadOut, @cHeadRet )
   
  if !Empty( cPostRet )
    varinfo( "WebPage", cPostRet )
  endif
   
  varinfo( "Header", cHeadRet )
return


Static Function zEnviaEmail(cLog) 
    cTitulo := 'Integração de Abastecimentos'
    cRemet  := "WorkFlow <workflow@prats.com.br>"
    cDestino:= GETMV("PR_BMBMAIL")
    cBody   := fEmailBody(cLog)
    cCopia  := GetNewPar("PR_EST05EC","")
    cCopia  := Replace(cCopia, " ", "")
    cDestino:= Replace(cDestino, " ", "")
    cTitulo := "[101010-Fabrica]Log de Integração Abastecimento"
    _aAttach := {}

    U_PRTCFG04(cDestino,cCopia,cTitulo,cBody,_aAttach)
Return 

Static Function fMontaLog(_cId,_cMsg,_cPlaca,_dData) 

    Local _cLog := ""
    _cLog += '<tr bgcolor="#c6f7c3">'
    _cLog += '<td style="width: 11.19%;" width="10%"><span style="font-family: Arial; font-size: xx-small;">'+_cId+'</span></td>'
    _cLog += '<td style="width: 7.34789%;"><span style="font-family: Arial; font-size: xx-small;">'+_cPlaca+'</span></td>'
    _cLog += '<td style="width: 71.4621%;" width="80%"><span style="font-family: Arial; font-size: xx-small;">'+_cMsg+'</td>'
    _cLog += '<td style="width: 10%;" align="CENTER" width="10%"><span style="color: #000000; font-family: Arial; font-size: xx-small;">'+_dData+'</span></td>'
    _cLog += '</tr>'
    
Return _cLog

Static Function fEmailBody(_cLog) 
    Local cRet := ""	
    
    cRet += '<!DOCTYPE html>'
    cRet += '<html>'
    cRet += '<head>'
    cRet += '</head>'
    cRet += '<body>'
    cRet += '<div id="message-content">'
    cRet += '<div class="leftcol" role="region" aria-labelledby="aria-label-messageattachments">'
    cRet += '<h2 id="aria-label-messageattachments" class="voice">Integra&ccedil;&atilde;o de Abastecimentos</h2>'
    cRet += '</div>'
    cRet += '<div class="rightcol" role="region" aria-labelledby="aria-label-messagebody">'
    cRet += '<div id="messagebody">'
    cRet += '<div id="message-htmlpart1" class="message-htmlpart"><!-- html ignored --><!-- head ignored --><!-- meta ignored -->'
    cRet += '<div class="rcmBody">'
    cRet += '<p align="left">Prats - WebService de Integra&ccedil;&atilde;o de Abastecimentos</p>'
    cRet += '<table border="0" width="100%" cellspacing="0" cellpadding="0">'
    cRet += '<tbody>'
    cRet += '<tr>'
    cRet += '<td width="100%">'
    cRet += '<table border="1" width="100%" cellspacing="0" cellpadding="0">'
    cRet += '<tbody>'
    cRet += '<tr>'
    cRet += '<td bgcolor="#2aba1a" width="100%">'
    cRet += '<p align="center"><strong><span style="font-family: Arial;">Log de Integra&ccedil;&atilde;o de Abastecimentos</span></strong></p>'
    cRet += '</td>'
    cRet += '</tr>'
    cRet += '</tbody>'
    cRet += '</table>'
    cRet += '</td>'
    cRet += '</tr>'
    cRet += '</tbody>'
    cRet += '</table>'
    cRet += '<p align="left">&nbsp;</p>'
    cRet += '<hr />'
    cRet += '<table border="1" width="100%" cellspacing="0" cellpadding="0">'
    cRet += '<tbody>'
    cRet += '<tr>'
    cRet += '<td bgcolor="#18b549" width="100%">'
    cRet += '<p align="center"><strong><span style="color: #ffffff; font-family: Arial; font-size: large;">Lista de Registros Processados</span></strong></p>'
    cRet += '</td>'
    cRet += '</tr>'
    cRet += '</tbody>'
    cRet += '</table>'
    cRet += '<table style="width: 100%;" border="0" width="100%" cellspacing="1" cellpadding="1">'
    cRet += '<tbody>'
    cRet += '<tr bgcolor="#18b549">'
    cRet += '<td style="width: 11.1871%;" width="10%"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Id</span></td>'
    cRet += '<td style="width: 7.33759%;"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Placa</span></td>'
    cRet += '<td style="width: 71.3845%;" width="80%"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Log</span></td>'
    cRet += '<td style="width: 10.7471%;" width="10%"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Data</span></td>'
    cRet += '</tr>'
    cRet += '</tbody>'
    cRet += '</table>'
    cRet += '<table style="width: 100%;" border="0" width="100%" cellspacing="1" cellpadding="1">'
    cRet += '<tbody>'
    cRet += _cLog
    cRet += '</tbody>'
    cRet += '</table>'
    cRet += '</div>'
    cRet += '</div>'
    cRet += '<div class="message-htmlpart">&nbsp;</div>'
    cRet += '<div class="message-htmlpart"><span style="font-family: Arial; font-size: small;"><br /></span><span style="font-family: Arial; font-size: xx-small;">Qualquer duvida entrar em contato no telefone (44) 99982-8795 ou e-mail erp@prats.com.br<br /></span><span style="font-family: Arial; font-size: xx-small;">Caso necessite pode abrir um chamado no sistema de Gestao de Tickts da Prats.</span><br /><!-- hb ignored --><span style="font-family: Arial; font-size: xx-small;">Fonte: PRWSEST1 </span></div>'
    cRet += '</div>'
    cRet += '</div>'
    cRet += '</div>'
    cRet += '</body>'
    cRet += '</html>'

Return(cRet)

