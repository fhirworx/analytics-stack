sudo swupd bundle-add package-utils
cd /opt 
mkdir gitlab
wget --content-disposition https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-13.6.1-ce.0.el7.x86_64.rpm/download.rpm
mv gitlab-ce-13.6.1-ce.0.el7.x86_64.rpm ./gitlab-ce.rpm
rpm2cpio gitlab-ce.rpm | ( cd /; cpio -idv)
rm gitlab-ce.rpm
sudo swupd bundle-remove package-utils

