public with sharing class RestManagerController {

	@AuraEnabled
	public static Map<String, Object> getInitialData() {

		Rest_Settings__c restSettings = Rest_Settings__c.getOrgDefaults();

		String objectsStr = restSettings.Objects__c;
		List<String> objectNames = String.isBlank(objectsStr) ? new List<String>{'Account'} : objectsStr.split(', ');

		Map<String, Map<String, Set<String>>> fieldsInfo = new Map<String, Map<String, Set<String>>>();
		for (String objectName : objectNames) {
			Set<String> formFields = getFieldSetFields(objectName, 'Record_Form');
			Set<String> listFields = getFieldSetFields(objectName, 'List');
			fieldsInfo.put(objectName, new Map<String, Set<String>> {
				'formFields' => formFields,
				'listFields' => listFields
			});
		}

		return new Map<String, Object> {
			'fieldsInfo'  => fieldsInfo,
			'namedCred'   => restSettings.Named_Credentials__c,
			'objectsList' => objectNames
		};
	}

	@AuraEnabled
	public static Map<String, Object> sendRequast(String method, Map<String, String> paramsMap, String body, String namedCred) {
		HttpResponse response = sendRequestToRestService(method, paramsMap, body, namedCred);
		return operateResponse(response, paramsMap.get('object'));
	}

	private static HttpResponse sendRequestToRestService(String method, Map<String, String> paramsMap, String body, String namedCred){

		HttpRequest request = new HttpRequest();
		String params       = '';

		if (String.isNotBlank(body)) { request.setBody(body); }

		for (String key : paramsMap.keySet()) {
			params += key + '=' + paramsMap.get(key) + '&';
		}
		if (paramsMap.size() > 0) {
			params = '?' + params.left(params.length() - 1);
		}

		request.setEndpoint('callout:' + namedCred + '/services/apexrest/Objects' + params);
		request.setHeader('Content-type', 'application/json; charset=UTF-8');
		request.setHeader('Accept',       'application/json');
		request.setMethod(method);

		return new Http().send(request);
	}

	private static Map<String, Object> operateResponse(HttpResponse response, String objectTypeName) {

		Map<String, Object> result = new Map<String, Object>{'status'=>'', 'body'=>''};
		SObjectType token = Schema.getGlobalDescribe().get(objectTypeName);
		if (token == null) {
			result.put('body', 'Invalid object: ' + objectTypeName);
			return result;
		}

		result.put('status', response.getStatusCode().toString());
		if (result.get('status') != '200') {
			result.put('body', response.getBody());
			return result;
		}

		List<Object> rawList  = (List<Object>)JSON.deserializeUntyped((String)response.getBody());
		List<sObject> records = new List<sObject>();

		for (Object item : rawList) {
			Map<String, Object> itemMap = (Map<String, Object>)item;
			sObject record = token.newSObject();
			for (String key : itemMap.keySet()) {
				if (key == 'attributes') { continue; }
				Object val = Utils.valueForField(token, key, itemMap.get(key));
				if (val != null) {
					record.put(key, val);
				}
			}
			records.add(record);
		}
		result.put('body', records);

		return result;
	}

	private static Set<String> getFieldSetFields(String objectName, String fieldSetName) {
		Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
		if (objType == null) {
			throw new IllegalArgumentException('Object not found: ' + objectName);
		}

		Schema.DescribeSObjectResult describeResult = objType.getDescribe();
		Schema.FieldSet fieldSet = describeResult.fieldSets.getMap().get(fieldSetName);
		if (fieldSet == null) {
			throw new IllegalArgumentException('FieldSet not found: ' + fieldSetName + ' on object ' + objectName);
		}

		return Utils.getFieldSetFields(fieldSet);
	}
}