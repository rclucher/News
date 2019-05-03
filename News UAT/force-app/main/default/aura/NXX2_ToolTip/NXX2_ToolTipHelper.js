({
	toggleHelper : function(component,event) {
	 var toggleText = component.find("tooltip");
	 $A.util.toggleClass(toggleText, "toggle");
	}
 })