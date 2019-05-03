global with sharing class PostRulesExecutionObserver implements csam.ObserverApi.IObserver{
    global PostRulesExecutionObserver() { }  

    global void execute(csam.ObserverApi.Observable o, Object arg) {

        if (o instanceof csb2c.ProductBasketObservable || Test.isRunningTest()) {
            csb2c.ProductBasketObservable pBObservable = (csb2c.ProductBasketObservable) o;
            List<Id> basketIds = pBObservable.getBasketIds();
            
            APIPostRuleExecution updateJob = new APIPostRuleExecution(basketIds);
            ID jobID = System.enqueueJob(updateJob);
        }
        
    }
    
}