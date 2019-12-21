# Deployment report

## Deployment testing

This deployment has been tested on 5.3.8-3-MANJARO (Linux) and 18.04.1-Ubuntu.

## Requirements

### Shell programs

* [`jps`](https://docs.oracle.com/javase/7/docs/technotes/tools/share/jps.html);
* [`OpenSSH`](https://www.openssh.com) [Ubuntu doc](https://help.ubuntu.com/lts/serverguide/openssh-server.html);
* [`tar`](https://linux.die.net/man/1/tar) [Ubuntu doc](https://manpages.ubuntu.com/manpages/bionic/en/man1/tar.1.html);
* [`zip`](https://linux.die.net/man/1/zip) [Ubuntu doc](http://manpages.ubuntu.com/manpages/trusty/man1/zip.1.html);
* `awk` [Ubuntu doc](http://manpages.ubuntu.com/manpages/trusty/man1/awk.1posix.html);
* `python3.7` [Ubuntu doc](https://packages.ubuntu.com/search?keywords=python3.7);
* `pip3` [Ubuntu doc](http://manpages.ubuntu.com/manpages/xenial/man1/pip.1.html);
* `wget` [Ubuntu doc](http://manpages.ubuntu.com/manpages/bionic/man1/wget.1.html).

### Environment variables

The application runs HDFS locally, hence java8 and `JAVA_HOME` will be required when running `start-app.sh`. It will be used on HDFS and spark's start-up as we are using for both of them the standalone deployment mode ([spark](https://spark.apache.org/docs/latest/spark-standalone.html), [hadoop](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)). Thus we suggest to set this environment variable in the `~/.profile` or `~/.bash_profile`.

* `export JAVA_HOME=/path/to/java8' (e.g. `/usr/lib/jvm/java-8-openjdk`)

### Open ports

* 9870 - Namenode UI;
* 9000 - HDFS IPC;
* 9092 - Kafka;
* 2181 - Zookeeper;
* 7077 - Spark master;
* 4040/8080 - Spark master UI.

### Instructions

Please repeat the following steps:

1. install the aforementioned shell programs;
2. set the environment variables;
3. make sure that the ports are open and available;
4. start the ssh server (sshd service e.g.[ `systemctl start sshd`](http://manpages.ubuntu.com/manpages/bionic/man1/systemctl.1.html));
5. execute:
```bash
cd code/     # from the project home folder
./download_apps.sh # this will download kafka, hadoop and spark
pip3 install -r mysimbdp/requirements.txt # consider using a *virtual environment* (venv)
```
```bash
./ssh_setup.sh
eval $(ssh-agent -s)
ssh-add -k ./.ssh/bdp3-768478_rsa
```
```bash
./start_app.sh
```
6. follow the instructions on screen in terminal `T1` (NB: on startup hadoop may try formatting its datanode, input `Y`);

7. To have a nice view of how the application works, open another terminal (`T2`) and execute:

```bash
cd logs
tail -f logs/spark-logs
```
8. Once spark is operating and computing the first batch you can trigger the client sending test stream of messages just pressing `ENTER` in `T1`. When logs similar to the following appear in `T2`, you may press `ENTER` in `T1`.

```
[19/11/28 12:44:35 INFO KafkaRDD: Beginning offset 0 is the same as ending offset skipping taxis_in 1
[19/11/28 12:44:35 INFO PythonRunner: Times: total = 53, boot = -314, init = 367, finish = 0
[19/11/28 12:44:35 INFO PythonRunner: Times: total = 48, boot = -320, init = 368, finish = 0
[19/11/28 12:44:35 INFO Executor: Finished task 0.0 in stage 1.0 (TID 1). 1386 bytes result sent to driver
-------------------------------------------
Time: 2019-11-28 12:44:30
-------------------------------------------
```

9. After `ENTER` is pressed, `T1` will show the results received by the client application once per 5 seconds.

10. You can test the application is correctly working on a small dataset using this [file](../data/taxis-test.xls).

11. Pressing `Ctrl-C` `start_app.sh` will call `stop-app.sh` which will shutdown the whole application. Let the program terminate gracefully, otherwise you may encounter errors in the next build.  If this happens, before running `start_app.sh`, please run `stop_app.sh`.

### Final considerations

> You may want to read the documentation of the main bash scripts of our platform before using them.

> As already mentioned the `ssh-setup.sh` command will create a ssh keypair in `code/mysimbdp/.ssh`. The public key will be then automatically stored to the `authorized_keys` file used by the ssh server (localhost in this case) to authenticate the Spark workers and HDFS components.

> If you want to prevent installation of python packages in your system, please create and use a [virtual environment](https://docs.python.org/3/library/venv.html) before triggering the first command at (point 5). Here is a good [tutorial](https://gist.github.com/Geoyi/d9fab4f609e9f75941946be45000632b) how to set it up, the version of the python interpreter must be `python3.7`.

> In order to clear the modification to ssh files (`authorized_keys`) please execute `./clear_ssh.sh`.

> Modifications to the deployment can be done editing the [configuration files](../code/mysimbdp/conf_files) of the platform.

> Logs are automatically generated in the [logs folder](../logs).
