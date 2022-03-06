global class LeadHandler extends EDHU.SObjectHandler {

    /**
     * The before insert functionality on the {{ object_name }} object
     */
    global override void beforeInsert(List<SObject> newList){
        System.debug('Overriden');
       List<Lead> newLeadList = (List<Lead>)newList;

       List<Lead> leadsToSendForAssignment = new List<Lead>();
       for (Lead l : newLeadList) {
           if (l.Created_with_Needs_Assessment_Scheduled__c  == false && l.Created_with_Video_Survey_Scheduled__c == false) {
               leadsToSendForAssignment.add(l);
           }
       }

       if (leadsToSendForAssignment.size() > 0) {
           // system.debug(leadsToSendForAssignment);
           LeadAssignmentUtility.checkForLeadAssignment(leadsToSendForAssignment);
       }    
    }

    /**
     * The after insert functionality on the {{ object_name }} object
     */
    global override void afterInsert(List<SObject> newList){
        System.debug('Overriden');
        List<Lead> newLeadList = (List<Lead>)newList;

        List<Lead> leadsToSendToSurveybot = new List<Lead>();
        for (Lead l : newLeadList) {
            if (l.SurveyBot_Lead_Guid__c != null) {
                leadsToSendToSurveybot.add(l);
            }
        }

        if (leadsToSendToSurveybot.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('newLeadToSurveybot', leadsToSendToSurveybot);
            System.enqueueJob(q);
        }
    }

    /**
     * The before update functionality on the {{ object_name }} object
     */
    // global override void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after update functionality on the {{ object_name }} object
     */
    global override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap){
        System.debug('Overriden');
        List<Lead> newLeadList = (List<Lead>)newList;
        Map<Id, Lead> oldLeadMap = (Map<Id, Lead>)oldMap;

        List<Lead> leadsToSendToSurveybot = new List<Lead>();
        for (Lead l : newLeadList) {
            if (l.SurveyBot_Lead_Guid__c != null && (l.SurveyBot_Lead_Guid__c != oldLeadMap.get(l.Id).SurveyBot_Lead_Guid__c)) {
                leadsToSendToSurveybot.add(l);
            }
        }

        if (leadsToSendToSurveybot.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('newLeadToSurveybot', leadsToSendToSurveybot);
            System.enqueueJob(q);
        }

        List<Lead> leadsToSendSurveybotEmail = new List<Lead>();
        for (Lead l : newLeadList) {
            if (l.Attempts__c != null && (l.Attempts__c != oldLeadMap.get(l.Id).Attempts__c)) {
                leadsToSendSurveybotEmail.add(l);
            }

        }
        if (leadsToSendSurveybotEmail.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('sendMessagesToSurveybot', leadsToSendSurveybotEmail);
            System.enqueueJob(q);
        }

        List<Lead> leadsConvertedToSendToSurveybot = new List<Lead>();
        for (Lead l : newLeadList) {
            if (l.IsConverted == true && oldLeadMap.get(l.Id).IsConverted != true) {
                if (l.ConvertedOpportunityId != null) {
                    leadsConvertedToSendToSurveybot.add(l);
                }
            }

        }
        if (leadsConvertedToSendToSurveybot.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('newOpportunityToSurveybot', leadsConvertedToSendToSurveybot);
            System.enqueueJob(q);
        }

        List<Lead> leadsStatusChangedToSendToSurveybot = new List<Lead>();
        for (Lead l : newLeadList) {
            if (l.IsConverted != true && oldLeadMap.get(l.Id).Status != l.Status) {
                leadsStatusChangedToSendToSurveybot.add(l);
            }
        }
        if (leadsStatusChangedToSendToSurveybot.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('leadsStatusChangedToSurveybot', leadsStatusChangedToSendToSurveybot);
            System.enqueueJob(q);
        }

    }

    /**
     * The before delete functionality on the {{ object_name }} object
     */
    // global override void beforeDelete(Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after delete functionality on the {{ object_name }} object
     */
    // global override void afterDelete(Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after undelete functionality on the {{ object_name }} object
     */
    // global override void afterUndelete(List<SObject> newList){
    //     System.debug('Overriden');
    // }

}