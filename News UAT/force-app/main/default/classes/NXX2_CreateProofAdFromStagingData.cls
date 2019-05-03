/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className    NXX2_CreateProofAdFromStagingData
* @description  This class will be used to create actual proof Ad records for staging proof Ads.  
*/
global class NXX2_CreateProofAdFromStagingData implements Database.Batchable<sObject>,Database.Stateful{
    private string socialProofAdRecordTypeId;
    private Map<String,String> stagingToActualProofAdTypeMap;
    private Map<String,String> stagingToActualProofAdCreativeTypeMap;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Default constructor
    */
    public NXX2_CreateProofAdFromStagingData(){
        socialProofAdRecordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName().get('Social Ad').getRecordTypeId();
        stagingToActualProofAdTypeMap = new Map<String,String>{
            'TRAFFIC' => 'Traffic',
            'CONVERSION' => 'Conversion',
            'LEAD_GENERATION' => 'Lead Generation',
            'ENGAGEMENT' => 'Engagement',
            'BRAND_AWARENESS' => 'Brand Awareness',
            'REACH' => 'Reach',
            'VIDEO_VIEWS' => 'Video Views',
            'EVENT_RESPONSE' => 'Event Response',
            'MESSENGER' => 'Messenger'
        };
        stagingToActualProofAdCreativeTypeMap = new Map<String,String>{
            'SLIDESHOW' => 'Slideshow',
            'CAROUSEL' => 'Carousel',
            'SINGLE_IMAGE' => 'Single image',
            'VIDEO' => 'Video'
        };
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
        system.debug('*******ProofAd*******');
        return Database.getQueryLocator([SELECT Campaign_Id__c,Has_Merged__c, Headline__c,Type__c,Related_ProofAd__c,Event_Name__c,
                                         Creative_Type__c,External_Id__c, Link__c, Link_Desc__c, Text__c, Button_Type__c,
                                         Processing_Status__c,Error_Message__c,Error_Details__c
                                         FROM NXX2_ProofAd_Staging__c 
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
        system.debug('*******Scope*******'+scope);
        try{
            processProofAdRecords((List<NXX2_ProofAd_Staging__c>)scope);
        }catch(Exception e){
            for(NXX2_ProofAd_Staging__c proofAd : (List<NXX2_ProofAd_Staging__c>)scope){
                proofAd.Processing_Status__c = 'Error';
                proofAd.Error_Message__c = 'Exception Occured!';
                proofAd.Error_Details__c = e.getMessage();
            }
            update scope;
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_ProofAd_Staging__c> stagingProofAds
    * @return       void
    */
    public void processProofAdRecords(List<NXX2_ProofAd_Staging__c> stagingProofAds){
        Set<String> stagingProofIds = new Set<String>();
        Map<String,NXX2_ProofAd_Staging__c> stagingProofAdIdToStagingProofAdMap = new Map<String,NXX2_ProofAd_Staging__c>();
        for(NXX2_ProofAd_Staging__c stagingProofAd : stagingProofAds){
            stagingProofAd.Has_Merged__c = true;
            stagingProofIds.add(stagingProofAd.Campaign_Id__c);
            stagingProofAdIdToStagingProofAdMap.put(stagingProofAd.External_Id__c, stagingProofAd);
        }
        system.debug('*******stagingProofIds*******'+stagingProofIds);
        system.debug('*******stagingProofAdIdToStagingProofAdMap*******'+stagingProofAdIdToStagingProofAdMap);
        Map<String,NXX2_Proof_Staging__c> StagingProofIdToActualProofIdMap = new Map<String,NXX2_Proof_Staging__c>();
        for(NXX2_Proof_Staging__c proofStaging : [SELECT Related_Proof__c,External_Id__c,Related_Proof__r.Status__c,
                                                  Related_Proof__r.RecordType.Name  
                                                  FROM NXX2_Proof_Staging__c 
                                                  WHERE External_Id__c IN :stagingProofIds 
                                                  AND Related_Proof__c != null 
                                                  AND Related_Proof__r.RecordType.Name = 'Social']){
            StagingProofIdToActualProofIdMap.put(proofStaging.External_Id__c, proofStaging);
        }
        system.debug('*******StagingProofIdToActualProofIdMap*******'+StagingProofIdToActualProofIdMap);
        Map<String,SocialAd__c> stagingProofAdIdToActualProofAd = new Map<String,SocialAd__c>();
        SocialAd__c proofAd;
        for(NXX2_ProofAd_Staging__c stagingProofAd : stagingProofAds){
            system.debug('*******stagingProofAd*******'+stagingProofAd);
            system.debug('*******Campaign_Id__c*******'+StagingProofIdToActualProofIdMap.get(stagingProofAd.Campaign_Id__c));
            if(StagingProofIdToActualProofIdMap.containsKey(stagingProofAd.Campaign_Id__c)){
                NXX2_Proof_Staging__c stagingProof = StagingProofIdToActualProofIdMap.get(stagingProofAd.Campaign_Id__c);
                proofAd = new SocialAd__c(
                    Ad_Headline__c = stagingProofAd.Headline__c,
                    Ad_Link__c = stagingProofAd.Link__c,
                    Ad_Newsfeed_Link_Description__c = stagingProofAd.Link_Desc__c,
                    Ad_Text__c = stagingProofAd.Text__c,
                    Ad_Type__c = stagingToActualProofAdTypeMap.get(stagingProofAd.Type__c),
                    Creative_Type__c = stagingToActualProofAdCreativeTypeMap.get(stagingProofAd.Creative_Type__c),
                    Button_Type__c = stagingProofAd.Button_Type__c,
                    Event_Name__c = stagingProofAd.Event_Name__c,
                    Social_Campaign__c = stagingProof.Related_Proof__c,
                    RecordTypeId = socialProofAdRecordTypeId,
                    Status__c = stagingProof.Related_Proof__r.Status__c,
                    Created_From_Staging__c = true
                );
                stagingProofAdIdToActualProofAd.put(stagingProofAd.External_Id__c,proofAd);
            }else{
                stagingProofAd.Processing_Status__c = 'Error';
                stagingProofAd.Error_Message__c = 'No Proof Exist For The Campaign Id.';
                stagingProofAd.Error_Details__c = 'No Proof Exist For The Campaign Id.';
            }
        }
        system.debug('******Social Proof Ad******'+stagingProofAdIdToActualProofAd.values());
        insert stagingProofAdIdToActualProofAd.values();
        for(String stagingProofAdId : stagingProofAdIdToActualProofAd.keyset()){
            stagingProofAdIdToStagingProofAdMap.get(stagingProofAdId).Related_ProofAd__c = stagingProofAdIdToActualProofAd.get(stagingProofAdId).Id;
            stagingProofAdIdToStagingProofAdMap.get(stagingProofAdId).Processing_Status__c = 'Success';
        }
        update stagingProofAdIdToStagingProofAdMap.values();
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateDisplayProofAdFromStaging b = new NXX2_CreateDisplayProofAdFromStaging();
        database.executebatch(b,1);
    }
}