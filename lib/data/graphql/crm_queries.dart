// Contact Queries and Mutations
String getContactsQuery(String customFields) => '''
      query GetPeople(\$filter: PersonFilterInput, \$first: Int, \$after: String) {
        people(filter: \$filter, first: \$first, after: \$after, orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              id
              name { firstName lastName }
              emails { primaryEmail }
              phones { primaryPhoneNumber primaryPhoneCallingCode }
              avatarUrl
              company { id name }
              createdAt
              updatedAt
              $customFields
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    ''';

String getContactByIdQuery(String customFields) => '''
      query GetPersonById(\$id: UUID!) {
        people(filter: { id: { eq: \$id } }) {
          edges {
            node {
              id
              name { firstName lastName }
              emails { primaryEmail additionalEmails }
              phones { primaryPhoneNumber primaryPhoneCallingCode additionalPhones }
              avatarUrl
              city
              jobTitle
              company { id name }
              createdAt
              updatedAt
              $customFields
            }
          }
        }
      }
    ''';

String getContactsByCompanyQuery(String customFields) => '''
      query GetCompanyPeople(\$filter: PersonFilterInput) {
        people(filter: \$filter, orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              id
              name { firstName lastName }
              emails { primaryEmail }
              phones { primaryPhoneNumber primaryPhoneCallingCode }
              avatarUrl
              company { id name }
              createdAt
              updatedAt
              $customFields
            }
          }
        }
      }
    ''';

const String getContactsByTaskQuery = r'''
      query GetTaskTargets($filter: TaskTargetFilterInput) {
        taskTargets(filter: $filter) {
          edges {
            node {
              targetPerson {
                id
                name { firstName lastName }
                emails { primaryEmail }
                phones { primaryPhoneNumber primaryPhoneCallingCode }
                avatarUrl
                company { id name }
                createdAt
                updatedAt
              }
            }
          }
        }
      }
    ''';

const String createContactMutation = r'''
      mutation CreatePerson($input: PersonCreateInput!) {
        createPerson(data: $input) {
          id
          name { firstName lastName }
          emails { primaryEmail }
        }
      }
    ''';

const String updateContactMutation = r'''
      mutation UpdatePerson($id: UUID!, $input: PersonUpdateInput!) {
        updatePerson(id: $id, data: $input) {
          id
          name { firstName lastName }
          emails { primaryEmail }
          phones { primaryPhoneNumber primaryPhoneCallingCode }
          avatarUrl
          company { id name }
        }
      }
    ''';

const String deleteContactMutation = r'''
      mutation DeletePerson($id: UUID!) {
        deletePerson(id: $id) { id }
      }
    ''';

const String getRecentContactsQuery = r'''
      query GetRecentContacts($first: Int!) {
        people(
          first: $first
          orderBy: { updatedAt: DescNullsLast }
        ) {
          edges { node {
            id
            name { firstName lastName }
            emails { primaryEmail }
            phones { primaryPhoneNumber primaryPhoneCallingCode }
            avatarUrl
            company { id name }
            createdAt
            updatedAt
          } }
        }
      }
    ''';

// Company Queries and Mutations
const String getWorkspaceMembersQuery = r'''
      query GetWorkspaceMembers {
        workspaceMembers(first: 100) {
          edges {
            node {
              id
              name {
                firstName
                lastName
              }
            }
          }
        }
      }
    ''';

const String getCurrentUserNameQuery = r'''
      query Me {
        workspaceMembers(first: 1) {
          edges {
            node {
              name {
                firstName
                lastName
              }
            }
          }
        }
      }
    ''';

const String createCompanyMutation = r'''
      mutation CreateCompany($input: CompanyCreateInput!) {
        createCompany(data: $input) {
          id
          name
          domainName { primaryLinkUrl }
          createdAt
        }
      }
    ''';

const String updateCompanyMutation = r'''
      mutation UpdateCompany($id: UUID!, $input: CompanyUpdateInput!) {
        updateCompany(id: $id, data: $input) {
          id
          name
          domainName { primaryLinkUrl }
          createdAt
        }
      }
    ''';

const String deleteCompanyMutation = r'''
      mutation DeleteCompany($id: UUID!) {
        deleteCompany(id: $id) { id }
      }
    ''';

String getCompaniesQuery(String customFields) => '''
      query GetCompanies(\$filter: CompanyFilterInput, \$first: Int, \$after: String) {
        companies(filter: \$filter, first: \$first, after: \$after, orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              id
              name
              domainName { primaryLinkUrl }
              employees
              createdAt
              $customFields
            }
          }
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }
    ''';

String getCompanyByIdQuery(String customFields) => '''
      query GetCompanyById(\$id: UUID!) {
        companies(filter: { id: { eq: \$id } }) {
          edges {
            node {
              id
              name
              domainName { primaryLinkUrl }
              employees
              createdAt
              $customFields
            }
          }
        }
      }
    ''';

// Note Queries and Mutations
const String getNotesByCompanyQuery = r'''
      query GetNotesByCompany($companyId: UUID!) {
        noteTargets(filter: { targetCompanyId: { eq: $companyId } },
                    orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              note { id bodyV2 { blocknote } createdAt updatedAt }
            }
          }
        }
      }
    ''';

const String getNotesByContactQuery = r'''
      query GetNotesByPerson($personId: UUID!) {
        noteTargets(filter: { targetPersonId: { eq: $personId } },
                    orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              note { id bodyV2 { blocknote } createdAt updatedAt }
            }
          }
        }
      }
    ''';

const String createNoteMutation = r'''
      mutation CreateNote($input: NoteCreateInput!) {
        createNote(data: $input) { id bodyV2 { blocknote } createdAt }
      }
    ''';

const String createNoteTargetMutation = r'''
      mutation CreateNoteTarget($input: NoteTargetCreateInput!) {
        createNoteTarget(data: $input) { id }
      }
    ''';

const String updateNoteMutation = r'''
      mutation UpdateNote($id: UUID!, $input: NoteUpdateInput!) {
        updateNote(id: $id, data: $input) { id bodyV2 { blocknote } createdAt }
      }
    ''';

const String deleteNoteMutation = r'''
      mutation DeleteNote($id: UUID!) {
        deleteNote(id: $id) { id }
      }
    ''';

// Task Queries and Mutations
String getOverdueTasksQuery(String conditions) => '''
      query GetOverdueTasks {
        tasks(
          first: 20
          filter: {
            and: [
              $conditions
            ]
          }
          orderBy: { dueAt: AscNullsLast }
        ) {
          edges { node { 
            id title status dueAt 
            taskTargets { edges { node {
              targetPersonId targetPerson { id name { firstName lastName } }
              targetCompanyId targetCompany { id name }
              targetOpportunityId targetOpportunity { id name }
            } } }
          } }
        }
      }
    ''';

String getTodayTasksQuery(String conditions) => '''
      query GetTodayTasks {
        tasks(
          first: 20
          filter: {
            and: [
              $conditions
            ]
          }
          orderBy: { dueAt: AscNullsLast }
        ) {
          edges { node { 
            id title status dueAt 
            taskTargets { edges { node {
              targetPersonId targetPerson { id name { firstName lastName } }
              targetCompanyId targetCompany { id name }
              targetOpportunityId targetOpportunity { id name }
            } } }
          } }
        }
      }
    ''';

String getTomorrowTasksQuery(String conditions) => '''
      query GetTomorrowTasks {
        tasks(
          first: 20
          filter: {
            and: [
              $conditions
            ]
          }
          orderBy: { dueAt: AscNullsLast }
        ) {
          edges { node { 
            id title status dueAt 
            taskTargets { edges { node {
              targetPersonId targetPerson { id name { firstName lastName } }
              targetCompanyId targetCompany { id name }
              targetOpportunityId targetOpportunity { id name }
            } } }
          } }
        }
      }
    ''';

const String getTasksQuery = r'''
      query GetTasks($filter: TaskFilterInput) {
        tasks(filter: $filter, orderBy: { dueAt: AscNullsLast }) {
          edges {
            node {
              id title bodyV2 { blocknote } status dueAt createdAt
              taskTargets { edges { node {
                targetPersonId targetPerson { id name { firstName lastName } }
                targetCompanyId targetCompany { id name }
                targetOpportunityId targetOpportunity { id name }
              } } }
            }
          }
        }
      }
    ''';

const String createTaskMutation = r'''
      mutation CreateTask($input: TaskCreateInput!) {
        createTask(data: $input) { id title status bodyV2 { blocknote } dueAt createdAt assigneeId }
      }
    ''';

const String createTaskTargetMutation = r'''
          mutation CreateTaskTarget($input: TaskTargetCreateInput!) {
            createTaskTarget(data: $input) { id }
          }
        ''';

const String updateTaskMutation = r'''
      mutation UpdateTask($id: UUID!, $input: TaskUpdateInput!) {
        updateTask(id: $id, data: $input) { id title status bodyV2 { blocknote } dueAt createdAt assigneeId }
      }
    ''';

const String deleteTaskMutation = r'''
      mutation DeleteTask($id: UUID!) {
        deleteTask(id: $id) { id }
      }
    ''';

// Workflow Queries and Mutations
const String getManualWorkflowsQuery = r'''
      query GetManualWorkflows {
        workflows(
          filter: {
            statuses: { containsAny: [ACTIVE] }
          }
        ) {
          edges {
            node {
              id
              name
              versions(filter: { status: { eq: ACTIVE } }) {
                edges {
                  node {
                    id
                    trigger
                    steps
                  }
                }
              }
            }
          }
        }
      }
    ''';

const String runWorkflowVersionMutation = r'''
      mutation RunWorkflowVersion($input: RunWorkflowVersionInput!) {
        runWorkflowVersion(input: $input) {
          workflowRunId
        }
      }
    ''';

const String getWorkflowRunsQuery = r'''
      query GetWorkflowRuns {
        workflowRuns(
          orderBy: { createdAt: DescNullsLast }
        ) {
          edges {
            node {
              id
              status
              createdAt
              workflowVersion {
                id
                workflow {
                  id
                  name
                }
              }
            }
          }
        }
      }
    ''';
