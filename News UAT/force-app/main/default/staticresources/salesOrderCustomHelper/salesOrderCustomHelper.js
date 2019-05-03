require(['./src/cs-full'], function (CS) {
    //globals
    var soScope = undefined;


    function waitUntilSalesOrderLoads() {
        //Sales order needs to be fully loaded before we try to create our observers/watchers
        var soScopeCheck = angular.element(document.getElementsByClassName('salesOrder')).scope();
        if (soScopeCheck === undefined || soScopeCheck.SalesOrderService === undefined ||
            soScopeCheck.SalesOrderService.so === undefined ||
            soScopeCheck.SalesOrderService.so.summarySpec === undefined ||
            soScopeCheck.SalesOrderService.so.summarySpec.tabs === undefined ||
            soScopeCheck.SalesOrderService.so.summarySpec.tabs.length === 0 ||
            soScopeCheck.SalesOrderService.so.summarySpec.tabs[0].sections === undefined)
        {
            //still not loaded
            console.log('Waiting for Sales Order load...');
            setTimeout(waitUntilSalesOrderLoads, 200);
        } else {
            //ready, start executing our logic
            executeLogic();
        }
    }

    function getScopeAndUpdateItems() {
        soScope = angular.element(document.getElementsByClassName('salesOrder')).scope();
        soScope.SalesOrderService.getItems().then(function() {
            discardNonApplicableSections(soScope);
        });

    }


    function discardNonApplicableSections(passedScope) {
        var pScope = (passedScope !== undefined) ? passedScope : angular.element(document.getElementsByClassName('salesOrder')).scope();

        console.log('Running main sections review with ' + passedScope);
        var soSummary = pScope.SalesOrderService.so.summary;
        var currentMainSection = pScope.SalesOrderService.so.summarySpec.tabs[0].sections;

        pScope.SalesOrderService.so.summarySpec.tabs[0].sections = _.filter( currentMainSection, function(section) {

            if (section.product === undefined) {
                return true;
            }
            if (section.product.includes('Print Display') && this.Basket_Products__c.includes(section.product)) {
                return true;
            }
            //extra check for bundles, due to possible bundles without Print Products
            if (section.product.includes('Bundle') && this.Basket_Products__c.includes(section.product)) {
                return true;
            }
        },soSummary);
    }

    function addScopeWatchers() {

        //tab change watcher
        var tabChangeWatcher = soScope.$watch('SalesOrderService.activeContent', function (newValue, oldValue, scope) {
            //user switched from MLE to any other tab

            if (newValue === "Fields" ){
                discardNonApplicableSections(soScope);
            };

        }, true);

        productsWatcher = soScope.$watch('SalesOrderService.so.summary', function (newServ, oldServ, scope) {

            if ((newServ.Basket_Products__c != undefined)) {
                discardNonApplicableSections(scope);
            }
        },true);
    }

    //put all we would like to execute here
    function executeLogic() {
        //initial run, all others should be handled by watcher
        soScope = angular.element(document.getElementsByClassName('salesOrder')).scope();

        //add scope watchers
        addScopeWatchers();
        discardNonApplicableSections(soScope);
    }
    //start it all
    waitUntilSalesOrderLoads();
})

