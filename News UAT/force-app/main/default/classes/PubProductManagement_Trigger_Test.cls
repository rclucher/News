/**
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes and triggers.
 * test requirement R-0822
 * 29/08/2013  Bohao Chen  Created
 * 2015-12-14  Atul Gupta  Updated 
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    //   - PublicationProductManagement_Helper.cls - 98%
    //   - PublicationProductManagement.trigger    - 100%
 ---------------------------------------------------------*/
@isTest 
private class PubProductManagement_Trigger_Test 
{
    static testMethod void Test() 
    {       
        // create testing products
        List<Product2> productsBatchOne = TestDataFactory.createProducts(10);
        List<Product2> productsBatchTwo = TestDataFactory.createProducts(10);
        List<Product2> productsBatchThree = TestDataFactory.createProducts(10);
        
        //List<Pricebook2> pricebooks = TestDataFactory.createPricebookData();
        
        List<PricebookEntry> pricebookEntriesOne = TestDataFactory.createPricebookEntryData(null, null, productsBatchOne);
        List<PricebookEntry> pricebookEntriesTwo = TestDataFactory.createPricebookEntryData(null, null, productsBatchTwo);
        List<PricebookEntry> pricebookEntriesThree = TestDataFactory.createPricebookEntryData(null, null, productsBatchThree);
        
        
        // testing publications one
        List<String> publications1 = TestDataFactory.createStringList(10, 'pub');
        // testing publications two
        List<String> publications2 = TestDataFactory.createStringList(10, 'bup');
        
        // testing publication codes
        List<String> publicationCodes1 = TestDataFactory.createStringList(10, 'pubC');
        List<String> publicationCodes2 = TestDataFactory.createStringList(10, 'pubC');
            
            
        // testing ad types
        List<String> adTypes = TestDataFactory.createStringList(10, 'adType'); 

        system.debug('===adTypes=== ' + adTypes);
        
        Test.startTest();
        
        // Case 1: insert new mappings
        List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(productsBatchOne, publications1, publicationCodes1, adTypes);
        insert publicationProducts;
        
        String publicationsString1 = '';
        
        for(String s : publications1)
        {
            publicationsString1 += ';' + s;
        }
        
        String publicationsString2 = '';
        
        for(String s : publications2)
        {
            publicationsString2 += ';' + s;
        }
        
        system.debug('====BC: publicationsString1=== ' + publicationsString1);
        
        // verify that every product has correct publications
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchOne])
        {
            system.assertEquals(publicationsString1, p.PublicationList__c);
        }
        
        // Case 2: update existing mappings
        // Case 2.1: update products
        
        system.debug('===publicationProducts before 1=== ' + publicationProducts);
        
        Integer i = 0;
        Integer j = 0;
        for(Publication_Product__c pub : publicationProducts)
        {
            pub.Product__c = productsBatchTwo[j].Id;
            i++;
            
            if(i == 10)
            {
                i = 0;
                j++;
            }
        }
        
        update publicationProducts;
        
        system.debug('===publicationProducts after 1=== ' + publicationProducts);
        
        // verify that every product has correct publications
        // product batch two should copy all publications1 from product batch one
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchTwo])
        {
            system.assertEquals(publicationsString1, p.PublicationList__c);
        }
        
        // product batch one should have blank publication
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchOne])
        {
            system.assert(String.isBlank(p.PublicationList__c));
        }
        
        // Case 2.2: update publications1
        
        system.debug('===publicationProducts before 2=== ' + publicationProducts);
        
        i = 0;
        for(Publication_Product__c pub : publicationProducts)
        {
            pub.Publication__c = publications2[i++];
            
            if(i == 10)
            {
                i = 0;
            }
        }
        
        update publicationProducts;
        
        system.debug('===publicationProducts after 2=== ' + publicationProducts);
        
        // verify that every product has correct publications
        // product batch two should change from publicationsString1 to publicationsString2 for each product
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchTwo])
        {
            system.assertEquals(publicationsString2, p.PublicationList__c);
        }
        
        // Case 2.3: update both products and publications
        system.debug('===publicationProducts before 3=== ' + publicationProducts);
        
        i = j = 0;
        for(Publication_Product__c pub : publicationProducts)
        {
            pub.Product__c = productsBatchThree[j].Id;
            pub.Publication__c = publications1[i++];
            
            if(i == 10)
            {
                i = 0;
                j++;
            }
        }
        update publicationProducts;
        
        system.debug('===publicationProducts before 3=== ' + publicationProducts);
        
        // verify that every product has correct publications
        // product batch three should copy all publications1 from product batch two
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchThree])
        {
            system.assertEquals(publicationsString1, p.PublicationList__c);
        }
        
        
        // product batch two should have blank publication        
        for(Product2 p : [Select PublicationList__c from Product2 Where Id IN: productsBatchTwo])
        {
            system.assert(String.isBlank(p.PublicationList__c));
        }
        
        // Case 3: delete existingmappings
        delete publicationProducts;
        
        // verify that all products has no publications
        for(Product2 p : [Select PublicationList__c from Product2 Where 
                            Id IN: productsBatchOne OR
                            Id IN: productsBatchTwo OR
                            Id IN: productsBatchThree])
        {
            system.assert(String.isBlank(p.PublicationList__c));
        }
        
        Test.stopTest();
    }
}