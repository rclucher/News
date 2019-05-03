/**
* @description  controller to check UserHasEditAccess
*
* @author       Paul Kang
* @date         2017-12-01
* @update       Used by custom quick action for "Campaign Execution" from classic to lightning
**/
global with sharing class GenericWebServices {

    @AuraEnabled
     webservice static Boolean userHasEditAccess(String UserId, String RecordId) {  
        RestRequest req = RestContext.request;
        
        //Id UserId = req.params.get('Userid');
        //Id RecordId = req.params.get('Campaignid');
        Boolean canEdit = false;
       try
       {
        for(UserRecordAccess ura: [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId=:UserId AND RecordId=:RecordId])
            canEdit=ura.HasEditAccess;
       }
        catch(Exception ex)
        {
            //System.debug('Exception @CampaignWebServices.userHasEditAccess:' + ex.getMessage());
        }
        return canEdit;
    }

    webservice static Id createCreativeForProductOrder (Id productOrderId, Id userId) {
      return UtilMethods.createCreativeForProductOrderId (productOrderId, userId);
    }

    webservice static string startOrchProcessFor (Id recordId, String processName) {
      return UtilMethods.startOrchestratorProcessFor (recordId, processName);
    }

    webservice static String regenerateProductOrders (Id orderId) {
      return UtilMethods.prepareDataToRegenerateProductOrder (orderId);
    }

    webservice static String startFulfilment (Id orderId) {
      return UtilMethods.startFulfilment (orderId);
    }


    /*
    * Used to check the condition to see if the current campaign record's Status and IsActive
    */
    @AuraEnabled
    public static Campaign getCampaignState(Id campaignId) {
        return [Select Status, IsActive from Campaign WHERE Id=:campaignId];
    }
}