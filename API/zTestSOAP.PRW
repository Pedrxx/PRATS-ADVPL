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
    cURL        := "http://ctasmart.com.br:8080/SvWebSincronizaAbastecimentos?token=Y9vY5Sv51d&data_inicio=01/01/2012&data_fim=01/01/2012"
    nTimeOut    := 15
    aChildren := {} 
    cNumDoc := GetSxeNum("SD3","D3_DOC")

    cGetRet := HTTPSGet( cURL, "", "", "", "", 15,/*aHeadOut*/,@cHeadRet)
    // Alert(cGetRet)

    If !Empty( cGetRet )
        oXML := TXMLManager():New()
        oXML:Parse(cGetRet)
        If Empty(cErro := oXml:Error())

            Alert(cCountArray := oXML:XPathChildCount( "/CTAPLUS/ABASTECIMENTOS" ))

            For i := 1 to cCountArray
                aChildren := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO["+CVALTOCHAR(i)+"]" )
                VARINFO("aChildren", aChildren)
                Alert(aChildren[1][3])
                Alert(PRTMOVIN("101010","501",cNumDoc,STRZERO(RANDOMIZE( 1, 99999 ),5),/*CToD(aChildren[3][3])*/dDataBase,,VAL(StrTran(aChildren[7][3],",",".")),aChildren[19][3],"05",,,"130110",aChildren[1][3]))
                Alert("Inseri "+ CVALTOCHAR( i ))
            Next
        Endif     
    Endif


Return 


/*
D3_FILIAL = 101010
D3_TM = 501
D3_COD = 1041.123.000001 OU 1041.123.000002 -> aChildren[19][3]
D3_UM = LT
D3_QUANT = aChildren[7][3]
D3_CF = RE0 
D3_CONTA = 1108001007          
D3_LOCAL = 01 
D3_DOC = !AUTO!
D3_EMISSAO -> aChildren[3][3]
D3_CC = !PLACA!
D3_NUMSEQ = !AUTO!
D3_OBSERVA = MOTORISTA + PLACA + HORA_INICIO + HORA_FIM
*/


Static Function PRTMOVIN(_cFilial, cCodTM, _cDocumento, _cSeqSD3, _dData, _cOP, _nQtdO, _cCodProF, _cLocalO, _cEndO, _cLoteO, _cCC, _cIdAbst)
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
        Return("PRTMOVIN_ERR_004-Qtd. Original Zerada.[" + 'Movimentação Interna') + ']'
    Endif

    // SD3->(dbSetOrder(19))
    // If SD3->(dbSeek(xFilial('SD3') + _cIdAbst))
    //     DisarmTransaction()
    //     RestArea(_aArea)
    //     Return("PRTMOVIN_ERR_002-Abastecimento ja incluso[" + 'Movimentação Interna') + ']'
    //     Alert("ID Abastecimento: " + SD3->D3_XIDABST)
    // Else
    //     Alert("Não achei | "+ SD3->D3_XIDABST)
    // EndIf

    SA5->(dbSetOrder(14))
    If SA5->(dbSeek(xFilial('SA5') + _cCodForn + _cCodLoja + _cCodProF))

        _cCodProP := SA5->A5_PRODUTO
    Else
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_003-Produto x Forencedor Não Encontrado.[" + 'Movimentação Interna') + ']'
    EndIf

    SB1->(dbSetOrder(1))
    If !SB1->(dbSeek(xFilial("SB1") + _cCodProF))
        DisarmTransaction()
        RestArea(_aArea)
        Return("PRTMOVIN_ERR_005-Produto de Origem Não Encontrado.[" + 'Movimentação Interna') + ']'
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
            Return("PRTMOVIN_ERR_008-Sld. de End. Nao Encontrado.[" + 'Movimentação Interna') + ']'
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
        mostraerro()
    Endif

End Transaction
RestArea(_aArea)
Return(_cRet)
