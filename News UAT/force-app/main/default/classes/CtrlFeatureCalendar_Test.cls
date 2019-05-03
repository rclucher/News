/************************************************************************
/* class CtrlFeatureCalendar_Test
/* description: test class for Controller CtrlFeatureCalendar
/* date: 13/02/2015
/* author: Noel Lim
/************************************************************************/
@isTest
public class CtrlFeatureCalendar_Test {

    
    static testmethod void runTest(){

        TestDataFactory.createFeatureCategoryColour();
        Feature__c feat = TestDataFactory.createFeature();
        

        PageReference pageRef = Page.FeatureCalendar;
        Test.setCurrentPage(pageRef);

        //Test.startTest();

        CtrlFeatureCalendar controller = new CtrlFeatureCalendar();


        List<SelectOption> sso = controller.getSectionFilterOptions();
        System.assert(sso.size() > 0);

        List<SelectOption> pso = controller.getProductFilterOptions();
        System.assert(pso.size() > 0);
        
        Map<String, String> categoryColours = controller.categoryColours;
        System.assert(categoryColours.size() > 0);

        //Test Core Date query works
        String remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), '', '', '', '', '', '{}');
        List<Object> mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);

        //Test Filter Name
        remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), 'Test Feature', '', '', '', '', '{}');
        mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);

        //Test Filter Product
        remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), '', 'The Daily Telegraph', '', '', '', '{}');
        mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);

        //Test Filter Section in Product
        remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), '', '', 'Home', '', '', '{}');
        mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);


        //Test Filter Date
        remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), '', '', '', String.valueOf(Date.today()), String.valueOf(Date.today()), '{}');
        mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);

        //Test Checkbox Filter
        String jsonCheckboxFilter = '{\"Category\":{\"Real Estate\":true}}';
         remoteResponse = CtrlFeatureCalendar.getJSONFeatures( 
            String.valueOf(Date.today()), String.valueOf(Date.today()), '', '', '', '', '', jsonCheckboxFilter);
        mapDeserializedFeatures = (List<Object>) JSON.deserializeUntyped(remoteResponse);
        System.assert(mapDeserializedFeatures.size() == 1);

    }


    




}