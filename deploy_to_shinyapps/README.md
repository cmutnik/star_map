# Shinyapps Deployment

[![Demo](https://img.shields.io/badge/Website-live-green)](http://takotime808.shinyapps.io/star_map)

**Deployment Step 0:**

Install necessary package:

```bash
Rscript -e "install.packages('rsconnect')"
```

**Deployment Step 1:**

Open the file [deployment_step_1.R](deployment_step_1.R) and populate the 
fields accordingly. Then run the following shell command:

```bash
Rscript deployment_step_1.R
```

**Deployment Step 2:**

Make sure the file `app.R` is in [star_map](./star_map/), 
[here](star_map/app.R). Then run the following shell command:

```bash
Rscript deployment_step_2.R
```

In this script, the path is already populated to be `star_map`.

Once this is completed, the site will be live at [http://takotime808.shinyapps.io/star_map](http://takotime808.shinyapps.io/star_map).