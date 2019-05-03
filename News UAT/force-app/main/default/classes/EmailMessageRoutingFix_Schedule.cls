global class EmailMessageRoutingFix_Schedule implements Schedulable
{
    // AUTHOR:     2016-05-17 Celso de Souza (Bluewolf)
    // DESC:       Email routing fix due to regex too complex
    // MOD:			2016-05-25 louis.wang@bluewolf.com - updated SOQL query so only correct Cases are selected
    //				Note - This class only needs to be scheduled once. 
    //						At the end of the batch, a new job will be auto scheduled in 5 min time.
    global void execute(SchedulableContext scMain) 
    {
        // updated query (applied to Production via execute anonymous on 2016-05-18)
		String q = 'SELECT Id, Ready_for_Routing__c FROM Case '
		+ 'WHERE Id IN '
		+ '(SELECT ParentId FROM EmailMessage '
		+ 'WHERE Parent.Origin=\'Email - Inbound for Routing\'  '
		+ 'AND Parent.Ready_for_routing__c=false ' 
		+ 'AND Parent.Status IN (\'Open\', \'Re-Opened\') ' 
		+ 'AND Incoming=true ' 
		+ 'AND CreatedDate=LAST_N_DAYS:7) ' 
		+ 'AND Owner.Name!=\'Integrator\' ' 
		+ 'ORDER BY CreatedDate DESC ';

		// set delay from 2 min to 0 min, as the new query can better target Cases now.
        EmailMessageRoutingFix_Batch emrf = new EmailMessageRoutingFix_Batch(q, 0);
        database.executeBatch(emrf);
    }
}