/**
* Schedule Tier calculation
**/

global class CS_BatchTierCalculationSchedule implements Schedulable {
	
	global void execute (SchedulableContext ctx) {
		Database.executeBatch(new CS_BatchTierCalculation());
	}

}