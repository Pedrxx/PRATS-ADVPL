#Include 'Protheus.ch'

User Function MTA120EX()

    Local lRet := .F.

        If (__CUSERID$GETNEWPAR("PR_MT120EX","000000"))
            lRet := .T.
        Else
            FWAlertError("Usuário não hábilitado a excluir pedidos de compra","Excluir Pedido")    
        EndIf  
        
Return lRet
