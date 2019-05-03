@isTest
public class CS_EventNotificationControllerTest {
      @testSetup static void setup() {
       Notification_Event_Setting__c NES = new Notification_Event_Setting__c();
       NES.Field_Name__c = 'Status__c';
       NES.From_Value__c = '*';
       NES.To_Value__c = 'Draft';
       NES.Object_Name__c = 'Order__c';
       insert NES;
       
       Notification_Event_Setting_User__c NESUser = new Notification_Event_Setting_User__c();
       NESUser.User__c = UserInfo.getUserID(); 
       NESUser.Audience__c = 'Campaign Mgmt Team;PO Mgmt Team;Social Team';
       NESUser.Active__c = true;
       NESUser.Notification_Event_Setting__c  = NES.ID;
       insert NESUser;
      }
      
         @isTest
        public static void testController() {
            Notification_Event_Setting__c  NES = [SELECT Id FROM Notification_Event_Setting__c  LIMIT 1];
            
            Test.startTest();
            PageReference csEventPage = Page.CS_EventNotification;
            Test.setCurrentPage(csEventPage);
            

            System.debug('NES.id' + NES.id);
             ApexPages.currentPage().getParameters().put('notificationEventSettingId',NES.id);
             ApexPages.currentPage().getParameters().put('userId',UserInfo.getUserID());
             System.debug('userId' + UserInfo.getUserID());
             ApexPages.currentPage().getParameters().put('audience','burek');
             CS_EventNotificationController eventCtrlr = new CS_EventNotificationController();
            Test.stopTest(); 
             
        }

}