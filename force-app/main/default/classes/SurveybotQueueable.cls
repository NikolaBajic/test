public without sharing class SurveybotQueueable implements Queueable, Database.AllowsCallouts {
    public List<Lead> leads {get; set;}
    public List<Opportunity> opportunities {get; set;}
    public List<Booked_Job__c> bookedJobs {get; set;}
    public String action {get; set;}

    public SurveybotQueueable(String leadAction, List<Lead> leadList) {
        action = leadAction;
        leads = leadList;
    }

    public SurveybotQueueable(String opportunityAction, List<Opportunity> opportunityList) {
        action = opportunityAction;
        opportunities = opportunityList;
    }

    public SurveybotQueueable(String bookedJobAction, List<Booked_Job__c> bookedJobList) {
        action = bookedJobAction;
        bookedJobs = bookedJobList;
    }

    public void execute(QueueableContext context) {
        List<Lead> leadsToUpdate = new List<Lead>();
        if (leads != null) {
            Set<Id> leadIds = new Set<Id>();
            for (lead l : leads) {
                leadIds.add(l.Id);
            }

            leadsToUpdate = [SELECT Id, Surveybot_Response__c, SurveyBot_Lead_Guid__c, Status, ConvertedOpportunityId
             FROM Lead WHERE Id IN: leadIds];
        }
        if (action == 'newLeadToSurveybot') {
            for (Lead l : leadsToUpdate) {
               l.Surveybot_Response__c = SurveybotCalloutUtility.sendLeadIdToSurveybot(l.Id, l.SurveyBot_Lead_Guid__c);
            }

            update leadsToUpdate;
        }
        else if (action == 'sendMessagesToSurveybot') {
            for (Lead l : leadsToUpdate) {
                l.Surveybot_Response__c = LeadUtility.SendSurveybotMessages(l.Id);
            }

            update leadsToUpdate;
        }
        else if (action == 'newOpportunityToSurveybot') {
            for (Lead l : leadsToUpdate) {
                l.Surveybot_Response__c = SurveybotCalloutUtility.sendNewOpportunityIdToSurveybot(l.ConvertedOpportunityId, l.Id);
            }

            update leadsToUpdate;
        }
        else if (action == 'leadsStatusChangedToSurveybot') {
            for (Lead l : leadsToUpdate) {
                System.debug(l);
                l.Surveybot_Response__c = SurveybotCalloutUtility.sendLeadStatusChangeToSurveybot(l.Id, UserInfo.getUserEmail(), l.Status);
            }

            update leadsToUpdate;
        }
        else if (action == 'newBookedJobToSurveybot') {
            if (bookedJobs != null) {
                Set<Id> bookedJobIds = new Set<Id>();
                for (Booked_Job__c j : bookedJobs) {
                    bookedJobIds.add(j.Id);
                }
                List<Booked_Job__c> bookedJobsToUpdate = [SELECT Id, Opportunity_Line_Item_ID__c FROM Booked_Job__c WHERE Id IN: bookedJobIds];

                for (Booked_Job__c j : bookedJobsToUpdate) {
                    SurveybotCalloutUtility.sendBookedJobIdToSurveybot(j.Id, j.Opportunity_Line_Item_ID__c);
                }
            }
        }
    }
}