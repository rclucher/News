public with sharing class CS_EventNotificationController {

    public Id notificationEventSettingId {get;set;}
    public Id userId {get;set;}
    public String audience {get;set;}
    public String message {get;set;}
    public List<Notification_Event_Setting_User__c> userSettings {get;set;}

    public CS_EventNotificationController() {
        this.notificationEventSettingId = ApexPages.currentPage().getParameters().get('notificationEventSettingId');
        this.userId = ApexPages.currentPage().getParameters().get('userId');
        this.audience = ApexPages.currentPage().getParameters().get('audience');
        this.message = '';

        if(notificationEventSettingId != null && userId != null && audience != null) 
            unsubscribe();
    }

    public void unsubscribe() {
        userSettings =  [   SELECT Id, Name, Active__c, Audience__c, Notification_Event_Setting__c, User__c,User__r.Name, Notification_Event_Setting__r.Key__c
                            FROM Notification_Event_Setting_User__c
                            WHERE Notification_Event_Setting__c = :notificationEventSettingId 
                            AND User__c = :userId
                        ];

        for (Notification_Event_Setting_User__c eventSetting :userSettings) {
            List<String> audienceList = eventSetting.Audience__c.split(';');
            List<String> audienceListNew = new List<String>();

            for (String audienceString :audienceList) {
                if (audienceString == audience) {
                    continue;
                } else {
                    audienceListNew.add(audienceString);
                }
            }
            String updatedAudience = String.join(audienceListNew,';');
            eventSetting.Audience__c = updatedAudience;
        }

        message = 'Dear <b>' + userSettings[0].User__r.Name + '</b>,  you have been unsubscribed as Audience: <b>' + audience + '</b> from Notification Event Setting with Key : <b>' + userSettings[0].Notification_Event_Setting__r.Key__c + '</b>.';
    }

    public void updateNotificationEventSettingUser() {
        if (userSettings != null)
            update userSettings;
    }
}