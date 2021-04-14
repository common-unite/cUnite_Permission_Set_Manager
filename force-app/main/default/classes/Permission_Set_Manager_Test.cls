/**
 * Created by robertwright on 4/13/21.
 */

@IsTest
private class Permission_Set_Manager_Test {
    @IsTest
    private static void processUser() {
        map<Id,User> userMap = new map<Id,User>([
                Select Id
                FROM User
                LIMIT 1
        ]);
        Permission_Set_Manager.syncPermissionSets(userMap.keySet());
    }

    @IsTest
    private static void processAll() {
        Permission_Set_Manager.allMap.put('testing',new Map<String, Set<Id>>());
        Permission_Set_Manager.processAll(new User());
        Permission_Set_Manager.allMap.put('Profile',new Map<String, Set<Id>>());
        Permission_Set_Manager.processAll(new User());
    }

    @IsTest
    private static void processPermissionSetMetaData() {
        Permission_Set_Assignment__mdt meta = new Permission_Set_Assignment__mdt(
                Matching_Type__c = 'Testing',
                Matching_Value__c = 'System Admin',
                Permission_Set_Name__c = 'Testing',
                Is_Group__c = true,
                Active__c = true
        );

        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'all';
        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'Profile';
        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'Role';
        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'User License';
        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'Division';
        Permission_Set_Manager.processPermissionSetMetaData(meta);
        meta.Matching_Type__c = 'Department';
        Permission_Set_Manager.processPermissionSetMetaData(meta);

    }

    @IsTest
    private static void putPermissionSetAssigmentMap() {
        Permission_Set_Manager.putPermissionSetAssigmentMap(new PermissionSetAssignment());
    }

    @IsTest
    private static void handleAssignments() {
        Permission_Set_Manager.handleAssignments(new User(Id='005R0000008BEjfIdd'),new Map<String, Set<Id>>());
        Permission_Set_Manager.handleAssignments('Testing', new User(Id='005R0000008BEjfIdd'),new Map<String, Set<Id>>());
        Permission_Set_Manager.handleGroupSetAssignments(new User(Id='005R0000008BEjfIdd'),new set<Id>());
        Permission_Set_Manager.handleGroupSetAssignments('0PaR0000007d6XtKkl', new User(Id='005R0000008BEjfIdd'),new set<Id>());
        Permission_Set_Manager.handleStandardSetAssignments(new User(Id='005R0000008BEjfIdd'),new set<Id>());
        Permission_Set_Manager.handleStandardSetAssignments('0PaR0000007d6XtKfl', new User(Id='005R0000008BEjfIdd'));
    }
}