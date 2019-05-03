/*
 * Author: Bohao Chen
 * Description: this is schedule class to update first contact for accounts. This is one-off batch and can be deleted later. JIRA SFE-381
 * Date: 31/03/2014
 */
global class FirstContactUpdate_Scheduler implements Schedulable
{
   global void execute(SchedulableContext sc)
   {
		String query = 'Select Id From Account a Where RecordType.DeveloperName != \'Private_Party\'';
		firstContactForAccountMassUpdate b = new firstContactForAccountMassUpdate(query);
		database.executebatch(b);
   }
}