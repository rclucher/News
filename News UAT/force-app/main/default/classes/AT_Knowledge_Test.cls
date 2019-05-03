@isTest
public class AT_Knowledge_Test {
    @testSetup
    static void init() {
        List<Knowledge__kav> knowledge = new List<Knowledge__kav>();
        
        knowledge.add(new Knowledge__kav(
            Title = 'test1',
            UrlName = 'test1',
            Summary = 'test1',
            External_Link__c = 'test1',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Document'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test2',
            UrlName = 'test2',
            Summary = 'test2',
            External_Link__c = 'test2',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Spreadsheet'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test3',
            UrlName = 'test3',
            Summary = 'test3',
            External_Link__c = 'test3',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Presentation'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test4',
            UrlName = 'test4',
            Summary = 'test4',
            External_Link__c = 'test4',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Image'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test5',
            UrlName = 'test5',
            Summary = 'test5',
            External_Link__c = 'test5',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Video'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test6',
            UrlName = 'test6',
            Summary = 'test6',
            External_Link__c = 'test6',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = 'Other'
        ));
        
        knowledge.add(new Knowledge__kav(
            Title = 'test7',
            UrlName = 'test7',
            Summary = 'test7',
            External_Link__c = 'test7',
            Page__c = 'Home',
            Content_Type__c = 'Knowledge',
            Icon__c = ''
        ));
        
        insert knowledge;
        
        List<Knowledge__ka> articles = [SELECT Id FROM Knowledge__ka];
        
        for (Knowledge__ka article: articles) {
        	KbManagement.PublishingService.publishArticle(article.Id, true);
        } 
    }
    
    @isTest
    static void testKnowledge() {
        AT_Knowledge.KnowledgeResults results = AT_Knowledge.queryKnowledge('Home', 'Content_Type__c', 'Knowledge');
        
       	System.assertEquals(7, results.articles.size());
        System.assertEquals('Knowledge', results.contentTypes[0]);
    }
}