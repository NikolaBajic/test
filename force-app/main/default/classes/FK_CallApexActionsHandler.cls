/******************************************************************************
// Details:      The class handler for Flexi Kanban Call Apex actions
// Test Classes:    FK_CallApexActionsHandlerTests
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/10/2020 - created
*******************************************************************************/

public with sharing class FK_CallApexActionsHandler implements FLX_KB.KanBanInterfaces.CallApexActionInterface, FLX_KB.KanBanInterfaces.LoggerInterface
{
    public Object executeCallApex(FLX_KB__KanBan_History__c history, sObject record, Object parameters)
    {
        ID recordId = getRecordId(history);
        if(recordId.getSObjectType() == Opportunity.getSObjectType()) sendToOpportunity(recordId, parameters);
        else if(recordId.getSObjectType() == Lead.getSObjectType()) sendToLead(recordId, parameters);
        
        return null;
    }
    
    public void log(String info)
    {
        System.debug(info);
    }
    
    private ID getRecordId(FLX_KB__KanBan_History__c history)
    {
        Map<String, Object> variables = (Map<String, Object>)JSON.deserializeUntyped(history.FLX_KB__Variables__c);
        return (ID)variables.get('sourceId');
    }
    
    private void sendToOpportunity(ID recordId, Object parameters)
    {
        Opportunity opportunityRecord = [select SurveyBot_GUID__c, Primary_Contact__r.Email from Opportunity where Id = :recordId];
        Organization currentOrg = [select IsSandbox from Organization limit 1];
        
        Map<String, Object> params = new Map<String, Object>{
            'LeadGuid' => (currentOrg.IsSandbox ? 'e7381372-b3b3-4659-bdeb-2eb74f57efa9' : opportunityRecord.SurveyBot_GUID__c),
            'Body' => (String)parameters,
            'Subject' => 'Your Needs Assessment Recap', 
            'SenderEmail' => (currentOrg.IsSandbox ? 'elise.r@shyftmoving.com' : UserInfo.getUserEmail()),
            'TriggerName' => 'recap_email',
            'ToEmails' => (currentOrg.IsSandbox ? new List<String> {'elise.r@shyftmoving.com'} : new List<String> {opportunityRecord.Primary_Contact__r.Email})
        };

        SurveybotCalloutUtility.calloutSurveybot('salesforceemail', JSON.serialize(params), 'POST');
    }
    
    private void sendToLead(ID recordId, Object parameters)
    {
        Lead leadRecord = [select SurveyBot_GUID__c, Email from Lead where Id = :recordId];
        Organization currentOrg = [select IsSandbox from Organization limit 1];
        
        Map<String, Object> params = new Map<String, Object>{
            'LeadGuid' => (currentOrg.IsSandbox ? 'e7381372-b3b3-4659-bdeb-2eb74f57efa9' : leadRecord.SurveyBot_GUID__c),
            'Body' => (String)parameters,
            'Subject' => 'Your Needs Assessment Recap', 
            'SenderEmail' => (currentOrg.IsSandbox ? 'elise.r@shyftmoving.com' : UserInfo.getUserEmail()),
            'TriggerName' => 'recap_email',
            'ToEmails' => (currentOrg.IsSandbox ? new List<String> {'elise.r@shyftmoving.com'} : new List<String> {leadRecord.Email})
        };

        SurveybotCalloutUtility.calloutSurveybot('salesforceemail', JSON.serialize(params), 'POST');
    }
}