# WIP: Test Dependencies
#
# until now, ctest could only be run serially, because some of the tests developed a
# dependency the tests before them. This is an attempt to de-construct this dependency
# and to transition to a parellel test suite.
#
# There are 3 independent phases in the serial execution of the tests:
#   * test 1-10: can run fully in parallel
#   * tests 12-71: can run in parallel for the most part (except for 58?), after 11 (install) is run
#   * tests 73-229: heavy dependency between tests, all have to run after 72 (reinstall)
# The picture looks as follows:
#   I      II              III                   <-- phase
# +---+-----------+---------------------------+
# 1   11          72                         229 <-- test #
#   (install)    (reinstall)
#
# Below is the code to establish edges in the dependency graph.
# Keep in mind that tests not referenced in this file have no dependencies, which
# means that they can run in parallel (e.g., the tests in phase I)

# TODO: figure out which tests need to be in the parallel vs serial section of each phase.

############### PHASE II DEPENDENCIES ###############
set(phase_ii_indep_tests
    /Unit/app/Validators/PasswordTest # 12
    /Feature/CDashTest # 13
    /Feature/LdapAuthWithRulesTest # 14
    /Feature/LoginAndRegistration # 15
    /Feature/Monitor # 16
    /Feature/OpenLdapAuthWithOverrides # 17
    /Feature/MigrateConfigCommand # 18
    /Feature/PasswordRotation # 19
    /Feature/ProjectPermissions # 20
    /Feature/UserCommand # 21
    /Feature/RouteAccessTest # 22
    /PHPUnitTest # 23
    /CDash/Api/GitHubWebhook # 24
    /CDash/BuildUseCase # 25
    /CDash/Config # 26
    /CDash/ConfigUseCase # 27
    /CDash/Controller/Auth/Session # 28
    /CDash/Database # 29
    /CDash/Lib/Repository/GitHub # 30
    /CDash/LinkifyCompilerOutput # 31
    /CDash/Messaging/Subscription/CommitAuthorSubscriptionBuilder # 32
    /CDash/Messaging/Subscription/UserSubscriptionBuilder # 33
    /CDash/Messaging/Topic/AuthoredTopic # 34
    /CDash/Messaging/Topic/BuildErrorTopic # 35
    /CDash/Messaging/Topic/ConfigureTopic # 36
    /CDash/Messaging/Topic/DynamicAnalysisTopic # 37
    /CDash/Messaging/Topic/EmailSentTopic # 38
    /CDash/Messaging/Topic/FixedTopic # 39
    /CDash/Messaging/Topic/MissingTestTopic # 40
    /CDash/Messaging/Topic/TestFailureTopic # 41
    /CDash/Messaging/Topic/TopicDecorator # 42
    /CDash/Messaging/Topic/UpdateErrorTopic # 43
    /CDash/Middleware/OAuth2 # 44
    /CDash/Middleware/OAuth2/GitHub # 45
    /CDash/Middleware/OAuth2/GitLab # 46
    /CDash/Middleware/OAuth2/Google # 47
    /CDash/Model/BuildError # 48
    /CDash/Model/BuildErrorFilter # 49
    /CDash/Model/BuildFailure # 50
    /CDash/Model/BuildRelationship # 51
    /CDash/Model/Repository # 52
    /CDash/MultipleSubprojectsEmail # 53
    /CDash/NightlyTime # 54
    /CDash/Service/RepositoryService # 55
    /CDash/ServiceContainer # 56
    /CDash/Submission/CommitAuthorHandlerTrait # 57
    /CDash/TestUseCase # TODO: 58 not actually indep?
    /CDash/UpdateUseCase # 59
    /CDash/XmlHandler/BuildHandler # 60
    /CDash/XmlHandler/ConfigureHandler # 61
    /CDash/XmlHandler/DynamicAnalysisHandler # 62
    /CDash/XmlHandler/TestingHandler # 63
    /CDash/XmlHandler/UpdateHandler # 64
    /Feature/PurgeUnusedProjectsCommand # 65
    /Feature/TestSchemaMigration # 66
    /Feature/MeasurementPositionMigration # 67
    /Feature/RemoveMeasurementCheckboxesMigration # 68
    /Feature/IncreaseSiteInformationCPUColumnsSizeMigration # 69
    install_into_empty_db # 70
)
set(phase_ii_dep_tests
    registeruser # 71
)
# set dependencies for parallel tests in phase II
foreach(test_name ${phase_ii_indep_tests})
    set_tests_properties(${test_name} PROPERTIES DEPENDS install)
endforeach()
# set dependencies for serial tests in phase II
set(prev_dep_test "")
foreach(test_name ${phase_ii_dep_tests})
    if ("${prev_dep_test}" STREQUAL "")
        # force the first serial test to wait until all parallel tests finish
        foreach(test_ii_name ${phase_ii_indep_tests})
            set_tests_properties(${test_name} PROPERTIES DEPENDS ${test_ii_name})
        endforeach()
    else()
        set_tests_properties(${test_name} PROPERTIES DEPENDS ${prev_dep_test})
    endif()
    set(prev_dep_test ${test_name})
endforeach()
# make sure reinstall runs between phases II and III
set_tests_properties(reinstall PROPERTIES DEPENDS ${test_name})


############### PHASE III DEPENDENCIES ###############
set(phase_iii_indep_tests
    compressedtest # 73
    createpublicdashboard # 74
    email # 75
    subproject # 77
    actualtrilinossubmission # 78
    summaryemail # 79
    committerinfo # 86
    dailyupdatefile # 87
    edituser # 88
    image # 89
    displayimage # 90
    managebanner # 91
    manageusers # 93
    projectindb # 94
    pubproject # 95
    querytests # 97
    sitestatistics # 98
    testenv # 99
    testoverview # 100
    userstatistics # 101
    user # 102
    projectxmlsequence # 109
    uploadfile # 110
    builddetails # 117
    excludesubprojects # 123
    testhistory # 124
    expectedandmissing # 125
    timesummary # 127
    passwordcomplexity # 131
    crosssubprojectcoverage # 132
    aggregatesubprojectcoverage # 133
    configurewarnings # 134
    seconds_from_interval # 136
    csvexport # 140
    testgraphpermissions # 144
    extracttar # 145
    pdoexecutelogserrors # 146
    revisionfilteracrossdates # 147
    timeoutsandmissingtests # 148
    disabledtests # 149
    multiplesubprojects # 150
    junithandler # 152
    limitedbuilds # 154
    coveragedirectories # 157
    outputcolor # 158
    buildproperties # 159
    filterbuilderrors # 162
    expiredbuildrules # 168
    filterblocks # 169
    rehashpassword # 174
    subprojecttestfilters # 184
    lotsofsubprojects # 188
    querytestsrevisionfilter # 189
    redundanttests # 190
    /Feature/AutoRemoveBuildsCommand # 194
    recoverpassword # 200
    submitsortingdata # 201
    indexfilters # 202
    timeline # 203
    nobackup # 204
    deferredsubmissions # 205
    simple_async # 206
    simple2_async_1 # 207
    manageBuildGroup # 208
    manageOverview # 209
    manageSubProject # 210
    viewBuildError # 211
    viewTest # 212
    sort_index # 213
    expected_build # 214
    remove_build # 215
    viewSubProjects # 216
    testSummary # 217
    queryTests # 218
    filterLabels # 219
    viewTestPagination # 220
    done_build # 221
    multiSort # 222
    subprojectGroupOrder # 223
    calendar # 224
    colorblind # 225
    daterange # 226
    autoremovebuilds_on_submit # 227
    deletesubproject # 228
)
set(phase_iii_dep_tests
    removebuilds # 229
)
# set dependencies for parallel tests in phase III
foreach(test_name ${phase_iii_indep_tests})
    set_tests_properties(${test_name} PROPERTIES DEPENDS reinstall)
endforeach()
# set dependencies for serial tests in phase III
set(prev_dep_test "")
foreach(test_name ${phase_iii_dep_tests})
    if ("${prev_dep_test}" STREQUAL "")
        # force the first serial test to wait until all parallel tests finish
        foreach(test_iii_name ${phase_iii_indep_tests})
            set_tests_properties(${test_name} PROPERTIES DEPENDS ${test_iii_name})
        endforeach()
    else()
        set_tests_properties(${test_name} PROPERTIES DEPENDS ${prev_dep_test})
    endif()
    set(prev_dep_test ${test_name})
endforeach()
