/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_SocialCampaignController
* @description  This class will be used as server side controller for proof related functionality.
*/
public with sharing class NXX2_SocialCampaignController {
    
    @AuraEnabled
    public static String getIconName(String sObjectName){
        String u;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }
        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return u;
    }
    
    
    
    @AuraEnabled
    public static List<NXX2_LightningReqRespModel.AccountDTO> fetchMyAccounts(){
        List<NXX2_LightningReqRespModel.AccountDTO> listOfAccountDTO = new List<NXX2_LightningReqRespModel.AccountDTO>();
        
        return listOfAccountDTO;
    }
    
    @AuraEnabled
    public static Integer getTotalCount(String parentRecordId,String ParentObjectName){
        AggregateResult results= [Select count(Id) total from SocialCampaign__c where Account__c=:parentRecordId];
        Integer total =(Integer)results.get('total') ; 
        return total;
    } 
    
    @AuraEnabled
    public static List<SocialCampaign__c> getSocialCampaigns(Integer limits , Integer offsets,String parentRecordId,
                                                             String ParentObjectName){
        Integer intlimits = integer.valueof(limits);
        Integer intoffsets = integer.valueof(offsets);
        List<SocialCampaign__c> listOfSocialCampaign = [Select id,Name,Status__c,Account__c from SocialCampaign__c where Account__c=:parentRecordId Order by Name Limit :intlimits Offset :intoffsets];
        return listOfSocialCampaign;
    }
}