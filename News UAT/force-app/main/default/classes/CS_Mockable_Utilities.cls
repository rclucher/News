/*------------------------------------------------------------
Author:         Mike Jupp
Company:        CloudSense
Description:    HTTP mock callouts for test classes
History
<Date>      <Authors Name>      <Brief Description of Change>
Sep 18      Mike Jupp           Created
Oct 30      Dave Scullion       Update endpoint with proper url    
------------------------------------------------------------*/
@isTest
public class CS_Mockable_Utilities implements HttpCalloutMock
{
    public HTTPResponse respond(HTTPRequest req)
    {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        
        // GeoNames
        //if (req.getEndpoint().startsWithIgnoreCase('http://api.geonames.org/findNearbyPostalCodesJSON'))
        if (req.getEndpoint().startsWithIgnoreCase('http://ba-ws.geonames.net/findNearbyPostalCodesJSON'))
        {
//          res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            CS_GeoNames_Utilities.postalCodeWrapper postalCodeWrapper = new CS_GeoNames_Utilities.postalCodeWrapper();

            CS_GeoNames_Utilities.postalCodeData postalCodeData1 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData1.postalCode  = '2113';
            postalCodeData1.placeName   = 'North Ryde';
            postalCodeWrapper.postalcodes.add(postalCodeData1);
            
            CS_GeoNames_Utilities.postalCodeData postalCodeData2 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData2.postalCode  = '2112';
            postalCodeData2.placeName   = 'Denistone East';
            postalCodeWrapper.postalcodes.add(postalCodeData2);

            CS_GeoNames_Utilities.postalCodeData postalCodeData3 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData3.postalCode  = '2111';
            postalCodeData3.placeName   = 'Gladesville';
            postalCodeWrapper.postalcodes.add(postalCodeData3);

            // Include data for private bags / post bags
            /*
            State/Territory Abbreviation    LVRs and PO Box Postcode range
            New South Wales                 1000—1999
            Australian Capital Territory    0200—0299
            Victoria                        8000—8999
            Queensland                      9000—9999
            South Australia                 5800—5999
            Western Australia               6800—6999
            Tasmania                        7800—7999
            Northern Territory              0900—0999
            */

            CS_GeoNames_Utilities.postalCodeData postalCodeData101 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData101.postalCode    = '1000';
            postalCodeData101.placeName = 'NSW start';
            postalCodeWrapper.postalcodes.add(postalCodeData101);

            CS_GeoNames_Utilities.postalCodeData postalCodeData102 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData102.postalCode    = '1999';
            postalCodeData102.placeName = 'NSW end';
            postalCodeWrapper.postalcodes.add(postalCodeData102);

            CS_GeoNames_Utilities.postalCodeData postalCodeData103 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData103.postalCode    = '200';
            postalCodeData103.placeName = 'ACT start';
            postalCodeWrapper.postalcodes.add(postalCodeData103);

            CS_GeoNames_Utilities.postalCodeData postalCodeData104 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData104.postalCode    = '299';
            postalCodeData104.placeName = 'ACT end';
            postalCodeWrapper.postalcodes.add(postalCodeData104);

            CS_GeoNames_Utilities.postalCodeData postalCodeData105 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData105.postalCode    = '8000';
            postalCodeData105.placeName = 'VIC start';
            postalCodeWrapper.postalcodes.add(postalCodeData105);

            CS_GeoNames_Utilities.postalCodeData postalCodeData106 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData106.postalCode    = '8999';
            postalCodeData106.placeName = 'VIC end';
            postalCodeWrapper.postalcodes.add(postalCodeData106);
            CS_GeoNames_Utilities.postalCodeData postalCodeData107 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData107.postalCode    = '9000';
            postalCodeData107.placeName = 'QLD start';
            postalCodeWrapper.postalcodes.add(postalCodeData107);

            CS_GeoNames_Utilities.postalCodeData postalCodeData108 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData108.postalCode    = '9999';
            postalCodeData108.placeName = 'QLD end';
            postalCodeWrapper.postalcodes.add(postalCodeData108);

            CS_GeoNames_Utilities.postalCodeData postalCodeData109 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData109.postalCode    = '5800';
            postalCodeData109.placeName = 'SA start';
            postalCodeWrapper.postalcodes.add(postalCodeData109);

            CS_GeoNames_Utilities.postalCodeData postalCodeData110 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData110.postalCode    = '5999';
            postalCodeData110.placeName = 'SA end';
            postalCodeWrapper.postalcodes.add(postalCodeData110);

            CS_GeoNames_Utilities.postalCodeData postalCodeData111 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData111.postalCode    = '6800';
            postalCodeData111.placeName = 'WA start';
            postalCodeWrapper.postalcodes.add(postalCodeData111);

            CS_GeoNames_Utilities.postalCodeData postalCodeData112 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData112.postalCode    = '6999';
            postalCodeData112.placeName = 'WA end';
            postalCodeWrapper.postalcodes.add(postalCodeData112);

            CS_GeoNames_Utilities.postalCodeData postalCodeData113 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData113.postalCode    = '7800';
            postalCodeData113.placeName = 'TAS start';
            postalCodeWrapper.postalcodes.add(postalCodeData113);

            CS_GeoNames_Utilities.postalCodeData postalCodeData114 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData114.postalCode    = '7999';
            postalCodeData114.placeName = 'TAS end';
            postalCodeWrapper.postalcodes.add(postalCodeData114);

            CS_GeoNames_Utilities.postalCodeData postalCodeData115 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData115.postalCode    = '900';
            postalCodeData115.placeName = 'NT start';
            postalCodeWrapper.postalcodes.add(postalCodeData115);

            CS_GeoNames_Utilities.postalCodeData postalCodeData116 = new CS_GeoNames_Utilities.postalCodeData();
            postalCodeData116.postalCode    = '999';
            postalCodeData116.placeName = 'NT end';
            postalCodeWrapper.postalcodes.add(postalCodeData116);

            res.setBody(JSON.serialize(postalCodeWrapper));
        }
        // Add more callouts here

        return res;
    }
    
}