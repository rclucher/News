/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className	NXX2_CreateProofAdContentFromStaging
* @description  This class will be used to create actual proof Ad records for staging proof Ads.  
*/
global class NXX2_CreateProofAdContentFromStaging implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts{
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the staging task Recods which are related to product order.
        return Database.getQueryLocator([SELECT Asset_Size__c,Asset_Type__c,Campaign_Id__c,Content_Type__c,
                                         External_Id__c,File_Name__c,Has_Merged__c,Headline__c,Parent_Id__c,
                                         Processing_Status__c,Error_Message__c,Error_Details__c,Related_Proof_Ad__c,
                                         Path__c,Seq_No__c,GUID__c,Related_Proof__c
                                         FROM NXX2_Asset_Staging__c 
                                         WHERE Has_Merged__c = false 
                                         AND GUID__c != null AND GUID__c != '']);
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
        	processAssetRecords((List<NXX2_Asset_Staging__c>)scope);
        }catch(Exception e){
            for(NXX2_Asset_Staging__c asset : (List<NXX2_Asset_Staging__c>)scope){
                asset.Processing_Status__c = 'Error';
                asset.Error_Message__c = 'Exception Occured!';
                asset.Error_Details__c = e.getMessage();
            }
            update scope;
        }
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_Asset_Staging__c> stagingAssets
    * @return       void
    */
    public void processAssetRecords(List<NXX2_Asset_Staging__c> stagingAssets){
		Set<String> stagingProofAdIds = new Set<String>();
        for(NXX2_Asset_Staging__c stagingAsset : stagingAssets){
            stagingProofAdIds.add(stagingAsset.Parent_Id__c);
            stagingAsset.Has_Merged__c = true;
            stagingAsset.Processing_Status__c = 'Success';
        }
        Map<String,NXX2_ProofAd_Staging__c> stagingProofAdIdToActualProofAdIdMap = new Map<String,NXX2_ProofAd_Staging__c>();
        for(NXX2_ProofAd_Staging__c stagingProofAd : [SELECT Related_ProofAd__c,External_Id__c,
                                                      Related_ProofAd__r.Creative_Type__c,
                                                      Related_ProofAd__r.Social_Campaign__c
                                                      FROM NXX2_ProofAd_Staging__c 
                                                      WHERE Related_ProofAd__c != null 
                                                      AND External_Id__c IN :stagingProofAdIds]){
            stagingProofAdIdToActualProofAdIdMap.put(stagingProofAd.External_Id__c,stagingProofAd);
        }
        Map<String,Id> stagingProofIdToActualProofIdMap = new Map<String,Id>();
        for(NXX2_Proof_Staging__c stagingProofAd : [SELECT Related_Proof__c,External_Id__c 
                                                    FROM NXX2_Proof_Staging__c 
                                                    WHERE Related_Proof__c != null 
                                                    AND External_Id__c IN :stagingProofAdIds]){
            stagingProofIdToActualProofIdMap.put(stagingProofAd.External_Id__c,stagingProofAd.Related_Proof__c);
        }
        system.debug('*****stagingProofAdIdToActualProofAdIdMap*****'+stagingProofAdIdToActualProofAdIdMap);
        system.debug('*****stagingProofIdToActualProofIdMap*****'+stagingProofIdToActualProofIdMap);
        List<Social_Ad_Content__c> proofAdContents = new List<Social_Ad_Content__c>();
        for(NXX2_Asset_Staging__c stagingAsset : stagingAssets){
            system.debug('*****Asset CampaignId*****'+stagingAsset.Campaign_Id__c);
            system.debug('*****Asset PARENTID*****'+stagingAsset.Parent_Id__c);
            system.debug('*****Asset RelatedProof*****'+stagingProofAdIdToActualProofAdIdMap.get(stagingAsset.Parent_Id__c));
            system.debug('*****Asset GUID*****'+stagingAsset.GUID__c);
            if(stagingProofAdIdToActualProofAdIdMap.containsKey(stagingAsset.Parent_Id__c)){
                NXX2_ProofAd_Staging__c stagingAd = stagingProofAdIdToActualProofAdIdMap.get(stagingAsset.Parent_Id__c);
                String googleDriveFileId = NXX2_GoogleDriveDataMigrationService.processFileMigration(stagingAd.Related_ProofAd__c, stagingAsset.GUID__c);
                system.debug('*****Asset googleDriveFileId*****'+googleDriveFileId);
                if(googleDriveFileId != null){                
                    proofAdContents.add(new Social_Ad_Content__c(
                        Display_Order__c = stagingAsset.Seq_No__c == null ? 1 : Decimal.valueOf(stagingAsset.Seq_No__c),
                        File_Name__c  = stagingAsset.File_Name__c,
                        File_Size__c = stagingAsset.Asset_Size__c == null ? 0 : Decimal.valueOf(stagingAsset.Asset_Size__c),
                        File_Type__c = stagingAsset.Content_Type__c,
                        Social_Ad__c = stagingAd.Related_ProofAd__c,
                        GoogleDrive_File_Id__c = googleDriveFileId,
                        Created_From_Staging__c = true
                    ));
                    stagingAsset.Related_Proof_Ad__c = stagingAd.Related_ProofAd__c;
                    stagingAsset.Related_Proof__c = stagingAd.Related_ProofAd__r.Social_Campaign__c;
                }else{
                    stagingAsset.Processing_Status__c = 'Error';
                    stagingAsset.Error_Message__c = 'File does not exist in google drive';
                    stagingAsset.Error_Details__c = 'File does not exist in google drive';
                }
            }else if(stagingProofIdToActualProofIdMap.containsKey(stagingAsset.Parent_Id__c)){
                NXX2_GoogleDriveDataMigrationService.processFileMigration(stagingProofIdToActualProofIdMap.get(stagingAsset.Parent_Id__c), stagingAsset.GUID__c);
            	stagingAsset.Related_Proof__c = stagingProofIdToActualProofIdMap.get(stagingAsset.Parent_Id__c);
            }else{
                stagingAsset.Processing_Status__c = 'Error';
                stagingAsset.Error_Message__c = 'Parent Id do not have any related object.';
                stagingAsset.Error_Details__c = 'Parent Id which may be socialAd Id or Campaign Id does not belong to any actual proof ad or proof.';
            }
        }
        system.debug('*****ProofAdContents*****'+proofAdContents);
        insert proofAdContents;
        update stagingAssets;
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateSocialFormFromStaging b = new NXX2_CreateSocialFormFromStaging();
        database.executebatch(b,1);
    }
}