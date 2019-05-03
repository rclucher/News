/*---------------------------------------------------------
Author:        Stuart Hamilton
Company:       Salesforce.com
Description:   Cache user-specific settings and config info
Test Class:    UserSettingsHelper_Test
History
12/06/2013     Stuart Hamilton Created
---------------------------------------------------------*/
public without sharing class UserSettings_Helper {
    
    public static List<CyberAd_User_Credential__c> cyberAdSettings {
        
        get {
            
            if (null == cyberAdSettings) {
                
                id userID = userInfo.getUserId();
                
                cyberAdSettings = [Select   c.Publication__c,
                                   c.Division__c,
                                   c.Database__c,
                                   c.CyberAd_Username__c,
                                   c.CyberAd_Password__c
                                   From     CyberAd_User_Credential__c c
                                   Where    c.User__c = :userID
                                   AND     c.RecordType.DeveloperName = 'CyberAd'];
            }
            return cyberAdSettings;
        }
        private set;
    }
    
    
    public static List<CyberAd_User_Credential__c> cyberSellSettings {
        
        get {
            system.debug('@ cyberSellSettings');
            if (null == cyberSellSettings) {
                
                id userID = userInfo.getUserId();
                
                //system.debug('Current USER:' + [Select name, username, id from User where id =: userID]);
                
                
                cyberSellSettings = [Select CyberSell_Divisions__c, Create_GBA_Types__c
                                     From     CyberAd_User_Credential__c c
                                     Where    c.User__c = :userID
                                     AND     c.RecordType.DeveloperName = 'CyberSell'
                                     ORDER BY CreatedDate Desc
                                     LIMIT 1];
            }
            return cyberSellSettings;
        }
        private set;
    }
    
    
    public static List<CyberAd_User_Credential__c> adPointSettings {
        
        get {
            system.debug('@ adPointSettings');
            if (null == adPointSettings) {
                
                id userID = userInfo.getUserId();
                
                //system.debug('Current USER:' + [Select name, username, id from User where id =: userID]);
                
                
                adPointSettings = [Select CyberSell_Divisions__c, Create_GBA_Types__c
                                   From     CyberAd_User_Credential__c c
                                   Where    c.User__c = :userID
                                   AND     c.RecordType.DeveloperName = 'AdPoint'
                                   AND     c.Login_Access__c = true
                                   ORDER BY CreatedDate Desc
                                   LIMIT 1];
            }
            return adPointSettings;
        }
        private set;
    }
    
    
    public static Boolean isCyberAddEnabled {
        
        get {
            
            system.debug('@ isCyberAddEnabled');
            system.debug('cyberAdSettings:' + cyberAdSettings);
            system.debug('cyberAdSettings.size():' + cyberAdSettings.size());
            isCyberAddEnabled = (cyberAdSettings!=null && cyberAdSettings.size()>0);
            return isCyberAddEnabled;
        }
        private set;
    }
    
    
    public static Boolean isCyberSellEnabled {
        
        get {
            system.debug('@ isCyberSellEnabled');
            isCyberSellEnabled = (cyberSellSettings!=null && cyberSellSettings.size()>0);
            system.debug('isCyberSellEnabled:' + isCyberSellEnabled);
            return isCyberSellEnabled;
        }
        private set;
    }
    
    public static Boolean isAdPointEnabled {
        
        get {
            system.debug('@ isAdPointEnabled');
            isAdPointEnabled = (adPointSettings!=null && adPointSettings.size()>0);
            system.debug('isAdPointEnabled:' + isAdPointEnabled);
            return isAdPointEnabled;
        }
        private set;
    }
    
    
    public static String createGBAType {
        
        get {
            system.debug('@ createGBAType');
            if(createGBAType==null)
            {
                system.debug('cyberSellSettings:' + cyberSellSettings);
                createGBAType='None';
                for(CyberAd_User_Credential__c c : cyberSellSettings)
                {
                    //needs to define if multiple records of Credentials will use th highest or lowest
                    createGBAType = c.Create_GBA_Types__c;
                }
            }
            system.debug('createGBAType:' + createGBAType);
            return createGBAType;
        }
        private set;
    }
    
    // added by Tim Fabros 21 / 07 / 2014 - SFE-575
    // BEGIN:
    public static String profileName {
        get {
            System.debug('@UserSettings_Helper profileName');
            if (profileName == null)
            {
                String id = userInfo.getProfileId();
                List<Profile> profiles = [SELECT Name From Profile WHERE Id =: id];
                if (!profiles.isEmpty())
                    return profiles[0].Name;
                return null;
            }
            
            return profileName;
        }
        
        private set;
    }
    // END:
    
    /**** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-26****/
    // this method looks for user divisions from external system user credential records
    public static Set<String> findUserDivisions(String userId)
    {
        Set<String> divisions = new Set<String>();
        
        for(CyberAd_User_Credential__c userCred : [Select c.Division__c
                                                   From CyberAd_User_Credential__c c 
                                                   Where c.RecordType.DeveloperName = 'CyberAd'
                                                   And c.User__c =: userId])
        {
            divisions.add(userCred.Division__c);
        }
        
        return divisions;
    }
    /**** Updated By Bohao Chen on 03/03/2014 ****/
}