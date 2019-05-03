global class CS_ResetOrchestratorPrioritySchedulable implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		
		CS_ResetOrchestratorPriority b = new CS_ResetOrchestratorPriority();

		Database.executebatch(b, 10);
	}
}