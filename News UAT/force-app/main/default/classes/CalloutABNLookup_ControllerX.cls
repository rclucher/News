/************************************************************************
 * Class CalloutABNLookup_Controller
 * Description: controller dor CalloutABNLookup visualforce page
 * Company: Salesforce.com
 * Date: 24/05/2013
 * History:
 * 24/05/2013   Celso de Souza   Created
 * 12/06/2013   Bohao Chen       Updated
 * 20/11/2017   Paul Kang        Updated -- Added the Constructor for Id and @AuraEnabled ValidateABN for lightning Quick Action
/************************************************************************/
public without sharing class CalloutABNLookup_ControllerX {

    @TestVisible private Account acct;
    private ApexPages.StandardController controller;
    private ABNLookupStub.AustralianBusinessNumber abnResponse;
    
    public  String mode { get; set; }
    public  ABNLookupStub.AustralianBusinessNumber abn {get{return abnResponse;}}


    public CalloutABNLookup_ControllerX(Id acctId) {
        if (acctId != null) {
            System.debug('@acctId passed: ' + (String)acctId);
            this.acct = [Select Id, AccountNumber, ABN_Status__c, Registered_Name__c,ABN_Validation__c FROM Account WHERE Id =:acctId];
            System.debug('this.acct is ' + this.acct);
        }
    }
    
    // constructor
    public CalloutABNLookup_ControllerX(ApexPages.StandardController controller) 
    {
    	if(!Test.isRunningTest())
            controller.addFields(new String[]{'AccountNumber'});    
        this.controller = controller;
        this.acct = (Account) controller.getRecord();
    }


    /*
    *   ValidateABN from client controller CalloutABNLookupController.js
    *
    */
    @AuraEnabled
    public static Account ValidateABN(Id acctId) {
        CalloutABNLookup_ControllerX ctrl = new CalloutABNLookup_ControllerX(acctId);
        Account acct;

        System.debug('@Account passed: ' + ctrl.acct);
        if(String.isNotBlank(ctrl.acct.AccountNumber))
        {
            if(ctrl.isAbnValid())
            {
                ctrl.doABNLookup();
            }
            else
            {
                ctrl.acct.Registered_Name__c = null;
                ctrl.acct.ABN_Status__c = 'Invalid ABN Number';
            }
            
            ctrl.acct.ABN_Validation__c = Date.today();
            
            update ctrl.acct;
            acct = ctrl.acct;
        }
        return acct;
    }

    // validate function to be called from VF page
    // it calls isAbnValid and doABNLookup methods
    public PageReference validateAbn()
    {
    	if(String.isNotBlank(this.acct.AccountNumber))
        {
	    	if(isAbnValid())
	    	{
	    		this.doABNLookup();
	    	}
	    	else
	    	{
	    		this.acct.Registered_Name__c = null;
	            this.acct.ABN_Status__c = 'Invalid ABN Number';
	    	}
	    	
	        this.acct.ABN_Validation__c = Date.today();
	    	
	        update this.acct;
        }
        
        PageReference acctPage = new PageReference('/' + this.acct.Id); 
        System.debug('getURL ' + acctPage.getUrl());
        acctPage.setRedirect(true);
        return acctPage;
    }
    
    // Updated by Bohao Chen on 13/May/2014 for JIRA SFE-242
    // using try catch to display any callout exception error messages
    // web service call to retrieve ABN information
    private void doABNLookup()
    {
        try
        {
            System.debug('this.acct.AccountNumber' + this.acct.AccountNumber);
            abnResponse = ABNLookupStub.ABRSearchByABN(this.acct.AccountNumber);

            if(abnResponse.isInvalid!=null && abnResponse.isInvalid)
            {
                this.acct.Registered_Name__c = null;
                this.acct.ABN_Status__c = 'ABN Not Found ';
            }
            else
            {
                this.acct.Registered_Name__c = abnResponse.name;
                this.acct.ABN_Status__c = abnResponse.Status;
            }
        }
        catch (Exception e)
        {
            System.debug('@doABNLookup exception: ' + e.getMessage());
            this.acct.Registered_Name__c = null;
            this.acct.ABN_Status__c = e.getMessage();
        }
    }
    
    // check sum to make sure ABN is valid number before sending out web service request
    private Boolean isAbnValid()
    {
        String cleanAbn = this.acct.AccountNumber.replace(' ','');
        
        List<String> cleanAbnList = cleanAbn.split('');
   
        List<String> weighting = new String[]{'', '10','1','3','5','7','9','11','13','15','17','19'};
	        
        Integer tally = (Integer.valueOf(cleanAbnList[1]) - 1) * Integer.valueOf(weighting[1]);
	        
        for (Integer i = 2; i < cleanAbnList.size(); i++)
        {
            tally += (Integer.valueOf(cleanAbnList[i]) * Integer.valueOf(weighting[i]));
        }
        
        if(Math.mod(tally, 89) == 0)
        	return true;
        else
        	return false;
    }
}