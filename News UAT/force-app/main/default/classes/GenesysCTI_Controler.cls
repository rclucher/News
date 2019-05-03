/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Karlis Zemitis
 * Company: Genesys
 * Description: This is controler for genesys cti page
 * History:
 * 29/10/2013  Karlis Zemitis Created
 * ---------------------------------------------------------*/
global class GenesysCTI_Controler{    
   @RemoteAction
    global static String CreateCase(Integer ixnType, String CLI, String connId, String contactIds, String accountIds)
    {        
        
        List<String> listContactIds = null;
        if(contactIds.contains(','))
            listContactIds = contactIds.split(',', 0);
        else if(contactIds.length() > 0)
        {
            listContactIds = new List<String>();
            listContactIds.add(contactIds);
        }       
                
        List<String> listAccountIds = null;
        if(accountIds.contains(','))
            listAccountIds =  accountIds.split(',', 0);
        else if(accountIds.length() > 0)
        {
            listAccountIds = new List<String>();
            listAccountIds.add(accountIds);
        }
            
        CTI_Helper.eventType evType;
        
        if(ixnType == 1)
            evType = CTI_Helper.eventType.CALL_INBOUND;
        else if(ixnType == 2)
            evType = CTI_Helper.eventType.CALL_OUTBOUND;
        else
            evType = CTI_Helper.eventType.EMAIL_INBOUND;
                                
        Id retId = CTI_Helper.CreateCase(evType, CLI, connId, listContactIds, listAccountIds);           
        
        return '' + retId;        
    }    
    
    @RemoteAction
    global static String CreateTask(Integer ixnType, String cli, String objectId, String objectType, Long startTime, Long endTime, Integer duration, String ixnId, Boolean callAnswered)
    {                           
        DateTime dtStart = DateTime.newInstance(startTime);
        DateTime dtEnd = DateTime.newInstance(endTime);
                
        CTI_Helper.eventType evType;
        
        String ret;
        
        if(ixnType == 1){
            evType = CTI_Helper.eventType.CALL_INBOUND;
            ret = '{"type":"Call",';
        } else if(ixnType == 2) {
            evType = CTI_Helper.eventType.CALL_OUTBOUND;
            ret = '{"type":"Call",';
        } else {
            evType = CTI_Helper.eventType.EMAIL_INBOUND;
            ret = '{"type":"Email",';
        }
                                
        Id id = CTI_Helper.CreateTask(evType, objectType, objectId, dtStart, dtEnd, duration, ixnId, cli, callAnswered);                      
        
        String taskId= '' + id;
        
        if(taskId == '')
            return '';
        
        /* Do Not Open Sub Task if Campaign Member */
        if(objectType != 'CampaignMember')
            ret = ret + '"id":"' + taskId + '","parentObjectId":"' + objectId +'","screenPop":true}';
        else    
            ret = ret + '"id":"' + taskId + '","parentObjectId":"' + objectId +'","screenPop":false}';
        
        return ret;
    }    
    
        
    @RemoteAction
    global static String SetCaseOwner(String caseId)
    {
        CTI_Helper.SetCaseOwner(Id.valueOf(caseId));
        
        return caseId;
    }

    /*@RemoteAction
    global static String GetCaseType(String caseId)
    {
        String caseType = [Select Origin from Case where Id = :caseId].Origin;
        
        return caseType ;
    }*/

}