/******************************************************************************
// File Name:       RecapEmailRestHandlerTests.cls
// Details:         The Apex tests class for RecapEmailRestHandler.cls
====================
// Modification Log: (Name - Change Summary - Initial)
// Roman Bulgakov    - 23/09/2020 - created
*******************************************************************************/

@IsTest
public class RecapEmailRestHandlerTests 
{
    @IsTest static void run() 
    {
    	Account accountRecord = new Account();
        accountRecord.RecordTypeId = [select Id from RecordType where Name = 'Partners' and SObjectType = 'Account'].Id;
        accountRecord.Name = 'Test Account';
        accountRecord.Referral_Type__c = 'Roommates';
        accountRecord.Account_Status__c = 'Active';
        accountRecord.Recap_Email__c = true;
        accountRecord.Lifestyle_Partnership__c = true;
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
        
        new RecapEmailRestHandler().call(null, new Map<String, Object>{
        	'recordId' => opportunityRecord.Id,
        	'services' => new List<String>{accountRecord.Id}
        });
       
        new RecapEmailRestHandler().call(null, new Map<String, Object>{
        	'recordId' => leadRecord.Id,
        	'services' => new List<String>{accountRecord.Id}
        });
    }
}