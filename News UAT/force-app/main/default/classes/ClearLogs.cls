public class ClearLogs {
    public static void run() {
        Http h = new Http();

         // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://newscorpaustralia--adsalesuat.cs31.my.salesforce.com/');
        req.setMethod('GET');
    
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        
    }
}