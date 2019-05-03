/**
 * Scheduler class that also acts as a batch job.
 * Used to process all unprocessed Order Requests i.e. those that failed real time processing
 * due to validation or concurrency issues (for instance Account object was locked by another process).
 * This class will collect and process all Ecommerce Order Request records that are:
 * - Created TODAY (only today's order can be processed so no point in trying to process something that must fail)
 * - Older than 1h (to ensure we do not compete with order request creation integration or real-time processing)
 * - Not already processed ()
 */
global class CS_OrderRequestReprocess_Scheduler implements Schedulable {
	//Schedulable interface implementation method
	global void execute(SchedulableContext SC) {
		//Batch size set to 1 due to limits
		APIPostRuleExecution apiPRE = new APIPostRuleExecution(null);
		Database.executeBatch(apiPRE, 1);
	}
}