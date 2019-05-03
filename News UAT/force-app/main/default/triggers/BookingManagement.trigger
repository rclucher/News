/*---------------------------------------------------------
 * Author: Paul Fayle
 * Company: Salesforce.com
 * Description: 
 * 1. trigger to populate the Advertiser/Customer,
 *    Placer, Payer Accounts from the parent Sales Order to the Booking
 *    which allows for related Bookings lists on Accounts. R-0740
 * 2. To change owner of booking's sales order based on value of sales rep on booking. R-0799
 * 3. send quote/confirmation email R-0221
 * History:
 * 20/08/2013  Paul Fayle           Created
 * 26/08/2013  Bohao Chen           Updated
 * 28/08/2013  Bohao Chen           Updated
 * 11/10/2013  Bohao Chen           Updated
 * 20/05/2014  Leonardo Mancilla    Updated (SFE-343 - Booking number not populating on the case)
 * 10/06/2014  Tim Fabros           Updated (SFE-343 - Booking number not populating on the case)
 * 04/05/2015  Louis Wang           Updated (UserStory16.3 - Update Account.Last_Booking_Value)
 * 2016-02-25  Atul Gupta           Updated
 * 2016-03-01  Darshan G            Updated (SFE-794 - Sales Order Owner of Booking & Sales Order are out of sync)
 * 2016-08-15  Peter Charalambous   Updated (Revenue Reporting R1.2 Solution)
 * 2017-05-17  Darshan G            Updated (AdSales 271 - Update Account.Last_Booking_Line_Item_Publication_Divs__c) 
 * 2018-01-25  Nishank Tandon       Updated (Backlog 1127)
 * 2019-03-15  Ashfaq Mohaamed      Updated (SFE-1068 - Allow for additoon of SalesOrder Owner Role field)
 ---------------------------------------------------------*/
 trigger BookingManagement on Booking__c (before insert, before update, after insert, after update)
 { 
    if (Global_Helper.canTrigger( 'BookingManagement' ) ) {
        if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
        {
            boolean isIntegrationUser = Global_Helper.amIIntegrationUser();

            Set<String> networkUsernames = new Set<String>();
            Set<String> externalSalesOrderIdSet = new set<String>();
            Map<String, Id> salesOrderIdByExternalId = new map<String, id>();

            Map<Id,List<Booking__c>> bookingListBySalesOrderId = new Map<Id,List<Booking__c>>(); // Added by Tim Fabros 17 / 06 / 2014 - SFE-412.

            //#R-0724
            Set<Id> updatedByIntegration = new Set<Id>();
            
            //2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to before trigger context
            List<Booking__c> bookingListForLog = new List<Booking__c>();
            try{
                for (Booking__c bk : trigger.new) 
                {

                    system.debug('@BookingManagement bk:' + bk);

                    /****** R-0740 *****/
                    bk.Advertiser_Account__c = bk.Sales_Order_Advertiser__c;
                    bk.Payer_Account__c = bk.Sales_Order_Payer_Account__c;
                    bk.Placer_Account__c = bk.Sales_Order_Placer_Account__c;
                    bk.Placer_Contact__c = bk.Sales_Order_Placer_Contact__c;
                
                    /****** R-0799 *****/
                    // if booking has sale rep value, add it to networkUsernames in order to find users later
                    if(String.isNotBlank(bk.Sales_Rep__c))
                    {
                        networkUsernames.add(bk.Sales_Rep__c);
                    }
                    
                    if(String.isNotBlank(bk.Ad_Taker__c))
                    {
                        networkUsernames.add(bk.Ad_Taker__c);
                    }


                    if(trigger.isInsert)
                    {

                        system.debug('@BookingManagement bk.External_Sales_Order_Id__c:' + bk.External_Sales_Order_Id__c);
                        if(bk.External_Sales_Order_Id__c != null && bk.External_Sales_Order_Id__c != '' && isIntegrationUser)
                            externalSalesOrderIdSet.add(bk.External_Sales_Order_Id__c);

                        // Added by Tim Fabros 17 / 06 / 2014 - SFE-412.
                        // Updated by Bohao Chen 25 June 2014 - SFE-412 
                        // fills out the booking's campaign lookup with the value set in the related sales order
                        // this is ONLY for update trigger
                        // BEGIN:
                        if (bk.Sales_Order__c != null)
                        {
                            if (bookingListBySalesOrderId.containsKey(bk.Sales_Order__c))
                                bookingListBySalesOrderId.get(bk.Sales_Order__c).add(bk);
                            else
                                bookingListBySalesOrderId.put(bk.Sales_Order__c, new List<Booking__c>{bk});
                        }
                        // END
                    }

                    if(trigger.isUpdate)
                    {
                        if(trigger.oldMap.get(bk.id).Integration_Date__c != trigger.newMap.get(bk.id).Integration_Date__c)
                        {
                            updatedByIntegration.add(bk.id);
                        }

                        //ignores atempts from the integration user to modify the Booking Sales Order Id
                        if(bk.Sales_Order__c == null || (bk.Sales_Order__c != trigger.oldMap.get(bk.id).Sales_Order__c && isIntegrationUser))
                        {
                            bk.Sales_Order__c = trigger.oldMap.get(bk.id).Sales_Order__c;
                        }
                        
                        if(trigger.oldMap.get(bk.Id).Quote_Confirmation__c != bk.Quote_Confirmation__c)
                        {
                            bk.Quote_Confirmation_waiting_msg_sent__c = false;
                        }
                    }
                    bookingListForLog.add(bk);
                }
            } catch(Exception ex){
                ExLog.log(ex, 'config', bookingListForLog, 'SFE-824 Booking records before trigger 1');
            }
            
            List<Sales_Order__c> salesOrderListForLog = new List<Sales_Order__c>();
            // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to before trigger context
            try{
                // Added by Tim Fabros 17 / 06 / 2014 - SFE-412.
                // fills out the booking's campaign lookup with the value set in the related sales order
                // BEGIN:
                for (Sales_Order__c so : [SELECT Id, Campaign__c FROM Sales_Order__c WHERE Id IN: bookingListBySalesOrderId.keySet()])
                {
                    if (so.Campaign__c != null)
                    {
                        for (Booking__c bk : bookingListBySalesOrderId.get(so.Id))
                        {
                            bk.Campaign__c = so.Campaign__c;
                        }
                    }
                    salesOrderListForLog.add(so);
                }
                // END:
            } catch(Exception ex){
                ExLog.log(ex, 'config', salesOrderListForLog, 'SFE-824 Sales Order records before trigger');
            }

            //#R-0724
            map<id,list<Booking_Line_Item__c>> lineItemsByBookingId = new map<id,list<Booking_Line_Item__c>>();
            //#R-0724
            

            if(updatedByIntegration.size()>0)
            {
                for(Booking_Line_Item__c bli : [SELECT  b.Til_Cancelled__c, b.Booking__c, b.Publication__c, b.Division__c, b.Classification__c, b.Ad_Type__c
                                                FROM    Booking_Line_Item__c b
                                                WHERE   b.Booking__c IN :updatedByIntegration])
                {
                    if(!lineItemsByBookingId.containsKey(bli.Booking__c))
                        lineItemsByBookingId.put(bli.Booking__c, new list<Booking_Line_Item__c>{bli});
                    else
                        lineItemsByBookingId.get(bli.Booking__c).add(bli);
                }   
            }


            system.debug('====networkUsernames=== ' + networkUsernames);
            
            // find user based on user network username
            // create map with user id as value and network name as key
            //Map<String, Id> userIdMapByNetworkUsername = BookingManagement_Trigger_Helper.getUserIdMap(networkUsernames);
            Map<String, user> userIdMapByNetworkUsername = BookingManagement_Trigger_Helper.getUserIdMap(networkUsernames);
            
            // get default sales rep id in case system couldn't find user id by network username
            SystemParameters__c sp = SystemParameters__c.getInstance('Default Sales Rep');
            Id defaultSalesRepId = sp.Value__c;
            //get default sales rep role name in case system could'nt find user id/role name by network username
            string defaultSalesRepRoleName = sp.Value__c;
            
            


            system.debug('@BookingManagement externalSalesOrderIdSet:' + externalSalesOrderIdSet);
            for(Sales_Order__c so : [Select id, External_Id__c from Sales_Order__c where External_Id__c IN :externalSalesOrderIdSet])
            {
                salesOrderIdByExternalId.put(so.External_Id__c, so.id);
            }
            
            List<Booking__c> bookingListForLogging = new List<Booking__c>();
            // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to before trigger context
            try{
                // Update Sales Order Owner on booking
                for (Booking__c bk : trigger.new) 
                {

                    if(trigger.isInsert)
                    {
                        if(bk.External_Sales_Order_Id__c != null &&
                            bk.External_Sales_Order_Id__c != '' &&
                            salesOrderIdByExternalId.containsKey(bk.External_Sales_Order_Id__c) &&
                            isIntegrationUser)
                        {
                            bk.Sales_Order__c = salesOrderIdByExternalId.get(bk.External_Sales_Order_Id__c);
                        }
                    }

                    //Prepopulate booking summary fields based on booking line items
                    //#R-0724
                    if(trigger.isUpdate && trigger.oldMap.get(bk.id).Integration_Date__c != bk.Integration_Date__c)
                    {

                        if(lineItemsByBookingId.containsKey(bk.id))
                        {
                            bk.Line_Item_Ad_Types__c='';
                            bk.Line_Item_Classifications__c='';
                            bk.Line_Item_Publication_Divisions_mpl__c='';
                            bk.Line_Item_Publications__c='';
                            bk.Line_Item_TC_Flags__c='';

                            Set<String> adTypesSet = new Set<String>();
                            Set<String> classificationsSet = new Set<String>();
                            Set<String> publicationsSet = new Set<String>();
                            Set<String> divisionsSet = new Set<String>();
                            Set<String> tcFlagsSet = new Set<String>();

                            List<String> adTypesList = new List<String>();
                            List<String> classificationsList = new List<String>();
                            List<String> publicationsList = new List<String>();
                            List<String> divisionsList = new List<String>();
                            List<String> tcFlagsList = new List<String>();

                            for(Booking_Line_Item__c bli : lineItemsByBookingId.get(bk.id))
                            {
                                if(bli.Ad_Type__c!=null && bli.Ad_Type__c.trim().length()>0)
                                    adTypesSet.add(bli.Ad_Type__c.trim());

                                if(bli.Classification__c!=null && bli.Classification__c.trim().length()>0)                       
                                    classificationsSet.add(bli.Classification__c);

                                if(bli.Publication__c!=null && bli.Publication__c.trim().length()>0)                    
                                    publicationsSet.add(bli.Publication__c);

                                if(bli.Division__c!=null && bli.Division__c.trim().length()>0)                    
                                    divisionsSet.add(bli.Division__c);
                                
                                tcFlagsSet.add(bli.Til_Cancelled__c?'true':'false');
                            }

                            adTypesList.addAll(adTypesSet);
                            classificationsList.addAll(classificationsSet);
                            publicationsList.addAll(publicationsSet);
                            divisionsList.addAll(divisionsSet);
                            tcFlagsList.addAll(tcFlagsSet);


                            bk.Line_Item_Ad_Types__c = String.join(adTypesList, ', ');
                            bk.Line_Item_Classifications__c = String.join(classificationsList, ', ');
                            bk.Line_Item_Publication_Divisions_mpl__c = String.join(divisionsList, ';');
                            bk.Line_Item_Publications__c = String.join(publicationsList, ', ');
                            bk.Line_Item_TC_Flags__c = String.join(tcFlagsList, ', ');
                        }
                    }

                    if(String.isNotBlank(bk.Sales_Rep__c))
                    {
                        
                        
                        if(userIdMapByNetworkUsername.containsKey(bk.Sales_Rep__c.toUpperCase()))
                        {
                            user u = new user();
                            u = userIdMapByNetworkUsername.get(bk.Sales_Rep__c.toUpperCase());
                            
                            // find user id according to network username, then assign to lookup field Sales_Order_Owner__c on booking
                            //bk.Sales_Order_Owner__c = userIdMapByNetworkUsername.get(bk.Sales_Rep__c.toUpperCase());
                            bk.Sales_Order_Owner__c = u.Id;
                            if(bk.Sales_Order_Owner_Role__c == null){
                                bk.Sales_Order_Owner_Role__c = u.UserRole.Name;
                            }
                            
                        }
                        else
                        {
                            // if system couldn't find user id by network username,
                            // system have to go to custom setting. 
                            // in system parameter, find 'Default sales rep' entry and get user Id
                            bk.Sales_Order_Owner__c = defaultSalesRepId;
                            bk.Sales_Order_Owner_Role__c = defaultSalesRepRoleName;
           

                        }
                    }
                    
                    if(String.isNotBlank(bk.Ad_Taker__c))
                    {
                        if(userIdMapByNetworkUsername.containsKey(bk.Ad_Taker__c.toUpperCase()))
                        {
                            user u = new user();
                            u = userIdMapByNetworkUsername.get(bk.Ad_Taker__c.toUpperCase());
                            
                            // find user id according to network username, then assign to lookup field Sales_Order_Ad_Taker__c on booking
                            bk.Sales_Order_Ad_Taker__c = u.Id;
                        }
                        else
                        {
                            // if system couldn't find user id by network username,
                            // system have to go to custom setting. 
                            // in system parameter, find 'Default sales rep' entry and get user Id
                            bk.Sales_Order_Ad_Taker__c = defaultSalesRepId;
                        }
                    }
                    bookingListForLogging.add(bk);
                }
            } catch(Exception ex){
                ExLog.log(ex, 'config', bookingListForLogging, 'SFE-824 Update Booking records in before trigger context');
            }
        }
        
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
        {
            Map<Id, Booking__c> validBookingIdMap = new Map<Id, Booking__c>();
            
            /**
            * SFE-343 - Booking number not populating on the case
            **/ 
            Map<Id,Id> salesOrdersAndBookings=new Map<Id,Id>();
            /**End Update LMancilla**/         
            
            for (Booking__c bk : trigger.new) 
            {
                // after sales order owner has been populated on booking
                // only choose booking with valid sale order owner
                // update: only validate sales order owner and ad taker when they are updated
                if(String.isNotBlank(bk.Sales_Order_Owner__c) || String.isNotBlank(bk.Sales_Order_Ad_Taker__c))
                {
                    // modified by Tim Fabros 10 / 10 / 2014 - SFE-343
                    // added extra condition to check if source is from adpoint
                    // BEGIN:
                    if(trigger.isInsert || bk.Source_System__c == 'AdPoint')
                    // END:
                    {
                        if(bk.Sales_Order__c!=null) 
                            validBookingIdMap.put(bk.Sales_Order__c, bk);
                        
                        /**
                        * SFE-343 - Booking number not populating on the case
                        **/
                        if(bk.Sales_Order__c!=null)             
                            salesOrdersAndBookings.put(bk.Id,bk.Sales_Order__c);
                        /**End Update LMancilla**/                    
                    }
                    // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
                        // Added extra condition check as to process booking having old Sales Owner as null                    
                    else if((String.isBlank(trigger.oldMap.get(bk.Id).Sales_Order_Owner__c))
                    || (String.isBlank(trigger.oldMap.get(bk.Id).Sales_Order_Ad_Taker__c))
                    || (String.isNotBlank(trigger.oldMap.get(bk.Id).Sales_Order_Owner__c) 
                               && trigger.oldMap.get(bk.Id).Sales_Order_Owner__c != bk.Sales_Order_Owner__c)
                       || (String.isNotBlank(trigger.oldMap.get(bk.Id).Sales_Order_Ad_Taker__c) 
                               && trigger.oldMap.get(bk.Id).Sales_Order_Ad_Taker__c != bk.Sales_Order_Ad_Taker__c))
                    {
                        if(bk.Sales_Order__c!=null) 
                            validBookingIdMap.put(bk.Sales_Order__c, bk);
                    }
                }
            }
            
            /**
            * SFE-343 - Booking number not populating on the case
            **/ 
            System.debug('@BookingManagement salesOrdersAndBookings.values(): ' + salesOrdersAndBookings.values());
            if (salesOrdersAndBookings.values().size() > 0) {
                List<Case> casesToUpdate = new List<Case>();
                casesToUpdate=[SELECT Id,Sales_Order__c,Booking__c FROM Case WHERE Booking__c=NULL AND Sales_Order__c IN:salesOrdersAndBookings.values()];
                
                System.debug('@BookingManagement casesToUpdate: ' + casesToUpdate);
                if (casesToUpdate.size() > 0) {
                    for (Id bkId : salesOrdersAndBookings.keySet()) {
                        for (Case c : casesToUpdate) {
                            if (salesOrdersAndBookings.get(bkId) == c.Sales_Order__c) {
                                c.Booking__c = bkId;
                            }
                        }
                    }
                    
                    // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to catch any exceptions on DML
                    try{
                        update casesToUpdate;
                    } catch(Exception ex){
                        ExLog.log(ex, 'config', casesToUpdate, 'SFE-824 Update Booking Nunber on Case');
                    }
                }
            }
            /**End Update LMancilla**/   
            
            // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
                // Updated method definition to pass map of booking instead of set of id. 
            system.debug('====validBookingIdMap=== ' + validBookingIdMap);
            
            // update owner of booking's sales order
            if(validBookingIdMap.size() > 0)
            {
               BookingManagement_Trigger_Helper.updateSalesOrderOwnerAndAdTaker(validBookingIdMap);
            }

            // added by Tim Fabros 27 / 08 / 2014 - SFE-581
            // roll up custom fields to account for reporting purposes
            // BEGIN:
            List<Account> updatedAccounts = new List<Account>();
            Set<Booking__c> bookingSet = new Set<Booking__c>();
            Map<String, String> accountIdByBookingId = new Map<String, String>();
            Map<String, Account> accountByAccountId = new Map<String, Account>();

            for (Booking__c booking : trigger.new)
            {
                if (trigger.oldMap != null && trigger.oldMap.containsKey(booking.Id) && 
                        (trigger.oldMap.get(booking.Id).Last_Expiry_Appearance__c != booking.Last_Expiry_Appearance__c
                        || trigger.oldMap.get(booking.Id).Line_Item_Publication_Divisions_mpl__c != booking.Line_Item_Publication_Divisions_mpl__c))
                {
                    accountIdByBookingId.put(booking.Id, booking.Advertiser_Account__c);
                }
            }

            string lstBookingClassification ='';
            string lstBookingLineItemPublicationDivs ='';
            
            for (Account account : [SELECT Last_Booking_Classification__c, Last_Booking_Division__c, 
                                           Last_Booking_Last_Expiry_Appearance__c, Last_Booking_Line_Item_Classifications__c,
                                           Last_Booking_Run_Schedule__c, Last_Booking_Number__c, Last_Booking_Value__c, Last_Booking_Line_Item_Publication_Divs__c
                                    FROM   Account
                                    WHERE  Id IN: accountIdByBookingId.values()])
            {
                for (Booking__c booking : trigger.new)
                {
                    if (accountIdByBookingId.containsKey(booking.Id))
                    {
                        if (accountIdByBookingId.get(booking.Id) == account.Id)
                        {
                            if (accountByAccountId.containsKey(account.Id))
                            {
                                if ((accountByAccountId.get(account.Id).Last_Booking_Last_Expiry_Appearance__c != null && booking.Last_Expiry_Appearance__c != null) &&
                                    (booking.Last_Expiry_Appearance__c > accountByAccountId.get(account.Id).Last_Booking_Last_Expiry_Appearance__c ||
                                    (booking.Last_Expiry_Appearance__c == accountByAccountId.get(account.Id).Last_Booking_Last_Expiry_Appearance__c &&
                                    Integer.valueOf(booking.Name) > Integer.valueOf(account.Last_Booking_Number__c))))
                                {
                                   
                                    account.Last_Booking_Classification__c            = BookingManagement_Trigger_Helper.subStringByCharacterLength(booking.CyberAd_Classification__c,30); //Added for backlog#1127
                                    account.Last_Booking_Division__c                  = booking.CyberAd_Division__c;
                                    account.Last_Booking_Last_Expiry_Appearance__c    = booking.Last_Expiry_Appearance__c;
                                    account.Last_Booking_Line_Item_Classifications__c = booking.Line_Item_Classifications__c;
                                    account.Last_Booking_Run_Schedule__c              = booking.Run_Schedule__c;
                                    account.Last_Booking_Number__c                    = booking.Name;
                                    // UserStory16.3 - Update Account.Last_Booking_Value just like account.Last_Booking_Number
                                    account.Last_Booking_Value__c                     = booking.Line_Item_Gross_Price__c;
                                    // AdSales 271 - Update Account.Last_Booking_Line_Item_Publication_Divs__c just like account.Last_Booking_Value__c
                                    account.Last_Booking_Line_Item_Publication_Divs__c= BookingManagement_Trigger_Helper.subStringByCharacterLength(booking.Line_Item_Publication_Divisions_mpl__c,255); //Added for backlog#1127

                                    accountByAccountId.put(account.Id, account);
                                }
                            }
                            else
                            {  
                                account.Last_Booking_Classification__c            = BookingManagement_Trigger_Helper.subStringByCharacterLength(booking.CyberAd_Classification__c,30); //Added for backlog#1127
                                account.Last_Booking_Division__c                  = booking.CyberAd_Division__c;
                                account.Last_Booking_Last_Expiry_Appearance__c    = booking.Last_Expiry_Appearance__c;
                                account.Last_Booking_Line_Item_Classifications__c = booking.Line_Item_Classifications__c;
                                account.Last_Booking_Run_Schedule__c              = booking.Run_Schedule__c;
                                account.Last_Booking_Number__c                    = booking.Name;
                                // UserStory16.3 - Update Account.Last_Booking_Value just like account.Last_Booking_Number
                                account.Last_Booking_Value__c                     = booking.Line_Item_Gross_Price__c;
                                // AdSales 271 - Update Account.Last_Booking_Line_Item_Publication_Divs__c just like account.Last_Booking_Value__c
                                account.Last_Booking_Line_Item_Publication_Divs__c= BookingManagement_Trigger_Helper.subStringByCharacterLength(booking.Line_Item_Publication_Divisions_mpl__c,255); //Added for backlog#1127

                                accountByAccountId.put(account.Id, account);
                            }
                        }
                    }
                }
            }

            if (!accountByAccountId.isEmpty())
            {
                // 2016-02-25 atul.gupta@bluewolfgroup.com - SFE-824 Exception Log framework method added to catch any exceptions on DML
                try{
                    update accountByAccountId.values();
                } catch(Exception ex){
                    ExLog.log(ex, 'config', accountByAccountId.values(), 'SFE-824 Update Account values from Booking');
                }
            }
            // END:


                //CdS 24/08/15 - JIRA-714
                BookingManagement_Trigger_Helper.updateOpportunityStageName(trigger.newMap, trigger.oldMap);
            
        }
        
        // every time booking gets updated, we have to check whether booking quote/confirmation can be sent out
        
        //if(trigger.isBefore && trigger.isUpdate)
        if(trigger.isAfter && trigger.isUpdate)
        {
            List<Booking__c> emailToSentBookings = new List<Booking__c>();      
            List<Booking__c> faxToSentBookings = new List<Booking__c>();
            Map<Id, List<Booking__c>> missingAdProofBookingsByUserId = new Map<Id, List<Booking__c>>();

            // get adProof document object prefix
            String adProofDocumentPrefix = Schema.getGlobalDescribe().get('Document').getDescribe().getKeyPrefix();
           
            for(Booking__c b : trigger.new)
            {

                if(b.Send_Channel__c != null
                    && trigger.oldMap.get(b.Id).Quote_or_Confirmation_Flag_Send_Date__c == b.Quote_or_Confirmation_Flag_Send_Date__c)
                {
                    // firstly, check if adProof document exists if adProof is required
                    // even Ad_Proof_Document__c field contains value, we still need to check if it is valid document id
                    if(b.AdProof_Required__c && 
                        (String.isBlank(b.Ad_Proof_Document__c) || b.Ad_Proof_Document__c.subString(0,3) != adProofDocumentPrefix))
                    {
     
                        if(!b.Quote_Confirmation_waiting_msg_sent__c)
                        {
                            // send error message to Quote or Confirmation User via email 
                            // if adProof document doesn't exist.
                            if(!missingAdProofBookingsByUserId.containsKey(b.Quote_or_Confirmation_User__c))
                            {
                                missingAdProofBookingsByUserId.put(b.Quote_or_Confirmation_User__c, new List<Booking__c>());
                            }
                            
                            missingAdProofBookingsByUserId.get(b.Quote_or_Confirmation_User__c).add(b);
                        }
                    }
                    else
                    {

    system.debug('*********************:'+b.Quote_or_Confirmation_Sent_Date__c);
                        if(b.Quote_or_Confirmation_Sent_Date__c == null)
                        {
    system.debug('*********************:456');
                            // In the case of Quote, email will be sent out when send email or send fax is checked
                            // else, if in the case of confirmation, in order to send email, not only send email or send fax has to be ticked,
                            // we also need to wait until all booking line items being written back from webMethods (check field 'Integeration Date' on booking)
                            if(b.Quote_Confirmation__c == 'Quote' || (b.Quote_Confirmation__c == 'Confirmation' && b.Integration_Date__c != null))
                            {

                                system.debug('*********************:789');
                                if(b.Send_Channel__c == 'Email')
                                    emailToSentBookings.add(b);
                                else if(b.Send_Channel__c == 'Fax')
                                    faxToSentBookings.add(b);
                                    system.debug('b.fax_content__c:'+b.fax_content__c);
                            }
                            
                        }
                    }   
                }
            }
            
            
            
            if(emailToSentBookings.size() > 0)
            {
                system.debug('@send email To Users');

                BookingManagement_Trigger_Helper.sendBookingQuoteConfirmationEmail(emailToSentBookings);
            }

            if(faxToSentBookings.size() > 0)
            {
                system.debug('@send fax To Users');
                BookingManagement_Trigger_Helper.sendBookingQuoteConfirmationFax(faxToSentBookings);
            }        
            
            system.debug('@BookingManagement missingAdProofBookingsByUserId: ' + missingAdProofBookingsByUserId);
            
            // send exception message to quote/confirmation users 
            set<Id> missingBookingIdSet = new set<Id>();
            if(missingAdProofBookingsByUserId.size() > 0)
            {
                String subject = 'Ad Proof will be sent';
                
                Map<String, String> messagesByEmail = new Map<String, String>();
                
                for(User u : [Select u.FirstName, u.LastName, u.Email 
                              From User u 
                              Where u.Id IN: missingAdProofBookingsByUserId.keySet()])  
                {
                    for(Booking__c booking : missingAdProofBookingsByUserId.get(u.Id))
                    {
                        String msg = '';
                        
                        if(!messagesByEmail.containsKey(u.Email))
                        {
                            msg = 'Dear ' + u.FirstName + ' ' + u.LastName + '<br />'
                                + 'You have requested to send an Ad Proof to ' + booking.Placer_Contact_Name__c + ' from '  + booking.Placer_Name__c + ' for ad number ' + booking.name +'.<br />'
                                + 'This will be automatically sent, once the Ad Proof PDF is ready and the booking line items have returned to Salesforce from the billing system. This process may take up to 15 minutes.';
                        }
                        else
                        {
                            msg = messagesByEmail.get(u.Email);
                        }
                        
                        msg += '<br />' + booking.Name;
                        
                        messagesByEmail.put(u.Email, msg);
                        missingBookingIdSet.add(booking.id);
                    }
                }
               
                system.debug('@send waiting Message To Users');
                Global_Helper.sendMessageToUsers(subject, messagesByEmail);
                BookingManagement_Trigger_Helper.updateBookingWaitingMessageSentFlag(missingBookingIdSet);
            }
        }
    }
}