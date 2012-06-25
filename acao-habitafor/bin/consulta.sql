select
bic."IdCadastro",
bic."NrFormulario",
to_char(bic."DtCadastro", 'yyyy-mm-dd') as "DtCadastro",
case WHEN b."NmOrgao" = 'HabitaFor' THEN 'Habitafor'
     WHEN b."NmOrgao" = 'SER I' THEN 'SER 1'
     WHEN b."NmOrgao" = 'SER II' THEN 'SER 2'
     WHEN b."NmOrgao" = 'SER III' THEN 'SER 3'
     WHEN b."NmOrgao" = 'SER IV' THEN 'SER 4'
     WHEN b."NmOrgao" = 'SER V' THEN 'SER 5'
     WHEN b."NmOrgao" = 'SER VI' THEN 'SER 6'
ELSE b."NmOrgao" END as "NmOrgao",
c."NmEntrevistador" ,
d."NmAssentamento",
case when a."DsCondicaoCadastro" = '1' then 'Beneficiário'
     when a."DsCondicaoCadastro" = '2' then 'Ocupante'
     when a."DsCondicaoCadastro" = '7' then 'Demanda Espontânea'
     else '' end as "DsCondicaoCadastro",
bic."NmLogradouro",
'' as cep,
bic."NrEndereco",
bic."DsComplemento",
bic."NrQuadra",
bic."NrLote",
e."NmBairro",
bic."NrTelefone",
'' as localizacaoCartografica,
case WHEN f."DsTitularidade" = 'Composse por Decisão Judicial' THEN 'Composse por decisão judicial' ELSE f."DsTitularidade" END  as "DsTitularidade",
case WHEN h."DsCondicaoMoradia" = 'Invadida' THEN 'Ocupada' ELSE h."DsCondicaoMoradia" END as "DsCondicaoMoradia",
case WHEN i."DsCoabitacao" = 'Não Existe' THEN 'Não existe'
ELSE i."DsCoabitacao" END as "DsCoabitacao",
case WHEN j."DsProcedenciaFamilia" = 'Outro Bairro' THEN 'Outro bairro'
     WHEN j."DsProcedenciaFamilia" = 'Bairro' THEN 'Mesmo bairro'
     WHEN j."DsProcedenciaFamilia" = 'Cidade do Interior' THEN 'Cidade do interior'
     WHEN j."DsProcedenciaFamilia" = 'Região Metropolitana' THEN 'Região metropolitana'
     WHEN j."DsProcedenciaFamilia" = 'Outro Estado' THEN 'Outro estado'
ELSE j."DsProcedenciaFamilia" END as "DsProcedenciaFamilia",
g."NrTempoMoradia",
g."NrFamilias",
g."NrMoradores",
g."NrMoradoresTrabalham",
g."NrMoradoresEstudam",
g."NrMenores",
g."NrMenoresTrabalham",
g."NrMenoresEstudam",
case WHEN g."FgAssociacaoComunitaria" = '1' THEN 'Não'
     WHEN g."FgAssociacaoComunitaria" = '2' THEN 'Sim'
     ELSE '' END as "FgAssociacaoComunitaria",
'' as "nomeAssociacao",
'' as "fx0a4",
'' as "fx5a9",
'' as "fx10a14",
'' as "fx15a17",
'' as "fx18a21",
'' as "fx22a24",
'' as "fx25a29",
'' as "fx30a39",
'' as "fx40a49",
'' as "fx50a59",
'' as "fx60a65",
'' as "fxacima65",
case WHEN k."DsRendaDespesa" = 'Até 1/2' THEN 'até 1/2'
     WHEN k."DsRendaDespesa" = 'Sem Renda' THEN 'Sem renda'
ELSE k."DsRendaDespesa" END as "DsRendaDespesa",
DefAuditiva."NrDeficientes" as "DefAuditiva",
DefVisual."NrDeficientes" as "DefVisual",
DefMotora."NrDeficientes" as "DefMotora",
DefMental."NrDeficientes" as "DefMental",
'' as tipoDeficienciaMotora,
ProgFederal."NrMoradoresAssistidos" as "NrMoradoresAssistidosFed",
ProgEstadual."NrMoradoresAssistidos" as "NrMoradoresAssistidosEst",
ProgMunicipal."NrMoradoresAssistidos" as "NrMoradoresAssistidosMun",
'' as "outrosMoradores",
'' as "outrosNumerosIdentificacao",
'' as "observacoes",
tip."DsTipologiaImovel",
'' as "localizacaoImovel",
case WHEN y."DsTipologiaUso" = 'Mista' THEN 'Misto' 
     WHEN y."DsTipologiaUso" = 'Serviços' THEN 'Serviço' 
     ELSE y."DsTipologiaUso" END as "DsTipologiaUso",
'' as "especifiqueTipologiaUso",
case WHEN x."DsCondicaoFundiaria" = 'Não Regularizada' THEN 'Não regularizada'
     WHEN x."DsCondicaoFundiaria" = 'Concessão Especial de Uso' THEN 'Regularizada'
     WHEN x."DsCondicaoFundiaria" = 'Concessão de Direito Real de Uso' THEN 'Regularizada'
     WHEN x."DsCondicaoFundiaria" = 'Domínio Pleno' THEN 'Regularizada'
ELSE x."DsCondicaoFundiaria" END as "DsCondicaoFundiaria",
'' as "tiporegularizacao",
'' as "matricula", 
'' as "cartorio",
'' as "proprietario",
w."DsTipologiaEdificacao",
v."DsFaixaArea",
u."DsTipologiaConstrucao",
case when u."DsTipologiaConstrucao" = '1' then 'Alvenaria'
     when u."DsTipologiaConstrucao" = '2' then 'Taipa'
     when u."DsTipologiaConstrucao" = '3' then 'Madeira'
     when u."DsTipologiaConstrucao" = '4' then 'Pré-moldado'
     when u."DsTipologiaConstrucao" = '5' then 'Papelão'
     when u."DsTipologiaConstrucao" = '6' then 'Plástico'
     when u."DsTipologiaConstrucao" = '7' then 'Lona'
     when u."DsTipologiaConstrucao" = '8' then 'Mista'
     else '' end as "DsTipologiaConstrucao",
'' as tipoCobertura,
'' as tipoPiso,
'' as tipoParede,
NrQuarto."NrComodo" as "NrQuarto",
NrSala."NrComodo" as "NrSala",
NrCozinha."NrComodo" as "NrCozinha",
NrBanheiro."NrComodo" as "NrBanheiro",
NrOutros."NrComodo" as "NrOutros",
'' as "especiqueOutrosComodos",
case when z."FgSituacaoRisco" = '2' then 'Não'
     when z."FgSituacaoRisco" = '1' then 'Sim'
     else '' end as "SituacaoRisco",
case WHEN RiscoAlagamento."DsTipoRisco" = 'Alagamento' THEN 'true'
    else 'false' end as "RiscoAlagamento",
case WHEN RiscoInundacao."DsTipoRisco" = 'Inundação' THEN 'true'
    else 'false' end as "RiscoInundacao",
case WHEN RiscoDeslizamento."DsTipoRisco" = 'Deslizamento' THEN 'true'
    else 'false' end as "RiscoDeslizamento",
case WHEN RiscoViaFerrea."DsTipoRisco" = 'Via Ferrea' THEN 'true'
    else 'false' end as "RiscoViaFerrea",
case WHEN RiscoLinhaAltaTensao."DsTipoRisco" = 'Linha Alta Tensão' THEN 'true'
    else 'false' end as "RiscoLinhaAltaTensao",
case WHEN RiscoOutro."DsTipoRisco" = 'Outro' THEN 'true'
    else 'false' end as "RiscoOutro",
'' as especiqueOutrosRiscos,    
case WHEN kit."IdTipologiaBeneficio" = '1' THEN 'true'
      ELSE 'false' END as "KitSanitario",
case WHEN mel."IdTipologiaBeneficio" = '2' THEN 'true'
      ELSE 'false' END as "MelhoriaHab",  
'' as "observacoesBeneficio", 
case WHEN ag."DsAgua" = 'Sem Hidrômetro' THEN 'Sem hidrômetro'
     WHEN ag."DsAgua" = 'Clandestina' THEN 'Clandestina'
     WHEN ag."DsAgua" = 'Sem Ligação' THEN 'Inexistente'
     WHEN ag."DsAgua" = 'Com Hidrômentro' THEN 'Hidrômentro individual'
     ELSE '' END as "DsAgua", 
'false' as "poco",
'false' as "chafariz",
'false' as "outroRedeAgua",
'' as  "especiqueOutro",
'' as "ligacaoRedeEsgoto",
'false' as "fossaSumidouro",
'false' as "viaPublica",
'false' as "redeDrenagemRecursoHidrico",
'false' as "outro",
'' as "especiqueOutro",
case WHEN l."FgColetaEsgoto" = '2' THEN 'Com ligação' ELSE '' END as "red_esg",
case WHEN m."IdEsgoto" = '3' THEN 'true' ELSE 'false' END as "fossaSumidouro",
case WHEN m."IdEsgoto" = '4' THEN 'true' ELSE 'false' END as "Viapublica",
case WHEN m."IdEsgoto" = '5' THEN 'true' ELSE 'false' END as "RedeDrenagem",
case WHEN m."IdEsgoto" = '6' THEN 'true' ELSE 'false' END as "outroColeta",
'' as "especiqueOutraColeEsg",
case WHEN l."IdEnergiaEletrica" = '1' THEN 'Inexistente'
     WHEN l."IdEnergiaEletrica" = '2' THEN 'Oficial'
     WHEN l."IdEnergiaEletrica" = '3' THEN 'Clandestina'
     ELSE '' END "RedeEletrica",
case WHEN l."IdPavimentacao" = '1' THEN 'Asfalto'
     WHEN l."IdPavimentacao" = '2' THEN 'Pedra tosca'
     WHEN l."IdPavimentacao" = '3' THEN 'Piçarra'
     WHEN l."IdPavimentacao" = '4' THEN 'Paralelepípedo'
     WHEN l."IdPavimentacao" = '5' THEN 'Outro'
     ELSE '' END "Pavimentacao",
'' as "especifiqueOutroInfra",
'' as "TelefoniaFixa",
case WHEN drenGal."IdTipoDrenagem" = '1' THEN 'true' ELSE 'false' END as "drenGal",
case WHEN drenSarj."IdTipoDrenagem" = '2' THEN 'true' ELSE 'false' END as "drenSarj",
case WHEN drenAg."IdTipoDrenagem" = '3' THEN 'true' ELSE 'false' END as "drenAg",
case WHEN drenNAg."IdTipoDrenagem" = '4' THEN 'true' ELSE 'false' END as "drenNAg",
case WHEN drenOut."IdTipoDrenagem" = '5' THEN 'true' ELSE 'false' END as "drenOut",
'' as "outrTipDren",
'' as "destLixo",
'' as "obs",
pes."NmPessoa" as "chefe",
'' as "apelido",
case WHEN pes."FgTitularImovel" = '2' THEN 'Sim'
     WHEN pes."FgTitularImovel" = '1' THEN 'Não'
     ELSE '' END as "titularImovel",
case WHEN pes."IdSexo" = '2' THEN 'Feminino'
     WHEN pes."IdSexo" = '1' THEN 'Masculino'
     ELSE '' END as "sexochf",
to_char(pes."DtNascimento", 'yyyy-mm-dd') as "DtNascimento",
case WHEN pes."IdEstadoCivil" = '1' THEN 'Solteiro(a)'
     WHEN pes."IdEstadoCivil" = '2' THEN 'Casado(a)'
     WHEN pes."IdEstadoCivil" = '3' THEN 'Viúvo(a)'
     WHEN pes."IdEstadoCivil" = '4' THEN 'Divorciado(a)'
     WHEN pes."IdEstadoCivil" = '5' THEN 'União estável'
     ELSE '' END as "estcivchf", 
case WHEN  char_length(pes."NrRG") < '3' THEN '' ELSE regexp_replace(pes."NrRG", '[^0-9]', '', 'g') END  as "rgchf",
pes."DsOrgaoExpedidor" as "exprgchf",
translate(pes."NrCPF", '.,/-', '') as "cpfch",
pes."NrTituloEleitor" as "titchf",
pes."NrZonaTituloEleitor" as "zntitch",
pes."NrSecaoTituloEleitor" as "sectitchf",
case when faixa."DsFaixaEtaria" = '13' then '15 a 16'
     when faixa."DsFaixaEtaria" = '14' then '17 a 19'
     when faixa."DsFaixaEtaria" = '15' then '20 a 24'
     when faixa."DsFaixaEtaria" = '16' then '25 a 29'
     when faixa."DsFaixaEtaria" = '17' then '30 a 39'
     when faixa."DsFaixaEtaria" = '18' then '40 a 49'
     when faixa."DsFaixaEtaria" = '19' then '50 a 59'
     when faixa."DsFaixaEtaria" = '20' then '60 a 65'
     when faixa."DsFaixaEtaria" = '21' then 'Acima de 65'
     else '' end as "faixetariachf",
case WHEN pes."FgEstuda" = '1' THEN 'Não'
     WHEN pes."FgEstuda" = '2' THEN 'Sim'
     ELSE '' END as "estchf", 
cc."DsProfissao" "prfch",
dd."DsOcupacao" "occh",
case WHEN pes."FgVinculoEmpregaticio" = '1' THEN 'Não'
     WHEN pes."FgVinculoEmpregaticio" = '2' THEN 'Sim'
     ELSE '' END as "vincempchf", 
ee."NmBairro" "baitrbch",
case WHEN pes."IdEscolaridade" = '1' THEN 'Analfabeto(a)'
     WHEN pes."IdEscolaridade" = '2' THEN 'Alfabetizado(a)'
     WHEN pes."IdEscolaridade" = '3' THEN 'Ensino fundamental incompleto'
     WHEN pes."IdEscolaridade" = '4' THEN 'Ensino fundamental completo'
     WHEN pes."IdEscolaridade" = '5' THEN 'Ensino médio incompleto'
     WHEN pes."IdEscolaridade" = '6' THEN 'Ensino médio completo'
     WHEN pes."IdEscolaridade" = '7' THEN 'Curso técnico incompleto'
     WHEN pes."IdEscolaridade" = '8' THEN 'Curso técnico completo'
     WHEN pes."IdEscolaridade" = '9' THEN 'Curso superior incompleto'
     WHEN pes."IdEscolaridade" = '10' THEN 'Curso superior completo'
     ELSE '' END as "escchf",
case WHEN ff."DsCondicaoFuncional" = '1' THEN 'Empregado(a)'
     WHEN ff."DsCondicaoFuncional" = '2' THEN 'Aposentado(a)'
     WHEN ff."DsCondicaoFuncional" = '3' THEN 'Pensonista'
     WHEN ff."DsCondicaoFuncional" = '4' THEN 'Autônomo(a)'
     WHEN ff."DsCondicaoFuncional" = '5' THEN 'Cooerperado(a)'
     WHEN ff."DsCondicaoFuncional" = '6' THEN 'Eventual'
     WHEN ff."DsCondicaoFuncional" = '7' THEN 'Desempregado(a)'
     ELSE '' END as "funcch", 
pes."DsNomePai" as "paich",
pes."DsNomeMae" as "maech",
pes."DsObservacao" as "obsch",
'false' as "homo",
comp."NmPessoa" as "comp",
'' as "apelidocomp",
case WHEN comp."FgTitularImovel" = '2' THEN 'Sim'
     WHEN comp."FgTitularImovel" = '1' THEN 'Não'
     ELSE '' END as "titularImovelcomp",
case WHEN comp."IdSexo" = '2' THEN 'Feminino'
     WHEN comp."IdSexo" = '1' THEN 'Masculino'
     ELSE '' END as "sexocomp",
to_char(comp."DtNascimento", 'yyyy-mm-dd') as "Nsccomp",
case WHEN comp."IdEstadoCivil" = '1' THEN 'Solteiro(a)'
     WHEN comp."IdEstadoCivil" = '2' THEN 'Casado(a)'
     WHEN comp."IdEstadoCivil" = '3' THEN 'Viúvo(a)'
     WHEN comp."IdEstadoCivil" = '4' THEN 'Divorciado(a)'
     WHEN comp."IdEstadoCivil" = '5' THEN 'União estável'
     ELSE '' END as "estcivcomp", 
case WHEN  char_length(comp."NrRG") < '3' THEN '' ELSE regexp_replace(comp."NrRG", '[^0-9]', '', 'g') END  as "rgcomp",
comp."DsOrgaoExpedidor" as "exprgcomp",
translate(comp."NrCPF", '.,/-', '') as "cpfcomp",
comp."NrTituloEleitor" as "titcomp",
comp."NrZonaTituloEleitor" as "zntitcomp",
comp."NrSecaoTituloEleitor" as "sectitcomp",
case when faixa."DsFaixaEtaria" = '13' then '15 a 16'
     when faixa."DsFaixaEtaria" = '14' then '17 a 19'
     when faixa."DsFaixaEtaria" = '15' then '20 a 24'
     when faixa."DsFaixaEtaria" = '16' then '25 a 29'
     when faixa."DsFaixaEtaria" = '17' then '30 a 39'
     when faixa."DsFaixaEtaria" = '18' then '40 a 49'
     when faixa."DsFaixaEtaria" = '19' then '50 a 59'
     when faixa."DsFaixaEtaria" = '20' then '60 a 65'
     when faixa."DsFaixaEtaria" = '21' then 'Acima de 65'
     else '' end as "faixetariacomp",
case WHEN comp."FgEstuda" = '1' THEN 'Não'
     WHEN comp."FgEstuda" = '2' THEN 'Sim'
     ELSE '' END as "estcomp", 
gg."DsProfissao" "prfcomp",
hh."DsOcupacao" "occomp",
case WHEN comp."FgVinculoEmpregaticio" = '1' THEN 'Não'
     WHEN comp."FgVinculoEmpregaticio" = '2' THEN 'Sim'
     ELSE '' END as "vincempcomp", 
ii."NmBairro" "baitrbcomp",
case WHEN comp."IdEscolaridade" = '1' THEN 'Analfabeto(a)'
     WHEN comp."IdEscolaridade" = '2' THEN 'Alfabetizado(a)'
     WHEN comp."IdEscolaridade" = '3' THEN 'Ensino fundamental incompleto'
     WHEN comp."IdEscolaridade" = '4' THEN 'Ensino fundamental completo'
     WHEN comp."IdEscolaridade" = '5' THEN 'Ensino médio incompleto'
     WHEN comp."IdEscolaridade" = '6' THEN 'Ensino médio completo'
     WHEN comp."IdEscolaridade" = '7' THEN 'Curso técnico incompleto'
     WHEN comp."IdEscolaridade" = '8' THEN 'Curso técnico completo'
     WHEN comp."IdEscolaridade" = '9' THEN 'Curso superior incompleto'
     WHEN comp."IdEscolaridade" = '10' THEN 'Curso superior completo'
     ELSE '' END as "esccomp", 
case WHEN jj."DsCondicaoFuncional" = '1' THEN 'Empregado(a)'
     WHEN jj."DsCondicaoFuncional" = '2' THEN 'Aposentado(a)'
     WHEN jj."DsCondicaoFuncional" = '3' THEN 'Pensonista'
     WHEN jj."DsCondicaoFuncional" = '4' THEN 'Autônomo(a)'
     WHEN jj."DsCondicaoFuncional" = '5' THEN 'Cooerperado(a)'
     WHEN jj."DsCondicaoFuncional" = '6' THEN 'Eventual'
     WHEN jj."DsCondicaoFuncional" = '7' THEN 'Desempregado(a)'
     ELSE '' END as "funccomp", 
comp."DsNomePai" as  "paicomp",
comp."DsNomeMae" as "maecomp",
comp."DsObservacao" as "obscomp",
inf."NmPessoa" as "inform",
case WHEN  char_length(inf."NrRG") < '3' THEN '' ELSE regexp_replace(inf."NrRG", '[^0-9]', '', 'g') END as "rginf",
inf."DsOrgaoExpedidor" as "exprginf",
to_char(inf."DtNascimento", 'yyyy-mm-dd') as "NscInf",
case WHEN inf."IdRelacaoTitularImovel" = '1' THEN 'O próprio'
     WHEN inf."IdRelacaoTitularImovel" = '2' THEN 'Parente'
     WHEN inf."IdRelacaoTitularImovel" = '3' THEN 'Companheiro(a)'
     ELSE '' END as "reltit",
inf."DsObservacao" as "obsinf",
'false' as "copiaRG",
'false' as "copiaCPF",
'false' as "copiaComprovanteResidencia",
'false' as "copiaOutros",
'' as "aguaBeber",
'false' as "DoencaColera",
'false' as "DoencaDengue",
'false' as "DoencaDiarreia",
'false' as "DoencaDoencaRespiratorias",
'false' as "DoencaVerminoses",
'false' as "DoencaViroses",
'false' as "DoencaHipertensao",
'false' as "DoencaDiabetes",
'false' as "DoencaDrogas",
'false' as "DoencaNenhuma",
'' as "DoencaOutros",
'false' as "DoencaColeraCrianca",
'false' as "DoencaDengueCrianca",
'false' as "DoencaDiarreiaCrianca",
'false' as "DoencaRespiratoriasCrianca",
'false' as "DoencaVerminosesCrianca",
'false' as "DoencaVirosesCrianca",
'false' as "DoencaHipertensaoCrianca",
'false' as "DoencaDiabetesCrianca",
'false' as "DoencaDrogasCrianca",
'false' as "DoencaNenhumaCrianca",
'' as "DoencaOutrosCrianca",
'' as "participaAtividadeCulturais",
'' as "qualAtividadeCultural",
'' as "interesseParticipar",
'' as "qualInteresse",
'false' as "praca",
'false' as "vizinho",
'false' as "tv",
'false' as "esportes",
'false' as "bar",
'false' as "radio",
'' as "outro",
'' as "qtdCriacasTemCertidoes",
'' as "qtdCriacasNaoTemCertidoes",
'' as "trabalhouSemanaPassada",
'' as "ondetrabalhouSemanaPassada",
'' as "rendaTitular",
'' as "rendaCompanheiro",
'' as "valorRecebeBCP",
'' as "valorRecebeBolsaFamilia",
'' as "valorRecebeOutroBeneficio",
'' as "quantoTempoExerceTrabalhoAtual",
'' as "despesaEnergiaEletrica",
'' as "despesaAguaEsgoto",
'' as "despesaGasCarvaoLenha",
'' as "despesaAlimentacaoHigieneLimpeza",
'' as "despesaTransporte",
'' as "despesaAluguel",
'' as "despesaMedicamentos",
'' as "pisoPredominante",
'' as "nrComodos",
case when uu."FgTransporteAlternativo" || uu."FgLinhaOnibus" = '2'  then 'true'
     when uu."FgTransporteAlternativo" || uu."FgLinhaOnibus" = '1'  then 'false'
     else 'false' end as "FgTransporteAlternativo",   	
case when uu."FgTrem" = '2' then 'true'
     when uu."FgTrem" = '1' then 'false'
     else 'false' end as "FgTrem",

'false' as "TransporteCarro",
'false' as "TransporteMoto",
'false' as "TransporteBicicleta",
'false' as "TransporteOutro",
'' as "TransporteEspecifiqueOutro",

case when ss."DsEquipamento" = '4' then 'true'
     else 'false' end as "Creche",	
'' as "crecheFacilAcesso",
     
case when ss."DsEquipamento" = '1' then 'true'
     else 'false' end as "ensinoFundamental",
'' as "escolaEnsinoFundamentalFacilAcesso",
     
case when ss."DsEquipamento" = '2' then 'true'
     else 'false' end as "ensinoMedio",
'' as "escolaEnsinoMedioFacilAcesso",
     
case when ss."DsEquipamento" = '5' then 'true'
     else 'false' end as "ensinoProfissionalizante",
'' as "ensinoProfissionalizanteFacilAcesso",
     
case when ss."DsEquipamento" = '3' then 'true'
     else 'false' end as "ensinoSuperior",
'' as "ensinoSuperiorFacilAcesso",
     
case when ss."DsEquipamento" = '6' then 'true'
     else 'false' end as "Hospital",
'' as "hospitalFacilAcesso",
     
case when ss."DsEquipamento" = '7' then 'true'
     else 'false' end as "PostoSaude",
'' as "postoSaudeFacilAcesso",
     
case when ss."DsEquipamento" = '8' then 'true'
     else 'false' end as "Ambulatorio",
'' as "ambulatorioFacilAcesso",
     
case when ss."DsEquipamento" = '9' then 'true'
     else 'false' end as "cras",
'' as "crasFacilAcesso",
     
case when ss."DsEquipamento" = '10' then 'true'
     else 'false' end as "associacaoComunitaria",
'' as "associacaoComunitariaFacilAcesso",
     
case when ss."DsEquipamento" = '11' then 'true'
     else 'false' end as "centroComunitario",
'' as "centroComunitarioFacilAcesso",
     
case when ss."DsEquipamento" = '33' then 'true'
     else 'false' end as "ONG",
'' as "ongFacilAcesso",
     
case when ss."DsEquipamento" = '14' then 'true'
     else 'false' end as "instituicaoReligiosa",
'' as "instituicaoReligiosaFacilAcesso",
     
case when ss."DsEquipamento" = '16' then 'true'
     else 'false' end as "Mercadinho / Mercearia",
'' as "mercadinhoFacilAcesso",
     
case when ss."DsEquipamento" = '17' then 'true'
     else 'false' end as "Bar / Lanchonete",
'' as "barLanchoneteFacilAcesso",
     
case when ss."DsEquipamento" = '19' then 'true'
     else 'false' end as "Padaria",
'' as "padariaFacilAcesso",
     
case when ss."DsEquipamento" = '18' then 'true'
     else 'false' end as "Açougue",
'' as "acougueFacilAcesso",     

case when ss."DsEquipamento" = '15' then 'true'
     else 'false' end as "Supermercado",
'' as "supermercadoFacilAcesso",
     
case when ss."DsEquipamento" = '20' then 'true'
     else 'false' end as "Restaurante",
'' as "restauranteFacilAcesso",

'' as "satisfeitoMoradiaAtual",
'false' as "localizacao",
'false' as "valorAluguel",
'false' as "vizinhanca",
'false' as "servicoPublico",
'false' as "infraestrutura",
'false' as "cedida",
'' as "conheceConjuntoHabitacional",
'' as "dispostoMudarConjuntoHabitacional",

'' as "qtdeMoradoresCancer",
'false' as "titular",
'false' as "companheiro",
'false' as "filho",
'false' as "neto",
'false' as "sobrinho",
'false' as "primo",
'false' as "tio",
'false' as "cunhado",
'false' as "sogro",
'false' as "genroNora",
'false' as "irmao",
'false' as "amigo",

'' as "qtdeMoradoresInsufucienciaRenal",
'false' as "titularRenal",
'false' as "companheiroRenal",
'false' as "filhoRenal",
'false' as "netoRenal",
'false' as "sobrinhoRenal",
'false' as "primoRenal",
'false' as "tioRenal",
'false' as "cunhadoRenal",
'false' as "sogroRenal",
'false' as "genroNoraRenal",
'false' as "irmaoRenal",
'false' as "amigoRenal",

'' as "qtdeMoradoresEpilepsia",
'false' as "titularEpilepsia",
'false' as "companheiroEpilepsia",
'false' as "filhoEpilepsia",
'false' as "netoEpilepsia",
'false' as "sobrinhoEpilepsia",
'false' as "primoEpilepsia",
'false' as "tioEpilepsia",
'false' as "cunhadoEpilepsia",
'false' as "sogroEpilepsia",
'false' as "genroNoraEpilepsia",
'false' as "irmaoEpilepsia",
'false' as "amigoEpilepsia",

'' as "qtdeMoradoresHiv",
'false' as "titularHiv",
'false' as "companheiroHiv",
'false' as "filhoHiv",
'false' as "netoHiv",
'false' as "sobrinhoHiv",
'false' as "primoHiv",
'false' as "tioHiv",
'false' as "cunhadoHiv",
'false' as "sogroHiv",
'false' as "genroNoraHiv",
'false' as "irmaoHiv",
'false' as "amigoHiv",

'' as "qtdeMoradoresDiabetes",
'false' as "titularDiabetes",
'false' as "companheiroDiabetes",
'false' as "filhoDiabetes",
'false' as "netoDiabetes",
'false' as "sobrinhoDiabetes",
'false' as "primoDiabetes",
'false' as "tioDiabetes",
'false' as "cunhadoDiabetes",
'false' as "sogroDiabetes",
'false' as "genroNoraDiabetes",
'false' as "irmaoDiabetes",
'false' as "amigoDiabetes",

'' as "qtdeMoradoresHipertensao",
'false' as "titularHipertensao",
'false' as "companheiroHipertensao",
'false' as "filhoHipertensao",
'false' as "netoHipertensao",
'false' as "sobrinhoHipertensao",
'false' as "primoHipertensao",
'false' as "tioHipertensao",
'false' as "cunhadoHipertensao",
'false' as "sogroHipertensao",
'false' as "genroNoraHipertensao",
'false' as "irmaoHipertensao",
'false' as "amigoHipertensao",

'' as "qtdeMoradoresOutraDoenca",
'' as "especifiqueOutraDoenca",
'false' as "titularOutraDoenca",
'false' as "companheiroOutraDoenca",
'false' as "filhoOutraDoenca",
'false' as "netoOutraDoenca",
'false' as "sobrinhoOutraDoenca",
'false' as "primoOutraDoenca",
'false' as "tioOutraDoenca",
'false' as "cunhadoOutraDoenca",
'false' as "sogroOutraDoenca",
'false' as "genroNoraOutraDoenca",
'false' as "irmaoOutraDoenca",
'false' as "amigoOutraDoenca"

from sishabitafor."BIC" bic
left join sishabitafor."CondicaoCadastro" a on a."IdCondicaoCadastro" = bic."IdCondicaoCadastro"
left join sishabitafor."Orgao" b on b."IdOrgao" = bic."IdOrgaoCadastrador"
left join sishabitafor."Entrevistador" c on c."IdEntrevistador" = bic."IdEntrevistador"
left join sishabitafor."Assentamento" d on d."IdAssentamento" = bic."IdAssentamento"
left join sishabitafor."Bairro" e on e."IdBairro" = bic."IdBairro"
left join sishabitafor."DadosSocioEconomicos" g on g."IdCadastro" = bic."IdCadastro"
left join sishabitafor."Titularidade" f on f."IdTitularidade" = g."IdTitularidade"
left join sishabitafor."CondicaoMoradia" h on h."IdCondicaoMoradia" = g."IdCondicaoMoradia"
left join sishabitafor."Coabitacao" i on i."IdCoabitacao" = g."IdCoabitacao"
left join sishabitafor."ProcedenciaFamilia" j on j."IdProcedenciaFamilia" = g."IdProcedenciaFamilia"
left join sishabitafor."RendaDespesa" k on k."IdRendaDespesa" = g."IdRenda"
left join (select def."IdCadastro", def."NrDeficientes" from sishabitafor."DeficienciaFisica" def where def."IdTipoDeficienciaFisica" = '1')  DefAuditiva on DefAuditiva."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrDeficientes" from sishabitafor."DeficienciaFisica" def where def."IdTipoDeficienciaFisica" = '2')  DefVisual on DefVisual."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrDeficientes" from sishabitafor."DeficienciaFisica" def where def."IdTipoDeficienciaFisica" = '3')  DefMotora on DefMotora."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrDeficientes" from sishabitafor."DeficienciaFisica" def where def."IdTipoDeficienciaFisica" = '4')  DefMental on DefMental."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrMoradoresAssistidos" from sishabitafor."ProgramaSocial" def where def."IdTipoProgramaSocial" = '1')  ProgFederal on ProgFederal."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrMoradoresAssistidos" from sishabitafor."ProgramaSocial" def where def."IdTipoProgramaSocial" = '2')  ProgEstadual on ProgEstadual."IdCadastro" = bic."IdCadastro"
left join (select def."IdCadastro", def."NrMoradoresAssistidos" from sishabitafor."ProgramaSocial" def where def."IdTipoProgramaSocial" = '3')  ProgMunicipal on ProgMunicipal."IdCadastro" = bic."IdCadastro"
left join sishabitafor."CaracteristicasImovel" z on z."IdCadastro" = bic."IdCadastro"
left join sishabitafor."TipologiaImovel" tip on tip."IdTipologiaImovel" = z."IdTipologiaImovel"
left join sishabitafor."TipologiaUso" y on y."IdTipologiaUso" = z."IdTipologiaUso"
left join sishabitafor."CondicaoFundiaria" x on x."IdCondicaoFundiaria" = z."IdCondicaoFundiaria"
left join sishabitafor."TipologiaEdificacao" w on w."IdTipologiaEdificacao" = bic."IdTipologiaEdificacao"
left join sishabitafor."FaixaArea" v on v."IdFaixaArea" = z."IdAreaEdificada"
left join sishabitafor."TipologiaConstrucao" u on u."IdTipologiaConstrucao" = z."IdTipologiaConstrucao"
left join (select t."IdCadastro", t."NrComodo" from sishabitafor."ComposicaoMoradia" as t where t."IdComodo" = '1') NrQuarto on NrQuarto."IdCadastro" = bic."IdCadastro"
left join (select t."IdCadastro", t."NrComodo" from sishabitafor."ComposicaoMoradia" as t where t."IdComodo" = '2') NrSala on NrSala."IdCadastro" = bic."IdCadastro"
left join (select t."IdCadastro", t."NrComodo" from sishabitafor."ComposicaoMoradia" as t where t."IdComodo" = '3') NrCozinha on NrCozinha."IdCadastro" = bic."IdCadastro"
left join (select t."IdCadastro", t."NrComodo" from sishabitafor."ComposicaoMoradia" as t where t."IdComodo" = '4') NrBanheiro on NrBanheiro."IdCadastro" = bic."IdCadastro"
left join (select t."IdCadastro", t."NrComodo" from sishabitafor."ComposicaoMoradia" as t where t."IdComodo" = '5') NrOutros on NrOutros."IdCadastro" = bic."IdCadastro"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '1') RiscoAlagamento on RiscoAlagamento."IdTipoRisco" = z."FgSituacaoRisco"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '2') RiscoInundacao on RiscoInundacao."IdTipoRisco" = z."FgSituacaoRisco"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '3') RiscoDeslizamento on RiscoDeslizamento."IdTipoRisco" = z."FgSituacaoRisco"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '4') RiscoViaFerrea on RiscoViaFerrea."IdTipoRisco" = z."FgSituacaoRisco"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '5') RiscoLinhaAltaTensao on RiscoLinhaAltaTensao."IdTipoRisco" = z."FgSituacaoRisco"
left join (select s."IdTipoRisco", s."DsTipoRisco" from sishabitafor."TipoRisco" as s where s."IdTipoRisco" = '6') RiscoOutro on RiscoOutro."IdTipoRisco" = z."FgSituacaoRisco"
left join sishabitafor."InfraEstrutura" l on l."IdCadastro" = bic."IdCadastro"
left join sishabitafor."OutroColetaEsgoto" m on m."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Drenagem" where "IdTipoDrenagem" = '1') drenGal on drenGal."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Drenagem" where "IdTipoDrenagem" = '2') drenSarj on drenSarj."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Drenagem" where "IdTipoDrenagem" = '3') drenAg on drenAg."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Drenagem" where "IdTipoDrenagem" = '4') drenNAg on drenNAg."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Drenagem" where "IdTipoDrenagem" = '5') drenOut on drenOut."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Pessoa" where "IdTipoPessoa" = '1' and "NrFamilia"::integer = 1) pes on pes."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Pessoa" where "IdTipoPessoa" = '2' and "NrFamilia"::integer = 1) comp on comp."IdCadastro" = bic."IdCadastro"
left join (SELECT *  FROM sishabitafor."Pessoa" where "IdTipoPessoa" = '3' ) inf on inf."IdCadastro" = bic."IdCadastro"
left join sishabitafor."FaixaEtaria" as faixa on faixa."IdFaixaEtaria" = pes."IdFaixaEtaria"
left join sishabitafor."Profissao" cc on cc."IdProfissao" = pes."IdProfissao"
left join sishabitafor."Ocupacao" dd on dd."IdOcupacao" = pes."IdOcupacao"
left join sishabitafor."Bairro" ee on ee."IdBairro" = pes."IdBairroTrabalho"
left join sishabitafor."CondicaoFuncional" ff on ff."IdCondicaoFuncional" = pes."IdCondicaoFuncional"
left join sishabitafor."Profissao" gg on gg."IdProfissao" = comp."IdProfissao"
left join sishabitafor."Ocupacao" hh on hh."IdOcupacao" = comp."IdOcupacao"
left join sishabitafor."Bairro" ii on ii."IdBairro" = comp."IdBairroTrabalho"
left join sishabitafor."CondicaoFuncional" jj on jj."IdCondicaoFuncional" = comp."IdCondicaoFuncional"
left join (SELECT * FROM sishabitafor."Beneficio" where "IdTipologiaBeneficio" = '1' ) as kit on kit."IdCadastro" = bic."IdCadastro"
left join (SELECT * FROM sishabitafor."Beneficio" where "IdTipologiaBeneficio" = '2' ) as mel on mel."IdCadastro" = bic."IdCadastro"
left join sishabitafor."InfraEstrutura" as uu on uu."IdCadastro" = bic."IdCadastro"
left join sishabitafor."Agua" as ag on ag."IdAgua" = uu."IdLigacaoRedeAgua"
left join sishabitafor."EquipamentosDisponiveis" as tt on tt."IdCadastro" = bic."IdCadastro"
left join sishabitafor."Equipamento" as ss on ss."IdEquipamento" = tt."IdEquipamento"
