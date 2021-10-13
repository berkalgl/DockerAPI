#!/usr/bin/env groovy
@Library('PipelineExternalLib@master') _


// cmdb variables
appServiceName = "dockerapi"
softwareModuleName = "dockerapi"
appVersion = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"


// artifacatory variables
artifactoryHostAddress = "artifactory"
applicationServiceName = "dockerapi"
artifactName = "dockerapi"
openshiftProjectName = "dockerapi"
gitCredentialSecret = "xxx"
artifactoryDeployerCredentialID = "jenkins-artifactory"

// docker/openshift variables
dockerRepo = "local-docker-dist-dev"
dockerRegistryBaseUrl = "${artifactoryHostAddress}/${dockerRepo}/com/turkcell"
openshiftProjectName = "dockerapi"								                 // openshift namespace
openshiftClientToken = "xxx"            				                	     // openshift credential name in Jenkins
imagePushSecret = "artifactory"							        			     // push secret name for docker registry on artifactory
imagePullSecret = "artifactory"						        				     // pull secret name for docker registry on artifactory
buildConfigTemplate = "openshift/build/build-config-template.yaml"			     // openshift build config template yaml file
deploymentConfigTemplate = "openshift/deploy/deployment-config-template.yaml"    // openshift deployment pod config template yaml file
newImageUrl = ""															     // newly created docker image address
gitCredentialSecret = "jenkins-git"	    								         // openshift build config git credential secret name


pipeline {

    agent none

    options {
        timestamps()
    }

	environment {
        m2 = "/home/jenkins/.m2"
        // mainBranch = "releasable"
        mainBranch = "devops"
	}

    stages {

        stage('CI') {
          	agent { label 'agent' }
            stages  {
				stage('build') {
					steps{
						script {
                            sh "echo build process running..."
                            
                            openshiftAppName = "${appServiceName}"
                            newImageUrl = "${dockerRegistryBaseUrl}/${openshiftAppName}/${softwareModuleName}:${appVersion}"
                            gitUrl = sh returnStdout: true, script: 'git config --get remote.origin.url'
                            openshiftClient {
                                openshift.apply(openshift.process(readFile(file: buildConfigTemplate), 
                                "-p", "APP_NAME=${softwareModuleName}", 
                                "-p", "APP_VERSION=${appVersion}", 
                                "-p", "SOURCE_REPOSITORY_URL=${gitUrl.trim()}", 
                                "-p", "BRANCH_NAME=${env.BRANCH_NAME}", 
                                "-p", "PUSH_SECRET=${imagePushSecret}", 
                                "-p", "PULL_SECRET=${imagePullSecret}", 
                                "-p", "REGISTRY_URL=${newImageUrl}", 
                                "-p", "SOURCE_SECRET_NAME=${gitCredentialSecret}"))


                                openshift.startBuild("${softwareModuleName}", "--wait", "--follow")
                            }
						}
					}
				}
                stage('deploy to TEST') {
                    steps {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'xxx', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                                //deploy the new docker image to openshift TEST namespace                  
                                openshiftClient {
                                    openshift.apply(openshift.process(readFile(file: deploymentConfigTemplate), "-p", "REGISTRY_URL=${newImageUrl}" ))
                                    def dc = openshift.selector('dc', "${softwareModuleName}")
                                    dc.rollout().status()
                                }
                            }
                        }
                    }
                    post {
                        always {
                            echo "Deploy to TEST stage finished."
                        }
                        success {
                            echo "Deploy to PROD stage successfullly completed."
                            script{
                                sh "echo status update running on jira"
                            }
                        }
                        failure {
                            script{
                                //back to GELISTIRME
                                sh "echo status update running on jira"
                                //updateJiraStatus("FAILED", "", 451)
                            }
                        }
                    }
                }
            }
			post {
				always {
					echo "CI stage finished."
				}
				success {
					echo "CI stage successfullly completed"
					script{
						sh "echo status update running on jira"
					}
				}
				failure {
					echo "CI stage failed!"
					script{
						sh "echo status update running on jira"
					}
				}
			}
        }
    }

	post {
        always {
            echo "this step executing ALWAYS"
        }
        success {
            echo "this step executing SUCCESS"
        }
        failure {
            echo "this step executing FAILURE"
        }
        cleanup {
            echo "this step executing CLEANUP"
        }
    }
}

def openshiftClient(Closure body) {
    openshift.withCluster('insecure://kubernetes.default.svc') {
        openshift.withCredentials(openshiftClientToken) {
            openshift.withProject(openshiftProjectName) {
                body()
            }
        }
    }
}