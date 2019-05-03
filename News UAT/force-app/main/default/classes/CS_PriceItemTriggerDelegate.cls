/**
 * Trigger delegate for cspmb__Price_Item__c object trigger.
 */
public with sharing class CS_PriceItemTriggerDelegate implements CS_TriggerHandler.Delegate {
	//context variables
	private Set<String> priceItemBundleDetails = new Set<String>();
	private Map<String, List<cspmb__Price_Item__c>> bundleDetailsToPriceItemsMap = new Map<String, List<cspmb__Price_Item__c>>();

	public void prepareBefore() {
		prepareForDateOverlapCheck();
	}

	public void prepareAfter() {
		// do any preparation here – bulk loading of data etc
	}

	public void beforeInsert(sObject o) {
		dateValidations(null, (cspmb__Price_Item__c)o);
	}

	public void beforeUpdate(sObject old, sObject o) {
		dateValidations((cspmb__Price_Item__c)old, (cspmb__Price_Item__c)o);
	}

	public void beforeDelete(sObject o) {
		// Apply before delete logic to this sObject. DO NOT do any SOQL
		// or DML here – store records to be modified in an instance variable
		// which can be processed by the finish() method
	}

	public void afterInsert(sObject o) {
		// Apply after insert logic to this sObject. DO NOT do any SOQL
		// or DML here – store records to be modified in an instance variable
		// which can be processed by the finish() method
	}

	public void afterUpdate(sObject old, sObject o) {
		// Apply after insert logic to this sObject. DO NOT do any SOQL
		// or DML here – store records to be modified in an instance variable
		// which can be processed by the finish() method
	}

	public void afterDelete(sObject o) {
		// Apply after delete logic to this sObject. DO NOT do any SOQL
		// or DML here – store records to be modified in an instance variable
		// which can be processed by the finish() method
	}

	public void afterUndelete(sObject o) {
		// Apply after undelete logic to this sObject. DO NOT do any SOQL
		// or DML here – store records to be modified in an instance variable
		// which can be processed by the finish() method
	}

	public void finish() {
		// do any final work here – DML on other sObjects etc.
	}

	//helper methods
	/**
	 * Collects all Price Item Names from trigger context records and load all
	 * existing active Price Items with that Name.
	 */
	private void prepareForDateOverlapCheck() {
		//not running for deletions as it isn't needed nor possible
		if (Trigger.isDelete) {
			return;
		}
		//cast the list for convenience
		List<cspmb__Price_Item__c> triggerNew = (List<cspmb__Price_Item__c>)Trigger.new;
		for (cspmb__Price_Item__c priceItem :triggerNew) {
			priceItemBundleDetails.add(priceItem.Bundle_Details__c);
		}
		//query all active records with our names, excluding records from trigger context as they are out of date
		List<cspmb__Price_Item__c> priceItemsForOverlapCheck = [SELECT Id, Name, cspmb__Effective_Start_Date__c, cspmb__Effective_End_Date__c,
																cspmb__Is_Active__c, Bundle_Details__c 
																FROM cspmb__Price_Item__c
																WHERE Bundle_Details__c = :priceItemBundleDetails AND Id NOT IN :triggerNew AND cspmb__Is_Active__c = true];
		//Now add all trigger context records as we would like to check the final version of the data
		priceItemsForOverlapCheck.addAll(triggerNew);
		//Populate the map
		for (cspmb__Price_Item__c priceItem :priceItemsForOverlapCheck) {
			//ignore inactive ones
			if (priceItem.cspmb__Is_Active__c) {
				if (bundleDetailsToPriceItemsMap.containsKey(priceItem.Bundle_Details__c)) {
					bundleDetailsToPriceItemsMap.get(priceItem.Bundle_Details__c).add(priceItem);
				} else {
					bundleDetailsToPriceItemsMap.put(priceItem.Bundle_Details__c, new List<cspmb__Price_Item__c>{priceItem});
				}
			}
		}
	}

	/**
	 * Checks if priceItem overlaps with any existing Price Item record and creates massage
	 * that can be used to generate record error.
	 * Returns empty string if there is no overlap.
	 */
	private String getOverlapMessage(cspmb__Price_Item__c priceItem) {
		String overlapMessage = '';
		String DETAILS_FORMAT = '{0} ({1} - {2})';
		List<String> overlapDetails = new List<String>();
		if (bundleDetailsToPriceItemsMap.containsKey(priceItem.Bundle_Details__c)) {
			for (cspmb__Price_Item__c existingPriceItem :bundleDetailsToPriceItemsMap.get(priceItem.Bundle_Details__c)) {
				//ignoring record that we are checking
				if (existingPriceItem.Id != priceItem.Id &&
					priceItem.cspmb__Effective_Start_Date__c <= existingPriceItem.cspmb__Effective_End_Date__c &&
					priceItem.cspmb__Effective_End_Date__c >= existingPriceItem.cspmb__Effective_Start_Date__c) {
					//capture Id and dates for every overlapping Price Item
					String msgDetail = String.format(DETAILS_FORMAT,
						new List<String>{existingPriceItem.Id, existingPriceItem.cspmb__Effective_Start_Date__c.format(), existingPriceItem.cspmb__Effective_End_Date__c.format()});
					overlapDetails.add(msgDetail);
				}
			}
		}
		//prepare message if we have details
		if (!overlapDetails.isEmpty()) {
			String msgDetail = String.format(DETAILS_FORMAT,
				new List<String>{priceItem.Id, priceItem.cspmb__Effective_Start_Date__c.format(), priceItem.cspmb__Effective_End_Date__c.format()});
			overlapMessage = 'Dates used on Price Item ' + msgDetail + ' overlaps with these Price Items: ' + String.join(overlapDetails, ', ');
		}

		return overlapMessage;
	}

	/**
	 * Checks Price Item dates and creates error for each validation failure.
	 * Validations are NOT executed if:
	 *  - Price Item was updated but neither of the date fields were changed
	 *  - Price item has both date fields empty
	 * 
	 * Validations:
	 *  - Either both fields has to be empty or populated
	 *  - End date should be equal or greater than start date
	 *  - Start/End dates shouldn't overlap with any existing and active price items
	 */
	private void dateValidations(cspmb__Price_Item__c oldPriceItem, cspmb__Price_Item__c priceItem) {
		Boolean runValidations = false;
		//basically an update
		if (oldPriceItem != null && priceItem != null) {
			//monitoring dates, name and active flag for changes
			if (oldPriceItem.cspmb__Effective_Start_Date__c <> priceItem.cspmb__Effective_Start_Date__c ||
				oldPriceItem.cspmb__Effective_End_Date__c <> priceItem.cspmb__Effective_End_Date__c ||
				oldPriceItem.cspmb__Is_Active__c <> priceItem.cspmb__Is_Active__c ||
				oldPriceItem.Bundle_Details__c <> priceItem.Bundle_Details__c) {
					//dates updated
				runValidations = priceItem.cspmb__Is_Active__c; //running only for active ones
			}
		} else if (priceItem != null) {
			//price item inserted so run
			runValidations = priceItem.cspmb__Is_Active__c; //running only for active ones
		}
		
		if (runValidations) {
			//one of the dates is empty
			if ((priceItem.cspmb__Effective_Start_Date__c == null && priceItem.cspmb__Effective_End_Date__c != null) || 
				(priceItem.cspmb__Effective_Start_Date__c != null && priceItem.cspmb__Effective_End_Date__c == null)) {
				priceItem.addError('Effective Start Date and Effective End Date fields have to be both set or both empty!', false);
			} else if (priceItem.cspmb__Effective_Start_Date__c > priceItem.cspmb__Effective_End_Date__c) {
				priceItem.addError('Effective End Date cannot be before Effective Start Date', false);
			} else {
				//now is OK to do more time consuming check
				String overlapMessage = getOverlapMessage(priceItem);
				if (overlapMessage != '') {
					priceItem.addError(overlapMessage, false);
				}
			}
		}
	}
}