/*------------------------------------------------------------  
Author:        Paras Prajapati
Company:       Salesforce.com
Description:   NXX2_SocialAdHistoryController - Controller class will be used to handle history of Social Ad and Social Ad content records.
Test Class:    ...
History
<Date>      <Authors Name>     <Brief Description of Change>
01/Nov/2018  Paras Prajapati
------------------------------------------------------------*/
public class NXX2_SocialAdHistoryController {
	 /***
     * getIconName description
     * @param  sObjectName sObjectName description
     * @return             return description
     */
	@AuraEnabled
    public static String getIconName(String sObjectName){
		  System.debug('sObjectName Name' + sObjectName);
          return NXX2_AppUtility.getIconName(sObjectName);
    }

	/***
     * getSocialAdHistory - This method will retrive all the history related to Social Ad and Social Ad content records.
     * @param  sObjectName sObjectName description
     * @return             return description
     */
	 @AuraEnabled
    public static List<NXX2_LightningReqRespModel.SocialAdHistoryResponse> getSocialAdHistory(String ParentId){
        List<NXX2_LightningReqRespModel.SocialAdHistoryResponse> adhistoryResponse = new List<NXX2_LightningReqRespModel.SocialAdHistoryResponse>();
        NXX2_LightningReqRespModel.SocialAdHistoryResponse historyResponse; 
        if(parentId!=null){
            List<SocialAd__History> socialAdHistoryRecords=[Select Id,IsDeleted,ParentId,Field,OldValue,NewValue,createdDate from SocialAd__History where ParentId =:ParentId AND Field != 'created'];
            if(socialAdHistoryRecords.size()>0){
                for(SocialAd__History socialAdHistory :socialAdHistoryRecords){
                    historyResponse = new NXX2_LightningReqRespModel.SocialAdHistoryResponse();
                    historyResponse.Id=socialAdHistory.Id;
                    historyResponse.IsDeleted=socialAdHistory.IsDeleted;
                    historyResponse.ParentId=socialAdHistory.ParentId;
                    historyResponse.Field=socialAdHistory.Field;
                    historyResponse.OldValue=String.valueOf(socialAdHistory.OldValue);
                    historyResponse.NewValue=String.valueOf(socialAdHistory.NewValue);
                    historyResponse.createdDate=socialAdHistory.createdDate;
                    adhistoryResponse.add(historyResponse); 
                }
            }
            Map<ID,Social_Ad_Content__c> socialAdContentmap = new Map<ID,Social_Ad_Content__c>([Select Id from Social_Ad_Content__c where  Social_Ad__c=:ParentId]);
            if(socialAdContentmap!=null && socialAdContentmap.size()>0){
              List<Social_Ad_Content__History> socialAdContentHistoryList=[Select Id,IsDeleted,ParentId,Field,OldValue,NewValue,createdDate from Social_Ad_Content__History where ParentId =:socialAdContentmap.keySet()];
              if(socialAdContentHistoryList.size()>0){
                for(Social_Ad_Content__History socialAdContentHistory :socialAdContentHistoryList){
                    historyResponse = new NXX2_LightningReqRespModel.SocialAdHistoryResponse();
                    historyResponse.Id=socialAdContentHistory.Id;
                    historyResponse.IsDeleted=socialAdContentHistory.IsDeleted;
                    historyResponse.ParentId=socialAdContentHistory.ParentId;
                    historyResponse.Field=socialAdContentHistory.Field;
                    historyResponse.OldValue=String.valueOf(socialAdContentHistory.OldValue);
                    historyResponse.NewValue=String.valueOf(socialAdContentHistory.NewValue);
                    historyResponse.createdDate=socialAdContentHistory.createdDate; 
                    adhistoryResponse.add(historyResponse);
                }
            }
            }
        }
        return adhistoryResponse;
    }

}