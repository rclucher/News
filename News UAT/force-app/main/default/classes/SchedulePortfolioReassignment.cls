/** 
 *
 * @author      Paul Kang 
 * @description Schedule the Batch Apex Reassign all Opened Opportunity PortfolioCode 
 * @description Modified 2018-02-08 Paul Kang 
 *				
 **/

global class SchedulePortfolioReassignment implements Schedulable {

	global void execute(SchedulableContext sc) {
		PortfolioReassignmentProcess process = new PortfolioReassignmentProcess();
		database.executebatch(process);
	}

}