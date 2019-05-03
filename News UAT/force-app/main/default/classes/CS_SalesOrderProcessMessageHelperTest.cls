/**
 * Created by petar.mikic on 17/10/2018.
 */

@isTest public class CS_SalesOrderProcessMessageHelperTest {

    @TestSetup static void setup() {
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        soApi.csmso__Line_Item_Fields_CSV__c = 'cscfga__Description__c,One_Off_Price__c';
        insert soApi;

        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [
                SELECT Name, Id
                FROM RecordType
                WHERE sObjectType = 'Account' AND
                Name = 'Prospecting Account'
                AND isActive = true
        ];
        acc.RecordTypeId = rtypes.Id;
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.Campaign_Start_Date__c = System.today();
        so.csmso__Status__c = 'Draft';
        insert so;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
    }

    @isTest static void testSettingProcessMessage() {
        csmso__Sales_Order__c so = [SELECT Id, csmso__Status__c,Invalid_Config_Count__c, Margin_Flag__c, Campaign_Length__c,
                                            Basket_Products__c, Campaign_Products_Type__c,
                                            Print_Display_MAX_PPT_Level__c,
                                            Print_Display_Approval_Level__c from csmso__Sales_Order__c LIMIT 1];
        Map<Id,csmso__Sales_Order__c> newSOsMap = new Map<Id, csmso__Sales_Order__c>{so.Id => so};

        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);
        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t cleared for empty basket');
        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message__c,'So Message wasn\'t cleared for empty basket');

        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = '';
        newSOsMap.get(so.Id).Basket_Products__c = 'Cool Products preapproved';
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);

        System.assertEquals('preapproved',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t set to preapproved');
        System.assertEquals(System.Label.SO_does_not_require_approval,newSOsMap.get(so.Id).csmso__Process_Message__c,'SO Message wasn\'t set to no approval required Label');

        CS_SalesOrderProcessMessageHelper.setProcessMessage(newSOsMap.get(so.Id),'','');
        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = 'Invalid';
        newSOsMap.get(so.Id).Basket_Products__c = 'fine';
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);


        System.assertEquals('warning',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t set to warning for Invalid combination');
        System.assertEquals(System.Label.Invalid,newSOsMap.get(so.Id).csmso__Process_Message__c,'SO Message wasn\'t set to Invalid label');


        CS_SalesOrderProcessMessageHelper.setProcessMessage(newSOsMap.get(so.Id),'','');
        newSOsMap.get(so.Id).Basket_Products__c = '[Print Display';
        newSOsMap.get(so.Id).Print_Display_MAX_PPT_Level__c = 3;
        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = '';
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);
        System.assertEquals('warning',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t set to warning for Bespoke Print PPT req. approval');
        System.assertEquals(true,newSOsMap.get(so.Id).csmso__Process_Message__c.contains(System.Label.SO_Level_PPT_Approval_Message) ,'SO Message doesn\'t contain PPT req. approval label');



        CS_SalesOrderProcessMessageHelper.setProcessMessage(newSOsMap.get(so.Id),'','');
        newSOsMap.get(so.Id).Basket_Products__c = '[Print Display';
        newSOsMap.get(so.Id).Proposed_Print_Discount__c = 90;
        newSOsMap.get(so.Id).Print_Display_DT_Percent_L1__c = 0.5;
        newSOsMap.get(so.Id).Print_Display_MAX_PPT_Level__c = 0;
        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = '';
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);

        System.assertEquals('preapproved',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t set to warning for Bespoke Print approval');
        System.assertEquals(false,newSOsMap.get(so.Id).csmso__Process_Message__c.contains(System.Label.Approval_Level) ,'SO Message doesn\'t contain Bespoke Print approval label');
        System.assertNotEquals(true,newSOsMap.get(so.Id).csmso__Process_Message__c.contains(System.Label.SO_Level_PPT_Approval_Message) ,'SO Message shouldn\'t contain PPT req. approval label ');


        CS_SalesOrderProcessMessageHelper.setProcessMessage(newSOsMap.get(so.Id),'','');
        newSOsMap.get(so.Id).Basket_Products__c = '[Print Display';
        newSOsMap.get(so.Id).Proposed_Print_Discount__c = 90;
        newSOsMap.get(so.Id).Print_Display_DT_Percent_L1__c = 0.5;
        newSOsMap.get(so.Id).Print_Display_MAX_PPT_Level__c = 3;
        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = '';
		newSOsMap.get(so.Id).Target_Discount__c = 70;
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);

        System.assertEquals('warning',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t set to warning for Bespoke Print and PPT approval');
        System.assertEquals(true,newSOsMap.get(so.Id).csmso__Process_Message__c.contains(System.Label.Approval_Level) ,'SO Message doesn\'t contain Bespoke Print approval label');
        System.assertEquals(true,newSOsMap.get(so.Id).csmso__Process_Message__c.contains(System.Label.SO_Level_PPT_Approval_Message) ,'SO Message doesn\'t contain PPT req. approval label ');

        //no need to reset warning message as xtend is setting to blank
        newSOsMap.get(so.Id).Campaign_Products_Type_Text__c = '';
        newSOsMap.get(so.Id).Campaign_Length__c = 1;
        newSOsMap.get(so.Id).Basket_Products__c = '[News Xtend';
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);

        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t clear for News Xtend seasonal');
        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message__c,'SO Message wasn\'t cleared for News Xtend seasonal');

        CS_SalesOrderProcessMessageHelper.setProcessMessage(newSOsMap.get(so.Id),'information','Clear this message');
        newSOsMap.put(so.Id,so);
        newSOsMap.get(so.Id).csmso__Status__c = 'Internally Approved';
        newSOsMap.get(so.Id).recalculateFormulas();
        CS_SalesOrderProcessMessageHelper.updateApprovalMessage(newSOsMap,null);
        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message_Type__c,'SO Message Severity wasn\'t cleared for Approved SO');
        System.assertEquals('',newSOsMap.get(so.Id).csmso__Process_Message__c,'SO Message wasn\'t cleared for Approved SO');




    }
}