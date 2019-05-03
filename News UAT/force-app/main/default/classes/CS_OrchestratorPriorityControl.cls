global with sharing class CS_OrchestratorPriorityControl {
    public CS_OrchestratorPriorityControl() {
        
    }

    webservice static String setOrchestratorPriorityCampaign(Id campaignId, String priority){

        String result = '';
        System.debug('**** setOrchestratorPriorityCampaign: ' + campaignId + ' - ' +priority);
        try{
            List<CSPOFA__Orchestration_Process__c> orchList = [SELECT Id, Name, CSPOFA__Priority__c, CSPOFA__Status__c, Order__c 
                                                                FROM CSPOFA__Orchestration_Process__c
                                                                WHERE Order__c = :campaignId AND CSPOFA__Status__c in ('In Progress', 'Initializing')];

            Order__c o = [SELECT Id, Orchestrator_Priority__c FROM Order__c WHERE Id = :campaignId Limit 1];
            System.debug('**** setOrchestratorPriorityCampaign orchList: ' + orchList);
            if(!orchList.isEmpty()){

                for(CSPOFA__Orchestration_Process__c item : orchList){
                    item.CSPOFA__Priority__c = priority;
                }

                update orchList;

                if(priority == '2 - Normal'){
                    o.Orchestrator_Priority__c = false;

                }else{
                    o.Orchestrator_Priority__c = true;
                }

                update o;

                // Fix for NXRIII-266, result = 'Orchstrator processes are sucesfully updated';
                result = 'Orchestrator processes are successfully updated';

            } else{
                result = 'Campaign does not have Orchestrator process that is in progress state.';
            }

        } catch (Exception ex){
            result = ex.getMessage() + ' -- Line: '+ex.getLineNumber();
        }


        return result;
    }


    webservice static String setOrchestratorPriorityProduct(Id productId, String priority){

        String result = '';
        System.debug('**** setOrchestratorPriorityProduct: ' + productId + ' - ' +priority);
        try{
            List<CSPOFA__Orchestration_Process__c> orchList = [SELECT Id, Name, CSPOFA__Priority__c, CSPOFA__Status__c, Product_Order__c 
                                                                FROM CSPOFA__Orchestration_Process__c
                                                                WHERE Product_Order__c = :productId AND CSPOFA__Status__c in ('In Progress', 'Initializing')];

            Product_Order__c po = [SELECT Id, Orchestrator_Priority__c FROM Product_Order__c WHERE Id = :productId Limit 1];
            System.debug('**** setOrchestratorPriorityProduct orchList: ' + orchList);
            if(!orchList.isEmpty()){

                for(CSPOFA__Orchestration_Process__c item : orchList){
                    item.CSPOFA__Priority__c = priority;
                }

                update orchList;

                if(priority == '2 - Normal'){
                    po.Orchestrator_Priority__c = false;

                }else{
                    po.Orchestrator_Priority__c = true;
                }

                update po;

                // Fix for NXRIII-266, result = 'Orchstrator processes are sucesfully updated';
                result = 'Orchestrator processes are successfully updated';

            } else{
                result = 'Product Order does not have Orchestrator process that is in progress state.';
            }

        } catch (Exception ex){
            result = ex.getMessage() + ' -- Line: '+ex.getLineNumber();
        }

        return result;
    }

    webservice static String setOrchestratorPriorityCreative(Id creativeId, String priority){

        String result = '';
        System.debug('**** setOrchestratorPriorityProduct: ' + creativeId + ' - ' +priority);
        try{
            List<CSPOFA__Orchestration_Process__c> orchList = [SELECT Id, Name, CSPOFA__Priority__c, CSPOFA__Status__c, Creative__c 
                                                                FROM CSPOFA__Orchestration_Process__c
                                                                WHERE Creative__c = :creativeId AND CSPOFA__Status__c in ('In Progress', 'Initializing')];

            Creative__c creative = [SELECT Id, Orchestrator_Priority__c FROM Creative__c WHERE Id = :creativeId Limit 1];
            System.debug('**** setOrchestratorPriorityProduct orchList: ' + orchList);
            if(!orchList.isEmpty()){

                for(CSPOFA__Orchestration_Process__c item : orchList){
                    item.CSPOFA__Priority__c = priority;
                }

                update orchList;

                if(priority == '2 - Normal'){
                    creative.Orchestrator_Priority__c = false;

                }else{
                    creative.Orchestrator_Priority__c = true;
                }

                update creative;

                // Fix for NXRIII-266, result = 'Orchstrator processes are sucesfully updated';
                result = 'Orchestrator processes are successfully updated';

            } else{
                result = 'Creative does not have Orchestrator process that is in progress state.';
            }

        } catch (Exception ex){
            result = ex.getMessage() + ' -- Line: '+ex.getLineNumber();
        }

        return result;
    }
}