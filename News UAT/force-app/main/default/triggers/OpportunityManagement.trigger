/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This trigger is for requirement R-0627:
 *              Ability to copy the revenue for the opportunity and opportunity product line at time 
 *              of opportunity closure (won or lost)
 * // TODO: description
 * History:
 * 13/06/2013  Bohao Chen  Created
 * 25/09/2013  Bohao Chen  Updated
 * 24/04/2016  David Dawson Added Sales Summary functionality
 * 15/08/2016  Peter Charalambous - Removed Revenue Reporting functions as per Revenue Reporting R1.2 Solution
 * 15/11/2017  Paul Kang - Commented out the call for creditcheck, this has been replaced with workflow
 * 16/03/2018  Pratyush Chalasani (Ativa) - Insert OpportunityContactRole for Contact__c on update, if one does not already exist (Item-01148)
 * 13/04/2018  Pratyush Chalasani (Ativa) - Copy Industry Code and Revenue group from Account, display error if null (Item-01302, Item-01334)
 * 01/11/2018  Mohsin Ali (Ativa) - Adding the recursive trigger check to ensure that the trigger doesn't run multiple times. This was done to cater the Downstream Processes (NR-730 & NR-750)
 ---------------------------------------------------------*/
trigger OpportunityManagement on Opportunity (after update, before update, before insert, before delete
        , after insert, after undelete) // updated by Bohao Chen on 6/6/2014 for JIRA SFE-498
{
    /*
    if(Trigger.isBefore && Trigger.isUpdate){
        if(News_TriggerHelper.OpportunityManagement_Before_Update_Executing){
            return;
        }else{
            News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
        }
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        if(News_TriggerHelper.OpportunityManagement_After_Update_Executing){
            return;
        }else{
            News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;
        }
    }
    */
    // Cloudsense Release 3
    // START

    CS_TriggerHandler.execute(new CS_OpportunityTriggerDelegate());

    // Cloudsense Release 3
    // END

    System.debug('PC: Opportunity trigger');

    if (Global_Helper.canTrigger( 'OpportunityManagement' ) ) {
        if (Trigger.isBefore && Trigger.isInsert) {
            //Pratyush Chalasani - 13/04/2018
            //Item-01302: auto populating industry field in Opportunity
            //Item-01334: Revenue Group to default from Account Revenue Group

            Map<String,Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

            Set<Id> enforcedRecordTypes = new Set<Id>();

            for (Enforce_Revenue_Group__mdt erg: [SELECT Label FROM Enforce_Revenue_Group__mdt]) {
                enforcedRecordTypes.add(rtMap.get(erg.Label).getRecordTypeId());
            }

            Set<Id> accountIDs = new Set<Id>();

            for (Opportunity opp: Trigger.NEW) if (opp.AccountId != null) accountIDs.add(opp.AccountId);

            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, IsPersonAccount, Industry_Code__c, Revenue_Group__c FROM Account WHERE Id IN :accountIDs]);

            for (Opportunity opp: Trigger.new) {
                Account acc = accountMap.get(opp.AccountId);

                if ((acc != null) && (acc.IsPersonAccount == false)) {
                    if (opp.Industry_Code__c == null) opp.Industry_Code__c = acc.Industry_Code__c;
                    if (opp.Revenue_Group__c == null) opp.Revenue_Group__c = acc.Revenue_Group__c;
                }

                // Only enforce a required revenue group for the specified Opportunity record types.
                // Temporarily disable this for unit tests, until the test data creation can be updated.
                if (!Test.isRunningTest() && enforcedRecordTypes.contains(opp.RecordTypeId) && (opp.Revenue_Group__c == null) && String.isblank(opp.Lead_Conversion__c)) {
                    opp.addError('Revenue Group must be selected (could not copy from Account)');
                }
            }
        }

        // If this is a new opportunity or if the stage has changed, then record the current date in the Stage Changed field.
        // This is used by the Days in Stage formula to determine how long an opportunity has been in a certain stage.
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            for (Opportunity opp: Trigger.new) {
                Opportunity old = (Trigger.oldMap != null) ? Trigger.oldMap.get(opp.Id) : null;

                if ((old == null) || (opp.StageName != old.StageName)) opp.Stage_Changed__c = System.Today();
            }
        }

        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            // Pratyush Chalasani - 16/03/2018 - Item-0114

            // Start by building up a set of all Contact IDs for the Opportunity records being updated
            Set<Id> contactIDs = new Set<Id>();
            for (Opportunity opp: Trigger.new) if (opp.Contact__c != null) contactIDs.add(opp.Contact__c);

            // Mapping of opportunity to set of contacts which they're related to
            Map<Id, Set<OpportunityContactRole>> oppRoleMap = new Map<Id, Set<OpportunityContactRole>>();

            // Get all existing OpportunityContactRole records for the Opportunity records being updated
            // and Contact records which they're currently assigned to (this is to narrow down the number of records which we query)
            // , and populate the above map.
            for (OpportunityContactRole role: [SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE (OpportunityId IN :Trigger.new) AND (ContactId IN :contactIDs)]) {
                Set<OpportunityContactRole> roles = oppRoleMap.get(role.OpportunityId);

                if (roles == null) roles = new Set<OpportunityContactRole>();

                roles.add(role);

                oppRoleMap.put(role.OpportunityId, roles);
            }

            // The new roles to insert
            List<OpportunityContactRole> newOppContactRoles = new List<OpportunityContactRole>();

            // Existing roles to make primary
            List<OpportunityContactRole> updateOppContactRoles = new List<OpportunityContactRole>();

            for (Opportunity opp: Trigger.new) {
                Set<OpportunityContactRole> roles = oppRoleMap.get(opp.Id);

                // For every Opportunity that has a Contact check if there's an existing relationship
                // in the OpportunityContactRole table
                if (opp.Contact__c != null) {
                    OpportunityContactRole existing = null;

                    if (roles != null) {
                        for (OpportunityContactRole role: roles) {
                            if (role.ContactId == opp.Contact__c) {
                                existing = role;
                                break;
                            }
                        }
                    }

                    if (existing == null) {
                        newOppContactRoles.add(new OpportunityContactRole(OpportunityId = opp.Id, ContactId = opp.Contact__c, IsPrimary = true, Role = 'Decision Maker'));
                    } else {
                        existing.IsPrimary = true;
                        updateOppContactRoles.add(existing);
                    }
                }
            }

            if (!newOppContactRoles.isEmpty()) insert newOppContactRoles;
            if (!updateOppContactRoles.isEmpty()) update updateOppContactRoles;

            // End - Item-0114
        }

        if(trigger.isUpdate && trigger.isAfter)
        {
            if (Trigger.size > 0) {
                CSPOFA.Events.emit('update', Trigger.newMap.keySet());
            }
            Set<Id> revenueCopiedOpportunityList = new Set<Id>();
            Set<Id> revenueUncopiedOpportunityList = new Set<Id>();

            for(String oId : trigger.newMap.keySet())
            {
                String currentStage = trigger.newMap.get(oId).StageName;
                String prevStage = trigger.oldMap.get(oId).StageName;

                if(currentStage != prevStage)
                {
                    if(currentStage.contains('Closed'))
                        revenueCopiedOpportunityList.add(trigger.newMap.get(oId).Id);
                    else
                            revenueUncopiedOpportunityList.add(trigger.newMap.get(oId).Id);
                }

            }

            OpportunityLineItem_Helper.updateOpportunityLineItemRevenueAtClose(revenueCopiedOpportunityList, revenueUncopiedOpportunityList);
        }

        /********* Start: his block is to copy opportunity to customer revenue schedule*******/
        if(trigger.isUpdate && trigger.isBefore)
        {
            List<Opportunity> agreeNegOpportunity = new List<Opportunity>();
            List<Opportunity> nonAgreeNegOpportunity = new List<Opportunity>();

            for(Opportunity oppty : trigger.new)
            {
                if(
                        //oppty.Opportunity_Type__c != 'Agreement Negotiation'
                        //oppty.RecordTypeId != Global_Helper.getRecordTypeIdByName('Agreement Negotiation', 'Opportunity') &&
                        (CustomRevenueSchedule_Helper.hasChanged('Opportunity', trigger.oldMap.get(oppty.Id), oppty) ||
                                trigger.oldMap.get(oppty.Id).RecordTypeId != trigger.newMap.get(oppty.Id).RecordTypeId)
                        )
                {
                    oppty.Last_Modified_Datetime__c = datetime.now();
                }

                // if opportunity type change from other to 'Agreement Negatiation', we need to find matched CRSs and delete them
                /*if(oppty.Opportunity_Type__c == 'Agreement Negotiation' 
                   && trigger.newMap.get(oppty.Id).Opportunity_Type__c != trigger.oldMap.get(oppty.Id).Opportunity_Type__c)
                {
                    agreeNegOpportunity.add(oppty);
                }
                
                if(oppty.Opportunity_Type__c != 'Agreement Negotiation' 
                    &&  trigger.oldMap.get(oppty.Id).Opportunity_Type__c == 'Agreement Negotiation'
                    && trigger.newMap.get(oppty.Id).Opportunity_Type__c != trigger.oldMap.get(oppty.Id).Opportunity_Type__c)
                {
                    nonAgreeNegOpportunity.add(oppty);
                }*/
                //replacing Process Builder - Opportunity: Update Close Date upon Close AB 08-11-2018
                if (trigger.oldMap.get(oppty.Id).isClosed != oppty.isClosed && oppty.isClosed) {
                    //Opp is just getting closed so set the close date
                    oppty.CloseDate = Date.today();
                }
            }

            if(agreeNegOpportunity.size() > 0)
            {
                CustomRevenueSchedule_Helper.deleteCrsByOpportunity(agreeNegOpportunity);
            }

            if(nonAgreeNegOpportunity.size() > 0)
            {
                List<OpportunityLineItem> opptyLineItems = [Select o.PricebookEntry.Product2Id, o.Opportunity.AccountId, o.OpportunityId, o.Sales_Order__c,
                        o.TotalPrice, o.ServiceDate
                From OpportunityLineItem o
                Where o.Opportunity.Owner.IsActive = true
                And o.OpportunityId IN: nonAgreeNegOpportunity];

                CustomRevenueSchedule_Helper.processCrsOpportunityLineItems(opptyLineItems);
            }
        }

        if(trigger.isInsert && trigger.isBefore)
        {
            for(Opportunity oppty : trigger.new)
            {
                oppty.Last_Modified_Datetime__c = datetime.now();

                // Todo: this is potential solution for JIRA SFE-498
                system.debug('@OpportunityManagement Case Origin Id: ' + oppty.Case_Origin_Id__c);
            }
        }

        if(trigger.isDelete && trigger.isBefore)
        {
            CustomRevenueSchedule_Helper.deleteCrsByOpportunity(trigger.old);
        }

        // updated by Bohao Chen on 6/6/2014 for JIRA SFE-498
        // Begin
        Map<Id, List<Id>> opportunityIdsByCaseId = new Map<Id, List<Id>>();

        if(trigger.isAfter && trigger.isInsert)
        {
            for(Opportunity o : trigger.new)
            {
                if(String.isNotBlank(o.Case_Origin_Id__c) && o.Case_Origin_Id__c.substring(0, 3) == '500')
                {
                    if(!opportunityIdsByCaseId.containsKey(o.Case_Origin_Id__c))
                    {
                        opportunityIdsByCaseId.put(o.Case_Origin_Id__c, new List<Id>());
                    }
                    opportunityIdsByCaseId.get(o.Case_Origin_Id__c).add(o.Id);
                }
            }
        }

        // added by Tim Fabros 14 / 08 / 2014 - SFE-612
        // BEGIN:
        if (trigger.isUpdate && trigger.isAfter)
        {
            Map<Id, List<OpportunityLineItem>> opportunityLineItemListByOpportunity = new Map<Id, List<OpportunityLineItem>>();
            List<OpportunityLineItem> updatedOpportunityLineItems = new List<OpportunityLineItem>();
            Set<Id> opportunityIds = new Set<Id>();

            for (Opportunity o : trigger.new)
            {
                // check if the probability or the owner has changed.
                if(o.Probability != trigger.oldMap.get(o.Id).Probability || o.OwnerId != trigger.oldMap.get(o.Id).OwnerId)
                    opportunityIds.add(o.Id);
            }
            if (!opportunityIds.isEmpty()) {
                for (OpportunityLineItem oli : [SELECT Opportunity_Probablity__c, Opportunity_Owner__c, OpportunityId
                FROM OpportunityLineItem
                WHERE OpportunityId IN: opportunityIds])
                {
                    if (!opportunityLineItemListByOpportunity.containsKey(oli.OpportunityId))
                        opportunityLineItemListByOpportunity.put(oli.OpportunityId, new List<OpportunityLineItem>());

                    opportunityLineItemListByOpportunity.get(oli.OpportunityId).add(oli);
                }

                for (Opportunity o : trigger.new)
                {
                    if (opportunityLineItemListByOpportunity.containsKey(o.Id))
                    {
                        for (OpportunityLineItem oli : opportunityLineItemListByOpportunity.get(o.Id))
                        {
                            oli.Opportunity_Probablity__c   = o.Probability;
                            oli.Opportunity_Owner__c        = o.OwnerId;

                            updatedOpportunityLineItems.add(oli);
                        }
                    }
                }
            }

            try{
                if (!updatedOpportunityLineItems.isEmpty()) {
                    update updatedOpportunityLineItems;
                }
            }
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', updatedOpportunityLineItems, 'SFE-824 Investigation');
            }
        }
        // END:

        Opportunity_Helper.populateCaseWithOpportunityId(opportunityIdsByCaseId);
        // End

        /********* End: this block is to copy opportunity to customer revenue schedule*******/
    }

    //if the status has changed, run a dummy update on the Opportunity Product record to fire the rollup utility
    if(Trigger.isUpdate && Trigger.isBefore){
        Set<Id> opIds = new Set<Id>();
        for(Opportunity o :Trigger.NEW){
            if(o.StageName != Trigger.oldMap.get(o.Id).StageName){
                opIds.add(o.Id);
            }
        }
        if(!opIds.isEmpty()){
            Opportunity_Helper.rollupTriggerOpportunityLineItem(opIds);
        }
    }


/*
    // added by Tim Fabros 2017-10-20
    if (trigger.isBefore) {

        if (trigger.isInsert) {
            Opportunity_Helper.createCreditCheckCase(trigger.new);
        }
    }
*/

    /*
     * 03-11-2018: Mohsin Ali (Ativa): Fixing test classes failures by changing the flags back to false after the execution of Trigger.
     * The original modification to check the flag if the trigger is running was done by Kevin from Cloud Sense on 01-11-2018
    */
    //News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    //News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;
}