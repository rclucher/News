({
	doInit: function(component, event, helper) {
        component.set('v.loaded', false);
        
        helper.loadKnowledge(component, helper);
	},
    handleSearch: function(component, event, helper) {
        helper.handleSearch(component, helper);
    },
    previousPage: function(component, event, helper) {
        var currentPage = component.get('v.currentPage');
        
        if (currentPage > 1) {
            currentPage--;
            
            component.set('v.currentPage', currentPage);
            
            helper.paginate(component, helper);
        }
    },
    nextPage: function(component, event, helper) {
        var pageCount = component.get('v.pageCount');
        var currentPage = component.get('v.currentPage');
        
        if (currentPage < pageCount) {
            currentPage++;
            
            component.set('v.currentPage', currentPage);
            
            helper.paginate(component, helper);
        }
    },
    selectArticle: function(component, event, helper) {
        helper.openContent(component, helper, event.target.name, event.target.value);
    },
    closeArticle: function(component, event, helper) {
        helper.closeContent(component, helper);
    },
    selectContentType: function(component, event, helper) {
        var contentType = event.getParam("value");
        
        component.set('v.selectedContentType', contentType);
        
        console.log(contentType);
        
        helper.handleSearch(component, helper);
    }
})