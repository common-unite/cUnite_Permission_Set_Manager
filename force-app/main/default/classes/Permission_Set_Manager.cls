/**
 * Created by robertwright on 3/23/21.
 */

global without sharing class Permission_Set_Manager {
    private static final string All = 'all';
    private static final string Profile = 'Profile';
    private static final string Role = 'Role';
    private static final string UserLicense = 'User License';
    private static final string Division = 'Division';
    private static final string Department = 'Department';
    private static final string GroupSet = 'Profile';
    private static final string StandardSet = 'Profile';

    private static map<String,map<String,set<Id>>> allMap = new map<String,map<String,set<Id>>>();
    private static map<String,map<String,set<Id>>> roleMap = new map<String,map<String,set<Id>>>();
    private static map<String,map<String,set<Id>>> profileMap = new map<String,map<String,set<Id>>>();
    private static map<String,map<String,set<Id>>> licenseMap = new map<String,map<String,set<Id>>>();
    private static map<String,map<String,set<Id>>> divisionMap = new map<String,map<String,set<Id>>>();
    private static map<String,map<String,set<Id>>> departmentMap = new map<String,map<String,set<Id>>>();

    private static list<User> getUsers(set<Id> userIds) {
        return [
                Select Id, Department, Division, UserRole.Name, UserRoleId,
                        Profile.Name, ProfileId,
                        Profile.UserLicenseId, Profile.UserLicense.Name
                FROM User
                WHERE Id IN : userIds
        ];
    }
    private static list<PermissionSetAssignment> insertCollection = new list<PermissionSetAssignment>();
    private static map<Id,User> userMap;
    global static void syncPermissionSets(set<Id> userIds) {
        insertCollection.clear();
        userMap = new map<Id,User>(getUsers(userIds));
        populateMaps();
        for(User usr : userMap.values()) processUser(usr);
        Database.insert(insertCollection,false);
    }

    private static void processUser(User usr) {
        if(!allMap.isEmpty()) processAll(usr);
        if(!roleMap.isEmpty() && roleMap.containsKey(usr.UserRole.Name)) handleAssignments(usr,roleMap.get(usr.UserRole.Name));
        if(!profileMap.isEmpty() && profileMap.containsKey(usr.Profile.Name)) handleAssignments(usr,profileMap.get(usr.Profile.Name));
        if(!licenseMap.isEmpty() && licenseMap.containsKey(usr.Profile.UserLicense.Name)) handleAssignments(usr,licenseMap.get(usr.Profile.UserLicense.Name));
        if(!divisionMap.isEmpty() && divisionMap.containsKey(usr.Division)) handleAssignments(usr,divisionMap.get(usr.Division));
        if(!departmentMap.isEmpty() && departmentMap.containsKey(usr.Department)) handleAssignments(usr,departmentMap.get(usr.Department));
    }

    private static void processAll(User usr) {
        for(String matchingType : allMap.keySet()) {
            if(matchingType == Profile) handleAssignments(usr,allMap.get(Profile));
            else if (matchingType == UserLicense) handleAssignments(usr,allMap.get(UserLicense));
            else if (matchingType == Role && String.isNotBlank(usr.UserRoleId)) handleAssignments(usr,allMap.get(Role));
            else if (matchingType == Division && String.isNotBlank(usr.Division)) handleAssignments(usr,allMap.get(Division));
            else if (matchingType == Department && String.isNotBlank(usr.Department)) handleAssignments(usr,allMap.get(Department));
        }
    }

    private static void handleAssignments(User usr, map<String,set<Id>> assignmentMap) {
        for(String setType : assignmentMap.keySet()) {
            IF(setType == GroupSet) handleGroupSetAssignments(usr,assignmentMap.get(setType));
            else handleStandardSetAssignments(usr,assignmentMap.get(setType));
        }
    }
    private static void handleGroupSetAssignments(User usr, set<Id> assigmentIds) {
        for(Id assignmentId : assigmentIds) {
            if(!permissionSetAssigmentMap.containsKey(usr.Id)) permissionSetAssigmentMap.put(usr.Id,new set<Id>());
            if(permissionSetAssigmentMap.get(usr.Id).contains(assignmentId)) continue;
            permissionSetAssigmentMap.get(usr.Id).add(assignmentId);
            insertCollection.add(new PermissionSetAssignment(AssigneeId=usr.Id,PermissionSetGroupId=assignmentId));
        }
    }
    private static void handleStandardSetAssignments(User usr, set<Id> assigmentIds) {
        for(Id assignmentId : assigmentIds) {
            if(!permissionSetAssigmentMap.containsKey(usr.Id)) permissionSetAssigmentMap.put(usr.Id,new set<Id>());
            if(permissionSetAssigmentMap.get(usr.Id).contains(assignmentId)) continue;
            permissionSetAssigmentMap.get(usr.Id).add(assignmentId);
            insertCollection.add(new PermissionSetAssignment(AssigneeId=usr.Id,PermissionSetId=assignmentId));
        }
    }

    private static Boolean mapsSet = false;
    private static void populateMaps() {
        if(mapsSet) return;
        setPermissionSetAssigmentMap(userMap.keySet());
        setPermissionSetGroupMap();
        setPermissionSetMap();
        setPermissionSetAssignments_MDT();
        mapsSet = true;
    }

    private static list<Permission_Set_Assignment__mdt> getPermissionSetAssignments_MDT() {
        list<Permission_Set_Assignment__mdt> returnList = [
                Select Id, Matching_Type__c, Matching_Value__c, Permission_Set_Name__c, Is_Group__c
                FROM Permission_Set_Assignment__mdt
                WHERE Active__c = TRUE
        ];

        return returnList;
    }
    private static void setPermissionSetAssignments_MDT() {
        for(Permission_Set_Assignment__mdt meta : getPermissionSetAssignments_MDT()) processPermissionSetMetaData(meta);
    }
    private static void processPermissionSetMetaData(Permission_Set_Assignment__mdt meta) {
        Id permissionSetId = (meta.Is_Group__c) ? permissionSetGroupMap.get(meta.Permission_Set_Name__c) : permissionSetMap.get(meta.Permission_Set_Name__c);
        if(string.isBlank(permissionSetId)) return; /**Return when no matching records are found**/

        meta.Permission_Set_Name__c = permissionSetId; /***Reset Name to Id***/
        String type = (meta.Matching_Value__c.toLowerCase() == All) ? All : meta.Matching_Type__c;

        switch on type {
            when 'all' {
                processAll(meta);
                return;
            }
            when 'Profile' {
                processMetaData(meta,profileMap);
                return;
            }
            when 'Role' {
                processMetaData(meta,roleMap);
                return;
            }
            when 'User License' {
                processMetaData(meta,licenseMap);
                return;
            }
            when 'Division' {
                processMetaData(meta,divisionMap);
                return;
            }
            when 'Department' {
                processMetaData(meta,departmentMap);
                return;
            }
        }
    }

    private static void processAll(Permission_Set_Assignment__mdt meta) {
        String permissionSetType = (meta.Is_Group__c) ? GroupSet : StandardSet;
        if(!allMap.containsKey(meta.Matching_Type__c)) allMap.put(meta.Matching_Type__c,new Map<String,Set<Id>>());
        if(!allMap.get(meta.Matching_Type__c).containsKey(permissionSetType)) allMap.get(meta.Matching_Type__c).put(permissionSetType,new set<Id>());
        allMap.get(meta.Matching_Type__c).get(permissionSetType).add(meta.Permission_Set_Name__c);
    }
    private static void processMetaData(Permission_Set_Assignment__mdt meta, map<String,map<String,set<Id>>> relatedMap) {
        String permissionSetType = (meta.Is_Group__c) ? GroupSet : StandardSet;
        if(!relatedMap.containsKey(meta.Matching_Value__c)) relatedMap.put(meta.Matching_Value__c,new Map<String,Set<Id>>());
        if(!relatedMap.get(meta.Matching_Value__c).containsKey(permissionSetType)) relatedMap.get(meta.Matching_Value__c).put(permissionSetType,new set<Id>());
        relatedMap.get(meta.Matching_Value__c).get(permissionSetType).add(meta.Permission_Set_Name__c);
    }

    private static map<String,Id> permissionSetMap = new map<String,Id>();
    private static list<PermissionSet> getPermissionSets() {
        return [
                Select Id, Name, Label
                FROM PermissionSet
        ];
    }
    private static void setPermissionSetMap() {
        for(PermissionSet pSet : getPermissionSets()) permissionSetMap.put(pSet.Name,pSet.Id);
    }

    private static map<String,Id> permissionSetGroupMap = new map<String,Id>();
    private static list<PermissionSetGroup> getPermissionSetGroups() {
        return [
                Select Id, DeveloperName, MasterLabel
                FROM PermissionSetGroup
        ];
    }
    private static void setPermissionSetGroupMap() {
        for(PermissionSetGroup pSetGroup : getPermissionSetGroups()) permissionSetGroupMap.put(pSetGroup.DeveloperName,pSetGroup.Id);
    }

    private static map<Id,set<Id>> permissionSetAssigmentMap = new map<Id,set<Id>>();
    private static list<PermissionSetAssignment> getPermissionSetAssignments(set<Id> assigneeIds) {
        return [
                Select Id, AssigneeId, PermissionSetGroupId, PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN : assigneeIds
        ];
    }
    private static void setPermissionSetAssigmentMap(set<Id> assigneeIds) {
        for(PermissionSetAssignment pSetAssignment : getPermissionSetAssignments(assigneeIds)) putPermissionSetAssigmentMap(pSetAssignment);
    }
    private static void putPermissionSetAssigmentMap(PermissionSetAssignment pSetAssignment) {
        if(!permissionSetAssigmentMap.containsKey(pSetAssignment.AssigneeId)) permissionSetAssigmentMap.put(pSetAssignment.AssigneeId,new set<Id>());
        Id permissionSetId = (string.isBlank(pSetAssignment.PermissionSetId)) ? pSetAssignment.PermissionSetGroupId : pSetAssignment.PermissionSetId;
        permissionSetAssigmentMap.get(pSetAssignment.AssigneeId).add(permissionSetId);
    }
}