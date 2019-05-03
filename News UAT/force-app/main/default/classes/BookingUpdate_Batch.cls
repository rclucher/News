global class BookingUpdate_Batch implements Database.Batchable<sObject>
{
    // AUTHOR:     2015-09-07 Louis Wang (Bluewolf)
    // DESC:       SFE-412
    //				This batch will find all booking records that has,
    //					- blank Campaign__c 
    //					- but has a value for Sales_Order__r.Campaign__c
    //				It will then populate Campaign__c from Sales_Order
    //				This batch will be scheduled to execute regularly, 
    //				so such records won't exist.
	global String query;

	global BookingUpdate_Batch() 
	{
        this.query = 'SELECT Id, Campaign__c, Sales_Order__r.Campaign__c ' +
						'FROM Booking__c ' +
						'WHERE Campaign__c = null ' +
						'AND Sales_Order__r.Campaign__c != null ' +
						'ORDER BY LastModifiedDate DESC '; 
	}

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Booking__c> scope)
    {
        System.debug('@BookigUpdate_Batch ***************** Batch Execution Started ****************');
        for(Booking__c b : scope)
        {
        	b.Campaign__c = b.Sales_Order__r.Campaign__c;
        }
        update scope;
    }   
    
    global void finish(Database.BatchableContext BC)
    {
        System.debug('@BookigUpdate_Batch ***************** Batch Execution Finished ****************');
    }	
}