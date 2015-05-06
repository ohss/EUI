# Source for gh-pages

This site uses a Jekyll plugin for image galleries, so you have to compile Jekyll locally and push the _site folder to the gh-pages branch.

## run:

* jekyll build
* cd _site
* git init
* git remote add origin git@github.com:ohss/EUI.git

After git init run

* git add .
* git commit -m "latest build"
* git push origin master:gh-pages

Or run 

* jekgit.sh "Latest build"

From the root directory
