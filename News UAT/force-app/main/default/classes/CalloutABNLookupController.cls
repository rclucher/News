/************************************************************************
/* class CalloutABNLookupController
/* description: controller dor CalloutABNLookup visualforce page
/* Company: Salesforce.com
/* date: 24/05/2013
/* author: Celso de Souza
/************************************************************************/
public without sharing class CalloutABNLookupController {

    public string abnQuery
    {
        get
        {
            if(ApexPages.currentPage().getParameters().get('abn')!=null &&
                abnQuery==null)
            {
                abnQuery = ApexPages.currentPage().getParameters().get('abn');
            }
            return abnQuery;
        }
        set;
    }

    private ABNLookupStub.AustralianBusinessNumber abnResponse;
    public  ABNLookupStub.AustralianBusinessNumber abn {get{return abnResponse;}}



    public void doABNLookup()
    {
        abnResponse = ABNLookupStub.ABRSearchByABN(abnQuery);

        if(abnResponse.isInvalid!=null && abnResponse.isInvalid)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, abnQuery + 'is not a valid ABN'));
        }

        SYSTEM.debug('### abnResponse:' + abnResponse);
        //PageReference pr = ApexPages.currentPage();
        //pr.getParameters().put('abn', abnQuery);
        //return pr;
    }
}