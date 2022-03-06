/******************************************************************************
// Details:         The test class for the class FK_CallApexActionsHandler
====================
// Modification Log: (Name - When - Change Summary)
// Roman Bulgakov - 08/10/2020 - created.
*******************************************************************************/

@isTest
public with sharing class FK_CallApexActionsHandlerTests {
     public static testMethod void run(){
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
        
     	new FK_CallApexActionsHandler().executeCallApex(new FLX_KB__KanBan_History__c(FLX_KB__Variables__c='{"sourceId":"' + opportunityRecord.Id + '"}'), null, 'Test');
     	new FK_CallApexActionsHandler().executeCallApex(new FLX_KB__KanBan_History__c(FLX_KB__Variables__c='{"sourceId":"' + leadRecord.Id + '"}'), null, 'Test');
     }
}