#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"


User Function PRTPON01()

    Local cFilialDe := Space(6) 
    Local cFilialAte := Space(6)

    Local cMatDe := Space(6)
    Local cMatAte := Space(6)

    Local cRelDe := Space(3)
    Local cRelAte := Space(3)

    Local cDateDe := Date()
    Local cDateAte := Date()

    local nVinc := 1 // MV_PAR09


    Local aPergs := {}


    aAdd(aPergs, {1, "Filial De", cFilialDe,   "",           ".T.",     "",    ".T.", 80,  .F.})
    aAdd(aPergs, {1, "Filial Ate", cFilialAte,  "",           ".T.",    "",    ".T.", 80,  .F.})
    aAdd(aPergs, {1, "Matrícula De", cMatDe,   "",           ".T.",     "",    ".T.", 80,  .F.})
    aAdd(aPergs, {1, "Matrícula Ate", cMatAte, "",           ".T.",     "",    ".T.", 80,  .F.})
    aAdd(aPergs, {1, "Data De",  cDateDe,      "",           ".T.",     "",    ".T.", 80,  .T.})
    aAdd(aPergs, {1, "Data Até", cDateAte,     "",           ".T.",     "",    ".T.", 80,  .T.})
    aAdd(aPergs, {1, "Relógio De", cRelDe,     "",           ".T.",     "",    ".T.", 80,  .F.})
    aAdd(aPergs, {1, "Relógio Ate", cRelAte,    "",          ".T.",     "",    ".T.", 80,  .F.})
    aAdd(aPergs, {2, "Exclui",      nVinc, {"1 = Leituras (RFB)", "2 = Apontamentos (RFE)","3 = Ambas"},                                       090, ".T.", .F.})


    Local _cQueryRFE := ''
    Local _cQueryRFB := ''


    If ParamBox(aPergs, "Parametros",,,,,,,,,.T.,.T.)
        _cQueryRFB += "UPDATE RFB100 SET D_E_L_E_T_ = '*' WHERE "
        _cQueryRFB += "RFB_DTHRLI BETWEEN '"+ SUBSTR(DTOS(dDATABASE),3,8) + "0000' AND '" + SUBSTR(DTOS(dDATABASE),3,8) + "2359'"
        _cQueryRFB += "AND RFB_RELOGI BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"'"
        // Alert('"' + SUBSTR(DTOS(dDATABASE),3,8) + "0000' AND '" + SUBSTR(DTOS(dDATABASE),3,8) + "2359'")
        
        _cQueryRFE := "UPDATE RFE100 SET D_E_L_E_T_ = '*' WHERE "
        _cQueryRFE +="RFE_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
        _cQueryRFE +="AND RFE_MATORG BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' "
        _cQueryRFE +="AND RFE_DATA BETWEEN '"+DTOS(MV_PAR05)+"' AND '"+DTOS(MV_PAR06)+"' " 
        _cQueryRFE +="AND RFE_RELSP0 BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"'"

        // Alert(_cQueryRFE)
        
        If MsgYesNo( "Deseja excluir os registros do sistema ?", "Exclui registros" )
            If MV_PAR09 == 1
                If zExecQry(_cQueryRFB) == .T.
                    FWAlertSuccess("Registros RFB excluidos com sucesso!", "Sucesso!")
                EndIf
            EndIf
            If MV_PAR09 == 2
                If zExecQry(_cQueryRFE) == .T.
                    FWAlertSuccess("Registros RFE excluidos com sucesso!", "Sucesso!")
                EndIf
            EndIf     
            If MV_PAR09 == 3                
                If zExecQry(_cQueryRFE) == .T.
                    zExecQry(_cQueryRFB)
                    FWAlertSuccess("Ambos registro excluidos com sucesso!", "Sucesso!")
                EndIf
            EndIf
        EndIF
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
