// AUTHOR:     2016-05-17 Celso de Souza (Bluewolf)
// DESC:       Email routing fix due to regex too complex
global class EmailMessageRoutingFix_Batch implements Database.Batchable<sObject>{
    
    global String query;
    global Integer addMinutes;
    global dateTime dt;
    
        global EmailMessageRoutingFix_Batch (String q, integer m){
            
            query=q;
            addMinutes = m;
            if(addMinutes!=null && addMinutes!=0)
            {
                dt = System.Now().addMinutes(addMinutes);
                query = query + ' and createdDate < :dt';
            }
        }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('@EmailMessageRoutingFix_Batch query:' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> scope){
        for(Case s : scope){
            s.Ready_for_Routing__c = true;
        }
        update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        // 2016-05-17 louis.wang@bluewolf.com - Schedule for the next batch in 5 min time, after the current batch is completed.
        system.debug('@EmailMessageRoutingFix_Batch query and addMinutes = ' + query + ' ' + addMinutes);
        
        // 2016-05-25 louis.wang@bluewolf.com - Make sure it is not scheduled in 5 min time in Test mode, 
        //                                      to avoid error 'The Apex job ... is already scheduled for execution.'
        if(!Test.isRunningTest())
        {
            system.scheduleBatch(new EmailMessageRoutingFix_Batch(query, addMinutes), 'EmailMessage Routing Patch', 5); 
        }
    }
}