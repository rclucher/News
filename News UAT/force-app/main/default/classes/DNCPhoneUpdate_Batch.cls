/*---------------------------------------------------------
 * Author:  Mathanan Yogaratnam
 * Description:
 * this class extracts the phone numbers from Leads and Contacts that are members of active campaigns
 * and loads checks them against the DNC register. If the phone numbers are found in the DNC register with the status
 * 'Unregistered' or 'Do Not Call' then the relevant Lead and Contact records are updated to reflect the latest status.
 * This class may be triggered by a timed schedule event or manually by the user wishing to 'wash' the campaign members
 * Company: Salesforce.com
 * Date: 23/08/2013
 * History:
 * 23/08/2013   Mathanan Yogaratnam       Created
 * 24/09/2013   Bohao Chen                Created
 
 ---------------------------------------------------------*/
global class DNCPhoneUpdate_Batch implements Database.Batchable<sObject>
{

    global String query;
    global final List<String> CAMPAIGN_STATUS = DNCPhone_Helper.CAMPAIGN_STATUS;

    global DNCPhoneUpdate_Batch(String q)
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

        DNCPhone_Helper.updateWashedPhones(scope);
    }

    global void finish(Database.BatchableContext BC)
    {
        System.debug('Finish Step: DNC Records Updated');
    }
}