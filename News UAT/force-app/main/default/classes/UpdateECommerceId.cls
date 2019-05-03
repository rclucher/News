global class UpdateECommerceId implements Database.Batchable<sObject> {
    
    private String query;
    
    public UpdateECommerceId() {
        query = 'select Id, csb2c__E_Commerce_Customer_Id__c, AdPoint_Id__c from Account where csb2c__E_Commerce_Customer_Id__c = null and AdPoint_Id__c != null';
        system.debug(query );
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        system.debug(scope);
        UpdateAccounts ((List<Account>) scope);
    }
    
    void UpdateAccounts(List<Account> accounts) {
        for (Account acc : accounts) {
            system.debug(acc);
            acc.csb2c__E_Commerce_Customer_Id__c = acc.AdPoint_Id__c;
            system.debug(acc);
        }
        
        //update accounts;
        Database.update(accounts, false);
        system.debug(accounts);
    }

    /**
     * Does nothing
     */
    global void finish(Database.BatchableContext BC){
    }
    
    

}