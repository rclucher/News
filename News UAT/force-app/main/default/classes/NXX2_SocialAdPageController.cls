/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className    NXX2_SocialAdPageController
* @description  This class handles server side logic for social ad related functionality.
*/
public class NXX2_SocialAdPageController extends NXX2_LightningReqRespModel{
    /**
    * @name         : getCreateAdConfigData
    * @description  : return social ad configuration like ad type, creative type etc.
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @return       : List<SocialAdType>
    * @param        : NA
    */
    @AuraEnabled
    public static List<SocialAdType> getCreateAdConfigData(){
        return NXX2_SalesforceDataService.getSocialAdTypes();
    }
    
    /**
    * @name         : saveAdDetails
    * @description  : This will be used to save ad details
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @return       : boolean
    * @param        : SocialAd__c 
    */
    @AuraEnabled
    public static SocialAd__c saveAdDetails(SocialAd__c adDetails,String recordType){
        try{
            Id recordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName()
                  .get(recordType).getRecordTypeId();
            adDetails.RecordTypeId = recordTypeId;
            upsert adDetails;
        }catch(exception e){
            throw new AuraHandledException('Server side error occured! Please contact admin or try again.');
        }
        return adDetails;
    }
    
    /**
    * @name         : saveAdContent
    * @description  : This will be used to save ad content
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @return       : List<Social_Ad_Content__c>
    * @param        : String adContentsString, Id socialAdId,String mode
    */
    @AuraEnabled
    public static List<Social_Ad_Content__c> saveAdContent(String adContentsString, Id socialAdId,String mode){
        List<Social_Ad_Content__c> adContents;
        if(socialAdId == null){
            throw new AuraHandledException('Invalid Id for the related social ad');
        }else{
            List<SocialAd__c> socialAds = [SELECT Id,Social_Campaign__c FROM SocialAd__c WHERE Id =: socialAdId];
            if(socialAds.size() == 0){
                throw new AuraHandledException('No related social ad found for the given Id');
            }else{
                adContents = (List<Social_Ad_Content__c>)JSON.deserialize(adContentsString, List<Social_Ad_Content__c>.class);
                List<Id> contentIds = new List<Id>();
                for(Social_Ad_Content__c content : adContents){
                    if(content.Id != null){
                        contentIds.add(content.Id);
                    }else{                    
                        content.Social_Ad__c = socialAdId;
                    }
                }
                if(mode == 'Edit'){
                    List<Social_Ad_Content__c> existingAdContents = [SELECT Id,GoogleDrive_File_Id__c 
                                                                     FROM Social_Ad_Content__c 
                                                                     WHERE Social_Ad__c =:socialAdId AND Id NOT IN :contentIds];
                    for(Social_Ad_Content__c content : existingAdContents){
                        if(content.GoogleDrive_File_Id__c != null && content.GoogleDrive_File_Id__c != ''){
                            NXX2_GoogleDriveConnector.deleteFiles(content.GoogleDrive_File_Id__c);
                        }
                    }
                    if(existingAdContents.size() > 0){
                        delete existingAdContents;
                    }
                }
                upsert adContents;
                if(mode == 'CreateNewVersion'){
                    SocialCampaign__c proof = [SELECT Status__c FROM SocialCampaign__c WHERE Id =: socialAds[0].Social_Campaign__c];
                    if(proof == null){
                        throw new AuraHandledException('No related proof found for this proof ad');
                    }else{
                        proof.Status__c = 'New';
                        proof.Number_of_Email_Sent_For_Approval__c = 0;
                        proof.Send_Approval_Emails__c = false;
                        update proof;
                    }
                }
            }
        }
        return adContents;
    }
    
    /**
    * @name         : saveAdDetails
    * @description  : This will be used to get ad details
    * @createdby    : Kamal Sharma - 6nd Aug 2018
    * @return       : SocialAdWithContent 
    * @param        : Id socialAdRecordId
    */
    @AuraEnabled
    public static SocialAdWithContent getAdDetails(Id socialAdRecordId){
        SocialAdWithContent adDetails = new SocialAdWithContent();
        if(socialAdRecordId == null){
            throw new AuraHandledException('Invalid Id for the record');
        }else{
            try{
                List<SocialAd__c> adDetailsList = [SELECT Start_Date__c,End_Date__c,Status__c,Version_Number__c,Display_Ad_Link__c,Form_Name__c,
                                                   Form_Privacy_Policy_Link__c,Form_Thank_You_Page_Link__c,
                                                   Form_Client_Specified_Criteria__c,Parent_Social_Ad__c,
                                                   Button_Type__c ,Ad_Headline__c ,Ad_Link__c ,Event_Name__c,
                                                   Ad_Newsfeed_Link_Description__c ,Ad_Text__c ,Ad_Type__c ,
                                                   Creative_Type__c,(SELECT File_Name__c,Ad_Headline__c ,Ad_Link__c ,
                                                                     Ad_Newsfeed_Link_Description__c ,File_Size__c ,File_Type__c,
                                                                     GoogleDrive_File_Id__c
                                                                     FROM Social_Ad_Contents__r ORDER BY Display_Order__c) FROM SocialAd__c
                                                   WHERE Id =:socialAdRecordId];
                if(adDetailsList.size() > 0){
                    List<GoogleDriveFilesDTO> googleDriveFiles = NXX2_GoogleDriveService.fetchFilesForSocialAd(adDetailsList[0].Parent_Social_Ad__c == null ? socialAdRecordId : adDetailsList[0].Parent_Social_Ad__c);
                    Map<String,GoogleDriveFilesDTO> googleDriveFilesMap = new Map<String,GoogleDriveFilesDTO>();
                    for(GoogleDriveFilesDTO dto : googleDriveFiles){
                        googleDriveFilesMap.put(dto.id, dto);
                    }
                    adDetails.socialAd = adDetailsList[0];
                    List<SocialAdContent> contents = new List<SocialAdContent>();
                    SocialAdContent adContentWrapper;
                    for(Social_Ad_Content__c content : adDetailsList[0].Social_Ad_Contents__r){
                        adContentWrapper = new SocialAdContent();
                        adContentWrapper.id = content.id;
                        adContentWrapper.name = content.File_Name__c;
                        adContentWrapper.type = content.File_Type__c;
                        adContentWrapper.size = content.File_Size__c;
                        adContentWrapper.adHeadline = content.Ad_Headline__c;
                        adContentWrapper.adLink = content.Ad_Link__c;
                        adContentWrapper.adNewsfeedDesc = content.Ad_Newsfeed_Link_Description__c;
                        if(content.File_Type__c != 'Text' && content.GoogleDrive_File_Id__c != null && googleDriveFilesMap.containsKey(content.GoogleDrive_File_Id__c)){
                            adContentWrapper.fileURL = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).thumbnailLink;
                            adContentWrapper.downloadUrl = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).downloadUrl;
                            adContentWrapper.GoogleDriveFileId = content.GoogleDrive_File_Id__c;
                            if(content.File_Type__c.contains('video')){
                                adContentWrapper.fileURL = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).embedLink;
                                adContentWrapper.hasEmbedLink = true;
                            }
                        }
                        contents.add(adContentWrapper);
                    }
                    adDetails.contents = contents;
                }else{
                    throw new AuraHandledException('No record found');
                }
            }catch(Exception e){
                throw new AuraHandledException('Server side issue, Please contact to admin.');
            }
        }
        return adDetails;
    }
    
    /**
    * @name         : getAllAds
    * @description  : This will be used to get all ads with ad details for the given campaign order id
    * @createdby    : Kamal Sharma - 7nd Aug 2018
    * @return       : List<SocialAdWithContent>
    * @param        : String campaignOrderId
    */
    @AuraEnabled
    public static List<SocialAdWithContent> getAllAds(String campaignOrderId){
        List<SocialAdWithContent> socialAdsWithContent = new List<SocialAdWithContent>();
        try{
            Id recordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName()
                  .get('Social Form').getRecordTypeId();
            Map<Id,SocialAd__c> adDetailsMap = new Map<Id,SocialAd__c>([SELECT Start_Date__c,End_Date__c,Status__c,Version_Number__c,Parent_Social_Ad__c,
                                                                        RecordTypeId,Display_Ad_Link__c,Button_Type__c,
                                                                        Social_Campaign__c,Ad_Headline__c ,Ad_Link__c ,
                                                                        Event_Name__c,Ad_Newsfeed_Link_Description__c ,
                                                                        Ad_Text__c ,Ad_Type__c,Form_Name__c,
                                                                        Form_Privacy_Policy_Link__c,Quick_Replies__c,Greetings_Card__c,
                                                                        Form_Thank_You_Page_Link__c,
                                                                        Form_Client_Specified_Criteria__c,
                                                                        Creative_Type__c,(SELECT File_Name__c,Ad_Headline__c,
                                                                                          Ad_Link__c,Ad_Newsfeed_Link_Description__c,
                                                                                          File_Size__c ,File_Type__c,
                                                                                          GoogleDrive_File_Id__c
                                                                                          FROM Social_Ad_Contents__r ORDER BY Display_Order__c)
                                                                        FROM SocialAd__c
                                                                        WHERE Social_Campaign__c =: campaignOrderId 
                                                                        AND Mark_As_Deleted__c != true ORDER BY Ad_Type__c]);
            Map<Id,SocialAd__c> adFormMap = new Map<Id,SocialAd__c>();
            Map<Id,List<SocialAd__c>> adWithAllVersion = new Map<Id,List<SocialAd__c>>();
            SocialAdWithContent adWithContent;
            SocialAdContent adContentWrapper;
            List<GoogleDriveFilesDTO> googleDriveFiles;
            Map<String,GoogleDriveFilesDTO> googleDriveFilesMap;
            for(SocialAd__c socialAd : adDetailsMap.values()){
                if(socialAd.RecordTypeId != recordTypeId){
                    if(socialAd.Parent_Social_Ad__c != null){
                        if(!adWithAllVersion.containsKey(socialAd.Parent_Social_Ad__c)){
                            adWithAllVersion.put(socialAd.Parent_Social_Ad__c,new List<SocialAd__c>());
                        }
                        adWithAllVersion.get(socialAd.Parent_Social_Ad__c).add(socialAd);
                    }else{
                        if(!adWithAllVersion.containsKey(socialAd.Id)){
                            adWithAllVersion.put(socialAd.Id,new List<SocialAd__c>());
                        }
                        adWithAllVersion.get(socialAd.Id).add(socialAd);
                    }
                }else{
                    adFormMap.put(socialAd.Parent_Social_Ad__c, socialAd);
                }
            }
            SocialAd__c latestSocialAd;
            Decimal latestVersion;
            for(Id adId : adWithAllVersion.keySet()){
                latestVersion = 1;
                latestSocialAd = adWithAllVersion.get(adId)[0];
                for(SocialAd__c versionAd : adWithAllVersion.get(adId)){
                    if(versionAd.Version_Number__c > latestVersion){
                        latestVersion = versionAd.Version_Number__c;
                        latestSocialAd = versionAd;
                    }
                }
                adWithContent = new SocialAdWithContent();
                adWithContent.socialAd = latestSocialAd;
                socialAdsWithContent.add(adWithContent);
            }
            for(SocialAdWithContent adWithoutForm : socialAdsWithContent){
                adWithoutForm.socialForm = adFormMap.get(adWithoutForm.socialAd.Id);
                if(adWithoutForm.socialAd.Parent_Social_Ad__c != null){
                    adWithoutForm.socialForm = adFormMap.get(adWithoutForm.socialAd.Parent_Social_Ad__c);
                }
            }
        }catch(Exception e){
            
        }
        return socialAdsWithContent;
    }
    
    /**
    * @name         : getAllVersionForSocialAd
    * @description  : This will be used to get all version of social ad
    * @createdby    : Kamal Sharma - 18th Sep 2018
    * @return       : List<SocialAdWithContent>
    * @param        : String parentSocialAdId
    */
    @AuraEnabled
    public static List<SocialAdWithContent> getAllVersionForSocialAd(String parentSocialAdId){
        List<SocialAdWithContent> socialAdsWithContent = new List<SocialAdWithContent>();
        try{
            Id recordTypeId = Schema.SObjectType.SocialAd__c.getRecordTypeInfosByName()
                  .get('Social Form').getRecordTypeId();
            Map<Id,SocialAd__c> adDetailsMap = new Map<Id,SocialAd__c>([SELECT Start_Date__c,End_Date__c,Status__c,Version_Number__c,Parent_Social_Ad__c,
                                                                        RecordTypeId,Display_Ad_Link__c,Button_Type__c,
                                                                        Social_Campaign__c,Ad_Headline__c ,Ad_Link__c ,
                                                                        Event_Name__c,Ad_Newsfeed_Link_Description__c ,
                                                                        Ad_Text__c ,Ad_Type__c,Form_Name__c,Quick_Replies__c,Greetings_Card__c,
                                                                        Form_Privacy_Policy_Link__c,
                                                                        Form_Thank_You_Page_Link__c,
                                                                        Form_Client_Specified_Criteria__c,
                                                                        Creative_Type__c,(SELECT File_Name__c,Ad_Headline__c,
                                                                                          Ad_Link__c,Ad_Newsfeed_Link_Description__c,
                                                                                          File_Size__c ,File_Type__c,
                                                                                          GoogleDrive_File_Id__c
                                                                                          FROM Social_Ad_Contents__r ORDER BY Display_Order__c)
                                                                        FROM SocialAd__c
                                                                        WHERE (Parent_Social_Ad__c =: parentSocialAdId OR Id =: parentSocialAdId)
                                                                        AND Mark_As_Deleted__c != true ORDER BY Version_Number__c]);
            SocialAdWithContent adWithContent;
            for(SocialAd__c socialAd : adDetailsMap.values()){
                if(socialAd.RecordTypeId != recordTypeId){
                    adWithContent = new SocialAdWithContent();
                    adWithContent.socialAd = socialAd;
                    socialAdsWithContent.add(adWithContent);
                }
            }
        }catch(Exception e){
            
        }
        return socialAdsWithContent;
    }
    
    /**
    * @name         : getContentForSocialAd
    * @description  : This will be used to get content for the given social ad id
    * @createdby    : Kamal Sharma - 2nd Sep 2018
    * @return       : List<SocialAdContent>
    * @param        : String socialAdRecordId,String parentSocialAd
    */
    @AuraEnabled
    public static List<SocialAdContent> getContentForSocialAd(String socialAdRecordId,String parentSocialAd){
        List<SocialAdContent> contents = new List<SocialAdContent>();
        try{
            List<Social_Ad_Content__c> adContentList = [SELECT File_Name__c ,Ad_Headline__c ,Ad_Link__c ,
                                                         Ad_Newsfeed_Link_Description__c ,File_Size__c ,File_Type__c,
                                                         GoogleDrive_File_Id__c
                                                         FROM Social_Ad_Content__c 
                                                         WHERE Social_Ad__c =: socialAdRecordId 
                                                         ORDER BY Display_Order__c];
            SocialAdContent adContentWrapper;
            List<GoogleDriveFilesDTO> googleDriveFiles = NXX2_GoogleDriveService.fetchFilesForSocialAd(parentSocialAd != null ? parentSocialAd : socialAdRecordId);
            Map<String,GoogleDriveFilesDTO> googleDriveFilesMap = new Map<String,GoogleDriveFilesDTO>();
            for(GoogleDriveFilesDTO dto : googleDriveFiles){
                googleDriveFilesMap.put(dto.id, dto);
            }
            for(Social_Ad_Content__c content : adContentList){
                adContentWrapper = new SocialAdContent();
                adContentWrapper.name = content.File_Name__c;
                adContentWrapper.type = content.File_Type__c;
                adContentWrapper.size = content.File_Size__c;
                adContentWrapper.adHeadline = content.Ad_Headline__c;
                adContentWrapper.adLink = content.Ad_Link__c;
                adContentWrapper.adNewsfeedDesc = content.Ad_Newsfeed_Link_Description__c;
                adContentWrapper.content = 'Nothing to display';
                if(content.File_Type__c != 'Text' && content.GoogleDrive_File_Id__c != null && googleDriveFilesMap.containsKey(content.GoogleDrive_File_Id__c)){
                    adContentWrapper.fileURL = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).thumbnailLink;
                    adContentWrapper.downloadUrl = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).downloadUrl;
                    if(content.File_Type__c.contains('video')){
                        adContentWrapper.fileURL = googleDriveFilesMap.get(content.GoogleDrive_File_Id__c).embedLink;
                        adContentWrapper.hasEmbedLink = true;
                    }
                    adContentWrapper.GoogleDriveFileId = content.GoogleDrive_File_Id__c;
                }
                contents.add(adContentWrapper);
            }
        }catch(Exception e){
            
        }
        return contents;
    }
    
    /**
    * @name         : getInitialForUser
    * @description  : This will be used to get initials for the logged in user
    * @createdby    : Kamal Sharma - 5th Sep 2018
    * @return       : String 
    */
    @AuraEnabled
    public static String getInitialForUser(){
        String initials = 'NX';
        try{
            User oUser = [select FirstName,LastName 
                 FROM User Where id =: userInfo.getUserId()];
            initials = oUser.FirstName.substring(0,1) + oUser.LastName.substring(0,1);
        }catch(Exception e){
            
        }
        return initials;
    }
    
    /**
    * @name         : markAdAsDeleted
    * @description  : This will be used to mark an ad as deleted
    * @createdby    : Kamal Sharma - 17th Sep 2018
    * @return       : void 
    * @param        : Id recordId
    */
    @AuraEnabled
    public static void markAdAsDeleted(Id recordId){
        try{
            SocialAd__c  ad = [SELECT Mark_As_Deleted__c 
                                  FROM SocialAd__c  WHERE Id = :recordId];
            ad.Mark_As_Deleted__c = true;
            update ad;
        }catch(Exception e){
            throw new AuraHandledException('Server side issue, Please contact to admin.');
        }
    }
    
    /**
    * @name         : updateProofStatus
    * @description  : This will be used to update the proof status.
    * @createdby    : Kamal Sharma - 16 Oct 2018
    * @return       : Void
    * @param        : String proofId,String proofStatus,String comments
    */
    @AuraEnabled
    public static void updateProofStatus(String proofId,String proofStatus,String comments){
        try{
            SocialCampaign__c  proof = [SELECT Status__c 
                                  FROM SocialCampaign__c  WHERE Id = :proofId];
            proof.Status__c = proofStatus;
            update proof;
            if(comments != null && comments != ''){
                ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), proofId, ConnectApi.FeedElementType.FeedItem, comments);
            }
        }catch(Exception e){
            throw new AuraHandledException('Server side issue, Please contact to admin.');
        }
    }
    
    /**
    * @name         : getCommunityBaseUrl
    * @description  : This will provide community base url
    * @createdby    : Kamal Sharma - 21 Dec 2018
    * @return       : String
    */
    @AuraEnabled
    public static String getCommunityBaseUrl(){
        String communityBaseUrl;
        try{
            NXX2_Email_Configuration_Detail__mdt emailConfiguration = [SELECT Community_Name__c
                                                                       FROM NXX2_Email_Configuration_Detail__mdt 
                                                                       WHERE DeveloperName = 'Send_Email_Config'];
            Network myNetwork = [SELECT Id FROM Network WHERE Name = :emailConfiguration.Community_Name__c];
            ConnectApi.Community  myCommunity;
            if(!Test.isRunningTest()){
                communityBaseUrl = ConnectApi.Communities.getCommunity(myNetwork.id).siteUrl;
            }
        }catch(Exception e){
            throw new AuraHandledException('Server side issue, Please contact to admin.');
        }
        return communityBaseUrl;
    }
    
    /**
    * @name         : isExternalUser
    * @description  : Check if the logged in user is portal user or not.
    * @createdby    : Kamal Sharma - 21 Dec 2018
    * @return       : Boolean
    */
    @AuraEnabled
    public static Boolean isExternalUser(){
      User loggedInUser = NXX2_SalesforceDataService.fetchLoggedInUsersDetails();
      return loggedInUser.UserType != 'Standard';
    }
    
    /**
    * @name         : getProofsForAccount
    * @description  : This will provide proofs for the given accountId
    * @createdby    : Kamal Sharma - 21 Dec 2018
    * @return       : List<SocialCampaign__c>
    * @param        : String accountId
    */
    @AuraEnabled
    public static List<SocialCampaign__c> getProofsForAccount(String accountId){
      return new List<SocialCampaign__c>([SELECT Proof_Name__c,Status__c,
                                          Campaign_Start_Date__c,Campaign_End_Date__c 
                                          FROM SocialCampaign__c 
                                          WHERE Account__c =: accountId]);
    }
    
    /**
    * @name         : getIconName
    * @description  : This will provide icon name for the given sObject
    * @createdby    : Kamal Sharma - 21 Dec 2018
    * @return       : String
    * @param        : String sObjectName
    */
    @AuraEnabled
    public static String getIconName(String sObjectName){
          return NXX2_AppUtility.getIconName(sObjectName);
    }
    
    /**
    * @name         : changePortalUserPassword
    * @description  : This method will change portal user password
    * @createdby    : Kamal Sharma - 21 Dec 2018
    * @return       : Boolean
    * @param        : String oldPassword,String newPassword
    */
    @AuraEnabled
    public static Boolean changePortalUserPassword(String oldPassword,String newPassword){
        Boolean changesSuccessfully = false;
        try{
            Site.changePassword(newPassword,newPassword,oldPassword);
            changesSuccessfully = true;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
          return changesSuccessfully;
    }
}