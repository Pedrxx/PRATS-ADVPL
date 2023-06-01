#include "protheus.ch"
#include "tbiconn.ch"
#include "totvs.ch"
#include "apwebsrv.ch"

#INCLUDE "RWMAKE.CH" 
#INCLUDE "TBICONN.CH"

User Function TMATA241()
    Local _aCab1 := {}
    Local _aItem := {}
    Local _atotitem:={}
    Local cCodigoTM:="501"
    Local cCodProd 
    Local cUnid := "LT"
    local cURL as char
    local cHeadRet as char
    cHeadRet    := ""
    cURL        := "http://ctasmart.com.br:8080/SvWebSincronizaAbastecimentos?token=Y9vY5Sv51d&data_inicio=01/01/2012&data_fim=01/01/2012"
    nTimeOut    := 15
    aChildren := {} 

    Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help
    Private lMsErroAuto := .f. //necessario a criacao

    cGetRet := HTTPSGet( cURL, "", "", "", "", 15,/*aHeadOut*/,@cHeadRet)
        // Alert(cGetRet)

        If !Empty( cGetRet )
            oXML := TXMLManager():New()
            oXML:Parse(cGetRet)
            If Empty(cErro := oXml:Error())
                aChildren := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO" )
                aChildrenVeic := oXML:XPathGetChildArray( "/CTAPLUS/ABASTECIMENTOS/ABASTECIMENTO/VEICULO" )
                VARINFO("aChildren", aChildren)
                Alert(aChildren[1][1] + aChildren[1][3])

            Endif
            
        Endif

    _aCab1 := {{"D3_DOC" ,NextNumero("SD3",2,"D3_DOC",.T.), NIL},;
            {"D3_TM" ,cCodigoTM , NIL},;
            {"D3_CC" ,"001", NIL},;
            {"D3_EMISSAO" ,aChildren[3][3], NIL}}


    _aItem:={{"D3_COD" ,RetProd(cCodProd) ,NIL},;
            {"D3_UM" ,cUnid ,NIL},; 
            {"D3_QUANT" ,1 ,NIL},;
            {"D3_LOCAL" ,"01" ,NIL},}

    aadd(_atotitem,_aitem) 

    MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab1,_atotitem,3)

    If lMsErroAuto 
        Mostraerro() 
        DisarmTransaction() 
        break

    EndIf

Return 


Static Function RetProd(CodNode) // Retorna Cod. Prod. com base no Node do XML

    If aChildren[19][3] == '1'
        Return cProd := '1041.123.000001' // S10
    ElseIf aChildren[19][3] == ''
        Return cProd := '1041.123.000002' // Arla
    EndIf

Return cProd
