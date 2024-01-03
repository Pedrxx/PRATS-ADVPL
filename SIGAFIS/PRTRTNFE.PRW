#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

User Function PRTRTNFE()
    
    
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
    aAdd(aPergs, {1, "Data De",          cDateDe,      "",           ".T.",     "",    ".T.", 80,  .T.}) // MV_PAR07
    aAdd(aPergs, {1, "Data Até",         cDateAte,     "",           ".T.",     "",    ".T.", 80,  .T.}) // MV_PAR02

    If (__CUSERID$GETNEWPAR("PR_USRRTNF","000000"))
        If ParamBox(aPergs, "Parametros",,,,,,,,,.T.,.T.)

    

    

        EndIf
    Else
        FWAlertError("Usuário não hábilitado para acessar esta rotina","PRTCOM14")
        lRet := .F.    
    EndIf  

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
