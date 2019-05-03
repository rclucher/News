({
	showSlides : function(component,n) {
		var i;
        var slideIndex = component.get('v.slideIndex');
        var slides = component.find("mySlide");
        var dots = component.find("slideDot");
        if(!$A.util.isUndefined(slides) && !$A.util.isUndefined(dots) && !$A.util.isUndefined(slideIndex)){
            if (n > slides.length) {
                slideIndex = 1;
            } 
            if (n < 1) {
                slideIndex = slides.length;
            }
            for (i = 0; i < slides.length; i++) {
                $A.util.addClass(slides[i].getElement(),'hide');
            }
            for (i = 0; i < dots.length; i++) {
                $A.util.removeClass(dots[i].getElement(),'active');
            }
            $A.util.removeClass(slides[slideIndex-1].getElement(),'hide');
            $A.util.addClass(dots[slideIndex-1].getElement(),'active');
            component.set('v.slideIndex',slideIndex);
        }
	},
    autoPlay : function(component,helper,timeInterval){
        component.set('v.componentInitialized',true);
        window.setTimeout(
            $A.getCallback(function() {
                var slideIndex = component.get('v.slideIndex');
                component.set('v.slideIndex',slideIndex+1);
                helper.showSlides(component,slideIndex+1);
                helper.autoPlay(component,helper,timeInterval);
            }), timeInterval
        );
    }
})