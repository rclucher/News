/** 
 *
 * @author      Paul Kang 
 * @description Schedule the Batch Apex to run for Portfolio_Staging__c to Portfolio2__c and Portfolio_Owners__c
 * @description Modified 2018-02-08 Paul Kang 
 *				
 **/

global class SchedulePortfolioSync implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		PortfolioProcess b = new PortfolioProcess();
		database.executebatch(b);
	}
}