@isTest(seeAllData=false)
public class MediaDemoIssuePickerPluginImplTest {
    
     @isTest 
    public static void issueTest() {
        Test.startTest();
        MediaDemoIssuePickerPluginImpl mdipiclass = new MediaDemoIssuePickerPluginImpl();
        String getIssue;
        String dispVal;
        
        mdipiclass.getIssuesJSON(getIssue);
        mdipiclass.displayValue(dispVal);
        mdipiclass.displayDateValue(Date.today());   
        Test.stopTest();
    }

}