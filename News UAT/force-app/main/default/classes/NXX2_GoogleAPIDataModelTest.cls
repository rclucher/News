@isTest
public class NXX2_GoogleAPIDataModelTest{
    public static testMethod void testContants() {
        Test.startTest();
        NXX2_GoogleAPIDataModel.ParentRequestClass parentRequest = new NXX2_GoogleAPIDataModel.ParentRequestClass();
        parentRequest.id = 'Test';
        NXX2_GoogleAPIDataModel.FolderRequestClass folderRequest = new NXX2_GoogleAPIDataModel.FolderRequestClass();
        folderRequest.title = 'Test';
        folderRequest.mimeType = 'Test';
        folderRequest.parents = new List<NXX2_GoogleAPIDataModel.ParentRequestClass>();
        NXX2_GoogleAPIDataModel.Permissions permission = new NXX2_GoogleAPIDataModel.Permissions();
        permission.role = 'Test';
        permission.type = 'Test';
        NXX2_GoogleAPIDataModel.FileRequestClass fileRequest = new NXX2_GoogleAPIDataModel.FileRequestClass();
        fileRequest.title = 'Test';
        fileRequest.mimeType = 'Test';
        fileRequest.parents = new List<NXX2_GoogleAPIDataModel.ParentRequestClass>();
        NXX2_GoogleAPIDataModel.FileRequestForChunkRequestClass fileRequestChunk = new NXX2_GoogleAPIDataModel.FileRequestForChunkRequestClass();
        fileRequestChunk.name = 'Test';
        fileRequestChunk.mimeType = 'Test';
        fileRequestChunk.parents = new List<String>();
        NXX2_GoogleAPIDataModel.GoogleDriveFilesDTO fileDto = new NXX2_GoogleAPIDataModel.GoogleDriveFilesDTO();
        fileDto.id = 'Test';
        fileDto.thumbnailLink = 'Test';
        fileDto.title = 'Test';
        fileDto.createdDate = 'Test';
        fileDto.downloadUrl = 'Test';
        fileDto.mimeType = 'Test';
        fileDto.displayUrl = 'Test';
        fileDto.embedLink = 'Test';
        Test.stopTest();
    }
}