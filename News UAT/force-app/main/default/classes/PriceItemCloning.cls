/**
 * Class that contains Price Item cloning logic.
 * Also used as a page controller for invoking cloning logic from Details page button and from list view.
 * Cloning consists of:
 *  - cloning price item record and adjusting: Effective Start Date, Effective End Date, External Id
 *  - cloning related Price Item Add On Price Item Association records
 *
 * If isNewBundleMode = true then we are using original Price Item as a template for new bundle.
 * This means cloned Price Item will have:
 *  - External Id = Latest External Id from the system (not from original price item) + 1
 *  - Effective Start Date = TODAY
 *  - Effective End Date = DEFAULT_END_DATE
 *  - Active = false (as it would overlap with original Price Item)
 */
public with sharing class PriceItemCloning {
	//defaults
	private static final String DEFAULT_EXTERNAL_ID       = 'B-000000';
	private static final String DEFAULT_EXTERNAL_ID_REL   = 'AS-0000';
	private static final String NO_SELECTION              = 'Nothing to clone! Please select at least one Price Item and try again!';
	private static final String ERROR_MSG_DATE            = 'Cloning Price Item ({0}) causes Effective Start Date/Effective End Date overlap with existing records: ';
	private static final String ERROR_MSG_USE_NEW         = 'Price Item ({0}) already superseded by another Price Item ({1}). Please use most recent one for cloning!';
	private static final String ERROR_MSG_END_DATE_UPDATE = 'Price Item ({0}) uses default Effective End Date ({1}). Please set correct Effective End Date and try again!';
	private static final String MISSING_DATES             = 'Price Item ({0}) has no Effective Start/End Date defined. Please set correct Effective Start/End Date and try again!';
	//using GMT to avoid running user time-zone differences
	private static final Date NOW_DATE         = DateTime.now().dateGMT();
	private static final Date DEFAULT_END_DATE = DateTime.newInstanceGmt(2099,12,31).dateGMT();
	private String latestExternalIdRel;
	private List<cspmb__Price_Item__c> priceItems;
	private List<cspmb__Price_Item__c> clonedPriceItems;
	private List<cspmb__Price_Item_Add_On_Price_Item_Association__c> clonedRelatedRecords;
	//used to keep track of new Price Item Ids so we can reparent related records
	private Map<Id, cspmb__Price_Item__c> oldIdToNewPriceItemMap;
	private Map<String, List<PriceItemWrapper>> bundleDetailsToPriceItemWrappersMap;
	public String selectedOperation {get; set;}
	public cspmb__Price_Item__c forecastResult { get; set; }
	public List<SelectOption> operations {
		get {
			if (operations == null || operations.isEmpty()) {
				operations = new List<SelectOption>();
				operations.add(new SelectOption('newVersion','Create new bundle version'));
				operations.add(new SelectOption('newBundle','Create new bundle'));
				selectedOperation = operations[0].getValue();//New Instance mode is default (newVersion)
			}
			return operations;
		}
		set;
	}
	//variables to store cloning context
	//latest external Id in the system, storing only base/bundle part of it (version information discarded)
	private String latestExternalId {
		get {
			if (latestExternalId == null) {
				List<cspmb__Price_Item__c> priceItemLatestId = [SELECT Id, ExternalID__c
																FROM cspmb__Price_Item__c
																ORDER BY ExternalID__c DESC NULLS LAST LIMIT 1];
				latestExternalId = priceItemLatestId.isEmpty() ? DEFAULT_EXTERNAL_ID : priceItemLatestId[0].ExternalID__c;
			}
			//if latest version is of expected format then discard version information
			if (latestExternalId.length() > 8 && latestExternalId.countMatches('-') > 1) {
				latestExternalId = latestExternalId.substringBeforeLast('-');
			}
			return latestExternalId;
		}
		set;
	}

	//Controller when used from details page
	public PriceItemCloning(ApexPages.StandardController stdController) {
		this.priceItems = new List<cspmb__Price_Item__c>();
		this.priceItems.add((cspmb__Price_Item__c)stdController.getRecord());
		this.isNewBundleMode = false;
	}

	//Controller when used from list view
	public PriceItemCloning(ApexPages.StandardSetController stdController) {
		this.priceItems      = (List<cspmb__Price_Item__c>)stdController.getSelected();
		this.isNewBundleMode = false;
	}

	//Controller that enable us to run cloning logic from other parts of the system
	public PriceItemCloning(List<cspmb__Price_Item__c> priceItemsToClone, String selectedOperation) {
		this.priceItems        = priceItemsToClone;
		this.selectedOperation = selectedOperation;
	}

	/**
	 * Clone method that does all the work.
	 * It runs the logic for all Price Items found in priceItems list.
	 * If logic invoked from details page (i.e. on a single price item record) then the
	 * priceItem will be added to the priceItems list and logic flow will be identical.
	 */
	public PageReference clonePriceItems() {
		//clean start
		ApexPages.getMessages().clear();
		PageReference returnPage;
		Savepoint sp = Database.setSavepoint();
		clonedPriceItems                                     = new List<cspmb__Price_Item__c> ();
		clonedRelatedRecords                                 = new List<cspmb__Price_Item_Add_On_Price_Item_Association__c>();
		Map<Id, cspmb__Price_Item__c> oldIdToNewPriceItemMap = new Map<Id, cspmb__Price_Item__c>();
		if (this.priceItems != null && !this.priceItems.isEmpty()) {
			//load all Price Items we need to clone making sure all their related records are loaded as well
			String query = 'SELECT ' + CS_Utils.getSobjectFields('cspmb__Price_Item__c') + ', ' +
						   '(SELECT ' + CS_Utils.getSobjectFields('cspmb__Price_Item_Add_On_Price_Item_Association__c') +
						   ' FROM cspmb__Price_Item_Add_On_Price_Item_Association__r) ' +
						   'FROM cspmb__Price_Item__c ' +
						   'WHERE Id IN :priceItems';
			System.debug('PriceItemCloning>clonePriceItems>query: ' + query);
			//overwriting our context with loaded data
			this.priceItems = Database.query(query);
			//get latest External Id
			//NOTE: Assumes external Id format consistency i.e. all values should have same length
			//otherwise string sorting will not return expected results!
			List<cspmb__Price_Item_Add_On_Price_Item_Association__c> assocLatestId = [SELECT Id, External_ID__c
																					  FROM cspmb__Price_Item_Add_On_Price_Item_Association__c
																					  ORDER BY External_ID__c DESC NULLS LAST LIMIT 1];
			//defaulting them before starting processing and processing will maintain them
			latestExternalIdRel = assocLatestId.isEmpty() ? DEFAULT_EXTERNAL_ID_REL : assocLatestId[0].External_ID__c;
			//load required data
			loadAndPrepareForOverlapCheck();
			//ready for cloning process
			for (cspmb__Price_Item__c priceItem :priceItems) {
				//clone only if allowed and if it doesn't cause overlap
				if (allowCloning(priceItem, true) && !overlapsWithExistingPriceItems(priceItem, true)) {
					//no overlap, we can clone everything and modify existing price item
					cspmb__Price_Item__c clonedPriceItem = clonePriceItem(priceItem);
					clonedPriceItems.add(clonedPriceItem);
					clonedRelatedRecords.addAll(clonePriceItemRelatedRecords(priceItem.cspmb__Price_Item_Add_On_Price_Item_Association__r));
					//capture old id to new record mapping
					oldIdToNewPriceItemMap.put(priceItem.Id, clonedPriceItem);
				}
			}

			//all DML exceptions "converted" to page messages and transaction aborted
			try {
				//if we generated errors during cloning then skip DMLs
				if (!ApexPages.hasMessages()) {
					//DMLs in correct order
					insert clonedPriceItems;
					//quick linking old to new instance before update for those that were cloned, only if not creating new bundle
					if (!isNewBundleMode) {
						for (cspmb__Price_Item__c priceItem :priceItems) {
							if (oldIdToNewPriceItemMap.containsKey(priceItem.Id)) {
								priceItem.New_Instance__c = oldIdToNewPriceItemMap.get(priceItem.Id).Id;
							}
						}
						update this.priceItems;
					}
					//quick reparenting before insert as we only now have the new Ids
					for (cspmb__Price_Item_Add_On_Price_Item_Association__c relRec :clonedRelatedRecords) {
						//we have to have it in the map so not checking if key exists
						relRec.cspmb__Price_Item__c = oldIdToNewPriceItemMap.get(relRec.cspmb__Price_Item__c).Id;
					}
					insert clonedRelatedRecords;
				}
			} catch (DmlException dmlEx) {
				ApexPages.addMessages(dmlEx);
			}

			//if we had only one Price Item to clone then open it, if we had more than one (list view) then just refresh the view
			if (ApexPages.hasMessages()) {
				//if we have messages then don't navigate away, let users see the message and they can use the cancel button
				returnPage = null;
				//rollback any changes we made
				Database.rollback(sp);
			} else if (clonedPriceItems.size() == 1) {
				returnPage = new PageReference('/' + clonedPriceItems[0].Id);
			} else {
				returnPage = new PageReference('/' + cspmb__Price_Item__c.SObjectType.getDescribe().getKeyPrefix());
			}
		} else {
			//no price items so nothing selected on list view.
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, NO_SELECTION));
		}
		return returnPage;
	}

	/**
	 * Loads all price items with same Name/Bundle Details values as ones we have in priceItems list but
	 * ignoring records from priceItems list. This is to ensure we don't throw date overlap check error for
	 * records that are to be cloned since we will update their Effective End Date.
	 */
	private void loadAndPrepareForOverlapCheck() {
		//prepare data for query
		Set<String> bundleDetails = new Set<String>();
		for (cspmb__Price_Item__c priceItem :priceItems) {
			bundleDetails.add(priceItem.Bundle_Details__c);
		}
		//query all active records with our names
		List<cspmb__Price_Item__c> priceItemsForOverlapCheck = [SELECT Id, Name, cspmb__Effective_Start_Date__c, cspmb__Effective_End_Date__c, Bundle_Details__c
																FROM cspmb__Price_Item__c
																WHERE Bundle_Details__c = :bundleDetails AND Id NOT IN :this.priceItems AND cspmb__Is_Active__c = true];
		//prepare map that will be used when checking
		bundleDetailsToPriceItemWrappersMap = new Map<String, List<PriceItemWrapper>>();
		for (cspmb__Price_Item__c priceItem :priceItemsForOverlapCheck) {
			if (bundleDetailsToPriceItemWrappersMap.containsKey(priceItem.Bundle_Details__c)) {
				bundleDetailsToPriceItemWrappersMap.get(priceItem.Bundle_Details__c).add(
					new PriceItemWrapper(priceItem.Id, priceItem.Bundle_Details__c, priceItem.cspmb__Effective_Start_Date__c,
										 priceItem.cspmb__Effective_End_Date__c));
			} else {
				bundleDetailsToPriceItemWrappersMap.put(priceItem.Bundle_Details__c,
											   new List<PriceItemWrapper>{new PriceItemWrapper(priceItem.Id, priceItem.Bundle_Details__c, priceItem.cspmb__Effective_Start_Date__c,
																							   priceItem.cspmb__Effective_End_Date__c)});
			}
		}
	}

	/**
	 * Checks if our cloned price item would cause date overlap with any of the existing
	 * price items with the same Name/Bundle details.
	 * If it overlaps method will return true and create VF error message if requested.
	 */
	private Boolean overlapsWithExistingPriceItems(cspmb__Price_Item__c priceItem, Boolean addToPageMessages) {
		Boolean overlaps = false;
		String message   = String.format(ERROR_MSG_DATE, new List<String>{priceItem.Id});
		List<String> ids = new List<String>();
		//get cloned record without modifying original
		cspmb__Price_Item__c clonedPriceItem = clonePriceItem(priceItem);
		//run date overlap check on cloned record if there is anything to check
		if (bundleDetailsToPriceItemWrappersMap.containsKey(priceItem.Bundle_Details__c)) {
			for (PriceItemWrapper piw :bundleDetailsToPriceItemWrappersMap.get(priceItem.Bundle_Details__c)) {
				if (clonedPriceItem.cspmb__Is_Active__c &&
					clonedPriceItem.cspmb__Effective_Start_Date__c <= piw.endDate &&
					clonedPriceItem.cspmb__Effective_End_Date__c >= piw.startDate) {
					overlaps = true;
					ids.add(piw.priceItemId);
				}
			}
			//add page message if needed
			if (overlaps && addToPageMessages) {
				message += String.join(ids, ', ');
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}
		return overlaps;
	}

	/**
	 * Validations we would like to perform before allowing Price item to be used for this
	 * cloning functionality.
	 * If price item shouldn't be cloned VF error message will be created if required.
	 * Returns true if price item could be cloned.
	 */
	private Boolean allowCloning(cspmb__Price_Item__c priceItem, Boolean addToPageMessages) {
		Boolean allowed = true;
		//not allowing if Price Item has already been cloned as we would like to users to use most recent version
		if (priceItem.New_Instance__c != null && !isNewBundleMode) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(ERROR_MSG_USE_NEW, new List<String>{priceItem.Id, priceItem.New_Instance__c});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}
		if (priceItem.cspmb__Effective_Start_Date__c == null || priceItem.cspmb__Effective_End_Date__c == null) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(MISSING_DATES, new List<String>{priceItem.Id});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		} else if (priceItem.cspmb__Effective_End_Date__c == DEFAULT_END_DATE && !isNewBundleMode) {
			allowed = false;
			if (addToPageMessages) {
				String message = String.format(ERROR_MSG_END_DATE_UPDATE, new List<String>{priceItem.Id, priceItem.cspmb__Effective_End_Date__c.format()});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
			}
		}
		return allowed;
	}

	/**
	 * Clones price item and does necessary adjustments:
	 *  - cloned price item start/end date adjustments and populates old_instance
	 * Returns cloned price item.
	 */
	private cspmb__Price_Item__c clonePriceItem(cspmb__Price_Item__c priceItemToClone) {
		//create cloned price item and adjust it
		cspmb__Price_Item__c clonedPriceItem = priceItemToClone.clone(false, true);
		if (isNewBundleMode) {
			clonedPriceItem.cspmb__Is_Active__c            = false;//has to be false
			clonedPriceItem.cspmb__Effective_Start_Date__c = NOW_DATE;
			clonedPriceItem.cspmb__Effective_End_Date__c   = DEFAULT_END_DATE;
			clonedPriceItem.Old_Instance__c                = null;
			clonedPriceItem.New_Instance__c                = null;
			//safe as nulls are not changed in CS_Utils.incrementString(), incrementing bundle part
			latestExternalId              = CS_Utils.incrementString(latestExternalId);
			//appending version part as this is 1st version of new bundle
			clonedPriceItem.ExternalID__c = latestExternalId + '-001';
		} else {
			clonedPriceItem.cspmb__Effective_Start_Date__c = priceItemToClone.cspmb__Effective_End_Date__c.addDays(1);
			clonedPriceItem.cspmb__Effective_End_Date__c   = DEFAULT_END_DATE;
			clonedPriceItem.Old_Instance__c                = priceItemToClone.Id;
			clonedPriceItem.New_Instance__c                = null;//resetting although validation would allow to reach this far
			//safe as nulls are not changed in CS_Utils.incrementString()
			clonedPriceItem.ExternalID__c = CS_Utils.incrementString(priceItemToClone.ExternalID__c);
		}
		return clonedPriceItem;
	}

	/**
	 * Clones Price Item Add On Price Item Association records.
	 * Returns cloned Price Item Add On Price Item Association records.
	 */
	private List<cspmb__Price_Item_Add_On_Price_Item_Association__c> clonePriceItemRelatedRecords(List<cspmb__Price_Item_Add_On_Price_Item_Association__c> recordsToClone) {
		List<cspmb__Price_Item_Add_On_Price_Item_Association__c> clonedRelatedRecords = new List<cspmb__Price_Item_Add_On_Price_Item_Association__c>();
		for (cspmb__Price_Item_Add_On_Price_Item_Association__c relRec :recordsToClone) {
			//clone and relink to new parent, it will be available after insert!
			cspmb__Price_Item_Add_On_Price_Item_Association__c clonedRec = relRec.clone(false, true);
			//increment latest external Id before using it
			latestExternalIdRel      = CS_Utils.incrementString(latestExternalIdRel);
			clonedRec.External_ID__c = latestExternalIdRel;
			clonedRelatedRecords.add(clonedRec);
		}
		return clonedRelatedRecords;
	}

	private Boolean isNewBundleMode {
		get {
			isNewBundleMode = selectedOperation == 'newBundle';
			return isNewBundleMode;
		}
		set;
	}

	public PageReference refreshForecastResult() {
		//using to generate page messages
		allowCloning(priceItems[0], true);
		//only failure point is end date as we need to add 1 day to it
		if (priceItems[0].cspmb__Effective_End_Date__c != null) {
			forecastResult = clonePriceItem(priceItems[0]);
			//reset latestExternalId to force refresh otherwise it would consume external Id
			latestExternalId = null;
		}
		return null;
	}

	//inner class for easier date overlap implementation
	class PriceItemWrapper {
		public Id priceItemId {get; set;}
		public String priceItemName {get; set;}
		public Date startDate {get; set;}
		public Date endDate {get; set;}

		public PriceItemWrapper(Id priceItemId, String priceItemName, Date startDate, Date endDate) {
			this.priceItemId   = priceItemId;
			this.priceItemName = priceItemName;
			this.startDate     = startDate;
			this.endDate       = endDate;
		}
	}
}