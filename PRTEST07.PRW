#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

/* 
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ PRTEST07  บ Autor ณPedro Augusto      บ Data ณ21/03/2023   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescrio ณ Cadastro de Familia Prats                                  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Especกfico para Grupo Pratinha                             บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบParametrosณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบAlteracao ณ                                                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
User Function PRTEST07()

    Local aArea := GetArea()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias('SZX')
    oBrowse:SetDescription("Cadastro de Familia")

    oBrowse:Activate()
    RestArea(aArea)

    
Return 

static function MenuDef()

    Local aRotina := {}

    ADD OPTION aRotina TITLE 'Incluir'       ACTION 'VIEWDEF.PRTEST07' OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'       ACTION 'VIEWDEF.PRTEST07' OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Visualizar'    ACTION 'VIEWDEF.PRTEST07' OPERATION 2 ACCESS 0 
    ADD OPTION aRotina TITLE 'Excluir'       ACTION 'VIEWDEF.PRTEST07' OPERATION 5 ACCESS 0

Return aRotina

static function ModelDef()

    Local oStSZX := FWFormStruct(1,'SZX')

    oModel := MPFormModel():New('ZMODELSZX', , , ,)
    oModel:AddFields('FORMSZX',,oStSZX)
    oModel:SetPrimaryKey({'SZX_FILIAL','SZX_CODIGO'})
    oModel:SetDescription('Modelo de Dados')
    oModel:GetModel('FORMSZX'):SetDescription("Formulario de Retorno")

Return oModel

static function ViewDef()

    Local oView := Nil
    Local oModel := FWLoadModel("PRTEST07")
    Local oStSZX:= FWFormStruct(2,"SZX")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZX", oStSZX, "FORMSZX")

    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView("VIEW_SZX", "Dados View")
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SZX","TELA")

Return oView

