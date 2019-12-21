# Assignment 3

In this project we simulate the behaviour of a streaming application executing simple analytics on input data. 

Once built the software is organized as represented below:

```bash
code
├── app-env.sh
├── clear_ssh.sh
├── client
│   ├── taxis-dequeuer.sh
│   └── taxis-enqueuer.py
├── download_apps.sh
├── mysimbdp
│   ├── conf_files
│   ├── hadoop-3.1.2
│   ├── kafka-2.3.1
│   ├── pydeps
│   ├── pydeps.zip
│   ├── requirements.txt
│   ├── spark-2.4.4
│   └── taxis-streamapp.py
├── README.md
├── ssh_setup.sh
├── start_app.sh
└── stop_app.sh
```

* `client`: contains the programs executed on the client machine;
* `mysimbdp`: will include the actual components of the platform and their [configuration](code/mysimbdp/conf_files);
* `code`: is composed also of setup scripts.

Follow the [deployment guide](code/README-deployment.md), to deploy this software as a standalone application in your local machine. 

You may find interesting to view some [logs](logs/spark-logs) of the application.
