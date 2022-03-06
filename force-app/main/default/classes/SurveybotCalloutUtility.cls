public without sharing class SurveybotCalloutUtility {

    // public String quoteId {get; set;}
    // public String billingId {get; set;}

    // public AvalaraCalloutUtility(String recordId) {

    // }
    public static String sendLeadIdToSurveybot(String leadId, String leadGUID) {

        String body = '{"LeadGuid":"' + leadGUID + '","SalesforceLeadId":"' + leadId + '"}';
        return calloutSurveybot('salesforcelead', body, 'POST');

    }

    public static String sendLeadStatusChangeToSurveybot(String leadId, String modifiedByEmail, String leadStatus) {

        String body = '{"SalesforceLeadId":"' + leadId + '","UpdatedByEmail":"' + modifiedByEmail + '","LeadState":"' + leadStatus + '"}';
        return calloutSurveybot('salesforcelead', body, 'PUT');

    }

    public static String sendEmailToLead(String leadGUID, String emailBody, String emailSubject, String senderEmail) {
        String body = '{"LeadGuid":"' + leadGUID + '","Body":"' + emailBody + '","Subject":"' + emailSubject + '","SenderEmail":"' + senderEmail + '"}';
        return calloutSurveybot('salesforceemail', body, 'POST');

    }

    public static String sendSMSToLead(String leadGUID, String emailBody, String senderEmail) {
        String body = '{"LeadGuid":"' + leadGUID + '","Body":"' + emailBody + '","SenderEmail":"' + senderEmail + '"}';
        return calloutSurveybot('salesforcesms', body, 'POST');

    }

    public static String sendBookedJobIdToSurveybot(String bookedJobId, String opportunityProductId) {

        String body = '{"SalesforceBookedJobId":"' + bookedJobId + '","SalesforceOpportunityProductId":"' + opportunityProductId + '"}';
        return calloutSurveybot('salesforcebookedjob', body, 'POST');

    }

    public static String sendNewOpportunityIdToSurveybot(String opportunityId, String leadId) {

        String body = '{"SalesforceLeadId":"' + leadId + '","SalesforceOpportunityId":"' + opportunityId + '"}';
        return calloutSurveybot('salesforceopportunity', body, 'POST');

    }

    public static String calloutSurveybot(String type, String body, String requestMethod) {

        HttpRequest req = new HttpRequest();
        List<Surveybot_Endpoint__mdt> endpoints = [SELECT Production_URL__c, Sandbox_URL__c, Auth_Key__c
            FROM Surveybot_Endpoint__mdt];
        if (endpoints.size() < 1) {
            return 'Endpoint metadata settings not found.';
        }

        Organization currentOrg = [SELECT IsSandbox from Organization LIMIT 1];

        if (currentOrg.IsSandbox) {
            req.setEndpoint(endpoints[0].Sandbox_URL__c + type);
        }
        else {
            req.setEndpoint(endpoints[0].Production_URL__c + type);
        }
        // req.setEndpoint('https://stage.api.shyftmoving.com/api/' + type);
        req.setMethod(requestMethod);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-AUTH', endpoints[0].Auth_Key__c);
        req.setBody(body);
        Http http = new Http();
    
        String responseString = '';

        HTTPResponse response;
        if (Test.isRunningTest()) {
            response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"example":"test"}');
            response.setStatusCode(200);
        }
        else {
            try {
            response = http.send(req);
            }
            catch(Exception e) {
                return e.getMessage();
            }
        }
        
        System.debug(JSON.deserializeUntyped(response.getBody()));
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            System.debug('RESPONSE BODY======' + response.getBody());
            responseString = String.valueOf(response.getBody());
        }
        else {
            responseString = String.valueOf(response.getBody());
        }

        return responseString;
    }
}