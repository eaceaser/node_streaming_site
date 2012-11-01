yum -y install git gcc gcc-c++ openssl-devel monit strace

ssh-keygen -t rsa -C "deploy@heypic.me"

git clone git@github.com:siggy/heypic.me.git

sudo iptables -A INPUT -p tcp --dport ssh -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

wget http://redis.googlecode.com/files/redis-2.4.2.tar.gz
tar xzf redis-2.4.2.tar.gz
cd redis-2.4.2
make
make install

cp ./redis.conf /etc/redis.conf
cp ./redis /etc/init.d/redis
chmod u+x /etc/init.d/redis

wget http://mmonit.com/monit/dist/monit-5.3.1.tar.gz
tar xzf monit-5.3.1.tar.gz
cd monit-5.3.1
./configure
make
make install

mv /usr/bin/monit /usr/bin/monit-old
ln -s /usr/local/bin/monit /usr/bin/monit

cp ./monitrc /etc/

mkdir -p /etc/monit.d/

cp ./monit/heypic_streamer /etc/monit.d/
cp ./monit/heypic_processor /etc/monit.d/
cp ./monit/heypic_server /etc/monit.d/
cp ./monit/redis /etc/monit.d/

groupadd deploy
adduser -g deploy deploy

chown -R deploy:deploy /etc/monit.d/heypic_streamer
chown -R deploy:deploy /etc/monit.d/heypic_processor
chown -R deploy:deploy /etc/monit.d/heypic_server

mkdir -p /tmp/heypic/
chown -R deploy:deploy /tmp/heypic/
chmod a+w /tmp/heypic/

# in /etc/init.d/monit
# CONFIG="/etc/monitrc"

/etc/init.d/monit start

git clone git://github.com/joyent/node.git
cd node
git checkout v0.4.12
./configure
make -j2
make install

curl http://npmjs.org/install.sh | sh

# deploy user
groupadd deploy
useradd -d /home/deploy -s /bin/bash -m deploy
echo deploy: | chpasswd
usermod -a -G deploy deploy
mkdir /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
mkdir /var/log/heypic
mkdir /usr/local/heypic
chown -R deploy:deploy /var/log/heypic
chown -R deploy:deploy /usr/local/heypic
echo 'deploy ALL=(ALL) ALL' >> /etc/sudoers
echo '%deploy ALL=NOPASSWD: ALL' >> /etc/sudoers

# dev system
gem install bundler
bundle
