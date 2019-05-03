/*---------------------------------------------------------
 * Author:  Mathanan Yogaratnam
 * Description: 
 * This class extracts the phone numbers from Leads and Contacts that are members of active campaigns and
 * loads them into the DNC Wash Register object. This class may be triggered by a timed schedule event 
 * or manually by the user wishing to 'wash' the campaign members
 * Company: Salesforce.com
 * Date: 23/08/2013
 * History:
 * 23/08/2013   Mathanan Yogaratnam       Created
 * 23/09/2013   Bohao Chen                Updated
 ---------------------------------------------------------*/
global class DNCPhoneExtract implements Database.Batchable<sObject>{

	global final String query;
	global Integer insertedCount = 0;
    global final List<String> CAMPAIGN_STATUS = DNCPhone_Helper.CAMPAIGN_STATUS;
    
    global DNCPhoneExtract(String q)
    {
    	this.query = q;
    }
    
	global Database.querylocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<CampaignMember> scope)
	{
		System.debug(Logginglevel.DEBUG, '*****************     Starting Batch Execution ****************');
        DNCPhone_Helper.extractPhonesFromCampaignMembers(scope, false);
	}
	
	global void finish(Database.BatchableContext BC)
	{
		System.debug('Finish Step: DNC Records extracted');
		        
        //Commence the cleanup job (get custom settings for scope size first) 
		//Get the scope size from custom settings
        DNCPhoneDelete del = new DNCPhoneDelete(DNCPhone_Helper.deleteQuery);
        ID batchprocessid = Database.executeBatch(del, DNCPhone_Helper.deleteScopeSize);


	}
	

}