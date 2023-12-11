#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"


User Function PRTFAT13()

    Local aArea := GetArea()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias('SZX')
    oBrowse:SetDescription("Cadastro de Familia")
    oBrowse:Activate()
    RestArea(aArea)
    
Return 

static function MenuDef()

    Local aRotina := {}

    // Menu
     
    ADD OPTION aRotina TITLE 'Incluir'       ACTION 'VIEWDEF.PRTFAT13' OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'       ACTION 'VIEWDEF.PRTFAT13' OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Visualizar'    ACTION 'VIEWDEF.PRTFAT13' OPERATION 2 ACCESS 0 


Return aRotina

static function ModelDef()

    Local oStSZX := FWFormStruct(1,'SZX')

    oModel := MPFormModel():New('C7ODELSZX', , , ,)
    oModel:AddFields('FORMSZX',,oStSZX)
    oModel:SetPrimaryKey({'SZX_FILIAL','SZX_NUM'})
    oModel:SetDescription('Modelo de Dados')
    oModel:GetModel('FORMSZX'):SetDescription("Formulario de Retorno")

Return oModel

static function ViewDef()

    Local oView := Nil
    Local oModel := FWLoadModel("PRTFAT13")
    Local oStSZX:= FWFormStruct(2,"SZX")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZX", oStSZX, "FORMSZX")

    oView:CreateHorizontalBox("TELA",100)
    oView:EnableTitleView("VIEW_SZX", "Dados View")
    oView:SetCloseOnOk({||.T.})
    oView:SetOwnerView("VIEW_SZX","TELA")

Return oView

