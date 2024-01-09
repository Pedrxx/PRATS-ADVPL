#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

User Function PRTFIS99()
    
    Local cFilialDe := Space(6)
    Local cFilialAte := Space(6)
    
    Local cNFlDe := Space(8)
    Local cNFAte := Space(8)

    Local cSerieDe := Space(3)
    Local cSerieAte := Space(3)

    Local cDataDe := Date()
    Local cDataAte := Date()

    Local aPergs := {}
    
    aAdd(aPergs, {1, "Filial De",        cFilialDe,    "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR01
    aAdd(aPergs, {1, "Filial Ate",       cFilialAte,   "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR02
    aAdd(aPergs, {1, "Nota Fiscal De",   cNFlDe,       "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR03
    aAdd(aPergs, {1, "Nota Fiscal Ate",  cNFAte,       "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR04
    aAdd(aPergs, {1, "Serie De",         cSerieDe,     "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR05
    aAdd(aPergs, {1, "Serie Fiscal Ate", cSerieAte,    "",           ".T.",     "",    ".T.", 80,  .F.}) // MV_PAR06
    aAdd(aPergs, {1, "Data De",          cDataDe,      "",           ".T.",     "",    ".T.", 80,  .T.}) // DToS(MV_PAR07)
    aAdd(aPergs, {1, "Data Até",         cDataAte,     "",           ".T.",     "",    ".T.", 80,  .T.}) // MV_PAR02

    Local cFirstDoc := 0
    Local cBodyEmail := ''

    Local cQuery1 
    Local cQuery2 
    Local cQuery3 
    Local cQuery4 
    Local cQuery5 
    Local cQuery6 


    If (__CUSERID$GETNEWPAR("PR_USRRTNF","000000"))
        If ParamBox(aPergs, "Parametros",,,,,,,,,.T.,.T.)
            cQuery1 := "UPDATE SF1100 SET D_E_L_E_T_ = '', R_E_C_D_E_L_ = '' WHERE F1_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND F1_DOC BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND F1_SERIE BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND F1_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"
            cQuery2 := "UPDATE SD1100 SET D_E_L_E_T_ = '', R_E_C_D_E_L_ = '' WHERE F1_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND F1_DOC BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND F1_SERIE BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND F1_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"
            cQuery3 := "UPDATE SFT100 SET FT_DTCANC = '', FT_OBSERV = '' WHERE FT_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND FT_NFISCAL BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND FT_SERIE BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND FT_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"
            cQuery4 := "UPDATE SF3100 SET F3_DTCANC = '', F3_OBSERV = '', F3_CODRSEF = '' WHERE F3_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND F3_NFISCAL BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND F3_SERIE BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND F3_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"
            cQuery5 := "UPDATE CD2100 SET D_E_L_E_T_ = '', R_E_C_D_E_L_ = '' WHERE CD2_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND CD2_DOC BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND CD2_SERIE BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND CD2_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"
            cQuery6 := "UPDATE SE2100 SET D_E_L_E_T_ = '', R_E_C_D_E_L_ = '' WHERE E2_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND E2_NUM BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' AND E2_PREFIXO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"' AND E2_EMISSAO BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'"

            zExecQry(cQuery1)
            zExecQry(cQuery2)
            zExecQry(cQuery3)
            zExecQry(cQuery4)
            zExecQry(cQuery5)
            zExecQry(cQuery6)

            // For cFirstDoc := MVPAR_03 to MVPAR_04
            //     cBodyEmail += fMontaLog(Val(SrtTran(AllTrim(cFirstDoc))),MV_PAR05,"Registro processado com sucesso",CONVERT(VARCHAR, GETDATE(), 103))
            // Next

            FWAlertSuccess('Sucesso no retorno da nota fiscal','Sucesso')

            // zEnviaEmail(cBodyEmail)

        EndIf

    Else
        FWAlertError("Usuário não hábilitado para acessar esta rotina","PRTFIS99")
        lRet := .F.    
    EndIf  

Return 

Static Function zEnviaEmail(cLog) 
    cTitulo := 'Retorno NF Entrada'
    cRemet  := "WorkFlow <workflow@prats.com.br>"
    cDestino:= GETMV("PR_BMBMAIL")
    cBody   := fEmailBody(cLog)
    cCopia  := GetNewPar("PR_EST05EC","")
    cCopia  := Replace(cCopia, " ", "")
    cDestino:= Replace(cDestino, " ", "")
    cTitulo := "[101010-Fabrica]Retorno de Nota Fiscal de Entrada"
    _aAttach := {}

    U_PRTCFG04(cDestino,cCopia,cTitulo,cBody,_aAttach)
Return 


Static Function zExecQry(cQuery, lFinal) 
    Local aArea     := FWGetArea()
    Local lDeuCerto := .F.
    Local cMensagem := ""
    Default cQuery  := ""
    Default lFinal  := .F.
 
    //Executa a clausula SQL
    If TCSqlExec(cQuery) < 0
         
        //Caso não esteja rodando via job / ws, monta a mensagem e exibe
        If ! IsBlind()
            cMensagem := "Falha na atualização do Banco de Dados!" + CRLF + CRLF
            cMensagem += "/* ==== Query: ===== */" + CRLF
            cMensagem += cQuery + CRLF + CRLF
            cMensagem += "/* ==== Mensagem: ===== */" + CRLF
            cMensagem += TCSQLError()
            ShowLog(cMensagem)      
        EndIf
 
        //Se for para abortar o sistema, será exibido uma mensagem
        If lFinal
            Final("zExecQry: Falha na operação. Contate o Administrador.")
        EndIf
 
    //Se deu tudo certo, altera a flag de retorno
    Else
        lDeuCerto := .T.
        //FWAlertSuccess("Registro retornado com sucesso!", "Sucesso!")
    EndIf
 
    FWRestArea(aArea) 
       
Return lDeuCerto


Static Function fMontaLog(_cDoc,_cSerie,_cLog,_dData) 

    Local _cLog := ""
    _cLog += '<tr bgcolor="#c6f7c3">'
    _cLog += '<td style="width: 11.19%;" width="10%"><span style="font-family: Arial; font-size: xx-small;">'+_cDoc+'</span></td>'
    _cLog += '<td style="width: 7.34789%;"><span style="font-family: Arial; font-size: xx-small;">'+_cSerie+'</span></td>'
    _cLog += '<td style="width: 71.4621%;" width="80%"><span style="font-family: Arial; font-size: xx-small;">'+_cLog+'</td>'
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
    cRet += '<h2 id="aria-label-messageattachments" class="voice">Retorno de NF de Entrada</h2>'
    cRet += '</div>'
    cRet += '<div class="rightcol" role="region" aria-labelledby="aria-label-messagebody">'
    cRet += '<div id="messagebody">'
    cRet += '<div id="message-htmlpart1" class="message-htmlpart"><!-- html ignored --><!-- head ignored --><!-- meta ignored -->'
    cRet += '<div class="rcmBody">'
    cRet += '<p align="left">Retorno de NF de Entrada</p>'
    cRet += '<table border="0" width="100%" cellspacing="0" cellpadding="0">'
    cRet += '<tbody>'
    cRet += '<tr>'
    cRet += '<td width="100%">'
    cRet += '<table border="1" width="100%" cellspacing="0" cellpadding="0">'
    cRet += '<tbody>'
    cRet += '<tr>'
    cRet += '<td bgcolor="#2aba1a" width="100%">'
    cRet += '<p align="center"><strong><span style="font-family: Arial;">Log de Retorno de NF de Entrada</span></strong></p>'
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
    cRet += '<td style="width: 11.1871%;" width="10%"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Documento</span></td>'
    cRet += '<td style="width: 7.33759%;"><span style="color: #ffffff; font-family: Arial; font-size: xx-small;">Serie</span></td>'
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
    cRet += '<div class="message-htmlpart"><span style="font-family: Arial; font-size: small;"><br /></span><span style="font-family: Arial; font-size: xx-small;">Qualquer dúvida entrar em contato no telefone (44) 99982-8795 ou e-mail erp@prats.com.br<br /></span><span style="font-family: Arial; font-size: xx-small;">Caso necessite pode abrir um chamado no sistema de Gestão de Tickets da Prats.</span><br /><!-- hb ignored --><span style="font-family: Arial; font-size: xx-small;">Fonte: PRTFIS99 </span></div>'
    cRet += '</div>'
    cRet += '</div>'
    cRet += '</div>'
    cRet += '</body>'
    cRet += '</html>'

Return(cRet)
