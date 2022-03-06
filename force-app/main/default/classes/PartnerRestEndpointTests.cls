/******************************************************************************
// File Name:       PartnerRestEndpointTests.cls
// Details:         The Apex tests class for PartnerRestEndpoint.cls
====================
// Modification Log: (Name - Change Summary - Initial)
// Roman Bulgakov    - 23/09/2020 - created
*******************************************************************************/

@IsTest
public class PartnerRestEndpointTests 
{
    @IsTest static void run() 
    {
    	Account accountRecord = new Account();
        accountRecord.RecordTypeId = [select Id from RecordType where Name = 'Partners' and SObjectType = 'Account'].Id;
        accountRecord.Name = 'Test Account';
        accountRecord.Referral_Type__c = 'Roommates';
        accountRecord.Account_Status__c = 'Active';
        accountRecord.Recap_Email__c = true;
        insert accountRecord;
        
        Contact contactRecord = new Contact();
        contactRecord.LastName = 'Test Contact';
        contactRecord.AccountId = accountRecord.Id;
        insert contactRecord;
		
		Opportunity opportunityRecord = new Opportunity();
        opportunityRecord.Name = 'Test';
        opportunityRecord.AccountId = accountRecord.Id;
        opportunityRecord.Primary_Contact__c = contactRecord.Id;
        opportunityRecord.StageName = 'Draft';
        opportunityRecord.CloseDate = Date.today().addDays(1);
        insert opportunityRecord;
        
        Lead leadRecord = new Lead();
        leadRecord.LastName = 'l1';
        leadRecord.Status = 'New';
        leadRecord.Company = 'Test';
        leadRecord.CurrencyIsoCode = 'USD';
        leadRecord.SurveyBot_GUID__c = '12345';
        insert leadRecord;
        
        RestContext.request = new System.RestRequest();
        RestContext.response = new System.RestResponse();
        
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
        	'type' => 'recap_email',
        	'data' => new Map<String, Object>{
	        	'recordId' => opportunityRecord.Id,
	        	'servicesIds' => null
	        }
        }));
        
        PartnerRestEndpoint.postHandler();
    }
}