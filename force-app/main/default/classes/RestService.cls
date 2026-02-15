@RestResource(urlMapping='/Objects/*')
global with sharing class RestService {

	@HttpGet
	global static List<sObject> getRecords() {
		try {
			RestRequest request = RestContext.request;
			Map<String, String> requestParams = request.params;

			String objectParam = String.escapeSingleQuotes(requestParams.get('object'));
			if (String.isBlank(objectParam)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: object');
			}

			String fieldsParam = requestParams.get('fields');
			fieldsParam        = fieldsParam.replaceAll('[^a-zA-Z0-9_,]', '');

			String limitStr     = String.escapeSingleQuotes(requestParams.get('limit'));
			String offsetStr    = String.escapeSingleQuotes(requestParams.get('offset'));
			String groupBy      = String.escapeSingleQuotes(requestParams.get('groupBy'));
			String searchString = String.escapeSingleQuotes(requestParams.get('searchString'));

			if (String.isBlank(groupBy)) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Missing query parameter: groupBy');
			}

			Integer limitParam  = String.isBlank(limitStr) ? 50000 : Integer.valueOf(limitStr);
			Integer offsetParam = String.isBlank(offsetStr) ? null : Integer.valueOf(offsetStr);

			if (offsetParam == null || offsetParam > 2000) {
				offsetParam = 0;
			}

			if (String.isNotBlank(searchString)) {
				String soslQuery =
				'FIND :searchString '      +
				'IN ALL FIELDS RETURNING ' +
				objectParam                + '(' + fieldsParam +
				' ORDER BY ' + groupBy     +
				' LIMIT :limitParam '      +
				'OFFSET :offsetParam)';

				List<List<sObject>> searchResults = Search.query(soslQuery, AccessLevel.USER_MODE);

				if (searchResults.size() == 0) { return new List<sObject>(); }

				return searchResults[0];
			}

			return Database.queryWithBinds (
				'SELECT '            + fieldsParam +
				' FROM '             + objectParam +
				' ORDER BY '         + groupBy     +
				' LIMIT :limitParam' +
				' OFFSET :offsetParam',
				new Map<String, Object>{ 'limitParam' => limitParam, 'offsetParam' => offsetParam },
				AccessLevel.USER_MODE
			);
		} catch(Exception e){
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpPost
	global static List<SObject> createRecords() {
		try {
			List<SObject> records = getRecordToUpsert();

			Database.insert(records, true, AccessLevel.USER_MODE);
			return records;
		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpPatch
	global static List<SObject> updateRecords() {
		try {
			List<SObject> records = getRecordToUpsert();
			Database.update(records, true, AccessLevel.USER_MODE);
			return records;
		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	@HttpDelete
	global static List<sObject> deleteRecord() {
		try {
			String recordId    = String.escapeSingleQuotes(RestContext.request.params.get('Id'));
			String objectParam = String.escapeSingleQuotes(RestContext.request.params.get('object'));

			List<sObject> records = Database.queryWithBinds (
				'SELECT Name, Id'        +
				' FROM '                 + objectParam +
				' WHERE Id = :recordId',
				new Map<String, Object>{ 'recordId' => recordId },
				AccessLevel.USER_MODE
			);

			if(records.size() == 0) {
				RestContext.response.statusCode = 400;
				throw new RestServiceException('Record with ID ' + recordId + ' is not exist!');
			}
			Database.delete(records[0], true, AccessLevel.USER_MODE);

			return records;

		} catch (Exception e) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException(e.getMessage());
		}
	}

	global static List<SObject> getRecordToUpsert() {

		RestRequest request   = RestContext.request;
		String objectTypeName = String.escapeSingleQuotes(request.params.get('object'));
		if (String.isBlank(objectTypeName)) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('Missing query parameter: object');
		}

		SObjectType token = Schema.getGlobalDescribe().get(objectTypeName);
		if (token == null) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('Invalid object: ' + objectTypeName);
		}

		List<Object> rawList  = (List<Object>)JSON.deserializeUntyped(request.requestBody.toString());
		List<sObject> records = new List<sObject>();

		for (Object item : rawList) {
			Map<String, Object> itemMap = (Map<String, Object>)item;
			sObject record = token.newSObject();
			for (String key : itemMap.keySet()) {
				Object val = Utils.valueForField(token, key, itemMap.get(key));
				if (val != null) {
					record.put(key, val);
				}
			}
			records.add(record);
		}

		if (records.size() == 0) {
			RestContext.response.statusCode = 400;
			throw new RestServiceException('No records to operate');
		}

		return records;
	}

	private class RestServiceException extends Exception {}
}