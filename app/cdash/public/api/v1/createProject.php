<?php
/*=========================================================================
  Program:   CDash - Cross-Platform Dashboard System
  Module:    $Id$
  Language:  PHP
  Date:      $Date$
  Version:   $Revision$

  Copyright (c) Kitware, Inc. All rights reserved.
  See LICENSE or http://www.cdash.org/licensing/ for details.

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE. See the above copyright notices for more information.
=========================================================================*/

namespace CDash\Api\v1\CreateProject;

require_once 'include/common.php';
require_once 'include/api_common.php';
require_once 'include/pdo.php';

use App\Services\PageTimer;
use App\Services\ProjectPermissions;

use CDash\Config;
use CDash\Model\Project;
use CDash\Model\Repository;
use CDash\Model\UserProject;
use CDash\ServiceContainer;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

$pageTimer = new PageTimer();
$service = ServiceContainer::getInstance();
$config = Config::getInstance();

$response = [];
if (!Auth::check()) {
    $response['requirelogin'] = 1;
    echo json_encode($response);
    return;
}

$userid = Auth::id();
if (!$userid) {
    $response['requirelogin'] = 1;
    echo json_encode($response);
    return;
}

/** @var Project $Project */
$Project = $service->create(Project::class);
$projectid = null;
if (isset($_GET['projectid'])) {
    // Make sure projectid is valid if one was specified.
    $Project->Id = $projectid = $_GET['projectid'];
    if (!$Project->Exists() || !can_access_project($Project->Id)) {
        $response['error'] = 'This project does not exist.';
        echo json_encode($response);
        return;
    }
}

/** @var \App\Models\User $User */
$User = Auth::user();

// Check if the user has the necessary permissions.
$userHasAccess = false;
if (!is_null($projectid)) {
    // Can they edit this project?
    $userHasAccess = Gate::allows('edit-project', $Project);
} else {
    // Can they create a new project?
    $userHasAccess = Gate::allows('create-project');
}
if (!$userHasAccess) {
    $response['error'] = 'You do not have permission to access this page.';
    echo json_encode($response);
    return;
}

$response = begin_JSON_response();
if ($projectid > 0) {
    get_dashboard_JSON($Project->GetName(), null, $response);
}
$response['hidenav'] = 1;
$menu =[];
$menu['back'] = 'user.php';
$response['menu'] = $menu;

$nRepositories = 0;
$repositories_response = [];

if (!is_null($projectid)) {
    $response['title'] = 'Edit Project';
    $response['edit'] = 1;
} else {
    $response['title'] = 'New Project';
    $response['edit'] = 0;
    $response['noproject'] = 1;
}

// List the available projects
$callback = function ($project) use ($Project) {
    if ($project['id'] === $Project->Id) {
        $project['selected'] = 1;
    }
    return $project;
};

$response['availableprojects'] = array_map($callback, UserProject::GetProjectsForUser($User));

$project_response = [];
if ($projectid > 0) {
    $Project->Fill();
    $project_response = $Project->ConvertToJSON($User);

    // Get the spam list
    $spambuilds = $Project->GetBlockedBuilds();
    $blocked_builds = [];
    foreach ($spambuilds as $spambuild) {
        $blocked_builds[] = $spambuild;
    }
    $project_response['blockedbuilds'] = $blocked_builds;

    $repositories = $Project->GetRepositories();
    foreach ($repositories as $repository) {
        $repository_response = array();
        $repository_response['url'] = $repository['url'];
        $repository_response['username'] = $repository['username'];
        $repository_response['password'] = $repository['password'];
        $repository_response['branch'] = $repository['branch'];
        $repositories_response[] = $repository_response;
        $nRepositories++;
    }
} else {
    // Initialize some variables for project creation.
    $project_response['AuthenticateSubmissions'] = 0;
    $project_response['Public'] = Project::ACCESS_PRIVATE;
    $project_response['AutoremoveMaxBuilds'] = 500;
    $project_response['AutoremoveTimeframe'] = 60;
    $project_response['CoverageThreshold'] = 70;
    $project_response['EmailBrokenSubmission'] = 1;
    $project_response['EmailMaxChars'] = 255;
    $project_response['EmailMaxItems'] = 5;
    $project_response['NightlyTime'] = '01:00:00 UTC';
    $project_response['ShowCoverageCode'] = 1;
    $project_response['TestTimeMaxStatus'] = 3;
    $project_response['TestTimeStd'] = 4.0;
    $project_response['TestTimeStdThreshold'] = 1.0;
    if (!$config->get('CDASH_USER_CREATE_PROJECTS') || $User->IsAdmin()) {
        $project_response['UploadQuota'] = 1;
    }
    $project_response['WarningsFilter'] = "";
    $project_response['ErrorsFilter'] = "";
    $project_response['ViewSubProjectsLink'] = 1;
}

// Make sure we have at least one repository.
if ($nRepositories == 0) {
    $repository_response = [];
    $repository_response['id'] = $nRepositories;
    $repository_response['url'] = '';
    $repository_response['branch'] = '';
    $repository_response['username'] = '';
    $repository_response['password'] = '';
    $repositories_response[] = $repository_response;
}
$project_response['repositories'] = $repositories_response;
$response['project'] = $project_response;

// Add the different types of Version Control System (VCS) viewers.
if (strlen($Project->CvsViewerType) == 0) {
    $Project->CvsViewerType = 'github';
}

$viewers = Repository::getViewers();
$callback = function ($key) use ($Project, $viewers, &$response) {
    $v = ['description' => $key, 'value' => $viewers[$key]];
    if ($Project->CvsViewerType === $v['value']) {
        $response['selectedViewer'] = $v;
    }
    return $v;
};

$response['vcsviewers'] = array_map($callback, array_keys($viewers));

$pageTimer->end($response);
echo json_encode(cast_data_for_JSON($response));
