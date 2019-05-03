/**
 * Class that contains Product Node cloning logic.
 * Also used as a page controller for invoking cloning logic from Details page button.
 * Cloning consists of:
 *  - cloning Product Node record and adjusting: Effective Start Date, Effective End Date, External Id
 *  - cloning related Child Product Node records
 *  - cloning related Node Advert Assignments records
 *  - cloning related Default Rate Card record
 *  - cloning related Rate Card Item Price records
 *  - cloning related Line Item Threshold records
 *
 * If isNewBespokeMode = true then we are using original Product Node as a template for new bespoke product.
 * This means cloned Product Node will have:
 *  - External Id = Latest External Id for given record type from the system (not from original Product Node) + 1
 *  - Effective Start Date = TODAY
 *  - Effective End Date = DEFAULT_END_DATE
 *  - Active = false (as it would overlap with original Product Node)
 *
 * Note: Cloning is recursive so for every related Child Product Node we are repeating all the cloning steps mentioned above!
 * Cloning is allowed only for Print Publication and Xtend levels and below and new instance and date overlap checks are ran only on current product node level!
 * All related records that are created by cloning will inherit Active, Effective Start Date and Effective End Date values from the
 * selected product node (top level for page context) i.e. all created records will have matching values.
 */
public with sharing class ProductNodeCloning {
	//defaults
	private static final String DEFAULT_EXTERNAL_ID       = 'PD-000000';
	private static final String ERROR_MSG_DATE            = '{0} {1} ({2}) causes Effective Start Date/Effective End Date overlap with existing records: ';
	private static final String ERROR_MSG_USE_NEW         = '{0} ({1}) already superseded by another {0} ({2}). Please use most recent one for cloning!';
	private static final String ERROR_MSG_END_DATE_UPDATE = '{0} ({1}) uses default Effective End Date ({2}). Please set correct Effective End Date and try again!';
	private static final String ERROR_MSG_RECORDTYPE      = 'Product Node ({0}) is not of allowed record types ({1}). Please select Product Node with correct record type and try again!';
	private static final String MISSING_DATES             = '{0} ({1}) has no Effective Start/End Date defined. Please set correct Effective Start/End Date and try again!';
	private static final String NO_CHANGES                = 'No changes detected. Please change one of the editable fields and try again!';
	//TODO move to labels
	private static final String NEW_VERSION_FORMAT = 'Creates new {0} that will replace selected {0} (new version of the same {0}).<br/>See Resulting {0} (simulated) section for simulated output.';
	private static final String NEW_BESPOKE_FORMAT = 'Creates new {0} that will use selected {0} as a template.<br/>See Resulting {0} (simulated) section for simulated output.';
	//should be used only on Xtend or publication level product nodes
	@testVisible private static final List<String> ALLOWED_RECORDTYPES = new List<String> {'Print Publication', 'Print Section', 'Print Subsection', 'Print Position', 'Xtend Product'};
	//using GMT to avoid running user time-zone differences
	@testVisible private static final Date NOW_DATE         = DateTime.now().dateGMT();
	@testVisible private static final Date DEFAULT_END_DATE = DateTime.newInstanceGmt(2099,12,31).dateGMT();
	//top level start and end date that we will propagate on all related records
	private static Date parentStartDate;
	private static Date parentEndDate;
	//master map for storing all old to new ids across all cloned records, updated periodically as we insert records
	//contains only complete pair i.e, there will be no oldId key until we have a newId value
	private Map<Id, Id> oldToNewIdMap = new Map<Id, Id>();
	//contains all old and new records as this is used to populate oldToNewIdMap
	private List<OldToNewWrapper> oldToNewRecords = new List<OldToNewWrapper>();
	//our top level Product Node
	private csmso__Product_Node__c bespokeProduct;
	//cloned top level Product Node, for redirect
	private csmso__Product_Node__c clonedBespokeProduct;
	public String selectedOperation {get; set;}
	public csmso__Product_Node__c forecastResult { get; set; }
	//used to query and group product nodes by levels
	public Map<Integer, Map<Id, csmso__Product_Node__c>> levelToProductNodesMap {
		get {
			if (levelToProductNodesMap == null && bespokeProduct != null) {
				levelToProductNodesMap = new Map<Integer,Map<Id, csmso__Product_Node__c>>();
				Set<Id> productIds     = new Set<Id>{bespokeProduct.Id};
				Integer level = 0;
				//SOQL in a loop as we expect only up to 5 levels and it is more safer than trying to use Breadcrumb
				//for identifying product nodes that belong to our bespokeProduct
				do {
					String query;
					if (level == 0) {
						//we need our top level so filtering on Id field
						query = 'SELECT ' + CS_Utils.getSobjectFields('csmso__Product_Node__c') + ' FROM csmso__Product_Node__c WHERE Id IN :productIds';
					} else {
						//all other levels are queried by their parents
						query = 'SELECT ' + CS_Utils.getSobjectFields('csmso__Product_Node__c') + ' FROM csmso__Product_Node__c WHERE csmso__Parent_Product_Node__c IN :productIds';
					}
					List<csmso__Product_Node__c> pnList = Database.query(query);
					//create new level only if we have something
					if (!pnList.isEmpty()) {
						Map<Id, csmso__Product_Node__c> levelMap = new Map<Id, csmso__Product_Node__c>(pnList);
						levelToProductNodesMap.put(level, levelMap.clone());//break the reference or we will lose last level
						productIds = levelMap.keySet();
						level     += 1;
					} else {
						//clear productIds as we need to break out of while
						productIds.clear();
					}
				} while (!productIds.isEmpty());
			}
			return levelToProductNodesMap;
		}
		set;
	}
	//supported modes
	public List<SelectOption> operations {
		get {
			if (operations == null || operations.isEmpty()) {
				operations = new List<SelectOption>();
				operations.add(new SelectOption('newVersion', 'Create New ' + bespokeProductRTname + ' Version'));
				operations.add(new SelectOption('newBespoke', 'Create New ' + bespokeProductRTname));
				operations.add(new SelectOption('propagateChanges','Propagate Changes'));
				selectedOperation = operations[0].getValue();//New Instance mode is default (newVersion)
			}
			return operations;
		}
		set;
	}
	//description getter
	public String operationDescription {
		get {
			switch on selectedOperation {
				when 'propagateChanges' {
					operationDescription  = 'Saves changes made to editable fields and propagates changes to all related records.';
					operationDescription += '<br/><b>Note:</b> only changed values will be propagated (i.e. only updated fields are used when propagating changes).';
				}
				when 'newVersion' {
					operationDescription = String.format(NEW_VERSION_FORMAT, new List<String>{bespokeProductRTname});
				}
				when 'newBespoke' {
					operationDescription = String.format(NEW_BESPOKE_FORMAT, new List<String>{bespokeProductRTname});
				}
			}
			return operationDescription;
		}
		set;
	}
	//latest ExternalId in the system, record type dependent
	private String latestExternalId {
		get {
			if (latestExternalId == null) {
				List<csmso__Product_Node__c> productNodeLatestId = [SELECT Id, ExternalID__c
																	FROM csmso__Product_Node__c
																	WHERE RecordTypeId = :bespokeProduct.RecordTypeId
																						 ORDER BY ExternalID__c DESC NULLS LAST LIMIT 1];
				latestExternalId = productNodeLatestId.isEmpty() ? DEFAULT_EXTERNAL_ID : productNodeLatestId[0].ExternalID__c;
			}
			//if latest version is of expected format then discard version information
			if (latestExternalId.length() > 8 && latestExternalId.countMatches('-') > 1) {
				latestExternalId = latestExternalId.substringBeforeLast('-');
			}
			return latestExternalId;
		}
		set;
	}
	//helper to avoid hardcoding values in controller and VF page
	private Map<Id, String> idToRecordtypeNameMap {
		get {
			if (idToRecordtypeNameMap == null) {
				idToRecordtypeNameMap = new Map<Id, String>();
				for (Schema.RecordTypeInfo rtInfo :Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName().values()) {
					idToRecordtypeNameMap.put(rtInfo.getRecordTypeId(), rtInfo.getName());
				}
			}
			return idToRecordtypeNameMap;
		}
		set;
	}
	//helper getter for defining current top level parent product record type name, used in controller and VF page
	public String bespokeProductRTname {
		get {
			return idToRecordtypeNameMap.get(bespokeProduct.RecordTypeId);
		} set;
	}

	//Controller when used from details page
	public ProductNodeCloning(ApexPages.StandardController stdController) {
		this.bespokeProduct   = (csmso__Product_Node__c)stdController.getRecord();
		this.isNewBespokeMode = false;
	}

	//additional constructor if we need to use this from other places
	public ProductNodeCloning(csmso__Product_Node__c bespokeProduct) {
		this.bespokeProduct   = bespokeProduct;
		this.isNewBespokeMode = false;
	}

	public PageReference startOperation() {
		//clean start
		ApexPages.getMessages().clear();
		PageReference returnPage;
		Savepoint sp = Database.setSavepoint();

		//all DML exceptions "converted" to page messages and transaction aborted
		try {
			//start logic
			if (selectedOperation == 'propagateChanges') {
				//validate our starting point again to see if editable fields are still within allowed values
				if (allowCloning(forecastResult, true) && !overlapsWithExistingProductNodes(forecastResult)) {
					propagateChanges();
				}
			} else {
				if (allowCloning(bespokeProduct, true) && !overlapsWithExistingProductNodes(bespokeProduct)) {
					cloneProductNodeHierarchy();
				}
			}
		} catch (DmlException dmlEx) {
			ApexPages.addMessages(dmlEx);
		}
		//either something failed and we "converted" it to page message or allowCloning generated them
		if (ApexPages.hasMessages()) {
			//if we have messages then don't navigate away, let users see the message and they can use the cancel button
			returnPage = null;
			//rollback any changes we made
			Database.rollback(sp);
		} else if (clonedBespokeProduct != null) {
			returnPage = new PageReference('/' + clonedBespokeProduct.Id);
		}

		return returnPage;
	}

	/**
	 * Method that does the actual cloning.
	 *
	 * IMPORTANT:
	 * This method loads its context and creates records in phases (to have access to new Ids) and it
	 * consumes:
	 *  - 4 x SOQL
	 *  - (N + 2) x DML where N = size of levelToProductNodesMap.
	 *  Example: 4 level deep hierarchy will consume 6 DMLs and 4 SOQLs).
	 * Modify carefully as ordering of inserts is crucial for functionality (parents inserted before child records).
	 */
	private void cloneProductNodeHierarchy() {
		System.debug('Cloning started...');
		Set<Id> productNodeIds                            = new Set<Id>();
		List<csmso__Product_Node__c> clonedProductNodes   = new List<csmso__Product_Node__c>();
		List<csmso__Node_Advert_Assignment__c> loadedNAAs = new List<csmso__Node_Advert_Assignment__c>();
		List<csmso__Node_Advert_Assignment__c> clonedNAAs = new List<csmso__Node_Advert_Assignment__c>();
		List<csmso__Rate_Card__c> loadedRateCards         = new List<csmso__Rate_Card__c>();
		List<csmso__Rate_Card__c> clonedRateCards         = new List<csmso__Rate_Card__c>();
		List<csmso__Rate_Card_Item_Price__c> loadedRCIPs  = new List<csmso__Rate_Card_Item_Price__c>();
		List<csmso__Rate_Card_Item_Price__c> clonedRCIPs  = new List<csmso__Rate_Card_Item_Price__c>();
		List<Line_Item_Threshold__c> loadedLITs           = new List<Line_Item_Threshold__c>();
		List<Line_Item_Threshold__c> clonedLITs           = new List<Line_Item_Threshold__c>();
		//load context
		//get Product Node Ids from all levels to be used in related records queries
		for (Integer level : levelToProductNodesMap.keySet()) {
			productNodeIds.addAll(levelToProductNodesMap.get(level).keySet());
		}
		String query;
		//Node Advert Assignment
		query      = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Node_Advert_Assignment__c') + ' FROM csmso__Node_Advert_Assignment__c WHERE csmso__Title_Product_Node__c IN :productNodeIds';
		loadedNAAs = Database.query(query);
		//Default Rate Card
		query           = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Rate_Card__c') + ' FROM csmso__Rate_Card__c WHERE csmso__Product_Node__c IN :productNodeIds';
		loadedRateCards = Database.query(query);
		//Rate Card Item Price
		query       = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Rate_Card_Item_Price__c') + ' FROM csmso__Rate_Card_Item_Price__c WHERE csmso__Product_Node__c IN :productNodeIds';
		loadedRCIPs = Database.query(query);
		//Line Item Threshold
		query      = 'SELECT '+ CS_Utils.getSobjectFields('Line_Item_Threshold__c') + ' FROM Line_Item_Threshold__c WHERE Product_Node__c IN :productNodeIds';
		loadedLITs = Database.query(query);

		//1. Product Nodes, each level processed and inserted individually as next level needs to know their new parent Id
		for (Integer level : levelToProductNodesMap.keySet()) {
			System.debug('Product nodes number for level '+ level + ' : ' + levelToProductNodesMap.get(level).size());
			Boolean isTopLevel = level == 0;
			//clear previous values as each level will be inserted
			clonedProductNodes = new List<csmso__Product_Node__c>();
			for (csmso__Product_Node__c tempProductNode :levelToProductNodesMap.get(level).values()) {
				csmso__Product_Node__c clonedProductNode = cloneProductNode(tempProductNode, isTopLevel);
				//register old to new pair and add to insert list
				oldToNewRecords.add(new OldToNewWrapper(tempProductNode, clonedProductNode));
				clonedProductNodes.add(clonedProductNode);
			}
			//we need to insert it
			insertSobjects(clonedProductNodes);
			//if it was top level then maintain global variable and update original product node
			if (isTopLevel) {
				//using/setting clonedBespokeProduct as we need to have it set due to redirect at the end
				clonedBespokeProduct           = clonedProductNodes[0];//top level has only one
				bespokeProduct.New_Instance__c = clonedBespokeProduct.Id;
				update bespokeProduct;
			}
		}
		//2. Node Advert Assignments
		System.debug('Number of NAA: ' + loadedNAAs.size());
		for (csmso__Node_Advert_Assignment__c nodeAdverAssignment :loadedNAAs) {
			csmso__Node_Advert_Assignment__c clonedNAA = cloneNAA(nodeAdverAssignment);
			//register old to new pair and add to insert list
			oldToNewRecords.add(new OldToNewWrapper(nodeAdverAssignment, clonedNAA));
			clonedNAAs.add(clonedNAA);
		}
		//not inserting NAA right away as we need them only for last insert, saving one DML
		//3. Default Rate Card
		System.debug('Number of Default Rate Cards: ' + loadedRateCards.size());
		for (csmso__Rate_Card__c rateCard :loadedRateCards) {
			csmso__Rate_Card__c clonedRC = cloneRateCard(rateCard);
			//register old to new pair and add to insert list
			oldToNewRecords.add(new OldToNewWrapper(rateCard, clonedRC));
			clonedRateCards.add(clonedRC);
		}
		//insert both NAA and RC as we need them for last step
		List<sObject> forInsert = new List<sObject>();
		forInsert.addAll((List<sObject>)clonedNAAs);
		forInsert.addAll((List<sObject>)clonedRateCards);
		insertSobjects(forInsert);
		//4. Rate Card Item Price
		System.debug('Number of RCIP:' + loadedRCIPs.size());
		for (csmso__Rate_Card_Item_Price__c rcip :loadedRCIPs) {
			csmso__Rate_Card_Item_Price__c clonedRCIP = cloneRateCardItemPrice(rcip);
			//register old to new pair and add to insert list
			oldToNewRecords.add(new OldToNewWrapper(rcip, clonedRCIP));
			clonedRCIPs.add(clonedRCIP);
		}
		//not inserting RCIP right away, saving one DML
		//5. Line Item Threshold
		System.debug('Number of LIT:' + loadedLITs.size());
		for (Line_Item_Threshold__c lit :loadedLITs) {
			Line_Item_Threshold__c clonedLIT = cloneLineItemThreshold(lit);
			//register old to new pair and add to insert list
			oldToNewRecords.add(new OldToNewWrapper(lit, clonedLIT));
			clonedLITs.add(clonedLIT);
		}
		//final insert, insert both RCIP and LIT records
		forInsert = new List<sObject>();
		forInsert.addAll((List<sObject>)clonedRCIPs);
		forInsert.addAll((List<sObject>)clonedLITs);
		insertSobjects(forInsert);
	}

	/**
	 * Instead of cloning it updates selected Product Node and updates equivalent fields
	 * on all child product nodes (propagates update).
	 * Additionally updates other related records, depending on updated fields.
	 * As a best practice update needs to prevent dirty write i.e. we need to update only
	 * changed fields regardless of what we had queried.
	 * IMPORTANT:
	 * Logic doesn't propagate all editable fields (from page), just ones that had its value changed.
	 * This is so that user can control which changes to propagate.
	 * Changes are identified by comparing this.forecastResult and this.bespokeProduct
	 * as that is the same record loaded from the system and unchanged by user.
	 * Deleting field values is not supported (for now) i.e. null value is treated as no change.
	 * Even if only Name was updated and only top level product node should be updated we are doing full hierarchy
	 * update as Breadcrumb needs to be updated (currently a flow update).
	 */
	private void propagateChanges() {
		System.debug('Propagate changes started...');
		//keeping update context locally
		Boolean isActive;
		Date startDate;
		Date endDate;
		String name;
		Id calendarId;
		//adding support for all related records, we might not use them all
		String query;
		Set<Id> productNodeIds                            = new Set<Id>();
		List<csmso__Product_Node__c> updateProductNodes   = new List<csmso__Product_Node__c>();
		List<csmso__Node_Advert_Assignment__c> updateNAAs = new List<csmso__Node_Advert_Assignment__c>();
		List<csmso__Node_Advert_Assignment__c> loadedNAAs = new List<csmso__Node_Advert_Assignment__c>();
		List<csmso__Rate_Card__c> updateRateCards         = new List<csmso__Rate_Card__c>();
		List<csmso__Rate_Card__c> loadedRateCards         = new List<csmso__Rate_Card__c>();
		//identify changes
		if (this.forecastResult.Is_Active__c != this.bespokeProduct.Is_Active__c) {
			isActive = this.forecastResult.Is_Active__c;
		}
		if (this.forecastResult.Name != this.bespokeProduct.Name) {
			name = this.forecastResult.Name;
		}
		if (this.forecastResult.Effective_Start_Date__c != this.bespokeProduct.Effective_Start_Date__c) {
			startDate = this.forecastResult.Effective_Start_Date__c;
		}
		if (this.forecastResult.Effective_End_Date__c != this.bespokeProduct.Effective_End_Date__c) {
			endDate = this.forecastResult.Effective_End_Date__c;
		}
		if (this.forecastResult.csmso__Calendar__c != this.bespokeProduct.csmso__Calendar__c) {
			calendarId = this.forecastResult.csmso__Calendar__c;
		}
		//not allowing "empty" update
		if (isActive == null && startDate == null && endDate == null && name == null && calendarId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, NO_CHANGES));
			return;
		}

		//if we reached this far it means we have changes to propagate
		//load context
		//get Product Node Ids from all levels to be used in related records queries
		for (Integer level : levelToProductNodesMap.keySet()) {
			productNodeIds.addAll(levelToProductNodesMap.get(level).keySet());
		}

		//ready for changes, ALWAYS create new record instance to prevent dirty write (since we are loading all possible fields)
		//Product Nodes, same change applies for all levels, no need to check for changes as we already know there is something to update
		//IMPORTANT: even if only Name was updated and only top level product node should be updated we are doing full hierarchy
		//update as Breadcrumb needs to be updated (currently a flow update)
		for (Integer level : levelToProductNodesMap.keySet()) {
			System.debug('Product nodes number for level '+ level + ' : ' + levelToProductNodesMap.get(level).size());
			for (csmso__Product_Node__c productNode :levelToProductNodesMap.get(level).values()) {
				//create new record instance with new field values and add to update list
				csmso__Product_Node__c tempProdNode = new csmso__Product_Node__c(Id = productNode.Id);
				//must not overwrite filed value with null if field wasn't changed
				if (isActive != null) {
					tempProdNode.Is_Active__c = isActive;
				}
				if (name != null && level == 0) {
					//IMPORTANT: Name should be updated ONLY on top level, otherwise we will overwrite all PN names!
					tempProdNode.Name = name;
				}
				if (startDate != null) {
					tempProdNode.Effective_Start_Date__c = startDate;
				}
				if (endDate != null) {
					tempProdNode.Effective_End_Date__c = endDate;
				}
				if (calendarId != null) {
					tempProdNode.csmso__Calendar__c = calendarId;
				}
				//add to update list
				updateProductNodes.add(tempProdNode);
			}
		}
		//Node Advert Assignment, running logic only if relevant fields were updated, saving SOQLs
		if (isActive != null || startDate != null || endDate != null) {
			query      = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Node_Advert_Assignment__c') + ' FROM csmso__Node_Advert_Assignment__c WHERE csmso__Title_Product_Node__c IN :productNodeIds';
			loadedNAAs = Database.query(query);
			System.debug('Number of NAA: ' + loadedNAAs.size());
			for (csmso__Node_Advert_Assignment__c nodeAdverAssignment :loadedNAAs) {
				csmso__Node_Advert_Assignment__c tempNAA = new csmso__Node_Advert_Assignment__c(Id = nodeAdverAssignment.Id);
				//must not overwrite filed value with null if field wasn't changed
				if (isActive != null) {
					tempNAA.Is_Active__c = isActive;
				}
				if (startDate != null) {
					tempNAA.Effective_Start_Date__c = startDate;
				}
				if (endDate != null) {
					tempNAA.Effective_End_Date__c = endDate;
				}
				//add to update list
				updateNAAs.add(tempNAA);
			}
		}
		//Rate Card
		if (startDate != null || endDate != null) {
			query           = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Rate_Card__c') + ' FROM csmso__Rate_Card__c WHERE csmso__Product_Node__c IN :productNodeIds';
			loadedRateCards = Database.query(query);
			System.debug('Number of Default Rate Cards: ' + loadedRateCards.size());
			for (csmso__Rate_Card__c rateCard :loadedRateCards) {
				csmso__Rate_Card__c tempRC = new csmso__Rate_Card__c(Id = rateCard.Id);
				//must not overwrite filed value with null if field wasn't changed
				if (startDate != null) {
					tempRC.csmso__From_Date__c = startDate;
				}
				if (endDate != null) {
					tempRC.csmso__To_Date__c = endDate;
				}
				//add to update list
				updateRateCards.add(tempRC);
			}
		}
		//Rate Card Item Price and Line Item Threshold records have nothing to update
		//Update all records
		List<sObject> forUpdate = new List<sObject>();
		forUpdate.addAll((List<sObject>)updateProductNodes);
		forUpdate.addAll((List<sObject>)updateNAAs);
		forUpdate.addAll((List<sObject>)updateRateCards);
		System.debug('Number of records to update: ' + forUpdate.size());
		update forUpdate;

		//last thing to do is to update clonedBespokeProduct as we use it for redirect.
		//simply setting it to original product node is sufficient
		this.clonedBespokeProduct = this.bespokeProduct;
	}

	/**
	 * Returns cloned product node (no DML) with all the fields adjusted as required.
	 * Reparenting logic needs to have Parent Product Node record inserted.
	 */
	private csmso__Product_Node__c cloneProductNode(csmso__Product_Node__c productNodeToClone, Boolean isTopLevel) {
		//create cloned product node and adjust it
		csmso__Product_Node__c clonedProductNode = productNodeToClone.clone(false, true);
		Date startDate;
		Date endDate;
		String extId;
		//we run this logic only on top level, all other levels will inherit the values
		if (isTopLevel) {
			startDate = isNewBespokeMode ? NOW_DATE : productNodeToClone.Effective_End_Date__c.addDays(1);
			endDate   = DEFAULT_END_DATE;
			//set globals for next recursion calls
			parentStartDate = startDate;
			parentEndDate   = endDate;
			if (isNewBespokeMode) {
				//safe as nulls are not changed in CS_Utils.incrementString(), incrementing bundle part
				latestExternalId = CS_Utils.incrementString(latestExternalId);
				extId            = latestExternalId + '-001';
			} else {
				extId = CS_Utils.incrementString(productNodeToClone.ExternalID__c);
			}
		} else {
			startDate = parentStartDate;
			endDate   = parentEndDate;
			extId     = null;
		}
		//update fields
		//only top level for newBespoke mode will be inactive, all other levels for all other operations will be as is
		clonedProductNode.Is_Active__c            = (isNewBespokeMode && isTopLevel) ? false : clonedProductNode.Is_Active__c;
		clonedProductNode.Effective_Start_Date__c = startDate;
		clonedProductNode.Effective_End_Date__c   = endDate;
		clonedProductNode.Old_Instance__c         = isNewBespokeMode ? null : productNodeToClone.Id;
		clonedProductNode.New_Instance__c         = null;
		clonedProductNode.ExternalID__c           = extId;
		clonedProductNode.ExternalHashID__c       = null;
		clonedProductNode.ExternalParentHashID__c = null;
		clonedProductNode.csmso__Code__c          = null; //needs to be set to Id but we don't have it yet, updated by flow
		//reparent if we know new Id, top level doesn't require reparenting as it is special case, we will handle it outside
		if (!isTopLevel && oldToNewIdMap.containsKey(clonedProductNode.csmso__Parent_Product_Node__c)) {
			clonedProductNode.csmso__Parent_Product_Node__c = oldToNewIdMap.get(clonedProductNode.csmso__Parent_Product_Node__c);
		} else if (!isTopLevel) {
			throw new ProcessingException('Possible integrity issue, cloned record not found for Id: ' + productNodeToClone.Id);
		}
		return clonedProductNode;
	}

	/**
	 * Method that holds core logic for cloning Node Advert Assignment records.
	 * Reparenting logic needs to have Product Node record inserted
	 */
	private csmso__Node_Advert_Assignment__c cloneNAA(csmso__Node_Advert_Assignment__c naaToClone) {
		csmso__Node_Advert_Assignment__c clonedNAA = naaToClone.clone(false, true);
		clonedNAA.ExternalID__c           = null;
		clonedNAA.ExternalHashID__c       = null;
		clonedNAA.ExternalParentHashID__c = null;
		//match top level values
		clonedNAA.Effective_Start_Date__c = parentStartDate;
		clonedNAA.Effective_End_Date__c   = parentEndDate;
		//reparent if we know new Id
		if (oldToNewIdMap.containsKey(clonedNAA.csmso__Title_Product_Node__c)) {
			clonedNAA.csmso__Title_Product_Node__c = oldToNewIdMap.get(clonedNAA.csmso__Title_Product_Node__c);
		} else {
			throw new ProcessingException('Possible integrity issue, cloned record not found for Id: ' + naaToClone.Id);
		}
		return clonedNAA;
	}

	/**
	 * Method that holds core logic for cloning Rate Card records.
	 * Reparenting logic needs to have Product Node record inserted
	 */
	private csmso__Rate_Card__c cloneRateCard(csmso__Rate_Card__c rateCardToClone) {
		csmso__Rate_Card__c clonedRC = rateCardToClone.clone(false, true);
		clonedRC.ExternalID__c           = null;
		clonedRC.ExternalHashID__c       = null;
		clonedRC.ExternalParentHashID__c = null;
		//match top level values
		clonedRC.csmso__From_Date__c = parentStartDate;
		clonedRC.csmso__To_Date__c   = parentEndDate;
		//reparent if we know new Id
		if (oldToNewIdMap.containsKey(clonedRC.csmso__Product_Node__c)) {
			clonedRC.csmso__Product_Node__c = oldToNewIdMap.get(clonedRC.csmso__Product_Node__c);
		} else {
			throw new ProcessingException('Possible integrity issue, cloned record not found for Id: ' + rateCardToClone.Id);
		}
		return clonedRC;
	}

	/**
	 * Method that holds core logic for cloning Rate Card Item Price records.
	 * Reparenting logic needs to have these records inserted: Product Node, Rate Card, Node Advert Assignment
	 */
	private csmso__Rate_Card_Item_Price__c cloneRateCardItemPrice(csmso__Rate_Card_Item_Price__c rateCardItemPriceToClone) {
		csmso__Rate_Card_Item_Price__c clonedRCIP = rateCardItemPriceToClone.clone(false, true);
		clonedRCIP.ExternalID__c             = null;
		clonedRCIP.ExternalHashID__c         = null;
		clonedRCIP.ExternalNAAHashID__c      = null;
		clonedRCIP.ExternalParentHashID__c   = null;
		clonedRCIP.ExternalRateCardHashID__c = null;
		//reparent if we know new Ids, all or nothing mode
		List<Id> oldIds = new List<Id>{
			clonedRCIP.csmso__Product_Node__c,
			clonedRCIP.csmso__Rate_Card__c,
			clonedRCIP.csmso__Advert_Assignment__c
		};
		if (oldToNewIdMap.keySet().containsAll(oldIds)) {
			clonedRCIP.csmso__Product_Node__c      = oldToNewIdMap.get(clonedRCIP.csmso__Product_Node__c);
			clonedRCIP.csmso__Rate_Card__c         = oldToNewIdMap.get(clonedRCIP.csmso__Rate_Card__c);
			clonedRCIP.csmso__Advert_Assignment__c = oldToNewIdMap.get(clonedRCIP.csmso__Advert_Assignment__c);
		} else {
			throw new ProcessingException('Possible integrity issue, cloned records not found for Ids: ' + String.join(oldIds,', '));
		}

		return clonedRCIP;
	}

	/**
	 * Method that holds core logic for cloning Line Item Threshold records.
	 * Reparenting logic needs to have these records inserted: Product Node, Node Advert Assignment
	 */
	private Line_Item_Threshold__c cloneLineItemThreshold(Line_Item_Threshold__c lineItemThresholdToClone) {
		Line_Item_Threshold__c clonedLIT = lineItemThresholdToClone.clone(false, true);
		//reparent if we know new Ids, all or nothing mode
		List<Id> oldIds = new List<Id>{
			clonedLIT.Product_Node__c,
			clonedLIT.Node_Advert_Assignment__c
		};
		if (oldToNewIdMap.keySet().containsAll(oldIds)) {
			clonedLIT.Product_Node__c           = oldToNewIdMap.get(clonedLIT.Product_Node__c);
			clonedLIT.Node_Advert_Assignment__c = oldToNewIdMap.get(clonedLIT.Node_Advert_Assignment__c);
		} else {
			throw new ProcessingException('Possible integrity issue, cloned records not found for Ids: ' + String.join(oldIds,', '));
		}

		return clonedLIT;
	}

	/**
	 * Validations we would like to perform before allowing Product Node to be used for this
	 * cloning functionality.
	 * If Product Node shouldn't be cloned VF error message will be created if required.
	 * Returns true if Product Node could be cloned.
	 */
	private Boolean allowCloning(csmso__Product_Node__c productNode, Boolean addToPageMessages) {
		Boolean allowed = true;
		//check allowed record types
		if (!ALLOWED_RECORDTYPES.contains(bespokeProductRTname)) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(ERROR_MSG_RECORDTYPE, new List<String>{productNode.Id, String.join(ALLOWED_RECORDTYPES, ', ')});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}
		//not allowing if Price Item has already been cloned as we would like to users to use most recent version
		if (productNode.New_Instance__c != null && !isNewBespokeMode && !isPropagateChanges) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(ERROR_MSG_USE_NEW, new List<String>{bespokeProductRTname, productNode.Id, productNode.New_Instance__c});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}
		if (productNode.Effective_Start_Date__c == null || productNode.Effective_End_Date__c == null) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(MISSING_DATES, new List<String>{bespokeProductRTname, productNode.Id});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		} else if (productNode.Effective_End_Date__c == DEFAULT_END_DATE && !isNewBespokeMode && !isPropagateChanges) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(ERROR_MSG_END_DATE_UPDATE, new List<String>{bespokeProductRTname, productNode.Id, productNode.Effective_End_Date__c.format()});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}

		return allowed;
	}

	/**
	 * Checks if our cloned Product Node would cause date overlap with any of the existing
	 * Product Nodes by matching them by Name and Record Type
	 * Intended to be used only for top level check (as other levels will complain about not finding new parent Id)
	 */
	private Boolean overlapsWithExistingProductNodes(csmso__Product_Node__c productNode) {
		Boolean overlaps = false;
		String operation = isPropagateChanges ? 'Updating' : 'Cloning';
		String message   = String.format(ERROR_MSG_DATE, new List<String>{operation, bespokeProductRTname, productNode.Id});
		List<String> ids = new List<String>();
		//get cloned record
		csmso__Product_Node__c clonedProductNode = cloneProductNode(productNode, true);
		//run date overlap check on cloned record if there is anything to check
		for (csmso__Product_Node__c existingProductNodes :[SELECT Id, Name, Effective_Start_Date__c, Effective_End_Date__c
														   FROM csmso__Product_Node__c
														   WHERE Is_Active__c = true AND RecordTypeId = :productNode.RecordTypeId
																										AND Name = :productNode.Name AND Id != :productNode.Id]) {
			if (clonedProductNode.Is_Active__c &&
				clonedProductNode.Effective_Start_Date__c <= existingProductNodes.Effective_End_Date__c &&
				clonedProductNode.Effective_End_Date__c >= existingProductNodes.Effective_Start_Date__c) {
				overlaps = true;
				ids.add(existingProductNodes.Id);
			}
		}
		//add page message
		if (overlaps) {
			message += String.join(ids, ', ');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
		}
		return overlaps;
	}

	private Boolean isNewBespokeMode {
		get {
			isNewBespokeMode = selectedOperation == 'newBespoke';
			return isNewBespokeMode;
		}
		set;
	}

	private Boolean isPropagateChanges {
		get {
			isPropagateChanges = selectedOperation == 'propagateChanges';
			return isPropagateChanges;
		}
		set;
	}

	public PageReference refreshForecastResult() {
		//using to generate page messages
		allowCloning(bespokeProduct, true);
		//only failure point is end date as we need to add 1 day to it
		if (bespokeProduct.Effective_End_Date__c != null) {
			if (isPropagateChanges) {
				//no simulation, we are modifying original values
				forecastResult = bespokeProduct.clone(true, true);//new reference as we must not change baspokeProduct
			} else {
				forecastResult = cloneProductNode(bespokeProduct, true);
			}
			//reset latestExternalId to force refresh otherwise it would consume external Id
			latestExternalId = null;
		}
		return null;
	}

	/**
	 * Wrapper method for inserting records as we need to run maintenance logic after ever insert.
	 * Will insert records and refresh all OldToNewWrapper items to populate oldId property.
	 * Additionally maintains oldToNewIdMap map.
	 */
	private void insertSobjects(List<sObject> recordsToInsert) {
		if (recordsToInsert == null || recordsToInsert.isEmpty()) {
			return;
		} else {
			insert recordsToInsert;
		}
		//capture newly created Ids
		for (OldToNewWrapper oldToNew :oldToNewRecords) {
			//since we are adding ids to the map once we have both Ids there is no need
			//to reprocess ones that were already added
			if (oldToNewIdMap.containsKey(oldToNew.oldId)) {
				continue;
			} else if (!String.isBlank((Id)oldToNew.newRecord.get('Id'))) {
				//if we now have new Id then update property and add it to the map
				oldToNew.newId = (Id)oldToNew.newRecord.get('Id');
				oldToNewIdMap.put(oldToNew.oldId, oldToNew.newId);
			}
		}
	}

	/**
	 * Summary details getter to used on VF page to provide quick scope overview
	 * i.e. informs user about the records that will be updated/cloned as part of the operation.
	 */
	public List<SummaryWrapper> summaryDetails {
		get {
			if (summaryDetails == null) {
				summaryDetails         = new List<SummaryWrapper>();
				Set<Id> productNodeIds = new Set<Id>();
				List<String> namesList = new List<String>();
				String names;
				//create one wrapper for each level
				for (Integer level : levelToProductNodesMap.keySet()) {
					productNodeIds.addAll(levelToProductNodesMap.get(level).keySet());
					namesList = new List<String>();
					Id recordTypeId;
					for (csmso__Product_Node__c productNode :levelToProductNodesMap.get(level).values()) {
						namesList.add(productNode.Name);
						recordTypeId = productNode.RecordTypeId;
					}
					//sort and remove duplicates
					namesList.sort();
					namesList = new List<String>(new Set<String>(namesList));
					names     = String.join(namesList, ', ');
					summaryDetails.add(new SummaryWrapper(
										   'Product Node > ' + idToRecordtypeNameMap.get(levelToProductNodesMap.get(level).values()[0].RecordTypeId),
										   levelToProductNodesMap.get(level).size(),
										   names));
				}
				//now summarize other related objects
				List<csmso__Node_Advert_Assignment__c> loadedNAAs = new List<csmso__Node_Advert_Assignment__c>();
				List<csmso__Rate_Card__c> loadedRateCards         = new List<csmso__Rate_Card__c>();
				List<csmso__Rate_Card_Item_Price__c> loadedRCIPs  = new List<csmso__Rate_Card_Item_Price__c>();
				List<Line_Item_Threshold__c> loadedLITs           = new List<Line_Item_Threshold__c>();
				String query;
				//Node Advert Assignment
				query      = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Node_Advert_Assignment__c') + ' FROM csmso__Node_Advert_Assignment__c WHERE csmso__Title_Product_Node__c IN :productNodeIds';
				loadedNAAs = Database.query(query);
				//create summary
				namesList = new List<String>();
				for (csmso__Node_Advert_Assignment__c naa :loadedNAAs) {
					namesList.add(naa.Name);
				}
				//sort and remove duplicates
				namesList.sort();
				namesList = new List<String>(new Set<String>(namesList));
				names     = String.join(namesList, ', ');
				summaryDetails.add(new SummaryWrapper('Node Advert Assignment', loadedNAAs.size(), names));
				//Default Rate Card
				query           = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Rate_Card__c') + ' FROM csmso__Rate_Card__c WHERE csmso__Product_Node__c IN :productNodeIds';
				loadedRateCards = Database.query(query);
				//create summary
				namesList = new List<String>();
				for (csmso__Rate_Card__c rateCard :loadedRateCards) {
					namesList.add(rateCard.Name);
				}
				//sort and remove duplicates
				namesList.sort();
				namesList = new List<String>(new Set<String>(namesList));
				names     = String.join(namesList, ', ');
				summaryDetails.add(new SummaryWrapper('Default Rate Card', loadedRateCards.size(), names));
				//Rate Card Item Price
				query       = 'SELECT '+ CS_Utils.getSobjectFields('csmso__Rate_Card_Item_Price__c') + ' FROM csmso__Rate_Card_Item_Price__c WHERE csmso__Product_Node__c IN :productNodeIds';
				loadedRCIPs = Database.query(query);
				namesList   = new List<String>();
				for (csmso__Rate_Card_Item_Price__c rcip :loadedRCIPs) {
					namesList.add(rcip.Name);
				}
				//sort and remove duplicates
				namesList.sort();
				namesList = new List<String>(new Set<String>(namesList));
				names     = String.join(namesList, ', ');
				summaryDetails.add(new SummaryWrapper('Rate Card Item Price', loadedRCIPs.size(), names));
				//Line Item Threshold
				query      = 'SELECT '+ CS_Utils.getSobjectFields('Line_Item_Threshold__c') + ' FROM Line_Item_Threshold__c WHERE Product_Node__c IN :productNodeIds';
				loadedLITs = Database.query(query);
				namesList  = new List<String>();
				for (Line_Item_Threshold__c lit :loadedLITs) {
					namesList.add(lit.Name);
				}
				//sort and remove duplicates
				namesList.sort();
				namesList = new List<String>(new Set<String>(namesList));
				names     = String.join(namesList, ', ');
				summaryDetails.add(new SummaryWrapper('Line Item Threshold', loadedLITs.size(), names));

			}
			return summaryDetails;
		}
		set;
	}

	//INNER CLASSES
	/**
	 * Wrapper class to capture links between original records and there clones.
	 * Needed to be able to track old to new Id changes.
	 */
	class OldToNewWrapper {
		//Ids extracted for convenience, we will not have newId until record is inserted
		public Id oldId {get; set;}
		public Id newId {get; set;}
		//full objects in case we need them
		public sObject oldRecord {get; set;}
		public sObject newRecord {get; set;}
		//constructor
		public OldToNewWrapper(sObject oldObj, sObject newObj) {
			this.oldId     = oldObj.Id;
			this.oldRecord = oldObj;
			this.newId     = newObj.Id; // will be null until we insert record so requires maintenance
			this.newRecord = newObj;
		}
	}

	/**
	 * Wrapper class to be able to summarize scope of modification
	 */
	@testVisible
	class SummaryWrapper {
		public String typeName {get; set;}
		public Integer count {get; set;}
		public String names {get; set;}
		//constructor
		public SummaryWrapper(String typeName, Integer count, String names) {
			this.typeName = typeName;
			this.count    = count;
			this.names    = names;
		}
	}

	//Custom exception
	public class ProcessingException extends Exception {}
}