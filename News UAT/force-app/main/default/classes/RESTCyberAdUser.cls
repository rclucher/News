@RestResource(urlMapping='/CyberAd/User/*')
global without sharing class RESTCyberAdUser {

    @HttpGet
    global static list<CyberAd_User_Credential__c> getCyberAdLogin()
    {
        return UserSettings_Helper.cyberAdSettings;
    }
}