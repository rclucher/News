/*---------------------------------------------------------
 * Author:  Mathanan Yogaratnam
 * Description: 
 * this class clears the records from the DNC Register Object based on the age of the 'qualified date'
 * Company: Salesforce.com
 * Date: 23/08/2013
 * History:
 * 23/08/2013   Mathanan Yogaratnam       Created
 * 23/09/2013   Bohao Chen                Updated
 ---------------------------------------------------------*/
global class DNCPhoneDelete implements Database.Batchable<sObject>
{
    global final String query;
    
    global DNCPhoneDelete(String q)
    {
        this.query = q;
    }
    
    global Database.querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<DNC_Wash_Register__c> scope)
    {
        System.debug(Logginglevel.DEBUG, '*****************     Starting Batch Execution ****************');
        DNCPhone_Helper.deleteInvalidPhones(scope);
    }

    global void finish(Database.BatchableContext BC)
    {
        System.debug(Logginglevel.DEBUG, '*****************     At finish step ****************');
    }
}