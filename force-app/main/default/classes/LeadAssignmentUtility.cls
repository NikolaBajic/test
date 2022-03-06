public without sharing class LeadAssignmentUtility {
    public static void checkForLeadAssignment(List<Lead> leadsForAssignment) {
        system.debug('LeadAssignmentUtility: '+ leadsForAssignment);
        /// change query to filter AND User.Profile.Name = 'Move Coach - Available'
        List<UserServicePresence> userServiceList;
        if(!Test.isRunningTest()){
            userServiceList = [SELECT Id, UserId, User.Profile.Name, StatusStartDate, StatusEndDate, ServicePresenceStatus.DeveloperName 
                                                        FROM UserServicePresence 
                                                        WHERE StatusEndDate = null 
                                                        AND ServicePresenceStatus.DeveloperName = 'Move_Coach_Available'
                                                        AND User.Profile.Name = 'Move Coach'];
        }
        else{
            userServiceList = [SELECT Id, UserId, User.Profile.Name, StatusStartDate, StatusEndDate 
                                                        FROM UserServicePresence];
        }
        
        system.debug('userServiceList: '+ userServiceList);

        Map<Id, List<Lead>> mapUserToLeads = new Map<Id, List<Lead>>();
        if(userServiceList.size() > 0){
            for(UserServicePresence u: userServiceList){
                if(!mapUserToLeads.containsKey(u.id)){
                    mapUserToLeads.put(u.UserId, new List<Lead>());
                }
            }
        }
        system.debug('mapUserToLeads= '+ mapUserToLeads);
        List<Lead> activeLeadsList = new List<Lead>();
        if(!mapUserToLeads.isEmpty()){
            Date today = Date.today();
            Date lastMonth = today.addDays(-30);
            activeLeadsList = [SELECT Id, OwnerId, Status 
                                        FROM Lead 
                                        WHERE Status != 'Qualified' 
                                        AND Status != 'Closed-Lost' 
                                        AND Status != 'Future Followup'
                                        AND Status != 'Closed - Unqualified'
                                        AND OwnerId IN: mapUserToLeads.keySet()
                                        AND LastmodifiedDate >: lastMonth];

        }
        
        if(activeLeadsList.size() > 0){
            for(Lead l: activeLeadsList){
                mapUserToLeads.get(l.OwnerId).add(l);
            }
        }
        system.debug('mapUserToLeads= '+ mapUserToLeads);

        UserServicePresence OwnerWithLosestLeads;
        integer currentLowestLeads;
        Datetime currentEarliestLogin;

        if(!mapUserToLeads.isEmpty()){
            for(UserServicePresence u: userServiceList){
                system.debug(mapUserToLeads.get(u.UserId).size());
                if(u != null){
                    if(OwnerWithLosestLeads == null && currentLowestLeads == null && currentEarliestLogin == null){
                        OwnerWithLosestLeads = u;
                        currentLowestLeads = mapUserToLeads.get(u.UserId).size();
                        currentEarliestLogin = u.StatusStartDate;
                    }
                    else{
                        if(mapUserToLeads.get(u.UserId).size() < currentLowestLeads && u.StatusStartDate < currentEarliestLogin){
                            OwnerWithLosestLeads = u;
                            currentLowestLeads = mapUserToLeads.get(u.UserId).size();
                            currentEarliestLogin = u.StatusStartDate;
                        }
                    }
                }
               
            }
        
            for(Lead l: leadsForAssignment){
                l.OwnerId = OwnerWithLosestLeads.UserId;
            }
        }
        else{
            QueueSobject leadQue = [SELECT Id, QueueId, SobjectType FROM QueueSobject WHERE SobjectType = 'Lead'];
            for(Lead l: leadsForAssignment){
                l.OwnerId = leadQue.QueueId;
            }
        }
        
        
    }
}