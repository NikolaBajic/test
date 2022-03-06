@isTest
public with sharing class SurveybotCalloutsTest {

    @isTest
    public static void testCallouts() {

        EDHU.TriggerPanel.setBreaker('Lead', true);
        EDHU.TriggerPanel.setBreaker('BookedJob', true);

        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'Lead';
        l.Company = 'Testing';
        l.SurveyBot_GUID__c = 'surveybot';
        l.OwnerId = UserInfo.getUserId();

        insert l;

        l.SurveyBot_GUID__c = 'surveybot2';

        update l;

        l.Attempts__c = 1;

        update l;

        LeadStatus nextStatus = [SELECT Id, MasterLabel, ApiName FROM LeadStatus WHERE IsConverted=false AND IsDefault=false LIMIT 1];
        l.Status = nextStatus.ApiName;

        update l;

        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.Id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.ApiName);

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        Transferee_Job__c tj = new Transferee_Job__c();
        tj.Name = 'Test';
        insert tj;

        Booked_Job__c j = new Booked_Job__c();
        j.Name = 'Test';
        j.Transferee_Job__c = tj.Id;

        insert j;
    }
}