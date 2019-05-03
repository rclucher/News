/************************************************************************
/* class FeatureTriggerHandler_Test
/* description: test class for FeatureTriggerHandler
/* date: 13/02/2015
/* author: Noel Lim
/************************************************************************/
@isTest
private class FeatureTriggerHandler_Test {

    
    static testmethod void runTest(){

        TestDataFactory.createFeatureProdState();
         Map<String, Feature_Product_State__c> fpsCustomSetting = Feature_Product_State__c.getAll();
        System.assertEquals(fpsCustomSetting.size(), 2);

        Feature__c feat = TestDataFactory.createFeature();

        for(Feature__c tempF : [Select State__c From Feature__c
                         Where Id=:feat.Id LIMIT 1])
        {
            System.assertEquals('NSW', tempF.State__c);
        }

        //State does not change if it has a value
        feat.Product__c = 'Darwin Sun';
        update feat;
        for(Feature__c tempF : [Select State__c From Feature__c
                         Where Id=:feat.Id LIMIT 1])
        {
            System.assertEquals('NSW', tempF.State__c);
        }

        //State changes when set to empty
        feat.State__c = '';
        update feat;
        for(Feature__c tempF : [Select State__c From Feature__c
                         Where Id=:feat.Id LIMIT 1])
        {
            System.assertEquals('NT', tempF.State__c);
        }

    }

}