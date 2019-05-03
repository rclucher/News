({
    doInit : function(component, event, helper) {
        if(!component.get("v.componentInitialized")){
            var autoPlay = component.get("v.autoPlay");
            var timeInterval = component.get("v.timeInterval");
            if(autoPlay && !$A.util.isUndefined(timeInterval)){
                helper.showSlides(component,1);
                helper.autoPlay(component,helper,timeInterval);
            }else{
                helper.showSlides(component,1);
            }
        }
    },
    onFileChange : function(component, event, helper){
        helper.showSlides(component,1);
    },
 	// Thumbnail image controls
    currentSlide : function(component, event, helper) {
        var index = event.currentTarget.dataset.index;
        component.set('v.slideIndex',parseInt(index)+1);
        helper.showSlides(component,parseInt(index)+1);
    }
})