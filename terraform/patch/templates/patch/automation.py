0###########
# IMPORTS
###########
import json
from datetime import datetime
import argparse
import boto3
import sys
import time

############
# FUNCTIONS
############


class patch:
    def __init__(self, env, appcomponent, topicarn):
        """ What does it do?

        :param ?: ?
        :returns: ?
        """

        self.s3 = boto3.client('s3')
        self.s3_resource = boto3.resource('s3')
        self.ssm = boto3.client('ssm')
        self.sns = boto3.client('sns')
        self.filename = "patch.json"
        self.appcomponent = appcomponent
        self.env = env
        self.topicarn = topicarn
        if(env == 'prod'):
            self.patchBucket = "sdn-prod-patch-bucket"
        else:
            self.patchBucket = "sdn-non-prod-patch-bucket"
        self.ec2 = boto3.client('ec2')
        with open(self.filename) as json_file:
            data = json.load(json_file)
            self.patch = data['patch']
            self.ApplyAllPatches = data['ApplyAllPatches']
            self.deploy_from = data['deploy_from']


    def sendMessage(self, subject, message):
        """ Send a message to SNS topic

        :param subject: The topic subject
        :param message: The topic message
        :returns: none
        """

        print('==== Publishing a message on SNS ====')
        try:
            self.sns.publish(
                TopicArn=self.topicarn,
                Message=str(message),
                Subject=subject
            )
        except Exception as e:
            raise Exception('==== An exception occurred: %s ====' % e)





    def getInstances(self):
        """ What does it do?

        :param ?: ?
        :returns: ?
        """

        try:
            print(self.env, self.appcomponent)
            response = self.ec2.describe_instances(
             Filters=[
                 {
                  'Name': 'tag:application-environment',
                  'Values': [self.env]
                  },
                  {
                      'Name': 'tag:automated-patching',
                      'Values': ['True']
                      
                  },
                  {
                      'Name': 'instance-state-name',
                      'Values': ['running']
                  }
             ]
            )
            print("==== Instances List: %s ====" % response)
            return response
        except Exception as e:
            raise Exception('An exception occurred: %s' % e)


    def createSnapShot(self):
        """ What does it do?

        :param ?: ?
        :returns: ?
        """

        try:
            response = self.getInstances()
            for instance in response['Reservations']:
                print("==== Taking the backup of instance with id %s ====" % (instance['Instances'][0]['InstanceId']))
                for i in instance['Instances'][0]['Tags']:
                    if (i['Key'] == 'Name'):
                        result_image = self.ec2.create_image(
                            Description='This is a snapshot',
                            DryRun=False,
                            InstanceId=instance['Instances'][0]['InstanceId'],
                            Name='snapshot-ec2-%s-%s-%s' % (i['Value'], self.env, datetime.now().strftime('%Y-%m-%d-%H-%M')),
                            NoReboot=True
                        )
                        #self.createEC2Tags(result_image['ImageId'])
                if(self.ApplyAllPatches):
                    for patch in self.patch:
                        command = "%s" % (self.patch[patch][0])
                        print("==== Running the patch for patch number %s ====" % patch)
                        print (instance['Instances'][0]['InstanceId'], command)
                        ssm_response = self.sendSSM(instance['Instances'][0]['InstanceId'], command, 'Patching')
                        if (not ssm_response):

                            sys.exit(1)
                else:
                    for patch in self.patch:
                        if(patch >= self.deploy_from):
                            command = "%s" % (self.patch[patch][0])
                            print("==== Running the patch for patch number %s ====" % patch)
                            ssm_response = self.sendSSM(instance['Instances'][0]['InstanceId'], command, 'Patching')
                            if (not ssm_response):
                                sys.exit(1)
        except Exception as e:
            raise Exception('An exception occurred while publishing a message: %s' % e)

    def sendSSM(self, instanceId, command, stage):
        """ What does it do?

        :param ?: ?
        :returns: ?
        """

        print("==== Running SSM Commands ====")
        print (instanceId, command)
        try:
            response = self.ssm.send_command(
                InstanceIds=[instanceId],
                DocumentName="AWS-RunShellScript",
                Comment="Patch",
                Parameters={
                    'commands': [command]
                },
                CloudWatchOutputConfig={
                    'CloudWatchLogGroupName': 'SSM',
                    'CloudWatchOutputEnabled': True
                }
            )
            time.sleep(5)
            status = True
            return_status = True
            while (status):
                response1 = self.ssm.list_command_invocations(CommandId=response['Command']['CommandId'])
                s = response1['CommandInvocations'][0]['Status']
                print("==== SSM Command Status: %s ====" % s)
                if ((s != 'Success') and (s != 'Failed') and (s != 'Cancelled') and (s != 'TimedOut')):
                    status = True
                elif ((s == 'Failed') or (s == 'Cancelled') or (s == 'TimedOut')):
                    print("==== %s stage on instance with id %s failed, hence exiting the system ====" % (stage, instanceId))
                    return_status = False
                    subject = "%s stage on instance with id %s failed" % (stage, instanceId)
                    message = """
{a:<20} : {r_time}
{b:<20} : {r_instance}
{c:<20} : {r_status}
{d:<20} : {r_detail}
""".format(a='Time', b='Instance Id', c='Status', d='Status Detail', r_time=response1['CommandInvocations'][0]['RequestedDateTime'], r_instance=instanceId, r_status=s, r_detail='For more information, please see CloudWatch Log Group SSM')
                    self.sendMessage(subject, message)
                    break
                elif (s == 'Success'):
                    status = False
                time.sleep(2)
            return return_status
        except Exception as e:
            raise Exception('An exception occurred: %s' % e)

    def updateGoldenAMI(self):
        """ What does it do?

        :param ?: ?
        :returns: ?
        """

        try:
            response_instances = self.getInstances()
            instanceId = response_instances['Reservations'][0]['Instances'][0]['InstanceId']
            response_create_ami = self.ec2.create_image(
                Description='This is a snapshot for golden image',
                DryRun=False,
                InstanceId=instanceId,
                Name='golden-image-%s' % (datetime.now().strftime('%Y-%m-%d-%H-%M')),
                NoReboot=True
            )
            time.sleep(20)
            while (True):
                describe_image_response = self.ec2.describe_images(
                    ImageIds=[response_create_ami['ImageId']]
                )
                print("==== Golden Image status: %s ====" % describe_image_response['Images'][0]['State'])
                if (describe_image_response['Images'][0]['State'] == "available"):
                    print("==== Golden Image is available ====")
                    break
                print("==== Golden Image is not available, hence waiting ====")
                time.sleep(10)
            #What here
            print("==== Adding SSM parameters ====")

            print ("==== checking if parameter, exist ====")
            try:
                response = self.ssm.get_parameter(
                    Name='/golden_ami_id',
                    WithDecryption=True
                )
                if(response):
                    self.ssm.delete_parameter(
                        Name='/golden_ami_id'
                    )
                    time.sleep(2)
                    self.ssm.put_parameter(
                    Name='/golden_ami_id',
                    Description='This is the latest  AMI id',
                    Value=response_create_ami['ImageId'],
                    Type='String',
                    Tags=self.tags
                    )
            except:
                print ("==== Parameter does not exist, hence this is first time patching ====")
                self.ssm.put_parameter(
                    Name='/golden_ami_id',
                    Description='This is the latest  AMI id',
                    Value=response_create_ami['ImageId'],
                    Type='String'
                )
            subject = 'New Golden Image available'
            message = """
{a:<20} : {r_detail}
{b:<20} : {r_image}
""".format(a='Detail', b='Image Id', r_detail='A new Golden Image has been created. To use the new Image, please update Terraform', r_image=response_create_ami['ImageId'])
            self.sendMessage(subject, message)
        except Exception as e:
            raise Exception('An exception occurred: %s' % e)


"""
    def createS3bucket(self):
 

        buckets = self.s3.list_buckets()
        for i in buckets['Buckets']:
            if (i['Name'] == self.patchBucket):
                print("==== Bucket with name %s exist, hence not creating a new one ====" % self.patchBucket)
        else:
            try:
                self.s3.create_bucket(
                    Bucket=self.patchBucket,
                    ACL='private'
                )
                self.s3.put_bucket_versioning(
                    Bucket=self.patchBucket,
                    VersioningConfiguration={
                        'MFADelete': 'Disabled',
                        'Status': 'Enabled'
                    }
                )
                self.s3.put_bucket_encryption(
                    Bucket=self.patchBucket,
                    ServerSideEncryptionConfiguration={
                        'Rules': [
                            {
                                'ApplyServerSideEncryptionByDefault': {
                                    'SSEAlgorithm': 'AES256'
                                }
                            }
                        ]
                    }
                )
            except Exception as e:
                raise Exception('An exception occurred while publishing a message: %s' % e)
        for patchnumber in self.patch:
            bucket = "%s-apply-fixpack" % (patchnumber)
            print("==== This is bucket %s ====" % bucket)
            self.s3.put_object(
                Bucket=self.patchBucket,
                Body='',
                Key='%s/' % (bucket)
            )
            for patchfile in self.patch[patchnumber]:
                if (patchfile):
                    patchfile = "%s" % (patchfile)
                    for key in self.s3.list_objects(Bucket=self.patchBucket)['Contents']:
                        files = key['Key']
                        if (files == patchfile):
                            print("==== Copying the %s to bucket %s and folder %s ====" % (files, self.patchBucket, bucket))
                            copy_source = {'Bucket': self.patchBucket, 'Key': files}
                            self.s3_resource.meta.client.copy(copy_source, self.patchBucket, '%s/%s' % (bucket, files))
"""

def main():
    """ What does it do?

    :param ?: ?
    :returns: ?
    """

    parser = argparse.ArgumentParser()
    parser.add_argument('-environment', help='please enter the environment to build')
    parser.add_argument('-appcomponent', help='please enter the application component')
    parser.add_argument('-updateGoldenImage', help='please enter the golden image decision')
    parser.add_argument('-topicarn', help='please enter the topic arn')
    args = parser.parse_args()
    p = patch(args.environment, args.appcomponent,  args.topicarn)
    update = args.updateGoldenImage

    if(update == "True"):
        p.updateGoldenAMI()
    else:
        p.createSnapShot()


if __name__ == "__main__":
    main()
