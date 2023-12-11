#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

User Function PRTCOM14()

    Local lRet
    Local aArea := GetArea()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SC7")
    oBrowse:SetDescription("Altera Fornecedor de Entrega")

    If (__CUSERID$GETNEWPAR("PR_COM600","000000"))
        oBrowse:Activate() // Ativando o Browse
        RestArea(aArea)
        lRet := .T.
    Else
        FWAlertError("Usuário não hábilitado para acessar esta rotina","PRTCOM14")
        lRet := .F.    
    EndIf  

Return lRet

static function MenuDef()

    Local aRotina := {}

    // Menu
     
    ADD OPTION aRotina TITLE 'Altera Fornecedor' ACTION 'U_ALTFORN()' OPERATION 7 ACCESS 0


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
    Local oModel := FWLoadModel("PRTCOM14")
    Local oStSC7:= FWFormStruct(2,"SC7")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SC7", oStSC7, "FORMSC7")

    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView("VIEW_SC7", "Dados View")
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SC7","TELA")

Return oView

User function ALTFORN() 

    Local cAlias := "SC7"
    Local _cNumPed := CValToChar(SC7->C7_NUM) 
    DbSelectArea(cAlias)

    Local cCodigo := Space(8)
    Local cLoja := Space(4)

    Local aPergs := {}

    
    aAdd(aPergs, {1, "Codigo", cCodigo,   "", "U_VLDLOJASC7()",  "SA2",    ".T.", 80,  .T.})
    aAdd(aPergs, {1, "Loja", cLoja,       "", ".T.",             "",       ".T.", 80,  .T.})

    If ParamBox(aPergs, "Informe os parametros")
        SC7->(DbSetOrder(1))
        If SC7->(dbSeek(xFilial("SC7") + _cNumPed))
            While !SC7->(Eof()) .And. SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7") + _cNumPed
                RecLock("SC7", .F.)
                    SC7-> C7_FORNECE = MV_PAR01
                    SC7-> C7_LOJA = MV_PAR02

                SC7->(MsUnlock())
                SC7->(dbSkip()) 
            Enddo
            FWAlertSuccess('Fornecedor alterado com sucesso!','Concluido')
        EndIf
    EndIf

Return 

User Function VLDLOJASC7()

    Local aArea := GetArea()
    Local lRet := .T.
    DbSelectArea("SA2")

    SA2->(DbSetOrder(1))

    If SA2->(DbSeek(FwxFilial('SA2')+MV_PAR01))
        MV_PAR02 = SA2->A2_LOJA
        lRet := .T.
    else    
        MsgStop("Fornecedor não encontrado!", "Atenção")
        lRet := .F.
    EndIf
    
    RestArea(aArea)

Return lRet



