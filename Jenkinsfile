/*
 * (C) Copyright 2019 Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     Florian Bématol <fbematol@nuxeo.com>
 */

if (currentBuild.rawBuild.getCauses().toString().contains('BranchIndexingCause')) {
    print "INFO: Build skipped due to trigger being Branch Indexing"
    currentBuild.result = 'ABORTED' // optional, gives a better hint to the user that it's been skipped, rather than the default which shows it's successful
    return
}

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '1'))
    }
    agent {
        kubernetes {
            yamlFile 'Jenkinsfile-pod.yaml'
        }
    }
    stages {
        stage('Checkout repository') {
            steps {
                container('skaffold') {
                    checkout scm: [
                        $class: 'GitSCM',
                        branches: scm.branches,
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [[$class: 'SubmoduleOption',
                                      disableSubmodules: false,
                                      parentCredentials: true,
                                      recursiveSubmodules: true,
                                      reference: '',
                                      trackingSubmodules: false],
                                     [$class: 'LocalBranch', localBranch: '**']],
                        submoduleCfg: [],
                        userRemoteConfigs: scm.userRemoteConfigs
                    ]
                }
            }
        }
        stage('Build docker images') {
            stages {
                stage('latest') {
                    when {
                        branch 'master'
                    }
                    steps {
                        gitStatusWrapper(credentialsId: 'pipeline-git-github',
                                         description: 'skaffold latest images',
                                         failureDescription: 'skaffold latest images',
                                         gitHubContext: 'skaffold-latest',
                                         successDescription: 'skaffold latest images') {
                            container('skaffold') {
                                sh 'skaffold build -p latest'
                            }
                        }
                    }
                }
                stage('release') {
                    when {
                        buildingTag()
                    }
                    steps {
                        gitStatusWrapper(credentialsId: 'pipeline-git-github',
                                         description: 'skaffold latest images',
                                         failureDescription: 'skaffold latest images',
                                         gitHubContext: 'skaffold-latest',
                                         successDescription: 'skaffold latest images') {
                            container('skaffold') {
                                sh 'skaffold build -p release'
                            }
                        }
                    }
                }
                stage('branch') {
                    when {
                        changeRequest()
                    }
                    steps {
                        gitStatusWrapper(credentialsId: 'pipeline-git-github',
                                         description: 'skaffold branch images',
                                         failureDescription: 'skaffold branch images',
                                         gitHubContext: 'skaffold-branch',
                                         successDescription: 'skaffold branch images') {
                            container('skaffold') {
                                sh 'skaffold build -p branch'
                            }
                        }
                    }
                }
            }
        }
        stage('Update Jira') {
            when {
                branch 'master'
            }
            steps {
                container('skaffold') {
                    step([$class       : 'JiraIssueUpdater',
                          issueSelector: [$class: 'DefaultIssueSelector'],
                          scm          : scm])
                }
            }
        }
    }
}



// Local Variables:
// indent-tabs-mode: nil
// End:
