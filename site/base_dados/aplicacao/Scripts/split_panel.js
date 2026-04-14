// Assets originais
var median3x3 = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Smooth_Median_3x3_Class_2024_SC');
var median5x5 = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Smooth_Median_5x5_Class_2024_SC');
var hardclass = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/CPT_Hard_5100_SC');
var mode3x3 = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Smooth_Mode_3x3_Class_2024_SC');
var mode5x5 = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Smooth_Mode_5x5_Class_2024_SC');
var multiprob = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Multiprob_santa_catarina');
var allpast_embeddings = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/SC_2024_AllPasture_v6_embeddigns-003');
var pastvspast = ee.Image('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/pasture_vs_pasture_Class_2024_SC_asset');
//var mapbiomascol10 = ee.Image('projects/mapbiomas-public/assets/brazil/lulc/collection10/mapbiomas_brazil_collection10_coverage_v2').select('classification_2024').eq(15);
var mapbiomascol10sentinel = ee.Image('users/polianavieira/Pasture_SC_Sentinel_2023').select('classification_2023').eq(1);
var embeddings_moda = ee.Image('projects/ee-felipejesus/assets/SC_2024_AllPasture_v6_embeddigns_hard_5x5_mode');
var pastagem_refinada = ee.Image('users/polianavieira/pastagem_SC_refinado_Beta');
var pastagem_auditada_final = ee.Image('projects/guilhermevaz/assets/class_pasture_SC_audited');
// --- Crie as imagens mascaradas ---

// 1. Mascarar pixels abaixo de 5100 para Mediana e Multiprobabilidade
var masked_median3x3 = median3x3.updateMask(median3x3.select('CPT').gte(5100));
var masked_median5x5 = median5x5.updateMask(median5x5.select('CPT').gte(5100));
var masked_multiprob = multiprob.updateMask(multiprob.select('CPT').gte(5100));
var masked_allpast = allpast_embeddings.updateMask(allpast_embeddings.select('b2').gte(5100));
var masked_emb_moda = embeddings_moda.updateMask(embeddings_moda.select('b1').eq(1))
// 2. Mascarar pixels igual a 0 para Moda e Hardclass
var masked_hardclass = hardclass.updateMask(hardclass.neq(0));
var masked_mode3x3 = mode3x3.updateMask(mode3x3.neq(0));
var masked_mode5x5 = mode5x5.updateMask(mode5x5.neq(0));
var masked_pastvspast = pastvspast.updateMask(pastvspast.neq(0));
var masked_pastagemrefinada = pastagem_refinada.updateMask(pastagem_refinada.eq(1));
var masked_pastagemauditada = pastagem_auditada_final.updateMask(pastagem_auditada_final.eq(1));
//var masked_mapbiomas = mapbiomascol10.updateMask(mapbiomascol10.neq(0));

var masked_mapbiomas_sentinel = mapbiomascol10sentinel.updateMask(mapbiomascol10sentinel.neq(0));

// --- Defina somente os assets mascarados para o seletor da UI ---
var images = {
'Mediana 3x3 Mascarada': masked_median3x3,
'Mediana 5x5 Mascarada': masked_median5x5,
'Classificação Original Mascarada': masked_hardclass,
'Moda 3x3 Mascarada': masked_mode3x3,
'Moda 5x5 Mascarada': masked_mode5x5,
'Multiprobabilidade Mascarada': masked_multiprob,
//'Mapbiomas Coleção 10': masked_mapbiomas,
'Embeddings All Pasture': masked_allpast,
'Pastagem Cultivada x Natural': masked_pastvspast,
'Mapbiomas Sentinel col 9': masked_mapbiomas_sentinel,
'Embeddings 5x5 Moda': masked_emb_moda,
'Pastagem Refinada' : masked_pastagemrefinada,
'Pastagem Auditada' : masked_pastagemauditada
};

// --- Parâmetros de visualização específicos ---
var visParams_median = {
bands: ['CPT'],
min: 5100,
max: 10000,
palette: ['black', 'yellow']
};

var visParams_mode = {
min: 0,
max: 1,
palette: ['black', 'yellow']
};

var visParams_multiprob = {
bands: ['OTH', 'NPT', 'CPT'],
min: 0,
max: 10000,
palette: ['red', 'green', 'blue']
};

// --- NOVOS PARÂMETROS DE VISUALIZAÇÃO COM AS CORES DA MODA ---
var visParams_allpast = {
bands: ['b2'],
min: 5100,
max: 10000,
palette: ['black', 'red'] // Nova cor: preto para 0 e vermelho para 1
};
var visParams_emb_moda = {
min: 0,
max: 1,
palette: ['black', 'yellow'] // Nova cor: preto para 0 e amarelo para 1
};
var visParams_mapbiomas = {
min: 0,
max: 1,
palette: ['black', 'yellow'] // Nova cor: preto para 0 e amarelo para 1
};
var visParams_mapbiomas_sentinel = {
min: 0,
max: 1,
palette: ['black', 'yellow'] // Nova cor: preto para 0 e amarelo para 1
};
var visParams_pastvspast = {
bands: ['NPT'],
min: 5100,
max: 10000,
palette: ['blue', 'yellow'] // Nova cor: azul para 0 e amarelo para 1
};
var visParams_Pastagem_refinada = {
min: 0,
max: 1,
palette: ['black', 'yellow'] // Nova cor: preto para 0 e amarelo para 1
};
var visParams_Pastagem_auditada = {
min: 0,
max: 1,
palette: ['black', 'orange'] // Nova cor: preto para 0 e amarelo para 1
};
//====================================LEGEND========================================//

// Os comentários de legenda foram mantidos por referência
// 1 - RED Color - Missed in the current map
// 2 - BLUE Color - Added in the current map
// 3 - GRAY Color - Stable between both maps

//==================================================================================//
// Background compositions
var realce = 'TRUE' // #'TRUE','AGRI','FALSE','FALSE20'

var dataset = ee.ImageCollection("COPERNICUS/S2_HARMONIZED")

var year = '2024'

// Define a região de interesse para filtrar as imagens.
var cartas = ee.FeatureCollection('projects/ee-felipejesus/assets/reMAP_Santa_Catarina/Santa_CatarinaShp')

var region = cartas

// Filtra e cria mosaicos de imagens Sentinel-2 por bimestre.
var fst_bi = dataset.filterDate(year+'-01-01', year+'-02-28')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

var scd_bi = dataset.filterDate(year+'-03-01', year+'-04-30')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

var thd_bi = dataset.filterDate(year+'-05-01', year+'-06-30')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

var fth_bi = dataset.filterDate(year+'-07-01', year+'-08-31')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

var fiv_bi = dataset.filterDate(year+'-09-01', year+'-10-31')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

var six_bi = dataset.filterDate(year+'-11-01', year+'-12-31')
.filterBounds(region)
.sort('CLOUDY_PIXEL_PERCENTAGE',false)
.mosaic()

// Parâmetros de visualização
var visParamz = {
'TRUE': {'bands': ['B4', 'B3', 'B2'], 'min': [300,350,700],'max': [2200,1900,1700],'gamma':[1.35]},
'AGRI': {'bands': ['B11', 'B8A', 'B5'], 'min' : [1000,600,450], 'max' : [4800,4800,3100],'gamma':[0.8]},
'FALSE': {'bands': ['B8','B4','B3'], 'min' : [1100,700,600], 'max' : [4000,2800,2400],'gamma':[1.1]},
'FALSE20': {'bands': ['B8A','B11','B5'], 'min' : [1700,700,600], 'max' : [4600,5000,2400],'gamma':[1.2]}
}

// Remove a linha original que adicionava o Sentinel ao mapa principal

//Map.addLayer(fst_bi, visParamz[realce], '1° Bimestre - ' + year, false);
//Map.addLayer(scd_bi, visParamz[realce], '2° Bimestre - ' + year, false);
//Map.addLayer(thd_bi, visParamz[realce], '3° Bimestre - ' + year, false);
//Map.addLayer(fth_bi, visParamz[realce], '4° Bimestre - ' + year, false);
//Map.addLayer(fiv_bi, visParamz[realce], '5° Bimestre - ' + year, false);
//Map.addLayer(six_bi, visParamz[realce], '6° Bimestre - ' + year, true);
// Define o tipo de mapa para "HYBRID"
Map.setOptions('HYBRID');



/*
* Configura os mapas e os controles
*/

var leftMap = ui.Map();
leftMap.add(ui.Label('Google'))
leftMap.setControlVisibility({all:true})
leftMap.setOptions('HYBRID')
// Adiciona a imagem Sentinel-2 no índice 1 (fundo) do mapa esquerdo
leftMap.layers().set(1, ui.Map.Layer(six_bi, visParamz[realce], '6° Bimestre - ' + year, true));

var leftSelector = addLayerSelector(leftMap, 0, 'top-left');

var rightMap = ui.Map();
rightMap.add(ui.Label('Google'))
rightMap.setControlVisibility({all:true})
rightMap.setOptions('HYBRID')
// Adiciona a imagem Sentinel-2 no índice 1 (fundo) do mapa direito
rightMap.layers().set(1, ui.Map.Layer(six_bi, visParamz[realce], '6° Bimestre - ' + year, true));

var rightSelector = addLayerSelector(rightMap, 1, 'top-right');


function addLayerSelector(mapToChange, defaultValue, position) {
var label = ui.Label('Escolha uma imagem para visualizar');

function updateMap(selection) {
var visParams;

if (selection.indexOf('Mediana') !== -1) {
visParams = visParams_median;
} else if (selection.indexOf('Moda') !== -1 || selection.indexOf('Classificação Original') !== -1) {
visParams = visParams_mode;
} else if (selection.indexOf('Multiprobabilidade') !== -1) {
visParams = visParams_multiprob;
} else if (selection === 'Embeddings All Pasture') {
visParams = visParams_allpast;
} else if (selection === 'Mapbiomas Coleção 10') {
visParams = visParams_mapbiomas;
} else if (selection === 'Mapbiomas Sentinel col 9') {
visParams = visParams_mapbiomas_sentinel;
} else if (selection === 'Embeddings 5x5 Moda') {
visParams = visParams_emb_moda;
} else if (selection === 'Pastagem Cultivada x Natural') {
visParams = visParams_pastvspast;
} else if (selection === 'Pastagem Refinada') {
visParams = visParams_Pastagem_refinada;
} else if (selection === 'Pastagem Auditada') {
visParams = visParams_Pastagem_refinada;

}

// Adiciona a camada de classificação no índice 0 (topo)
mapToChange.layers().set(0, ui.Map.Layer(images[selection], visParams, selection));
}

var select = ui.Select({items: Object.keys(images), onChange: updateMap});
select.setValue(Object.keys(images)[defaultValue], true);

var controlPanel = ui.Panel({widgets: [label, select], style: {position: position}});

mapToChange.add(controlPanel);
}


//Map.centerObject(median5x5)
/*
* Junta tudo
*/

var splitPanel = ui.SplitPanel({
firstPanel: leftMap,
secondPanel: rightMap,
wipe: true,
style: {stretch: 'both'}
});

ui.root.widgets().reset([splitPanel]);
var linker = ui.Map.Linker([leftMap, rightMap]);

leftMap.setCenter(-50.0, -27.5, 9);