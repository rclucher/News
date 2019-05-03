public class AT_UpdateOpportunityStage {
    
    @InvocableMethod(label='Create Opp Orders')
    public static void createOppOrders(List<Id> oppIDs) {
        // Debugging for NXRIII-358
        System.debug('Creating opp orders for: ' + oppIDs);
        
        CS_OpportunityTriggerDelegate delegate = new CS_OpportunityTriggerDelegate();
        
        // Fix for NXRIII-356, call prepareAfter() so that the orchUser variable is set properly
        // (NXRIII-358: moving this to the top to prevent overwriting newlyClosedOneOpps)
        delegate.prepareAfter();
        
        delegate.newlyClosedOneOpps = new Map<Id, Opportunity>();
        
        for (Opportunity opp: [SELECT Id, AccountId, Name, OwnerId, Owner_Division__c, Contact__c, Amount, Industry_Code__c FROM Opportunity WHERE Id IN :oppIDs]) {
            delegate.newlyClosedOneOpps.put(opp.Id, opp);
        }
        
        // Debugging for NXRIII-358
        System.debug('Newly Closed Won: ' + delegate.newlyClosedOneOpps);
        
        if (!delegate.newlyClosedOneOpps.keySet().isEmpty()) {
            delegate.CreateResetOrders();
        }
    }
    
    public AT_UpdateOpportunityStage(List<Id> oppIDs){
        createOppOrders(oppIDs);
    }
}