/**
* @author       Kamal Sharma
* @date         2018-08-17
* @className	NXX2_GoogleDriveAPIMockUp
* @description  This class will be used for mocking of google drive API during testing.
*/
global class NXX2_GoogleDriveAPIMockUp implements HttpCalloutMock {
    /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  This method provides mock response for google drive rest API call dusring testing.
    * @param        HttpRequest req
    * @return       HttpResponse
    */
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        //Default Response
        String body = '{"id" : "Test", "thumbnailLink" : "Test"}';
        if(req.getMethod().contains('DELETE')) {
            //Response For Delete
            body = '{"id" : "Test", "thumbnailLink" : "Test"}';
        }else if(req.getMethod().contains('PUT')) {
            //Response For uploading file in chunk
            body = '{"id" : "Test", "thumbnailLink" : "Test"}';
        }else if(req.getEndpoint().contains('copy')) {
            //Response For PATCH
            body = '{"id" : "Test", "name" : "Test"}';
        }else if(req.getEndpoint().contains('/drive/v3/files/generateIds')) {
            //Response For generating ID
            body = '{"ids" : ["Test"]}';
        }else if(req.getEndpoint().contains('/drive/v2/files?corpus=DEFAULT')) {
            //Response For retrieving files inside a folder
            body = '{"items" : [{"id" : "Test"}]}';
        }else if(req.getEndpoint().contains('/drive/v2/files?corpora=teamDrive')) {
            //Response For retrieving files inside a folder under teamdrive
            body = '{"items" : [{"id" : "Test"}]}';
        }else if(req.getEndpoint().contains('/drive/v3/files?includeTeamDriveItems=true')) {
            //Response For verifying if folder exist or not
            body = '{"files" : [{"id" : "Test"}]}';
        }else if(req.getEndpoint().contains('/upload/drive/v3/files?uploadType=resumable')) {
            //Response For resumable file upload
            res.setHeader('Location','Test');
        }else if(req.getEndpoint().contains('upload')) {
            //Response For uploading file in single go
            body = '{"id" : "Test", "thumbnailLink" : "Test"}';
        }else if(req.getEndpoint().contains('/drive/v2/files') && req.getMethod().contains('POST')) {
            //Response For creating folder
            body = '{"id" : "Test", "thumbnailLink" : "Test"}';
        }
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}