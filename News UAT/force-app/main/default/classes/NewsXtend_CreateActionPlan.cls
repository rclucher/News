/**
 * @author       Bohao Chen
 * @date         2015-07-21
 * @version      1.0
 * @description  Extention class for Visualforce page NewsXtend_CreateActionPlan
 *               2015-07-23 louis.wang@bluewolf.com - updated the followings,
 *                              - Use Probability=100 rather than rely on Stage=Closed Won
 *                              - Use any 1 of the Address to validate Account (Billing, Shipping, PersonMailing, PersonOther)
 *                              - Exclude Private Party from ABN requirement
 *                              - Validate Opportunity Platform using "contains" NewsXtend rather than "equal" NewsXtend
 *               2015-08-28 louis.wang@bluewolf.com NewsXtend Phase 2
 *                              - Populate Opportunity field based on the Opportunity started
 *                              - This locks the relationship between Opportunity and ActionPlan to one to one
 */
public with sharing class NewsXtend_CreateActionPlan 
{
    public Opportunity opportunity;

    private Action_Plan__c newActionPlan;
    private Boolean hasErrorMessages;
    private List<String> errorMessages;

    /**
    * @description  This is constructor. 
    *               It calls function isOpportunityValid() to validate related fields on opportunity and set flag hasErrorMessages accordingly.
    * @param        ApexPages.StandardController        Opportunity Record
    */
    public NewsXtend_CreateActionPlan(ApexPages.StandardController controller) 
    {
        if(controller.getId() != NULL)
        {
            if(!Test.isRunningTest())
            {
                controller.addFields(this.getFields());
            }

            this.opportunity = (Opportunity)controller.getRecord();

            //System.debug('@NewsXtend_CreateActionPlan NewsXtend_CreateActionPlan this.opportunity ' + this.opportunity);

            // validate opportunity
            this.hasErrorMessages = !this.isOpportunityValid();
            //System.debug('@NewsXtend_CreateActionPlan NewsXtend_CreateActionPlan hasErrorMessages: ' + this.hasErrorMessages);

        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Opportunity id has not been provided'));
        }
    }

    /**
    * @description  This method creates a new action plan record and associates it with opportunity.
    * @param        NULL
    * @return       Id     new action plan record id
    */
    private Id createNewActionPlan()
    {
        Id newActionPlanId;

        SavePoint sp;

        try
        {
            sp = Database.setSavepoint();

            this.newActionPlan = new Action_Plan__c();
            // populate opportunity field when create ActionPlan
            this.newActionPlan.Opportunity__c = this.opportunity.Id;
            insert this.newActionPlan;

            newActionPlanId = this.newActionPlan.Id;
            this.opportunity.Action_Plan__c = newActionPlanId;
            update this.opportunity;  

        } catch(Exception e) {
            Database.rollback(sp);
            throw new CustomException(e.getMessage());
        }

        //System.debug('@NewsXtend_CreateActionPlan setNewActionPlan newActionPlanId: ' + newActionPlanId);

        return newActionPlanId;
    }

    /**
    * @description  This method redirects user to action plan page if there is no validation error.
    *               Otherwise, it shows error messages on the page.
    * @param        NULL
    * @return       PageReference     action plan page URL
    */
    public PageReference goToActionPlan()
    {
        PageReference pr;

        //System.debug('@NewsXtend_CreateActionPlan goToActionPlan errorMessages: ' + this.errorMessages);

        if(this.hasErrorMessages)
        {
            for(String msg : this.errorMessages)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
            }
        }
        else if(this.opportunity != NULL && !this.hasErrorMessages)
        {
            try
            {
                Id actionPlanId;

                if(this.opportunity.Action_Plan__c == NULL)
                {
                    actionPlanId = this.createNewActionPlan();
                }
                else
                {
                    actionPlanId = this.opportunity.Action_Plan__c;
                }
                //System.debug('@NewsXtend_CreateActionPlan goToActionPlan actionPlanId: ' + actionPlanId);

                pr = new PageReference('/' + actionPlanId);
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }

        return pr;
    }

    /**
    * @description  This method validates related fields on opportunity and assigns error message to variable errorMessages accordingly.
    * @param        NULL
    * @return       Boolean     boolean representation of valid or invalid opportunity
    */
    private Boolean isOpportunityValid()
    {
        Boolean isOpportunityValid = true;

        // validate fields on opportunity
        // set isOpportunityValid to false if it doesn't satisfy conditions
        Opportunity oppt = this.opportunity;

        if(oppt.Probability != 100 || 
            ((oppt.OpportunityGroup__c == NULL || !oppt.OpportunityGroup__c.contains('NewsXtend')) && oppt.LeadSource != 'Walk In') ||
            oppt.Contact__c == NULL ||
            String.isBlank(oppt.Contact__r.Email) ||
            (String.isBlank(oppt.Contact__r.MobilePhone) && String.isBlank(oppt.Contact__r.Phone)) ||
            oppt.AccountId == NULL ||
            ((oppt.Account.BillingStreet == NULL) && (oppt.Account.ShippingStreet == NULL) 
                && (oppt.Account.PersonMailingStreet == NULL) && (oppt.Account.PersonOtherStreet == NULL)) ||
            (!oppt.Account.IsPersonAccount && oppt.Account.AccountNumber == NULL) || 
            oppt.Payer_Account__c == NULL
            )
        {
            isOpportunityValid = false;

            this.errorMessages = new List<String>();

            if(oppt.Probability != 100) 
                this.errorMessages.add('Opportunity probability is not 100%');

            // modified by tim Fabros 2015-10-14: BR_016
            // now checks for either 'NewsXtend' selected as an opp platform (OpportunityGroup__c)
            // OR LeadSource is 'Walk In'
            if((oppt.OpportunityGroup__c==NULL || !oppt.OpportunityGroup__c.contains('NewsXtend')) && 
                (oppt.LeadSource != 'Walk In'))
                this.errorMessages.add('Opportunity platform is not \'NewsXtend\' or Lead Source is not a \'Walk In\'');

            if(oppt.Contact__c == NULL) 
                this.errorMessages.add('Opportunity doesn\'t have contact');
            if(String.isBlank(oppt.Contact__r.Email)) 
                this.errorMessages.add('Opportunity contact doesn\'t have email address');
            if(String.isBlank(oppt.Contact__r.MobilePhone) && String.isBlank(oppt.Contact__r.Phone)) 
                this.errorMessages.add('Opportunity contact doesn\'t have mobile or phone number');
            if(oppt.AccountId == NULL) 
                this.errorMessages.add('Opportunity doesn\'t have account');
            if((oppt.Account.BillingStreet == NULL) && (oppt.Account.ShippingStreet == NULL) 
                && (oppt.Account.PersonMailingStreet == NULL) && (oppt.Account.PersonOtherStreet == NULL))
                this.errorMessages.add('Opportunity account doesn\'t have address detail');
            if(!oppt.Account.IsPersonAccount && oppt.Account.AccountNumber == NULL)
                this.errorMessages.add('Opportunity account doesn\'t have ABN');
            if(oppt.Payer_Account__c == NULL)
                this.errorMessages.add('Opportunity doesn\'t have payer account');
        }

        //System.debug('@NewsXtend_CreateActionPlan isOpportunityValid errorMessages: ' + this.errorMessages);

        return isOpportunityValid;
    }

    /**
    * @description  This method validates related fields on opportunity and assigns error message to variable errorMessages accordingly.
    * @param        NULL
    * @return       List<String>    list of fields that we need from opportunity record
    */
    @testvisible private List<String> getFields()
    {
        // modified by Tim Fabros 2015-10-14
        List<String> fieldNames = new String[]{
            'Name', 'Id', 'Status__c', 'OpportunityGroup__c', 'Contact__c', 'Contact__r.Email', 'Contact__r.Phone', 'Contact__r.MobilePhone', 'Payer_Account__c',
            'Account', 'Account.ShippingStreet', 'Account.BillingStreet', 'Account.IsPersonAccount', 'Account.AccountNumber', 'Account.PersonMailingStreet',
            'Action_Plan__c', 'Probability', 'Account.PersonOtherStreet', 'LeadSource'
        };
        return fieldNames;
    }

    private class CustomException extends Exception {}


}