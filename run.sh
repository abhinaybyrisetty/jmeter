#!/bin/bash
ORG=$1
GIT_REPO=$2
OES_GATE_IP=$3
OES_UI_IP=$4
PORT=$5
SCHEME=$6
USERNAME=$7
PASSWORD=$8
JMX_FILE=$9

echo -e "Running JMeter tests...\n"
git clone https://github.com/$ORG/$GIT_REPO.git &> git_out.txt
cd $GIT_REPO
rm -rf result.jtl jmeter.log jmeter_console.txt
jmeter -n -Jgate-url=$OES_GATE_IP -Jui-url=$OES_UI_IP -Jport=$PORT -Jprotocol=$SCHEME -Jusername=$USERNAME \
          -Jpassword=$PASSWORD -t $JMX_FILE -l result.jtl -j jmeter.log > jmeter_console.txt

RETURN_CODE=$?

if [ $RETURN_CODE -eq 0 ]; then
  echo -e "\nJMeter execution successfully completed\n"
  echo -e '\t === JMeter Execution Summary ==== \t\t\n\n'
  cat jmeter_console.txt | grep "summary"

  echo -e "Pushing artifacts to GitHub\n\n"
  # Push the output files to github for reference
  git config --global user.email "vamsi.krishna@opsmx.io"
  git config --global user.name "vkvamsiopsmx"
  git commit -m "adding the reports back" &> git_out.txt
  git push https://vkvamsiopsmx:6d3481ae2da96648c95013d29f8cb04246da2e15@github.com/$1/$2.git --all &> git_out.txt

  ERRORS=$(cat jmeter_console.txt | grep -e "Err:" | awk -F' ' '{print $14 $15}')
  for output in $ERRORS; do
    if [[ ! "$output" =~ ^Err:0$ ]]; then
      echo "Errors detected!!!; Breaking pipeline\n";
      echo -e $output;
      exit 1;
    fi
  done
  echo -e "\n\n\nNo errors detected, JMeter stage execution successfully completed\n"
  exit 0
else
  ## Error while executing Jmeter script
  echo -e "\nError encountered while executing Jmeter script\n"
  cat jmeter_console.txt
  exit $RETURN_CODE
fi
