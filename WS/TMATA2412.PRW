#INCLUDE "PROTHEUS.CH"
#INCLUDE"RWMAKE.CH"
#INCLUDE "TBICONN.CH"

User Function XMATA240()

  local aDados := {}
  local aTotDados := {}
  local _aCabSD3 := {}
  local lMsErroAuto 


  _aCabSD3 := {{"D3_TM","501",Nil},;
  {"D3_EMISSAO","01/05/2023",Nil},;
  {"D3_CC","000",Nil}}

  aDados := {{"D3_FILIAL","101010",Nil},;
  {"D3_TM","501",Nil},;
  {"D3_COD","1010.200.000002",Nil},; 
  {"D3_UM","UN",Nil} ,;
  {"D3_CF","RE4",Nil} ,;
  {"D3_LOCAL","01",Nil},;
  {"D3_DOC","TSTEXEC01",Nil}}

  Aadd(aTotDados,aDados)

  lMsErroAuto := .F.

  MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCabSD3,aTotDados,3)

  If lMsErroAuto
    MostraErro("\SYSTEM\LOG\",+FUNNAME()+".LOG")
    MsgInfo("Não foi possivel realizar a gravação dos dados","Atenção")
    DisarmTransaction()
  EndIf

Return 
