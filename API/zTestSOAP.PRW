#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE 'RESTFUL.CH'
#INCLUDE 'XMLXFUN.CH'

User Function zTestSOAP()

    local cURL as char
    local cHeadRet as char
    local i
    cHeadRet    := ""
    // cURL        := "http://ctasmart.com.br:8080/SvWebSincronizaAbastecimentos?token=we1jyKpEle&data_inicio=22/05/2023&data_fim=22/05/2023"
    cURL      := "http://ctasmart.com.br:8080/SvWebSincronizaAbastecimentos?token=Y9vY5Sv51d&data_inicio=01/01/2012&data_fim=09/04/2012"
    nTimeOut    := 15
    aChildren := {} 
    cNumDoc := GetSxeNum("SD3","D3_DOC")

    cGetRet := HTTPSGet( cURL, "", "", "", "", 15,/*aHeadOut*/,@cHeadRet)

    If !Empty( cGetRet )
        oXML := TXMLManager():New()
        oXML:Parse(cGetRet)
        If Empty(cErro := oXml:Error())

            Alert(cCountArray := oXML:XPathChildCount( "/CTAPLUS/ABASTECIMENTOS" ))

            For i := 1 to cCountArray
                aChildren := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]" )
                aChildrenVeic := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]/VEICULO" )

                VARINFO("aChildren", aChildren)
                VARINFO("aChildrenVeic", aChildrenVeic)

                Alert(aChildren[1][3])
                Alert(PRTMOVIN("101010","501",cNumDoc,STRZERO(RANDOMIZE( 1, 99999 ),5),CToD(aChildren[3][3]),,VAL(StrTran(aChildren[7][3],",",".")),aChildren[19][3],"05",,,aChildren[1][3],aChildrenVeic[2][3]))
                
                // Alert("Inseri "+ CVALTOCHAR( i ))
            Next
        Endif     
    Endif


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
Local cPath         := AllTrim(GetTempPath())
Local _cTmpPath	    := GetNewPar("PR_FIN1PT","C:\TEMP\")
Local _lCustoFixo	:= GetNewPar("PR_PCP23C0",.T.) //->Custo Zero

Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help
Private lMsErroAuto := .f. //necessario a criacao

DEFAULT _cOP := ""
DEFAULT _cLoteO := ""
DEFAULT _cEndO := ""
DEFAULT _cCodForn:= "15001448"
DEFAULT _cCodLoja := "0001"


If !ExistDir(cPath)
	MakeDir(cPath)
	If !ExistDir(cPath)
        RestArea(_aArea)
        Return('PRTMOVIN_ERR_023-Pasta Padrao ' + cPath + ' nao existe.' + " [PRTMOVIN]")
	Endif
EndIf

If !ExistDir(_cTmpPath)
	MakeDir(_cTmpPath)
	If !ExistDir(_cTmpPath)
        RestArea(_aArea)
        Return('PRTMOVIN_ERR_024-Pasta Padrao ' + _cTmpPath + ' nao existe.' + " [PRTMOVIN]")
	Endif
EndIf

_cLogErro:= 'Operação: Movimentação Interna'

//->Cria Armazén de Origem
SB2->(dbSetOrder(1))
If !SB2->(dbSeek(cFilAnt + _cCodProF + _cLocalO))
    CriaSB2(_cCodProF,_cLocalO)
Endif

Begin Transaction
    If _nQtdO == 0
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_001-Qtd. Original Zerada.[" + 'Movimentação Interna') + ']'
    Endif

    SD3->(dbSetOrder(19))
    If SD3->(dbSeek(xFilial('SD3') + _cIdAbst))
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_002-Abastecimento ja incluso[" + 'Movimentação Interna') + ']'
    //     Alert("ID Abastecimento: " + SD3->D3_XIDABST)
    // Else
    //     Alert("Não achei ")
    EndIf

    DA3->(DbSetOrder(3))
    If DA3->(DbSeek(xFilial("DA3") + _cPlaca))
        CTT->(DbSetOrder(1))
        If !CTT->(DbSeek(xFilial("CTT") + DA3->DA3_XCC))
            DisarmTransaction()
            RestArea(_aArea)
            Return("PRTMOVIN_ERR_003- Centro de Custos Não Encontrado.[" + 'Movimentação Interna') + ']'
        Else
            _cCC := CTT->CTT_CUSTO
        EndIf
    Else
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_004- Veiculo Não Encontrado.[" + 'Movimentação Interna') + ']'
    EndIf

    SA5->(dbSetOrder(14))
    If SA5->(dbSeek(xFilial('SA5') + _cCodForn + _cCodLoja + _cCodProF))

        _cCodProP := SA5->A5_PRODUTO
    Else
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_005-Produto x Forencedor Não Encontrado.[" + 'Movimentação Interna') + ']'
    EndIf

    SB1->(dbSetOrder(1))
    If !SB1->(dbSeek(xFilial("SB1") + _cCodProF))
        DisarmTransaction()
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

    If _lLocalizO	
        //->Saldos endereço de destino
        SBF->(dbSetOrder(1)) //->BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
        If !SBF->(dbSeek( xFilial("SBF") + _cLocalO + Padr(_cEndO,TamSx3("BF_LOCALIZ")[1]) + _cCodProF))
            DisarmTransaction()
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
            {"D3_OSTEC" ,'TP' + _cSeqSD3  , NIL},;
            {"D3_LOCAL" ,_cLocalO ,NIL},;
            {"D3_CUSTO1" ,_nCusOri,NIL},;
            {"D3_LOTECTL" ,_cLoteO,NIL},;
            {"D3_LOCALIZ" , _cEndO,NIL}}
    Else
        _aItSD3:={{"D3_COD" ,_cCodProP ,NIL},;
            {"D3_UM" ,_cUM1ProO ,NIL},; 
            {"D3_QUANT" ,_nQtdO ,NIL},;
            {"D3_OSTEC" ,'TP' + _cSeqSD3  , NIL},;
            {"D3_LOCAL" ,_cLocalO ,NIL},;
            {"D3_LOTECTL" ,_cLoteO,NIL},;
            {"D3_LOCALIZ" , _cEndO,NIL},;
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
        PostSSL(CriaXMLRet(_cIdAbst,.F.))
        mostraerro(_cUrl)
    else
        PostSSL(CriaXMLRet(_cIdAbst,.T.))
    Endif

End Transaction
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
//   Local _cPostParams 
  Local _cURL    
   
  // Acrescenta o UserAgent na requisição ...
  // http://tools.ietf.org/html/rfc3261#page-179

  _cURL  := "https://ctasmart.com.br:8443/SvWebInformaSincronismo?token=Y9vY5Sv51d&xml=" + _cXML + "&formato=xml"

//   _cPostParams := "&formato=xml"

  AAdd( aHeadOut, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')' )
  cPostRet := HTTPSPost( _cUrl, "","","","","", nTimeOut, aHeadOut, @cHeadRet )
   
  if Empty( cPostRet )
    Alert( "Fail HTTPSPost" )
  else
    Alert( "OK HTTPSPost" )
    varinfo( "WebPage", cPostRet )
  endif
   
  varinfo( "Header", cHeadRet )
return
