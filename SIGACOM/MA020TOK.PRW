#Include "TOTVS.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"


User Function MA020TOK()

    Local lRet := .F.

    // COlocar A2_TPJ como obrigat�rio e padr�o em branco

    IF (M->A2_TPJ == "3")
        IF(EMPTY(M->A2_DTNASC ) .AND. EMPTY( M->A2_XCPFMEI ))
            FWAlertError("Este fornecedor � um MEI, verifique os campos"+CRLF+" - Dt. Nasc "+CRLF+" - CPF MEI", "A020EOK")
            lRet := .F.
        Else 
            IF(!ChkCPF(M->A2_XCPFMEI))
                FWAlertError("Este CPF � inv�lido"+CRLF+" - "+ M->A2_XCPFMEI, "A020EOK")
                lRet := .F.
            else
                lRet := .T.
            EndIF
        EndIF
    EndIf

Return lRet