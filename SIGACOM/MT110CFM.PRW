#Include "TOTVS.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

User Function MT110CFM()

    Local nNumSC := PARAMIXB[1]       // Numero da Solicitao de compras 
    Local nOpca  := PARAMIXB[2]       // 1 = Aprovar; 2 = Rejeitar; 3 = Bloquear
    Local dDataAprov := dDataBase 
    Local cAlias := "SC1"

    DbSelectArea(cAlias)

	IF nOpca == 1
		SC1->(DbSetOrder(1))
        IF SC1->(dbSeek(xFilial("SC1") + nNumSC))
            While !SC1->(Eof()) .AND. SC1->(C1_FILIAL+C1_NUM) == xFilial("SC1") + nNumSC
                // Preenche a data de liberação com a database
                RecLock("SC1", .F.)
                SC1-> C1_XDTAPSC := dDataAprov
                SC1->(MsUnlock())
                SC1->(DbSkip())
            Enddo
            Return
        EndIf
    ElseIf nOpca == 2 .OR. nOpca == 3
        SC1->(DbSetOrder(1))
        IF SC1->(dbSeek(xFilial("SC1") + nNumSC))
            While !SC1->(Eof()) .AND. SC1->(C1_FILIAL+C1_NUM) == xFilial("SC1") + nNumSC
                // Limpa a data de liberação em caso de estorno/rejeição
                RecLock("SC1", .F.)
                SC1-> C1_XDTAPSC := cToD("  /  /    ")
                SC1->(MsUnlock())
                SC1->(DbSkip())
            Enddo
            Return
        EndIf
	ENDIF
    
Return
