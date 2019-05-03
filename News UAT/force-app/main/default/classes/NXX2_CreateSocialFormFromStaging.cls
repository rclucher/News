/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className	NXX2_CreateSocialFormFromStaging
* @description  This class will be used to create actual proof Ad records for staging proof Ads.  
*/
global class NXX2_CreateSocialFormFromStaging implements Database.Batchable<sObject>,Database.Stateful{
    private string socialProofAdRecordTypeId;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Default constructor
    */
    public NXX2_CreateSocialFormFromStaging(){
        socialProofAdRecordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName().get('Social Ad').getRecordTypeId();
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the staging task Recods which are related to product order.
        return Database.getQueryLocator([SELECT Campaign_Id__c,Has_Merged__c, Client_Criteria__c,Privacy_Url__c,
                                         SocialForm_Name__c,External_Id__c, Thankyou_Url__c,Related_Proof__c,
                                         Processing_Status__c,Error_Message__c,Error_Details__c,Related_Proof_Ad__c
                                         FROM NXX2_SocialForm_Staging__c  
                                         WHERE Has_Merged__c = false 
                                         AND Campaign_Id__c != ''
                                        ]);
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  execute method implementation of Batch interface
    * @param        Database.BatchableContext BC, List<sObject> scope
    * @return       void
    */
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
        	processProofAdRecords((List<NXX2_SocialForm_Staging__c>)scope);
        }catch(Exception e){
            for(NXX2_SocialForm_Staging__c stagingForm : (List<NXX2_SocialForm_Staging__c>)scope){
                stagingForm.Processing_Status__c = 'Error';
                stagingForm.Error_Message__c = 'Exception Occured!';
                stagingForm.Error_Details__c = e.getMessage();
            }
            update scope;
        }
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_SocialForm_Staging__c> stagingForms
    * @return       void
    */
    public void processProofAdRecords(List<NXX2_SocialForm_Staging__c> stagingForms){
        Set<String> campaignIds = new Set<String>();
        for(NXX2_SocialForm_Staging__c stagingForm : stagingForms){
            campaignIds.add(stagingForm.Campaign_Id__c);
            stagingForm.Has_Merged__c = true;
        }
        Map<String,List<NXX2_ProofAd_Staging__c>> stagingProofIdTostagingProofAdMap = new Map<String,List<NXX2_ProofAd_Staging__c>>();
        for(NXX2_ProofAd_Staging__c stagingProofAd : [SELECT Related_ProofAd__c,Related_ProofAd__r.Social_Campaign__c,
                                                      Campaign_Id__c 
                                                      FROM NXX2_ProofAd_Staging__c 
                                                      WHERE Related_ProofAd__c != null 
                                                      AND Campaign_Id__c IN :campaignIds
                                                      AND Type__c = 'LEAD_GENERATION']){
            if(!stagingProofIdTostagingProofAdMap.containsKey(stagingProofAd.Campaign_Id__c)){
                stagingProofIdTostagingProofAdMap.put(stagingProofAd.Campaign_Id__c,new List<NXX2_ProofAd_Staging__c>());          
            }
            stagingProofIdTostagingProofAdMap.get(stagingProofAd.Campaign_Id__c).add(stagingProofAd);
        }
        List<SocialAd__c> socialForms = new List<SocialAd__c>();
        for(NXX2_SocialForm_Staging__c stagingForm : stagingForms){
            if(stagingProofIdTostagingProofAdMap.containsKey(stagingForm.Campaign_Id__c)){
                for(NXX2_ProofAd_Staging__c stagingProofAd : stagingProofIdTostagingProofAdMap.get(stagingForm.Campaign_Id__c)){
                    socialForms.add(new SocialAd__c(
                        RecordTypeId = socialProofAdRecordTypeId,
                        Created_From_Staging__c = true,
                        Form_Name__c = stagingForm.SocialForm_Name__c,
                        Form_Client_Specified_Criteria__c = stagingForm.Client_Criteria__c,
                        Form_Privacy_Policy_Link__c = stagingForm.Privacy_Url__c,
                        Form_Thank_You_Page_Link__c = stagingForm.Thankyou_Url__c,
                        Social_Campaign__c = stagingProofAd.Related_ProofAd__r.Social_Campaign__c,
                        Parent_Social_Ad__c = stagingProofAd.Related_ProofAd__c
                    ));
                    stagingForm.Related_Proof_Ad__c = stagingProofAd.Related_ProofAd__c;
                    stagingForm.Related_Proof__c = stagingProofAd.Related_ProofAd__r.Social_Campaign__c;
                }
                stagingForm.Processing_Status__c = 'Success';
            }else{
                stagingForm.Processing_Status__c = 'Error';
                stagingForm.Error_Message__c = 'No related social ad';
                stagingForm.Error_Details__c = 'It seems like their is no any Lead Generation type social ad for this form\'s campaign id';
            }
        }
        insert socialForms;
        update stagingForms;
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){}
}