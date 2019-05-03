/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className    NXX2_CreateProofAdFromStagingData
* @description  This class will be used to create actual proof Ad records for staging proof Ads.  
*/
global class NXX2_ResetErrorRecordInStagingData implements Database.Batchable<sObject>,Database.Stateful{
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the staging task Recods which are related to product order.
        system.debug('*******Proof*******');
        return Database.getQueryLocator([SELECT External_Id__c,Has_Merged__c,Error_Message__c,Processing_Status__c,
                                         Error_Details__c
                                         FROM NXX2_Proof_Staging__c
                                         WHERE Has_Merged__c = true 
                                         AND Processing_Status__c = 'Error'
                                         AND Error_Message__c = 'Exception Occured!'
                                         AND Related_Proof__c = null
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
        system.debug('*******Scope*******'+scope);
        try{
            processProofRecords((List<NXX2_Proof_Staging__c>)scope);
        }catch(Exception e){
            system.debug('*******Error Occured*******'+e.getMessage());
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_ProofAd_Staging__c> stagingProofAds
    * @return       void
    */
    public void processProofRecords(List<NXX2_Proof_Staging__c> stagingProofs){
        Set<String> CampaignIds = new Set<String>();
        for(NXX2_Proof_Staging__c stagingProof : stagingProofs){
            stagingProof.Has_Merged__c = false;
            stagingProof.Error_Details__c = '';
            stagingProof.Error_Message__c = '';
            stagingProof.Processing_Status__c = '';
            CampaignIds.add(stagingProof.External_Id__c);
        }
        update stagingProofs;
        List<NXX2_ProofAd_Staging__c> stagingProofAds = [SELECT External_Id__c,Has_Merged__c,
                                                         Error_Message__c,Processing_Status__c,
                                                         Error_Details__c
                                                         FROM NXX2_ProofAd_Staging__c
                                                         WHERE Has_Merged__c = true 
                                                         AND Processing_Status__c = 'Error'
                                                         AND Related_ProofAd__c = null
                                                         AND Campaign_Id__c IN :CampaignIds
                                                        ];
        for(NXX2_ProofAd_Staging__c stagingProofAd : stagingProofAds){
            stagingProofAd.Has_Merged__c = false;
            stagingProofAd.Error_Details__c = '';
            stagingProofAd.Error_Message__c = '';
            stagingProofAd.Processing_Status__c = '';
        }
        update stagingProofAds;
        List<NXX2_SocialForm_Staging__c> socialForms = [SELECT External_Id__c,Has_Merged__c,
                                                        Error_Message__c,Processing_Status__c,
                                                        Error_Details__c
                                                        FROM NXX2_SocialForm_Staging__c
                                                        WHERE Has_Merged__c = true 
                                                        AND Processing_Status__c = 'Error'
                                                        AND Related_Proof__c = null
                                                        AND Error_Message__c = 'No related social ad'
                                                        AND Campaign_Id__c IN :CampaignIds
                                                       ];
        for(NXX2_SocialForm_Staging__c socialForm : socialForms){
            socialForm.Has_Merged__c = false;
            socialForm.Error_Details__c = '';
            socialForm.Error_Message__c = '';
            socialForm.Processing_Status__c = '';
        }
        update socialForms;
        List<NXX2_Asset_Staging__c> assets = [SELECT External_Id__c,Has_Merged__c,
                                              Error_Message__c,Processing_Status__c,
                                              Error_Details__c
                                              FROM NXX2_Asset_Staging__c
                                              WHERE Has_Merged__c = true 
                                              AND Processing_Status__c = 'Error'
                                              AND Related_Proof__c = null
                                              AND Error_Message__c = 'Parent Id do not have any related object.'
                                              AND Campaign_Id__c IN :CampaignIds
                                             ];
        for(NXX2_Asset_Staging__c asset : assets){
            asset.Has_Merged__c = false;
            asset.Error_Details__c = '';
            asset.Error_Message__c = '';
            asset.Processing_Status__c = '';
        }
        update assets;
        List<NXX2_Task_Staging__c> tasks = [SELECT External_Id__c,Has_Merged__c,
                                            Error_Message__c,Processing_Status__c,
                                            Error_Details__c
                                            FROM NXX2_Task_Staging__c
                                            WHERE Has_Merged__c = true 
                                            AND Related_Proof__c = null
                                            AND Campaign_Id__c IN :CampaignIds
                                           ];
        for(NXX2_Task_Staging__c task : tasks){
            task.Has_Merged__c = false;
            task.Error_Details__c = '';
            task.Error_Message__c = '';
            task.Processing_Status__c = '';
        }
        update tasks;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateActualProofForStagingProof b = new NXX2_CreateActualProofForStagingProof();
        database.executebatch(b,1);
    }
}