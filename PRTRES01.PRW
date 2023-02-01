#include 'protheus.ch'
#include 'parmtype.ch'
#include 'FwMvcDef.ch'
#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} User Function PRTRES01
    RETORNO DE PEDIDOS ELIMINADOS POR RESIDUOS
    @type  Function
    @author Pedro Augusto Costa
    @since 30/01/2023
    /*/
user function PRTRES01()

    Local aArea := GetArea()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SC7")
    oBrowse:SetDescription("Retorna Pedido")

    // legendas
	oBrowse:AddLegend("SC7->C7_RESIDUO == 'S'","RED", "Eliminado") //verde
	oBrowse:AddLegend("SC7->C7_RESIDUO == ' '","GREEN", "Disponivel") //vermelho

    oBrowse:Activate() // Ativando o Browse
    RestArea(aArea)

Return Nil

static function MenuDef()

    Local aRotina := {}

    // Menu
     
    ADD OPTION aRotina TITLE 'Retorna Pedido' ACTION 'U_RETPEDI()' OPERATION 7 ACCESS 0


Return aRotina

static function ModelDef()

    Local oStSC7 := FWFormStruct(1,'SC7')

    oModel := MPFormModel():New('C7ODELSC7', , , ,)
    oModel:AddFields('FORMSC7',,oStSC7)
    oModel:SetPrimaryKey({'SC7_FILIAL','SC7_NUM'})
    oModel:SetDescription('Modelo de Dados')
    oModel:GetModel('FORMSC7'):SetDescription("Formulario de Retorno")

Return oModel

static function ViewDef()

    Local oView := Nil
    Local oModel := FWLoadModel("PRTRES01")
    Local oStSC7:= FWFormStruct(2,"SC7")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC7", oStSC7, "FORMSC7")

    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView("VIEW_SC7", "Dados View")
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SC7","TELA")

Return oView

user function RETPEDI() 

    Local cAlias := "SC7"
    Local _cNumPed := CValToChar(SC7->C7_NUM) 
    Local _cQuery := "UPDATE "+RetSqlName("SCR")+" SET D_E_L_E_T_ = ' ' WHERE CR_TIPO = 'PC' AND CR_NUM = '"+_cNumPed+"'"

    DbSelectArea(cAlias)

    If MsgYesNo("Deseja retornar o pedido eliminado", "Retorna Pedido")
        SC7->(DbSetOrder(1)) 
        If SC7->(dbSeek(xFilial("SC7") + _cNumPed))
            While !SC7->(Eof()) .And. SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7") + _cNumPed
                If SC7->C7_RESIDUO = "S" .AND. SC7->C7_ENCER = "E"    
                        RecLock("SC7", .F.)
                            SC7->C7_RESIDUO = " "
                            SC7->C7_ENCER = " "

                        zExecQry(_cQuery)

                        SC7->(MsUnlock())

                    MsgInfo("Item eliminado", "Retorna Pedido")
                    SC7->(dbSkip())
                Else
                    MsgInfo("Item não eliminado", "Retorna Pedido")
                    SC7->(dbSkip())
                EndIf
            Enddo
        EndIf
    Endif
Return 


static Function zExecQry(cQuery, lFinal)
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
    EndIf
 
    FWRestArea(aArea)    
Return lDeuCerto
