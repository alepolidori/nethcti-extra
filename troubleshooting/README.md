### [nethcti3-troubleshooting.sh](https://raw.githubusercontent.com/alepolidori/nethcti-extra/master/troubleshooting/nethcti3-troubleshooting.sh)

Print some server information related to [NethCTI](https://github.com/nethesis/nethcti-server) application to simplify the troubleshooting.

#### [Download](https://raw.githubusercontent.com/alepolidori/nethcti-extra/master/troubleshooting/nethcti3-troubleshooting.sh)

#### Help message

You can see how to use it by executing the script without parameters.

![](https://trello-attachments.s3.amazonaws.com/4f86d016a53e842c6711eb2e/5d809bde152529692e275e78/51ab249d0c21b69b4e8dc26288eeabce/Screenshot_from_2019-09-17_12-56-11.png)

#### TODO before usage

Open the script and replace `username` variable with your SOS username.
Example:

from

![](https://trello-attachments.s3.amazonaws.com/4f86d016a53e842c6711eb2e/5d809bde152529692e275e78/e81ac5f32edf53d8a4346c2684ed8169/image.png)

to

![](https://trello-attachments.s3.amazonaws.com/4f86d016a53e842c6711eb2e/5d809bde152529692e275e78/81a034ea6f7229f55ff29d621c571537/image.png)

#### How to use

It can be executed:

- from your machine using SOS ID

`./nethcti3-troubleshooting.sh cff8795e-e4ae-43e2-a0...`

- from your machine using connection parameters as with SSH connections

```
./nethcti3-troubleshooting.sh root@192.168.5.244
./nethcti3-troubleshooting.sh root@192.168.5.244:2222
```

- copying it into the NethVoice machine and executing it locally

`./nethcti3-troubleshooting.sh localhost`
