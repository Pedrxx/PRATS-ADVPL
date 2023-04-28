#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"                                        
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOTVS.CH"
#include "TOPCONN.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"

user function PRTPON99()

     // Instancio o objeto
    oTable := FwTemporaryTable():New("SZK")
    
    aCpoTMP:= {}
    
    // Crio com array com os campos da tabela
    aAdd(aCpoTMP, {'TMP_FILIAL'    , TamSx3('ZK_FILIAL')[3]       , TamSx3('ZK_FILIAL')[1] , 0})
    aAdd(aCpoTMP, {'TMP_NUM'       , TamSx3('ZK_NUM')[3]          , TamSx3('ZK_NUM')[1]    , 0})
    aAdd(aCpoTMP, {'TMP_NOME'      , TamSx3('ZK_NOME')[3]        , TamSx3('ZK_NOME')[1]   , 0})
    aAdd(aCpoTMP, {'TMP_EMAIL'     , TamSx3('ZK_EMAIL')[3]       , TamSx3('ZK_EMAIL')[1]  , 0})
    aAdd(aCpoTMP, {'TMP_CC'        , TamSx3('ZK_CC')[3]          , TamSx3('ZK_CC')[1]     , 0})
    aAdd(aCpoTMP, {'TMP_STATUS'    , TamSx3('ZK_STATUS')[3]       , TamSx3('ZK_STATUS')[1] , 0})
    aAdd(aCpoTMP, {'TMP_TURNO'     , TamSx3('ZK_TURNO')[3]        , TamSx3('ZK_TURNO')[1]  , 0})

    // Adiciono os campos na tabela
    oTable:SetFields(aCpoTMP)

    // Adicionando filtro
    /*Local cCamFilT :=  "ZK_STATUS"
    Local cVarFilT1 := "1"
    Local cVarFilT2 := cVarFilT1
    oTable:SetFilter(cCamFilT,cVarFilT1,cVarFilT2)*/
    
    // Adiciono os índices da tabela
    oTable:AddIndex('01', {'TMP_FILIAL','TMP_NUM'})
    
    // Crio a tabela no banco de dados
    oTable:Create()

    Local aArea := getArea()
    Local oBrowse := FWMBrowse():New()
    Local cCamFil :=  "ZK_STATUS"
    Local cVarFil1 := " "
    Local cVarFil2 := cVarFil1
    
    oBrowse:SetAlias("SZK")
    oBrowse:SetDescription("Cad. Supervisor X Colaborador")

    oBrowse:SetFilter(cCamFil,cVarFil1,cVarFil2)

    // Ativando o Browse
    oBrowse:Activate() 
    RestArea(aArea)

return Nil

static function MenuDef()

    Local aRotina := {}

    // Menu 
        ADD OPTION aRotina TITLE 'Incluir'       ACTION 'VIEWDEF.PRTCTT01' OPERATION 3 ACCESS 0
        ADD OPTION aRotina TITLE 'Alterar'       ACTION 'VIEWDEF.PRTCTT01' OPERATION 4 ACCESS 0
        ADD OPTION aRotina TITLE 'Visualizar'    ACTION 'VIEWDEF.PRTCTT01' OPERATION 2 ACCESS 0 

Return aRotina

static function ModelDef()

    oModel := MP
    Model():New('ZMODELSZK', , , ,)
    Local oStSZK := FWFormStruct(1,'SZK')
    Local oStTMP := FWFormStruct(1,'TMP')

    oModel:AddFields('SZKMASTER',,oStSZK)
    oModel:AddGrid('TMPDETAIL','SZKMASTER',oStTMP)
    oModel:SetRelation('TMPDETAIL',{'TMP_FILIAL','xFilial("TMP")'},{'TMP_NUM','SZK_NUM'},TMP->(IndexKey(1       )))
    oModel:SetPrimaryKey({'TMP_FILIAL','TMP_NUM'})

    oModel:SetDescription("Modelo 3")
    oModel:GetModel('SZKMASTER'):SetDescription("Cad. Supervisor X Colaborador")
    oModel:GetModel('TMPDETAIL'):SetDescription("Cad. Colaborador")

Return oModel

static function ViewDef()

    Local oView := Nil
    Local oModel := FWLoadModel("PRTPON99")
    Local oStSZK:= FWFormStruct(2,"SZK")
    Local oStTMP:= FWFormStruct(2,"TMP")

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZK", oStSZK, "SZKMASTER")
    oView:AddGrid("VIEW_TMP", oStTMP, "TMPDETAIL")

    oView:CreateHorizontalBox("CABEC",60)
    oView:CreateHorizontalBox("GRID",60)

    oView:SetOwnerView('VIEW_SZK','CABEC')
    oView:SetOwnerView('VIEW_TMP','GRID')

    oView:EnableTitleView("VIEW_SZK", "Dados View")
    oView:EnableTitleView("VIEW_TMP", "Dados Grid")
    oView:SetCloseOnOk({||.T.})

Return oView
