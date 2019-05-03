@isTest
public class ApproveSOEmailHandlerTest {
    
    static testmethod void method1(){
        // Create a new email and envelope object.
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
       
       email.subject = 'test Subject';
       env.fromAddress = 'test@news.com.au';
        
        // Create a test account
        account a = new account();
        a.Name = 'Test Account';
        a.phone = '0466579548';
        a.Revenue_Group__c = 'Employment';
        a.Status__c = 'Active';
        a.Share_of_Wallet__c = '<50%';
        a.No_Parent_Account__c = true;
        insert a;
        
        opportunity o = new opportunity();
        o.name = 'Test Opportunity';
        o.AccountId = a.id;
        o.Type = 'Core Activity';
        o.Customer_Books_Direct__c ='Yes';
        o.Opportunity_Type__c = 'Proactive';
        o.Description = 'Test Opportunity Summary';
        o.StageName = 'Discover Needs';
        o.Campaign_Start_Date__c = system.today();
        o.Campaign_End_Date__c = system.today()+30;
        o.CloseDate = system.today()+30;
        o.Competitor__c = 'Online - Other';
        o.OpportunityGroup__c = 'Newspaper';
        insert o;
        
        csmso__Sales_Order__c so = new csmso__Sales_Order__c();
        so.csmso__Opportunity__c = o.id;
        so.csmso__Advertiser__c = a.id;
        insert so;
        
        
       
       // Call the class and test it with the data in the testMethod.
       ApproveSOEmailhandler AppSOObj = new ApproveSOEmailhandler();
       AppSOObj.handleInboundEmail(email, env );
    }

}