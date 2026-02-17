@isTest
private class RestServiceTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'Test Account');
    }

    @isTest
    static void testGetRecords() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('object', 'Account');
        req.addParameter('fields', 'Name,Id');
        req.addParameter('limit', '10');
        req.addParameter('offset', '0');
        req.addParameter('groupBy', 'Name');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        List<SObject> result = RestService.getRecords();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Should return list');
    }

    @isTest
    static void testGetRecordsMissingObject() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('groupBy', 'Name');
        req.addParameter('fields', 'Name,Id');
        req.addParameter('limit', '10');
        req.addParameter('offset', '0');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            RestService.getRecords();
            System.assert(false, 'Should throw when object is missing');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Missing') || e.getMessage().contains('object'), 'Expected missing param error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRecordsMissingGroupBy() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('object', 'Account');
        req.addParameter('fields', 'Name,Id');
        req.addParameter('limit', '10');
        req.addParameter('offset', '0');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            RestService.getRecords();
            System.assert(false, 'Should throw when groupBy is missing');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Missing') || e.getMessage().contains('groupBy'), 'Expected missing groupBy error');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateRecords() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('object', 'Account');
        req.requestBody = Blob.valueOf('[{"Name":"Created From Rest"}]');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        List<SObject> result = RestService.createRecords();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one record');
        System.assertNotEquals(null, result[0].Id, 'Record should be inserted with Id');
    }

    @isTest
    static void testUpdateRecords() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('object', 'Account');
        req.requestBody = Blob.valueOf('[{"Id":"' + acc.Id + '","Name":"Updated Name"}]');
        req.httpMethod = 'PATCH';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        List<SObject> result = RestService.updateRecords();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one record');
        System.assertEquals('Updated Name', [SELECT Name FROM Account WHERE Id = :acc.Id].Name, 'Name should be updated');
    }

    @isTest
    static void testDeleteRecord() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.addParameter('object', 'Account');
        req.addParameter('Id', acc.Id);
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        List<SObject> result = RestService.deleteRecord();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return deleted record');
        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, remaining.size(), 'Account should be deleted');
    }

    @isTest
    static void testCreateRecordsMissingObject() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/Objects/';
        req.httpMethod = 'POST';
        req.addParameter('other', 'value'); // ensure params map exists but 'object' is missing
        req.requestBody = Blob.valueOf('[{"Name":"X"}]');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            RestService.createRecords();
            System.assert(false, 'Should throw when object param is missing');
        } catch (Exception e) {
            String msg = e.getMessage();
            System.assert(
                String.isNotBlank(msg) && (msg.contains('Missing') || msg.contains('object') || msg.contains('parameter')),
                'Expected error about missing object: ' + msg
            );
        }
        Test.stopTest();
    }
}
