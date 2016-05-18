//function layerTollBooth () {
//    this.CasesLoaded =  false;
//    this.getCasesStatus = function () {
//        return this.CasesLoaded
//    };
//    this.setCasesStatus = function(val) {
//        console.log('testsetCasesStatus')
//        this.CasesLoaded = val;
//    };
//}
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
    this.handleCasesLayerVisibility = function(){
//        if (heatLayerOn || clustersOn){
//            //turn casesLayer off
//        }
//        
    }
    this.handleLayersTime = function(){
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
    }
    this.enableDisableButtons = function(state){
      if (state = 'enable'){
          
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