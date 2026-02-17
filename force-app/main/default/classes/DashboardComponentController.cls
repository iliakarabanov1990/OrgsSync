public with sharing class DashboardComponentController {
   @AuraEnabled
    public static Map<String, Object> getCrossOrgData() {

		Rest_Settings__c restSettings = Rest_Settings__c.getOrgDefaults();
		String namedCred        = restSettings.Named_Credentials__c;
		String accountsReportId = restSettings.AccountsReportId__c;

		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:' + namedCred + '/services/data/v65.0/analytics/reports/' + accountsReportId);
		req.setMethod('GET');
		Http http = new Http();
		HttpResponse res = http.send(req);

		if(res.getStatusCode() == 200){
			Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			return data;
		} else {
			throw new AuraHandledException('Error receiving report: ' + res.getBody());
		}
	}
}