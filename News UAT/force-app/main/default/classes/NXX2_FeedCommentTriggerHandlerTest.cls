@isTest
public class NXX2_FeedCommentTriggerHandlerTest{
    public static testMethod void testTriggerHandler() {
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
        System.runAs(currentUser){
            Test.startTest();
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            User portalAccountOwner1 = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'test2@test.com',
                Alias = 'batman',
                Email='test@testSalesforce.com',
                EmailEncodingKey='UTF-8',
                Firstname='Bruce',
                Lastname='Wayne',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago'
            );
            insert portalAccountOwner1;
            List<Account> accounts = TestDataFactory.createAccounts(3,false);
            accounts[0].ownerId = portalAccountOwner1.Id;
            insert accounts;
            List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
            contacts[0].Email = 'NXX2Test123@News.com';
            contacts[0].NewsXtend_My_Account_Access__c = true;
            insert contacts;
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
            opportunities[0].Payer_Account__c = accounts[1].Id;
            opportunities[1].Payer_Account__c = accounts[2].Id;
            insert opportunities;
            User user = NXX2_TestUtility.createPortalUser(contacts[0]);
            Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
            List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1, campaignOrder.Id);
            SocialCampaign__c proof = NXX2_TestUtility.createProof(pos[0].Id); 
            SocialCampaign__Share proofShare = new SocialCampaign__Share();
            proofShare.UserOrGroupId = user.Id;
            proofShare.ParentId = proof.Id;
            proofShare.RowCause = Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c;
            proofShare.AccessLevel  = 'Edit';
            insert proofShare;
            List<SocialAd__c> proofAds = NXX2_TestUtility.createProofAd(new List<SocialCampaign__c>{proof});
            Test.stopTest();
            NXX2_FeedCommentTriggerHandler handler = new  NXX2_FeedCommentTriggerHandler();
            System.runAs(user){
                handler.AfterDelete(null);
                handler.AfterInsert(null);
                handler.AfterUndelete(null);
                handler.AfterUpdate(null, null);
                handler.BeforeDelete(null);
                FeedComment comment = NXX2_TestUtility.createFeedComment(proofAds[0].Id,'Test');
                comment.CommentBody = 'Change';
                update comment;
            }
        }
    }
}