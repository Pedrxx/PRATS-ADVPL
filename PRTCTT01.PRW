#include 'protheus.ch'
#include 'parmtype.ch'
#include 'FwMvcDef.ch'
#Include "TOTVS.ch"
#Include "TBICONN.ch"

user function PRTCTT01() 

    Local aArea := GetArea()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SZM")
    oBrowse:SetDescription("Contratos de Exportacao")

    // legendas
	oBrowse:AddLegend("SZM->ZM_STATUS == 'A'","GREEN", "Aberto") //verde
	oBrowse:AddLegend("SZM->ZM_STATUS == 'F'","RED", "Fechado") //vermelho

    oBrowse:Activate() // Ativando o Browse
    RestArea(aArea)

Return Nil

static function MenuDef()

    Local aRotina := {}

    // Menu 
        ADD OPTION aRotina TITLE 'Incluir'       ACTION 'VIEWDEF.PRTCTT01' OPERATION 3 ACCESS 0
        ADD OPTION aRotina TITLE 'Alterar'       ACTION 'VIEWDEF.PRTCTT01' OPERATION 4 ACCESS 0
        ADD OPTION aRotina TITLE 'Visualizar'    ACTION 'VIEWDEF.PRTCTT01' OPERATION 2 ACCESS 0
        ADD OPTION aRotina TITLE 'Inclui Pedido' ACTION 'U_TMATA410()    ' OPERATION 7 ACCESS 0
        ADD OPTION aRotina TITLE 'Excluir'       ACTION 'VIEWDEF.PRTCTT01' OPERATION 5 ACCESS 0
        ADD OPTION aRotina TITLE 'Encerrar'      ACTION 'U_ENCERCTT()'     OPERATION 6 ACCESS 0
        ADD OPTION aRotina TITLE 'Reabrir '      ACTION 'U_REABRCTT()'     OPERATION 6 ACCESS 0
        ADD OPTION aRotina TITLE 'Imprimir'      ACTION 'VIEWDEF.PRTCTT01' OPERATION 8 ACCESS 0
        ADD OPTION aRotina TITLE 'Copiar'        ACTION 'VIEWDEF.PRTCTT01' OPERATION 9 ACCESS 0 

Return aRotina

static function ModelDef()

    Local oStSZM := FWFormStruct(1,'SZM')

    oModel := MPFormModel():New('ZMODELSZM', , , ,)
    oModel:AddFields('FORMSZM',,oStSZM)
    oModel:SetPrimaryKey({'SZM_FILIAL','SZM_CODIGO'})
    oModel:SetDescription('Modelo de Dados')
    oModel:GetModel('FORMSZM'):SetDescription("Formulario de Cadastro")

Return oModel

static function ViewDef()

    Local oView := Nil
    Local oModel := FWLoadModel("PRTCTT01")
    Local oStSZM:= FWFormStruct(2,"SZM")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZM", oStSZM, "FORMSZM")

    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView("VIEW_SZM", "Dados View")
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SZM","TELA")

Return oView

User Function ENCERCTT() 

    Local cAlias := "SZM"

    DbSelectArea(cAlias)
    SZM->(DbSetOrder(1))

    If MsgYesNo("Deseja encerrar o contrato?", "Encerra Contrato")
        If SZM->(DbSeek(FWxFilial('SZM')+ CValToChar(SZM->ZM_CODIGO)))
           If SZM->ZM_STATUS = "A"
                RecLock("SZM", .F.)
                    SZM->ZM_STATUS = "F"
                SZM->(MsUnlock())
            Else
                MsgInfo("Contrato já encerrado", "Encerra Contrato")
            EndIf
        EndIf
    EndIF

Return 

User Function REABRCTT() 

    Local cAlias := "SZM"

    DbSelectArea(cAlias)
    SZM->(DbSetOrder(1))

    If MsgYesNo("Deseja reabrir o contrato?", "Reabre Contrato")
        If SZM->(DbSeek(FWxFilial('SZM')+ CValToChar(SZM->ZM_CODIGO)))
            If SZM->ZM_STATUS = "F"
                RecLock("SZM", .F.)
                    SZM->ZM_STATUS = "A"
                SZM->(MsUnlock())
            Else
                MsgInfo("Contrato já aberto", "Reabre Contrato")
            EndIf
        EndIf
    EndIF

Return 

// FUNÇÃO PRINCIPAL
User Function TMATA410()
    Local nOpr    := 3  // NÚMERO DA OPERAÇÃO (INCLUSÃO)
    Local aHeader := {} // INFORMAÇÕES DO CABEÇALHO
    Local aLine   := {} // INFORMAÇÕES DA LINHA
    Local aItems  := {} // CONJUNTO DE LINHAS
    Local aArea   := {} // ARMAZENA ÁREA CORRENTE
    Local oProcess

    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.

    aArea := GetArea() // CAPTURA DA ÁREA PARA FUTURA RESTAURAÇÃO

    If SZM->(DbSeek(FWxFilial('SZM')+ CValToChar(SZM->ZM_CODIGO)))
        RecLock("SZM", .F.)

        // cNum := GetSXENum("SC5", "C5_NUM") // REMOVER PARA GERAÇÃO DE NUMERAÇÃO AUTOMÁTICA PELA ROTINA

        // DADOS DO CABEÇALHO
        // AAdd(aHeader, {"C5_NUM", cNum, NIL}) // REMOVER PARA GERAÇÃO DE NUMERAÇÃO AUTOMÁTICA PELA ROTINA
        AAdd(aHeader, {"C5_TIPO", "N", NIL})
        AAdd(aHeader, {"C5_CLIENTE", SZM->ZM_CLIENTE, NIL})
        AAdd(aHeader, {"C5_LOJACLI", SZM->ZM_LOJA, NIL})
        AAdd(aHeader, {"C5_LOJAENT", SZM->ZM_LOJA, NIL})
        AAdd(aHeader, {"C5_CONDPAG", "000", NIL})
        AAdd(aHeader, {"C5_TABELA", "095", NIL})
        AAdd(aHeader, {"C5_VEND1", "000001", NIL})
        AAdd(aHeader, {"C5_BANCO", "001", NIL})
        AAdd(aHeader, {"C5_TRANSP", "000035", NIL})
        AAdd(aHeader, {"C5_TPFRETE", "R", NIL})
        AAdd(aHeader, {"C5_XCTTXPD", SZM->ZM_CODIGO, NIL})

        // DADOS DOS ITENS
        AAdd(aLine, {"C6_PRODUTO", SZM->ZM_PRODUTO, NIL})
        AAdd(aLine, {"C6_QTDVEN", 1, NIL})
        AAdd(aLine, {"C6_PRUNIT", 1116.13, NIL})
        AAdd(aLine, {"C6_PRCVEN", 1116.13, NIL})
        AAdd(aLine, {"C6_VALOR", 1116.13, NIL})
        AAdd(aLine, {"C6_OPER", "01", NIL})
        AAdd(aLine, {"C6_LOCAL", "08", NIL})
        AAdd(aLine, {"C6_TES", "505", NIL})
        AAdd(aLine, {"C6_CF", "7101", NIL})

        AAdd(aItems, aLine)


        //MsExecAuto({|x, y, z| MATA410(x, y, z)}, aHeader, aItems, nOpr)
        oProcess := MsNewProcess():New({|| MsExecAuto({|x, y, z| MATA410(x, y, z)}, aHeader, aItems, nOpr)}, "Processando...", "Aguarde...", .T.)
        oProcess:Activate()

        // VALIDAÇÃO DE ERRO
        If (lMsErroAuto)
            MostraErro()
            // RollbackSX8() // REMOVER PARA GERAÇÃO DE NUMERAÇÃO AUTOMÁTICA PELA ROTINA

            ConOut(Repl("-", 80))
            ConOut(PadC("MATA410 automatic routine ended with error", 80))
            ConOut(PadC("Ended at: " + Time(), 80))
            ConOut(Repl("-", 80))
        Else
            // ConfirmSX8() // REMOVER PARA GERAÇÃO DE NUMERAÇÃO AUTOMÁTICA PELA ROTINA

            ConOut(Repl("-", 80))
            ConOut(PadC("MATA410 automatic routine successfully ended", 80))
            ConOut(PadC("Ended at: " + Time(), 80))
            ConOut(Repl("-", 80))
        EndIf

        RestArea(aArea) // RESTAURAÇÃO DA ÁREA ANTERIOR
    
    SZM->(MsUnlock())
    EndIf
Return (NIL)
