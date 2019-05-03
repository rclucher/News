/*---------------------------------------------------------
 * Author: Stuart Hamilton
 * Company: Salesforce.com
 * Description: This is the helper class for interaction 
 *              with the Genesys CTI Visualforce page
 * Test Class: CTI_Helper_Test
 * History:
 * 06/09/2013  Stuart Hamilton  Created
 * 22/10/2013  Stuart Hamilton  Added SetCaseOwner
 ---------------------------------------------------------*/
public without sharing class CTI_Helper{

    // ## cache?  
    public static Id rtCaseAdvertising = [Select Id From RecordType where SobjectType = 'Case' and name='Advertising' LIMIT 1].Id;
    
    // create the Case record for an inbound or outbound call
    public static Id CreateCase (CTI_Helper.eventType caseType, 
        						             String cLI, 
                                 String ConnID,
                                 List<String> ContactIds, 
                                 List<String> AccountIds) 
    {
      return CreateCase (caseType, cLI, ConnID, ContactIds, AccountIds, '') ;
    }
    
    // Overload create the Case record for an inbound or outbound call passing Queue Name as parameter
    public static Id CreateCase (CTI_Helper.eventType caseType, 
        						              String cLI, 
                                  String ConnID,
                                  List<String> inContactIds, 
                                  List<String> inAccountIds,
                                  String QueueName) 
    {
      String cOrigin; 
        
        
      List<String> contactIds = new list<string>();
  		List<String> accountIds = new list<string>();
  		
  		if(inContactIds!=null)
  		{
  			for(string s : inContactIds)
  			{
  				system.debug('@ CreateCase() inContactIds s:' + s);
  	       //Verify if id is likely to be a valid contact Id
  				if(s.trim().length()>=15 && s.trim().substring(0,3) == Contact.SObjectType.getDescribe().getKeyPrefix())
  					contactIds.add(s.trim());
  			}
    	}		
   
   		if(inAccountIds!=null)
   		{
  	 		for(string s : inAccountIds)
  			{
  				system.debug('@ CreateCase() inAccountIds s:' + s);
  		    //Verify if id is likely to be a valid account Id
  				if(s.trim().length()>=15 && s.trim().substring(0,3) == Account.SObjectType.getDescribe().getKeyPrefix())
  					accountIds.add(s.trim());
  			}
   		}
 		        
      // get contacts and accounts
      List<Contact> cons; 
      
      Id contactId;
      Id accountId;
	
  		system.debug('@ CreateCase() caseType:' + caseType);
  		system.debug('@ CreateCase() cLI:' + cLI);
  		system.debug('@ CreateCase() contactIds:' + contactIds);
  		system.debug('@ CreateCase() accountIds:' + accountIds);

  		//single contact (associate the Contact and Contact's Account)
  		if (contactIds != null && contactIds.size() == 1) {
  			cons = [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds];
       	contactId = cons[0].Id;
  	   	accountId = cons[0].AccountId;
      }

      //Single Accounts, NO or Multiple contacts (associate Account, no contact)        
      else if (accountIds != null && accountIds.size() == 1  && 
               (contactIds == null || (contactIds != null && contactIds.size() != 1))) {
        accountId = accountIds[0];
      }        
  		else
    	{
    		//#Hadled by UI other combinations
    	}
      
      if (eventType.CALL_INBOUND == caseType) {
          cOrigin = 'Call - Inbound';
      } else if (eventType.CALL_OUTBOUND == caseType) {
          cOrigin = 'Call - Outbound';
      } else if (eventType.EMAIL_INBOUND == caseType) {
          cOrigin = 'Email - Inbound';
      }else {
      	// ##handle other types or error??    
      }
                  
      // create the Case
      Case c; 
      try{
      	c = New Case(RecordTypeId = rtCaseAdvertising,
          			     AccountId = accountId, 
                     ContactId = contactId, 
                     CLI__c = cLI, 
                     Type = 'Advertising', 
                     Origin = cOrigin, 
                     Status = 'Open',
                     Priority = '3-Medium', 
                     Call_ID__c = ConnId
                     );

        //For inbound calls owner should be set and status set as In Progress Incident #4154
        if(cOrigin == 'Call - Inbound' || cOrigin == 'Call - Outbound')
        {
          c.OwnerId = UserInfo.getUserId();
          c.Status = 'In Progress';
        }

        insert c;


      }
      catch (Exception ex)
      {
      	system.debug('@ CreateCase() :' + ex.getMessage());
      	throw new CTIHelperException(ex.getMessage());
      }
      return c.Id;
    }
    
    // change the owner of the case to the current user
    // set the Status = In Progress
    public static void SetCaseOwner (Id caseId) {
        if (caseId != null) {
            List<Case> c = [SELECT OwnerId, Status FROM Case WHERE Id = :caseId];
	        if (c.size() == 1) {
    	    	c[0].OwnerId = UserInfo.getUserId();
                c[0].Status = 'In Progress';
        	    update c;
        	} else {
        		// error 
            	throw (new CTIHelperException('Case not found: ' + caseId));
        	}
        } else {
        	throw (new CTIHelperException('Parameter caseId is required'));
        }
    }
    
    public static Id CreateTask (CTI_Helper.eventType taskType, 
        						            String objectType, 
                                 String objectId, 
                                 DateTime startDateTime, 
                                 DateTime endDateTime, 
                                 Integer duration, 
                                 String interactionId, 
                                 String CLI, 
                                 Boolean callAnswered) 
    {

      String tType; 
      String tSubject;
      // default task status to In Progress, for user to manually wrap-up
      String tStatus = 'In Progress'; 
      Id tWhat;
      Id tWho;

      // set appropriate defaults by task type
      if (eventType.CALL_INBOUND == taskType) {
       	  tSubject = 'Call';
          tType = 'Call - Inbound';
      } else if (eventType.CALL_OUTBOUND == taskType) {
      		tSubject = 'Call';
          tType = 'Call - Outbound';
      } else if (eventType.EMAIL_INBOUND == taskType) {
          tSubject = 'Email';
          tType = 'Email - Inbound';
      }
       

      //Find potential Camapaign Member from Contact
      if('Contact' == objectType)
      {
          list<CampaignMember>  crL = [SELECT   ContactId,
                                                CampaignId,
                                                In_Progress__c,
                                                Locked_by__c 
                                       FROM     CampaignMember
                                       WHERE    ContactId = :objectId
                                        AND     In_Progress__c = True
                                        AND     Locked_by__c = :UserInfo.getUserId()
                                       ORDER BY CreatedDate Desc
                                       LIMIT    1];

          if(crL.size()>0)
          {
            objectType = 'CampaignMember';
            objectId = crL[0].id;
          }

      }



      // get who and what from object
      if ('Contact' == objectType) {
        try
        {        
          Contact c = [SELECT AccountId FROM Contact WHERE Id = :objectId LIMIT 1];
          tWho = c.Id; 
          tWhat = c.AccountId; 
        }
        catch (Exception ex)
        {
          system.debug('@ CreateTask() Invalid Contact Id :' + ex.getMessage());
          throw new CTIHelperException(ex.getMessage());
        }

      } else if ('Lead' == objectType) {
          tWho = objectId; 
      } else if ('Case' == objectType) {
        try
        {  
      	 Case c = [SELECT ContactId FROM Case WHERE Id = :objectId LIMIT 1];
          tWho = c.ContactId; 
          tWhat = c.Id; 
        }
        catch (Exception ex)
        {
          system.debug('@ CreateTask() Invalid Case id :' + ex.getMessage());
          throw new CTIHelperException(ex.getMessage());
        }

      } else if ('Opportunity' == objectType) {
        try
        { 
       	  Opportunity o = [SELECT Contact__c FROM Opportunity WHERE Id = :objectId LIMIT 1];
          tWho = o.Contact__c;
          tWhat = o.Id;
        }
        catch (Exception ex)
        {
          system.debug('@ CreateTask() Invalid Opportunity id :' + ex.getMessage());
          throw new CTIHelperException(ex.getMessage());
        } 
      } else if ('CampaignMember' == objectType) {
        try
        { 
          CampaignMember cm = [SELECT CampaignId, ContactId, LeadId
                               FROM CampaignMember WHERE Id = :objectId LIMIT 1];
          if (cm.ContactId != null) {
          	tWhat = cm.CampaignId;
            tWho = cm.ContactId;
          } else {
              // can't attach task to both Lead & Campaign, so just Lead
              tWho = cm.LeadId;
          }
          // for campaign activities, complete the activity
          tStatus = 'Done'; 
        }
        catch (Exception ex)
        {
          system.debug('@ CreateTask() Invalid Campaign Member id :' + ex.getMessage());
          throw new CTIHelperException(ex.getMessage());
        } 
      } else {
          tWhat = objectId; 
      	// Objects that don't support activities are caught by the try catch block on insert.
        // An Error is thrown if the objects is not supported  
      }

      Task t;

      try
      {
      	t = new Task(Type = tType, 
        				     Subject = tSubject, 
                     Status = tStatus, 
                     CallDurationInSeconds = duration, 
                     Call_ID__c = interactionId,
                     ActivityDate = startDateTime.date(),
                     Call_Start__c = startDateTime, 
                     Call_End__c = endDateTime, 
                     WhatId = tWhat,
                     WhoId = tWho, 
                     IsReminderSet = false, 
                     IsRecurrence = false,
                     Call_Answered__c = callAnswered
            			 );
        insert t;
      }
      catch (Exception ex)
      {
        system.debug('@ CreateTask() :' + ex.getMessage());
        throw new CTIHelperException(ex.getMessage());
      }
      return t.Id;
    }
    
    public enum eventType {CALL_INBOUND, CALL_OUTBOUND, EMAIL_INBOUND}
    
    public class CTIHelperException extends Exception {}
}