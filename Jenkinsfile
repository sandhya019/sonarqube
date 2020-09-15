pipeline {
    agent any
    tools {
	  jdk 'jdk8'
      maven 'Maven3'
    }

    environment {
        //Use Pipeline Utility Steps plugin to read information from pom.xml into env variables
        ARTIFACT_NAME = readMavenPom().getArtifactId()
        VERSION = readMavenPom().getVersion()
        PACKAGING = readMavenPom().getPackaging()
        
	}

    stages{
        stage('Compile'){
            steps{
                sh script: 'mvn clean compile'
            }
        }

    stage(' ArtifactVer Automation'){
          steps{ 
             script{
              if (env.BRANCH_NAME == 'master')
            {
               sh '''
               sversion=`mvn help:evaluate -Dexpression=project.version -q -DforceStdout`
               echo $sversion
                if  [[ ${sversion} == *-SNAPSHOT* ]]
                then
                version=`echo "$sversion" | cut -d '-' -f1`
                mvn versions:set -DnewVersion=$version
		else 
		 echo " version is as expected $sversion "
                fi
              ''' 
                  }
            else
                  {
                    sh '''
                    sversion=`mvn help:evaluate -Dexpression=project.version -q -DforceStdout`  
                   echo $sversion
                   if  [[ ${sversion} != *-SNAPSHOT* ]]
                   then
	           version="$sversion-SNAPSHOT"
                   mvn versions:set -DnewVersion=$version
		   else 
		    echo " version is as expected $sversion "
                   fi
                   '''
                 }
             }
         }
     }

        stage('MUnit'){
            steps{
                sh script: 'mvn test-compile test package'
                sh '''
               ls -lrt ${WORKSPACE}/target
               '''
            }
        }

	stage('Munit Report'){	
	    steps{
		 sh '''
                 echo " ${WORKSPACE} "
                 cd ${WORKSPACE}
                 mkdir -p  MunitReports
                 echo " ${WORKSPACE} "
                 mv ./target/site/munit/coverage/summary.html ./MunitReports/MunitReport-$BUILD_ID.html
		 '''
		  }
		}
		
	stage('SonarQube Analysis') {
		steps{
		   script {	
	          def Maven3 = tool name: 'Maven3', type: 'maven'
		  withSonarQubeEnv("Sonar_server") {
	           sh 'mvn clean package sonar:sonar'
		  // sh "${Maven3}/bin/mvn sonar:sonar" 
		      }
		   }	   
		}	
  	 }
  }	    
		

        //stage('Artifactory-Publish'){
                  //steps{ 
			 
			//sh '''
			//curl -u admin:admin123 -X POST http://3.137.145.165:8082/artifactory/api/maven/generatePom/com/lla/${ARTIFACT_NAME}/${VERSION}/${ARTIFACT_NAME}-${VERSION}-${BUILD_TIMESTAMP}-${PACKAGING}.jar
			 //curl -u admin:admin123 -X POST http://3.137.145.165:8082/artifactory/api/maven/calculateMetadata/lla-esb-snapshot/com/lla/${ARTIFACT_NAME}/${VERSION}                         


			//curl -u admin:admin123 -X PUT "http://3.137.145.165:8082/artifactory/lla-esb-snapshot/com/lla/${ARTIFACT_NAME}/${VERSION}/${ARTIFACT_NAME}-${VERSION}-${PACKAGING}.jar" -T "./target/${ARTIFACT_NAME}-${VERSION}-${PACKAGING}.jar"

		
		
			
			//curl -u admin:admin123 -X POST "http://3.137.145.165:8082/artifactory/api/maven/generatePom/lla-esb-snapshot/com/lla/customer-management-biz/1.0.22-SNAPSHOT/customer-management-biz-1.0.22-20200908.070242-1-mule-application.jar"

			//curl -u admin:admin123 -X POST "http://3.137.145.165:8082/artifactory/api/maven/calculateMetadata/lla-esb-snapshot/com/lla/customer-management-biz/1.0.22-SNAPSHOT/"
	
			//curl -u admin:admin123 -X PUT "http://3.137.145.165:8082/artifactory/lla-esb-snapshot/com/lla/customer-management-biz/1.0.22-SNAPSHOT/customer-management-biz-1.0.22-SNAPSHOT-mule-application.jar" -T "./customer-management-biz-1.0.22-SNAPSHOT-mule-application.jar"
			// '''
	// }
        //}
	  
post {
        always {
            echo 'I will always say Hello again!'
            
            //emailext body: "${currentBuild.currentResult}: Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}\n More info at: ${env.BUILD_URL}",
             //   recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
               // subject: "Jenkins Build ${currentBuild.currentResult}: Job ${env.JOB_NAME}"
            
        }
    }


}

