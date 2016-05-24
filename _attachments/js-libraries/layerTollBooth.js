function LayerTollBooth() {
    this.casesLoaded =  false;
    this.heatLayerOn = false;
    this.heatMapButton = $('.heatMapButton button');
    this.clustersOn = false;
    this.clusterButton = $('.clusterButton button');
    this.timeOn = false;
    this.timeButton = $('.timeButton button');
//    this.getCasesStatus = function () { return this.CasesLoaded;}
    this.setCasesStatus = function (val){this.casesLoaded = val;}
    this.setHeatLayerStatus = function (val){this.heatLayerOn = val;}
    this.setClustersStatus = function (val){this.clustersOn = val;}
    this.setTimeStatus = function (val){this.timeOn = val;}
    this.toggleCasesLayer = function(heatLayer, heatTimeLayer, casesLayer, casesTimeLayer, map){
        console.log('casesLayer: ' + casesLayer)
        if (!this.timeOn){
            if (this.heatLayerOn || this.clustersOn){
                console.log('casesLayerOff')
                map.removeLayer(casesLayer)
            }
            if (!this.heatLayerOn && !this.clustersOn){
                console.log('casesLayerOn')
                map.addLayer(casesLayer)
            }
        }
        else{
            console.log('timeOn')
            if (this.heatLayerOn || this.clustersOn){
                console.log('casesLayerOff')
                map.removeLayer(timeCasesLayer)
            }
            if (!this.heatLayerOn && !this.clustersOn){
                console.log('casesLayerOn')
                map.addLayer(timeCasesLayer)
            }
        }   
    }
    this.handleHeatMap = function(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer){
        if (!this.timeOn){
            if (this.heatLayerOn){
                console.log('casesLayerOff')
                if (map.hasLayer(casesLayer)){
                    map.removeLayer(casesLayer)
                }
                map.addLayer(heatLayer)
            }
            else{
                console.log('casesLayerOn')
                if (!this.clustersOn){
                    map.addLayer(casesLayer)
                }
                map.removeLayer(heatLayer)
            }
        }
        else{
            if (this.heatLayerOn){
                console.log('casesLayerOff')
                if (map.hasLayer(casesTimeLayer)){
                    map.removeLayer(casesTimeLayer)
                }
                map.addLayer(heatTimeLayer)
            }
            else{
                console.log('casesLayerOn')
                if (!this.clustersOn){
                    map.addLayer(casesTimeLayer)
                }
                map.removeLayer(heatTimeLayer)
            }
        }
    }
    this.handleClusters = function(map, clustersLayer, clustersTimeLayer, casesLayer, casesTimeLayer){
        if (!this.timeOn){
            if (this.clustersOn){
                console.log('casesLayerOff')
                if (map.hasLayer(casesLayer)){
                    map.removeLayer(casesLayer)
                }
                map.addLayer(clustersLayer)
            }
            else{
                console.log('casesLayerOn')
                if (!this.heatLayerOn){
                    map.addLayer(casesLayer)
                }
                map.removeLayer(clustersLayer)
            }
        }
    }
    this.handleTime = function(map, heatLayer, heatTimeLayer, casesLayer, casesTimeLayer){
        console.log('handleTime this.heatLayerOn: '+ this.heatLayerOn)
        if (this.timeOn){
            if (map.hasLayer(casesLayer)){
                map.removeLayer(casesLayer);
            }
            if (map.hasLayer(heatLayer)){
                map.removeLayer(heatLayer);
            }
        }
        else{
            console.log('heatLayerOff')
            if(map.hasLayer(casesTimeLayer)){
                map.removeLayer(casesTimeLayer);
                if (this.casesLoaded){
                    map.addLayer(casesLayer)
                }
            }
            if(map.hasLayer(heatTimeLayer)){
                map.removeLayer(heatTimeLayer);
                if (this.heatLayerOn){
                    map.addLayer(heatLayer)
                }
            }
        }
  
    }
    this.enableDisableButtons = function(state){
      if (state == 'enable'){
          
          $('.heatMapButton button').toggleClass('mdl-button--disabled', false)
          $('.clusterButton button').toggleClass('mdl-button--disabled', false)
          $('.timeButton button').toggleClass('mdl-button--disabled', false)
      }
      else{
          $('.heatMapButton button').toggleClass('mdl-button--disabled', true);
          $('.clusterButton button').toggleClass('mdl-button--disabled', true);
          $('.timeButton button').toggleClass('mdl-button--disabled', true);
      }
    }
    this.handleActiveState = function(button, activeStatus){
        console.log('handleActiveState')
        if (activeStatus =='on'){
            button.removeClass( "mdl-color--cyan" ).addClass( "mdl-color--red" );
        }
        else{
            button.removeClass( "mdl-color--red" ).addClass( "mdl-color--cyan" );
        }
    }
    
}

//layerTollBooth.prototype.getCasesStatus = function() {
//    return this.CasesLoaded;
//};
//layerTollBooth.prototype.setCasesStatus = function(val) {
//    this.CasesLoaded = val;
//};
//    var HeatLayerOn = false;
//    var ClusterOn = false;
//    var TimeOn = false;
    
//    createInstance() {
//        var object = LayerTollBooth;
//        return object;
//    }
//    this.setCasesStatus = function(toggleStatus){
//        console.log('setCasesStatus: '+toggleStatus)
//        console.log('setCasesStatus this.CasesLoaded: '+CasesLoaded)
//        CasesLoaded = toggleStatus
//        console.log('setCasesStatus this.CasesLoaded: '+CasesLoaded)
//    };
//    this.getCasesStatus = function(){
//        return 'CasesLoaded';
//    };
//    this.setHeatStatus = function(toggleStatus){
//        HeatLayerOn = toggleStatus
//    };
//    this.getHeatStatus = function(){
//        return this.HeatLayerOn;
//    };
//    this.setClusterStatus = function(toggleStatus){
//        ClusterOn = toggleStatus
//    };
//    this.getClusterStatus = function(){
//        return this.ClusterOn;
//    };
//    this.handleCasesLayerVisibility = function(){
//        if (heatLayerOn || clustersOn){
//            //turn casesLayer off
//        }
//        
//    };
//    this.handleLayersTime = function(){
//        //if turn off heatmap or cluster{
////      if (!heatLayerOn && !clusterOn){
////          if (!TimeOn){
////              turn on the cases layer
////          }
////          else{
////              turn on time cases
////          }
////      } 
////    }    
//    };
//    this.enableDisableButtons = function(){
////        if (!cases){
////            disable heatLayer
////            disable cluster
////            disable time
////        }
////        else{
////            enable heatLayer
////            enable cluster
////            enable time
////        }
//    };
//}