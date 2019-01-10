#! /usr/bin/python

import json
import os
import sys
import boto3

def _main(args):
	print(type(args[2]))
	client = boto3.client('sts')
	response = client.get_session_token(
	    DurationSeconds=129600,
	    SerialNumber=args[1],
	    TokenCode=args[2],
	)
	print(response)

	cmd1 = "export AWS_SESSION_TOKEN=\""+response['Credentials']['SessionToken']+"\""
	cmd2 = "export AWS_SECRET_ACCESS_KEY=\""+response['Credentials']['SecretAccessKey']+"\""
	cmd3 = "export AWS_ACCESS_KEY_ID=\""+response['Credentials']['AccessKeyId']+"\""

	f= open("session.sh","w+")
	f.write("#!/bin/sh"+ "\n")
	f.write(cmd1+ "\n")
	f.write(cmd2+ "\n")
	f.write(cmd3+ "\n")
	f.close()

if __name__ == '__main__':
    _main(sys.argv)