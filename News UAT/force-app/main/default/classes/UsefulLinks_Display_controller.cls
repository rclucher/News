//***********************************************************************************************************************
//*
//* Useful Links Display Controller
//* Created by: David Scullion
//* Created date: 2019-04-12
//*
//* Purpose - To allow the display of records from the Useful Links Objects on Lighting Home Pages
//*
//* Change Log
//*
//* Date       Change by                JIRA       Description
//* ---------------------------------------------------------------------------------------------------------------------
//*
//*

public class UsefulLinks_Display_controller {

    @AuraEnabled
    public static List <Useful_Link__c> getUsefulLinks(string HomePageRef) {
        List <Useful_Link__c> returnList = new List <Useful_Link__c>();
        If (HomePageRef == 'IMA_Home_Page_Enhanced_Sequence__c')
        {
            returnlist =  [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE IMA_Home_Page_Enhanced_Sequence__c != NULL ORDER BY IMA_Home_Page_Enhanced_Sequence__c ASC];
        } else if (HomePageRef == 'IMA_Home_Page_Manager_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE IMA_Home_Page_Manager_Sequence__c != NULL ORDER BY IMA_Home_Page_Manager_Sequence__c ASC];
        } else if (HomePageRef == 'KAC_Home_Page_Enhanced_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE KAC_Home_Page_Enhanced_Sequence__c != NULL ORDER BY KAC_Home_Page_Enhanced_Sequence__c ASC];
        } else if (HomePageRef == 'KAC_Home_Page_Manager_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE KAC_Home_Page_Manager_Sequence__c != NULL ORDER BY KAC_Home_Page_Manager_Sequence__c ASC];
        } else if (HomePageRef == 'Real_Estate_Home_Page_Manager_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE Real_Estate_Home_Page_Manager_Sequence__c != NULL ORDER BY Real_Estate_Home_Page_Manager_Sequence__c ASC];
        } else if (HomePageRef == 'SME_Home_Page_Enhanced_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE SME_Home_Page_Enhanced_Sequence__c != NULL ORDER BY SME_Home_Page_Enhanced_Sequence__c ASC];
        } else if (HomePageRef == 'SME_Home_Page_Enhanced_no_CPQ_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE SME_Home_Page_Enhanced_no_CPQ_Sequence__c != NULL ORDER BY SME_Home_Page_Enhanced_no_CPQ_Sequence__c ASC];
        } else if (HomePageRef == 'SME_Home_Page_Manager_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE SME_Home_Page_Manager_Sequence__c != NULL ORDER BY SME_Home_Page_Manager_Sequence__c ASC];
        } else if (HomePageRef == 'System_Administrator_Home_Page_Sequence__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE System_Administrator_Home_Page_Sequence__c != NULL ORDER BY System_Administrator_Home_Page_Sequence__c ASC];
        } else if (HomePageRef == 'The_Australian_Home_Page_Manager_Sequenc__c') {
            returnlist = [Select Useful_Link_Label__c, Useful_Link_URL__c FROM Useful_Link__c WHERE The_Australian_Home_Page_Manager_Sequenc__c != NULL ORDER BY The_Australian_Home_Page_Manager_Sequenc__c ASC];
        }
        return returnlist;
    }
}