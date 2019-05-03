/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This help class include all methods needed for custom revenue schedule batchs, namely, Crs_OpportunityLineItem_Batch and Crs_Opportunity_Batch
 * Company: Salesforce.com
 * Date: 02/10/2013
 * History:
 * 25/09/2013   Bohao Chen       Created
 ---------------------------------------------------------*/
public without sharing class CustomRevenueSchedule_Helper 
{
    // user define which fields changed on opportunity determine the copy process needed
    private static List<String> opptyFieldNames = new String[]{'AccountId', 'OwnerId'};
    
    public static final String crsOpptyQuery = 'Select Id, AccountId, OwnerId, Amount, CloseDate From Opportunity '
				                            + 'Where Last_Modified_Datetime__c != null '
				                          //  + 'and Opportunity_Type__c != \'Agreement Negotiation\' '
				                            + 'and Last_Modified_Datetime__c > : crsOpptyLastRunSuccessDatetime '
				                            + 'and Owner.IsActive = true';
    
    public static final String crsOpptyLineItemQuery = 'Select o.PricebookEntry.Product2Id, o.Opportunity.AccountId, o.OpportunityId, o.Sales_Order__c, '
                                                    + 'o.TotalPrice, o.ServiceDate '
					                                + 'From OpportunityLineItem o '
					                                + 'Where o.LastModifiedDate > : crsOpptyLineItemLastRunSuccessDatetime '
					                                + 'And o.Opportunity.Owner.IsActive = true';
					                           //     + 'And o.Opportunity.Opportunity_Type__c != \'Agreement Negotiation\'';
                                                        
    // user define which fields changed on opportunity line item determine the copy process needed
    
    public static void upsertCrsOpprotunities(List<Opportunity> opportunities)
    {
    	system.debug('====CustomRevenueSchedule_Helper: upsertCrsOpprotunities====');
    	
        List<Revenue_Schedule__c> rss = new List<Revenue_Schedule__c>();
        
    	Set<Id> existingOpptyIds = new Set<Id>();
    	
        for(Revenue_Schedule__c rs : [Select OwnerId, Opportunity__c, Account__c, Opportunity__r.AccountId, 
                                        Opportunity__r.OwnerId, Owner__c, Rev_Amount__c, Rev_Date__c,
                                        Opportunity__r.Amount, Opportunity__r.CloseDate
                                      From Revenue_Schedule__c 
                                      Where Opportunity__c IN: opportunities
                                      ])
        {
        	existingOpptyIds.add(rs.Opportunity__c);
        	rs.Account__c = rs.Opportunity__r.AccountId;
        	rs.Owner__c = rs.Opportunity__r.OwnerId;
        	rs.OwnerId = rs.Owner__c;
        	rs.Rev_Amount__c = 0;
        	rs.Rev_Date__c = null;
            rss.add(rs);
        }
        
        for(Opportunity oppty : opportunities)
        {
        	// if existing opportunity id set doesn't contain current opportunity id,
        	// it means that this opportunity hasn't been copied over to CRS. Therefore, 
        	// we need to insert a new CRS record
        	if(!existingOpptyIds.contains(oppty.Id))
        	{
        		Revenue_Schedule__c rs = new Revenue_Schedule__c();
	            rs.Account__c = oppty.AccountId;
	            rs.Opportunity__c = oppty.Id;
	            rs.Owner__c = oppty.OwnerId;
	            rs.OwnerId = rs.Owner__c;
	            rs.Rev_Amount__c = 0;
	            rs.Rev_Date__c = null;
	            rss.add(rs);
        	}
        }
        
        //system.debug(logginglevel.error, '===rss=== ' + rss);
        try{
        	upsert rss;
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', rss, 'SFE-824 Investigation');
        }
    }

    public static void processCrsOpportunityLineItems(List<OpportunityLineItem> opptyLineItems)
    {
    	List<Revenue_Schedule__c> newCrsList = new List<Revenue_Schedule__c>();
    	Map<Id, Revenue_Schedule__c> updateCrsMapById = new Map<Id, Revenue_Schedule__c>();
        Map<Id, Revenue_Schedule__c> deleteCrsMapById = new Map<Id, Revenue_Schedule__c>();
    	 
        
        Map<Id, List<OpportunityLineItemSchedule>> opptyLineItemScheduleByOpptyLineItemId = new Map<Id, List<OpportunityLineItemSchedule>>();
        Map<Id, OpportunityLineItem> opptyLineItemById = new Map<Id, OpportunityLineItem>();  
        Map<Id, OpportunityLineItemSchedule> opptyLineItemScheduleById = new Map<Id, OpportunityLineItemSchedule>();
        
        //Map<Id, Map<Id, Revenue_Schedule__c>> deleteCrsByIdByOpptyLineItemId = new Map<Id, Map<Id, Revenue_Schedule__c>>(); 
        Map<Id, List<Revenue_Schedule__c>> deleteCrsByOpptyLineItemId = new Map<Id, List<Revenue_Schedule__c>>(); 
        
        ///Set<Id> opptyIds = new Set<Id>(); // opportunity id set of all updated opportunity line items
        Map<Id, List<OpportunityLineItem>> oliListMapByOpportunityId = new Map<Id, List<OpportunityLineItem>>(); // opportunity id set of all updated opportunity line items
    	Set<Id> oliIds = new Set<Id>(); // opportunity line item id set of all updated opportunity line items
    	Set<Id> scheduleItemIds = new Set<Id>(); // schedule line item id set of all updated schedule line items
    	
    	// query schedule items for each opportunity line item
    	for(OpportunityLineItemSchedule opptyItemSchedule : [Select Id, Revenue, ScheduleDate, OpportunityLineItemId, OpportunityLineItem.Opportunity.AccountId, 
													    	OpportunityLineItem.Opportunity.OwnerId, OpportunityLineItem.OpportunityId, 
													    	OpportunityLineItem.PricebookEntry.Product2Id, OpportunityLineItem.Sales_Order__c 
													    	From OpportunityLineItemSchedule Where OpportunityLineItemId IN: opptyLineItems])
    	{
    		String opptyLineItemId = opptyItemSchedule.OpportunityLineItemId;
    		
	        if(!opptyLineItemScheduleByOpptyLineItemId.containsKey(opptyLineItemId))
            {
                opptyLineItemScheduleByOpptyLineItemId.put(opptyLineItemId, new List<OpportunityLineItemSchedule>());
            }
            
            scheduleItemIds.add(opptyItemSchedule.Id);
            opptyLineItemScheduleById.put(opptyItemSchedule.Id, opptyItemSchedule);
            
            opptyLineItemScheduleByOpptyLineItemId.get(opptyLineItemId).add(opptyItemSchedule);
    	}
    	
    	// loop through opportunity line items
    	for(OpportunityLineItem oli : opptyLineItems)
    	{
    		oliIds.add(oli.Id);
    		
    		if(!oliListMapByOpportunityId.containsKey(oli.OpportunityId))
    		{
    			oliListMapByOpportunityId.put(oli.OpportunityId, new List<OpportunityLineItem>());
    		}
    		
    		oliListMapByOpportunityId.get(oli.OpportunityId).add(oli);
    		
    		
    		opptyLineItemById.put(oli.Id, oli);
    	}

        //system.debug(loggingLevel.error, '===oliListMapByOpportunityId=== ' + oliListMapByOpportunityId);
        //system.debug(loggingLevel.error, '===opptyLineItemById=== ' + opptyLineItemById);
        
        //system.debug(loggingLevel.error, '===opptyLineItemScheduleById=== ' + opptyLineItemScheduleById);
        //system.debug(loggingLevel.error, '===opptyLineItemScheduleByOpptyLineItemId=== ' + opptyLineItemScheduleByOpptyLineItemId);
        

    	
        Map<Id, Revenue_Schedule__c> crsByScheduleItemId = new Map<Id, Revenue_Schedule__c>();  
    	
    	system.debug(loggingLevel.error, '====change sales order===');
    	
    	// update opportunity line item part of crs if matched crs found based on opportunity line item id
        for(Revenue_Schedule__c rs : [Select Opportunity__c, Account__c, Opportunity__r.AccountId, Sales_Order__c, 
                                        Line_Item_Schedule_Id__c, Opportunity_Line_Item_Id__c, Product__c
                                      From Revenue_Schedule__c 
                                      //Where Opportunity_Line_Item_Id__c IN: oliIds
                                      Where Opportunity__c IN: oliListMapByOpportunityId.keySet()
                                      ])
    	{
    		// if opportunity line item id on current revenue schedule is blank
    		// it means the opportunity of current revenue schedule didn't have line item previously 
    		// but now it has at least one opportunity line item.
    	    // so we have to override this revenue schedule
    		if(String.isBlank(rs.Opportunity_Line_Item_Id__c))
    		{
    			for(OpportunityLineItem opptyLineItem : oliListMapByOpportunityId.get(rs.Opportunity__c))
    			{
    				//system.debug(loggingLevel.error, '====override empty rs ===');
    				rs.Opportunity_Line_Item_Id__c = opptyLineItem.Id;
    				rs.Rev_Amount__c = opptyLineItem.TotalPrice;
    				rs.Rev_Date__c = opptyLineItem.ServiceDate;
    				break;
    			}
    		}
	
	       //system.debug(loggingLevel.error, '====oli id 1 ===' + rs.Opportunity_Line_Item_Id__c);
	
	       // check if map contains this opportunity line item id in case current opportunity line item id on crs is invalid
	       if(opptyLineItemById.containsKey(rs.Opportunity_Line_Item_Id__c))
	       {
	    		// update opportunity line item part of crs
	    		OpportunityLineItem oli = opptyLineItemById.get(rs.Opportunity_Line_Item_Id__c);
	    		
				rs.Product__c = oli.PricebookEntry.Product2Id;
				rs.Sales_Order__c = oli.Sales_Order__c;
				
	    		oliIds.remove(rs.Opportunity_Line_Item_Id__c);
	    		updateCrsMapById.put(rs.Id, rs);
    		} 	
    	}

        //system.debug(loggingLevel.error, '===processCrsOpportunityLineItems : after loop: updateCrsMapById 1=== ' + updateCrsMapById);

        system.debug('===processCrsOpportunityLineItems : after loop:  oliIds=== ' + oliIds);

        // need to create new crs for rest of id in oliIds set
    	for(Id oliId : new List<Id>(oliIds))
    	{
    		//system.debug(loggingLevel.error, '===oliId=== ' + oliId);
    		//system.debug(loggingLevel.error, '===opptyLineItemScheduleByOpptyLineItemId=== ' + opptyLineItemScheduleByOpptyLineItemId);
    		
    		if(opptyLineItemScheduleByOpptyLineItemId.containsKey(oliId))
    		{
	            for(OpportunityLineItemSchedule opptyLineItemSchedule : opptyLineItemScheduleByOpptyLineItemId.get(oliId))
	            {
	    		 	newCrsList.add(CustomRevenueSchedule_Helper.createOrUpdateCrs(opptyLineItemSchedule, null));
			 	}
    		}
    	}
    	
        system.debug('===processCrsOpportunityLineItems : newCrsList 1=== ' + newCrsList);
    	
    	
        system.debug('===processCrsOpportunityLineItems : before loop:  scheduleItemIds=== ' + scheduleItemIds);

    	
    	// update schedule item part of crs if matched crs found based on schedule item id
    	for(Revenue_Schedule__c rs : updateCrsMapById.values())
    	{
    		//if(rs.Line_Item_Schedule_Id__c != null)
    		//{
	            // if schedule items are found, remove id from schedule item id set.
	    		if(rs.Line_Item_Schedule_Id__c != null && scheduleItemIds.contains(rs.Line_Item_Schedule_Id__c))
	    		{
	    			
	    			// Update schedule item part of CRS
	    			OpportunityLineItemSchedule lineItemSchedule = opptyLineItemScheduleById.get(rs.Line_Item_Schedule_Id__c);
	    			rs.Rev_Amount__c = lineItemSchedule.Revenue;
	    			rs.Rev_Date__c = lineItemSchedule.ScheduleDate;
	    			
                    scheduleItemIds.remove(rs.Line_Item_Schedule_Id__c);
	    		}
	    		else if(rs.Line_Item_Schedule_Id__c == null)
	    		{
	    			// ASSUMPTION: we don't have line item without schedule!!!!
	    			// using opportunity line item id on crs to find random schedule item from map collection
	    			// Therefore, the system won't create crs for opportunity line item without item schedule
	    			if(opptyLineItemScheduleByOpptyLineItemId.containsKey(rs.Opportunity_Line_Item_Id__c))
	    			{
		    			OpportunityLineItemSchedule lineItemSchedule = opptyLineItemScheduleByOpptyLineItemId.get(rs.Opportunity_Line_Item_Id__c)[0];
	                    rs.Rev_Amount__c = lineItemSchedule.Revenue;
	                    rs.Rev_Date__c = lineItemSchedule.ScheduleDate;
		    			rs.Line_Item_Schedule_Id__c = lineItemSchedule.Id;
	                    scheduleItemIds.remove(rs.Line_Item_Schedule_Id__c);
	    			}
	    		}
	    		// if schedule item id set doesn't contain current line item schedule id of crs
	    		// it means that this crs record needs to be deleted cuz its schedule item doesn't exist any more
	    		else 
	    		{
	    			if(!deleteCrsByOpptyLineItemId.containsKey(rs.Opportunity_Line_Item_Id__c))
	    			{
	    				deleteCrsByOpptyLineItemId.put(rs.Opportunity_Line_Item_Id__c, new List<Revenue_Schedule__c>());
	    			}
	    			
	    			deleteCrsByOpptyLineItemId.get(rs.Opportunity_Line_Item_Id__c).add(rs);
	    		}
    		//}
    	}

        //system.debug(loggingLevel.error, '===processCrsOpportunityLineItems : after loop: updateCrsMapById 2=== ' + updateCrsMapById);

        //system.debug(logginglevel.error, '===processCrsOpportunityLineItems : before loop: deleteCrsByOpptyLineItemId=== ' + deleteCrsByOpptyLineItemId);
    	
        system.debug(logginglevel.error, '@size of unfound scheduleItemIds=== ' + scheduleItemIds.size());
        system.debug(logginglevel.error, '@size of deleteCrsByOpptyLineItemIds==== ' + deleteCrsByOpptyLineItemId.size());
    	
        // For the rest of unfound schedule items,
        // find existing CRS according to their opportunity line item Id
        for(Id scheduleItemId : new List<Id>(scheduleItemIds))
        {
        	
        	system.debug('==scheduleItemId== ' + scheduleItemId);
        	
        	// retrieve opportunity line item key
        	String opptyLineItemId;
        	OpportunityLineItemSchedule opptyLineItemSchedule;
        	
        	if(opptyLineItemScheduleById.containsKey(scheduleItemId))
        	{
        		opptyLineItemSchedule = opptyLineItemScheduleById.get(scheduleItemId); 
        		opptyLineItemId = opptyLineItemSchedule.OpportunityLineItemId; 
        	}
        	
        	system.debug('==opptyLineItemSchedule== ' + opptyLineItemSchedule);
        	system.debug('==opptyLineItemId== ' + opptyLineItemId);
        	
        	
        	if(opptyLineItemId != null && !oliIds.contains(opptyLineItemId))
        	{
        		// if map contains same opportunity line item as key
        		// reuse list of crs entries from map and try to override them with the rest of opportunity line item schedules
	        	if(deleteCrsByOpptyLineItemId.containsKey(opptyLineItemId))
	        	{
	        		List<Revenue_Schedule__c> deleteCrs = deleteCrsByOpptyLineItemId.get(opptyLineItemId);
	                
                    system.debug('===deleteCrs 1==== ' + deleteCrs.size());
	                
	                
	        		if(deleteCrs.size() > 0)
	        		{
	        			Revenue_Schedule__c crs = deleteCrs[0];
		     
	                    // override crs with new values	     
		                crs = CustomRevenueSchedule_Helper.createOrUpdateCrs(opptyLineItemSchedule, crs);
	                           			
	        			// remove record from delete collection
	                    deleteCrs.remove(0);
	                    
                        system.debug('===deleteCrs 2==== ' + deleteCrs.size());
	                    
	                    // add updated record to upsert collection
	                    updateCrsMapById.put(crs.Id, crs);
	                    

	        		}
	        		
                     // if crs list size reduced to zero, 
                    // we have to remove deleteCrsByOpptyLineItemId entry based on current opportunity line item id
                    else
                    {
                    	system.debug('==before remove=== ' + deleteCrsByOpptyLineItemId);
                    	
                        deleteCrsByOpptyLineItemId.remove(opptyLineItemId);
                     
                        system.debug('==after remove=== ' + deleteCrsByOpptyLineItemId);
                     
                        Revenue_Schedule__c crs = CustomRevenueSchedule_Helper.createOrUpdateCrs(opptyLineItemSchedule, null);
 
	                    system.debug('===processCrsOpportunityLineItems : new crs 1==== ' + crs);
	                                
	                    newCrsList.add(crs);
                    }
	        	}
	        	// create new crs if there is no available crs records from to-be-delete map 'deleteCrsByOpptyLineItemId'
	            else
	        	{	    
	        		Revenue_Schedule__c crs = CustomRevenueSchedule_Helper.createOrUpdateCrs(opptyLineItemSchedule, null);
 
                    system.debug('===processCrsOpportunityLineItems : new crs 2==== ' + crs);
	        		    		
	        		newCrsList.add(crs);
	        		
	        		
	        	}
        	}
        	
            system.debug('===deleteCrsByOpptyLineItemId end==== ' + deleteCrsByOpptyLineItemId);
        	
        }

        //system.debug('===processCrsOpportunityLineItems : last deleteCrsByOpptyLineItemId=== ' + deleteCrsByOpptyLineItemId);        
        //system.debug(loggingLevel.error, '===processCrsOpportunityLineItems : after loop: updateCrsMapById 3=== ' + updateCrsMapById);
        //system.debug('===processCrsOpportunityLineItems : last newCrsList=== ' + newCrsList);
	
	
	    // The following block of code is to test concurrency issue happened during records update operation.
	    // Therefore, it's been commented out after testing.
	    /*if(updateCrsMapById.values().size() > 0)
	    {
	    	system.debug(logginglevel.error, '@remove updating record for testing: ' + updateCrsMapById.values()[0]);
	    	String crsId = updateCrsMapById.values()[0].Id;
            system.debug(logginglevel.error, '@remove updating record Id: ' + updateCrsMapById.values()[0].Id);
	    	delete [Select r.Id From Revenue_Schedule__c r Where r.Id =: crsId limit 1];
	    }*/
	
	    // update CRS records
	    // NOTE: we need to update CRS records firstly. In case of any record failure, move CRS records into new CRS records list.
	    // These records will be inserted during insertion operation.
        system.debug(logginglevel.error, '@processCrsOpportunityLineItems updateCrsMapById.values() size: ' + updateCrsMapById.values().size());
        
        
        /***** Updated By Bohao Chen on 21/March/2014 for JIRA issue SFE-7 ********/
        // convert Map to List in order to keep list in order when displaying error results
        List<Revenue_Schedule__c> updatedRevenueSchedules = new List<Revenue_Schedule__c>();
        updatedRevenueSchedules = updateCrsMapById.values();
        Database.SaveResult[] srList = Database.update(updatedRevenueSchedules, false);
        
        Integer i = 0;
        String exceptionMessage = '';

        for(Database.SaveResult result : srList) 
        {
            if (!result.isSuccess())
            {           
            	exceptionMessage += 'Failed record ' +  updatedRevenueSchedules[i].Id + '  '; 	
                for(Database.Error error : result.getErrors()) 
                {                    
                    exceptionMessage += error.getMessage();
                    
                }
            }

            i++;
        }
        
        if(String.isNotBlank(exceptionMessage))
        {			
			ExLog.log(new CustomException('Opportunity Line Item Schedule Update Error - see Additional Info'), 'config', (sObject) null, exceptionMessage);            
        }
        
        List<Revenue_Schedule__c> failedUpdateCrs = CustomRevenueSchedule_Helper.displaySaveErrorResults(srList, updatedRevenueSchedules, 'update');
        /***** Updated By Bohao Chen ****/
        
        
        system.debug(logginglevel.error, '@failedUpdateCrs ' + failedUpdateCrs);

        if(failedUpdateCrs != null && failedUpdateCrs.size() > 0)
        {
        	newCrsList.addAll(failedUpdateCrs);
        }
        
        srList = Database.insert(newCrsList, false);

		i = 0;
        exceptionMessage = '';

        for(Database.SaveResult result : srList) 
        {
            if (!result.isSuccess())
            {           
            	exceptionMessage += 'Failed record ' +  newCrsList[i].Id + '  '; 	
                for(Database.Error error : result.getErrors()) 
                {                    
                    exceptionMessage += error.getMessage();
                    
                }
            }

            i++;
        }
        
        if(String.isNotBlank(exceptionMessage))
        {			
			ExLog.log(new CustomException('Opportunity Line Item Schedule Insert Error - see Additional Info'), 'config', (sObject) null, exceptionMessage);            
        }
        
        CustomRevenueSchedule_Helper.displaySaveErrorResults(srList, null, 'insert');
		
		List<Revenue_Schedule__c> deleteCrsList = new List<Revenue_Schedule__c>();
            
        for(List<Revenue_Schedule__c> crs : deleteCrsByOpptyLineItemId.values())
        {
            deleteCrsList.addAll(crs);
        }
                
        system.debug(logginglevel.error, '@processCrsOpportunityLineItems deleteCrsByOpptyLineItemId.values() size' + deleteCrsByOpptyLineItemId.values().size());

        Database.Deleteresult[] drList = Database.delete(deleteCrsList, false);
		i = 0;
        exceptionMessage = '';

        for(Database.Deleteresult result : drList) 
        {
            if (!result.isSuccess())
            {           
            	exceptionMessage += 'Failed record ' +  deleteCrsList[i].Id + '  '; 	
                for(Database.Error error : result.getErrors()) 
                {                    
                    exceptionMessage += error.getMessage();
                    
                }
            }

            i++;
        }
        
        if(String.isNotBlank(exceptionMessage))
        {			
			ExLog.log(new CustomException('Opportunity Line Item Schedule Delete Error - see Additional Info'), 'config', (sObject) null, exceptionMessage);            
        }
		
        //CustomRevenueSchedule_Helper.displayDeleteErrorResults(drList);
    }
    
    // Iterate through each returned result
    /***** Updated By Bohao Chen on 21/March/2014 for JIRA issue SFE-7 ********/
    private static List<Revenue_Schedule__c> displaySaveErrorResults(Database.SaveResult[] srList, 
																    List<Revenue_Schedule__c> updateCrsList, 
																    String dmlOperationType)
	/***** Updated By Bohao Chen ***/
    {
    	List<Revenue_Schedule__c> failedCrsList = new List<Revenue_Schedule__c>();
    	
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    	
    	// Iterate through each returned result
    	Integer i = 0;
        for (Database.SaveResult sr : srList) 
        {
            if (!sr.isSuccess()) 
            {
            	/***** Updated By Bohao Chen on 21/March/2014 for JIRA issue SFE-7 ********/
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{'bohao.chen@bluewolf.com'});
                mail.setSubject('CRS batch error from Custom Revenue Schedule Batch for ' + dmlOperationType);
                
                String emailBody = '';
                
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) 
                {
		            emailBody = i + '. error code: ' + err.getStatusCode() + ', error message: ' + err.getMessage();
                }
                
                if(dmlOperationType == 'update' && updateCrsList.size() > 0 &&  updateCrsList[i].Id != null)
                {
                    Revenue_Schedule__c crsRec = updateCrsList[i];
                    emailBody += ' Opportunity Id is: ' + crsRec.Opportunity__c;
                    emailBody += ' Opportunity Line Item Id is: ' + crsRec.Opportunity_Line_Item_Id__c;
                    emailBody += ' Schedule Item Id is: ' + crsRec.Line_Item_Schedule_Id__c;
                    emailBody += ' this record will be re-insert after this failure. Please use above ids to check CRS records to make sure that it has been synced with CRS';
                    
                    Revenue_Schedule__c crsRecCp = new Revenue_Schedule__c();
                    crsRecCp = crsRec.clone();
                    failedCrsList.add(crsRecCp);
                }
                /***** Updated By Bohao Chen ***/
                
                mail.setPlainTextBody(emailBody);
                mails.add(mail);
            }
            
            i++;
        }
        
        if(mails.size() > 0)
            Messaging.sendEmail(mails);
        
        system.debug('@failedCrsList: ' + failedCrsList);    
        return failedCrsList;
    }
    
    // Iterate through each returned result
    /*private static void displayDeleteErrorResults( Database.Deleteresult[] drList)
    {
        // TODO: this is for debugging process, remove later
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
    	for(Database.DeleteResult dr : drList) 
        {
		    if (!dr.isSuccess()) 
            {
		        // Operation failed, so get all errors                
		        for(Database.Error err : dr.getErrors()) 
                {		        	
		            System.debug('The following error has occurred.');                    
		            System.debug(err.getStatusCode() + ': ' + err.getMessage());
		            System.debug('Fields that affected this error: ' + err.getFields());
		            
                    // TODO: this is for debugging process, remove later
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[]{'bohao.chen@bluewolf.com'});
                    mail.setSubject('CRS batch error from UAT: displayDeleteErrorResults');
                    mail.setPlainTextBody('error code: ' + err.getStatusCode() + ', error message: ' + err.getMessage() + ', Fields that affected this error: ' + err.getFields());
                    mails.add(mail);
		        }
		    }
	    }
	    
        Messaging.sendEmail(mails);
    }*/
    
    private static Revenue_Schedule__c createOrUpdateCrs(OpportunityLineItemSchedule olis, Revenue_Schedule__c crsIn)
    {
    	Revenue_Schedule__c crs;
    	
    	if(crsIn == null)
    	{
    		crs = new Revenue_Schedule__c();
    	}
    	else
    	{
    		crs = crsIn;
    	}
    	
        crs.Account__c = olis.OpportunityLineItem.Opportunity.AccountId;
        crs.Owner__c = olis.OpportunityLineItem.Opportunity.OwnerId;
        crs.OwnerId = crs.Owner__c;
        crs.Line_Item_Schedule_Id__c = olis.Id;
        crs.Opportunity__c = olis.OpportunityLineItem.OpportunityId;
        crs.Opportunity_Line_Item_Id__c = olis.OpportunityLineItemId;
        crs.Product__c = olis.OpportunityLineItem.PricebookEntry.Product2Id;
        crs.Rev_Amount__c = olis.Revenue;
        crs.Rev_Date__c = olis.ScheduleDate;
        crs.Sales_Order__c = olis.OpportunityLineItem.Sales_Order__c;
    	return crs;
    }
    
    public static void deleteCrsByOpportunityLineItems(List<OpportunityLineItem> opptyLineItems)
    {
    	// get opportunity ids of opportunity line items in order to understand
    	// how many crs for each opportunity id
    	Set<Id> opptyIds = new Set<Id>();
    	Set<Id> oliIds = new Set<Id>();
    	
    	for(OpportunityLineItem oli : opptyLineItems)
    	{
    		oliIds.add(oli.Id);
    		opptyIds.add(oli.OpportunityId);
    	}
    	
    	Map<String, Integer> numOfCrsByOpptyId = new Map<String, Integer>();
    	
    	for(AggregateResult ar : [Select Opportunity__c opptyId, count(Id) num
								    	From Revenue_Schedule__c 
								    	Where Opportunity__c IN: opptyIds
								    	group by Opportunity__c])
    	{
    		numOfCrsByOpptyId.put(String.valueOf(ar.get('opptyId')), Integer.valueOf(ar.get('num')));
    	}
    	
    	//system.debug(logginglevel.error, '====numOfCrsByOpptyId=== ' + numOfCrsByOpptyId);
    	
    	if(oliIds.size() > 0)
    	{
	        List<Revenue_Schedule__c> deleteRss = new List<Revenue_Schedule__c>();
	        List<Revenue_Schedule__c> updateRss = new List<Revenue_Schedule__c>();
	        
	        // loop through queried revenue schedules.
	        // delete all revenuse schedules except the last one.
	        // For the last revenue schedule, it needs to be updated so that
	        // revenue amount and revenue date will gets updated according to opportunity's unit price and close date,
	        // and line item schedule value will be blank
	        for(Revenue_Schedule__c rs : [Select Opportunity__c, Account__c, Opportunity__r.AccountId, Product__c, 
	                                       Opportunity__r.Amount, Opportunity__r.CloseDate, Sales_Order__c
                                             From Revenue_Schedule__c 
                                             Where Opportunity_Line_Item_Id__c IN: oliIds
                                         ])
            { 
            	String opptyId = rs.Opportunity__c;
            	
            	if(numOfCrsByOpptyId.get(opptyId) > 1)
                {
                    deleteRss.add(rs);
                    numOfCrsByOpptyId.put(opptyId, numOfCrsByOpptyId.get(opptyId) - 1);
                }
                else if(numOfCrsByOpptyId.get(opptyId) == 1)
                {
                	rs.Opportunity_Line_Item_Id__c = null;
                	rs.Line_Item_Schedule_Id__c = null;
                	rs.Rev_Amount__c = 0;
                    rs.Rev_Date__c = null;
                    rs.Product__c = null;
                    rs.Sales_Order__c = null;
                    updateRss.add(rs);
                }
            }
	        
	        try{
	        	update updateRss;
	        }
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', updateRss, 'SFE-824 Investigation');
	        }
	        
	        try{
	        	delete deleteRss;
	        }
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', deleteRss, 'SFE-824 Investigation');
	        }	        
    	}
    }

    public static void deleteCrsByOpportunity(List<Opportunity> opportunities)
    {
    	List<Revenue_Schedule__c> tempSchedule = new List<Revenue_Schedule__c>();
    	tempSchedule = [Select Id From Revenue_Schedule__c Where Opportunity__c IN: opportunities];
    	try{ 
        	delete tempSchedule;
    	}
    	catch(Exception ex){
    		ExLog.log(ex, 'config', tempSchedule, 'SFE-824 Investigation');
    	}
    }
    
    public static boolean hasChanged(String objectName, Opportunity oldOppty, Opportunity newOppty)
    {
        Boolean hasChanged = false;
        
        for(String fieldName : opptyFieldNames)
        {
        	if(oldOppty.get(fieldName) != newOppty.get(fieldName))
        	{
		        system.debug('===BC: value on ' + fieldName + ' is changed');
        		
        		hasChanged = true;
        	}
        }
        
        return hasChanged;
    }
    
    /**    
    * @description  This inner class extends Exception class. It is used to enter Reusable Exception Logging Module.
    * @author       darshan.gosar@bluewolf.com
    * @date         2016-06-10
    */
    public class CustomException extends Exception {}    

}