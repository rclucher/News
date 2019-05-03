'use strict';

require(['./src/cs-full'], function (CS) {
	function waitUntilSalesOrderLoads() {	
		//Sales order needs to be fully loaded before we try to create our observers/watchers
		var soScope = angular.element(document.getElementsByClassName('salesOrder')).scope();
		if (soScope === undefined) {
			//still not loaded
			console.log('Waiting for Sales Order load...');
			setTimeout(waitUntilSalesOrderLoads, 200);
		} else {
			//ready, start executing our logic
			executeLogic();
		}
	}
	
	function correctApprovalLinkTarget(retryCount) {
		if (retryCount === undefined) {
			retryCount = 10;
		}
		//Get Click Approve button that start approval from all Upload approval records (if more than one)
		//and set link to open in the same tab
		var caIcons = document.getElementsByClassName('click-approve icon-document-text-add ng-scope');
		if (caIcons.length > 0) {
			Array.from(caIcons).forEach(function(approveBtn){approveBtn.target="_top"});
		} else if (retryCount > 0){
			//might still be loading so quick fix is to give it more time
			console.log('Waiting for related tab to load...');
			setTimeout(correctApprovalLinkTarget, 300, retryCount-1);
		}
	}
	
	// Callback function to execute when mutations are observed
	var callback = function(mutationsList) {
		for(var mutation of mutationsList) {
			if (mutation.type == 'childList') {
				correctApprovalLinkTarget(1);
			}
		}
	};
	
	//mutation observer to capture changes on upload approval records list (i.e. new record created)
	function createObserver(retryCount) {
		if (retryCount === undefined) {
			retryCount = 10;
		}
		// Select the node that will be observed for mutations: dataTable div of  UA records list
		var targetNode = document.querySelectorAll('div.salesOrderRelatedItems.ng-scope')[0];
		// Options for the observer (which mutations to observe)
		var config = { childList: true, subtree: true };
		if (targetNode !== undefined) {
			// Create an observer instance linked to the callback function only if we have a node
			var observer = new MutationObserver(callback);
			// Start observing the target node for configured mutations
			observer.observe(targetNode, config);
			console.log('CA observer created.');
		} else if (retryCount > 0){
			//give it some more time
			console.log('Waiting for attachments to load...');
			setTimeout(createObserver, 300, retryCount-1);
		}
	}
	
	function addWatchers() {
		var soScope = angular.element(document.getElementsByClassName('salesOrder')).scope();
		var tabChangeWatcher = soScope.$watch('SalesOrderService.activeContent', function (newValue, oldValue, scope) {
				//user switched to Related tab
				if (newValue == "RelatedItems" && oldValue != "RelatedItems"){
					console.log('Switched to Related tab');
					correctApprovalLinkTarget(10);
					//create observer as we probably don't have it (SO rarely opens on Related tab)
					createObserver(10);
				};
			}, true);
	}
	
	//put all we would like to execute here
	function executeLogic() {
		//initial run, all others should be handled by watcher
		correctApprovalLinkTarget(0);
		addWatchers();
		createObserver(0);
	}
	//start it all
	waitUntilSalesOrderLoads();
})