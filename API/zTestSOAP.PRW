#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE 'RESTFUL.CH'
#INCLUDE 'XMLXFUN.CH'

/*/{Protheus.doc} nomeFunction
    (long_description)
    @type  Function
    @author user
    @since 26/05/2023
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function zTestSOAP()

    local cURL as char
    local cHeadRet as char
    cHeadRet    := ""
    cURL        := "http://ctasmart.com.br:8080/SvWebSincronizaAbastecimentos?token=Y9vY5Sv51d&data_inicio=01/01/2012&data_fim=01/01/2012"
    nTimeOut    := 15
    aChildren := {} 

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


Return 


/*
D3_FILIAL = 101010
D3_TM = 501
D3_COD = 1041.123.000001 OU 1041.123.000002 -> aChildren[19][3]
D3_UM = LT
D3_QUANT
D3_CF = RE0 
D3_CONTA = 1108001007          
D3_LOCAL = 01 
D3_DOC = !AUTO!
D3_EMISSAO -> aChildren[3][3]
D3_CC = !PLACA!
D3_NUMSEQ = !AUTO!
D3_OBSERVA = MOTORISTA + PLACA + HORA_INICIO + HORA_FIM
*/
