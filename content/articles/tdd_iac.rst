====================================
Using TDD to boost your IaC strategy
====================================

:Date: 2020-01-13 16:34
:Modified: 2020-01-13 16:34
:Category: Python
:Tags: python, iac, tdd, testing
:Slug: tdd-iac
:Authors: Sean Marlow
:Summary: Using TDD with Pytest to drive production of Salt states for an example Flask app.

Overview
--------

The goal of this presentation is to provide an example of how you can test
software defined infrastructure code with Python integration tests.

Tech stack
^^^^^^^^^^

* Pytest with Testinfra plugin for integration tests
* Salt states for infrastructure configuration
* Example Flask app that provides pancake ingredients
* Terraform for automating the test suite (if time permits)

App requirements
^^^^^^^^^^^^^^^^

* Python3
* Flask
* Apache2
* mod_wsgi

App info
^^^^^^^^

The example app is a simple Flask API that exposes four endpoints related
to pancake types and ingredients. The endpoints include:

* GET All: /pancakes/
* GET Type: /pancakes/banana
* Add Type (POST): /pancakes/
* DELETE Type: /pancakes/fake

The app runs in Apache2 with the mod_wsgi plugin and is Python3 based. The data
is stored in a json file which by default is located at /user/lib/pancake/pancakes.json.

Links
^^^^^

* Example Flask app: https://github.com/smarlowucf/glowing-pancake
* App config (tests & states): https://github.com/smarlowucf/glowing-pancake-config
* Presentation files: https://github.com/smarlowucf/presentations/tree/master/tdd_iac
* Pytest: https://docs.pytest.org/en/latest/
* Testinfra: https://testinfra.readthedocs.io/en/latest/
* Salt: https://docs.saltstack.com/en/latest/

Writing tests
-------------

Pancake user
^^^^^^^^^^^^

Ensure we have a pancake user that the app can run as. We want the users
home directory to be /var/lib/pancake and the user should have a group with
the same name.

The host parameter is a fixture provided by Testinfra. This is the main module
which we will focus on for the remainder of the test suite.

.. code-block:: python
   :linenos: table
   :hl_lines: 2 6

   def test_pancake_user(host):
       user = host.user('pancake')
    
       assert user.group == 'users'
       assert 'pancake' in user.groups
       assert user.home == '/var/lib/pancake'

Packages
^^^^^^^^

Check that all required packages are installed. This test is using the
paramterize function from Pytest. It allows us to re-use a given test
based on a list of arguments. Here the test runs four times to confirm
all packages are installed.

.. code-block:: python
   :linenos: table
   :hl_lines: 3 4 5 6 7 8

   import pytest

   @pytest.mark.parametrize('name', [
       ('apache2'),
       ('python3-Flask'),
       ('apache2-mod_wsgi-python3'),
       ('git')
   ])
   def test_required_packages(host, name):
       assert host.package(name).is_installed

Apache service
^^^^^^^^^^^^^^

Make sure Apache service is running and enabled.

.. code-block:: python
   :linenos: table
   :hl_lines: 2

   def test_apache2_service(host):
       srv = host.service('apache2')

       assert srv.is_running
       assert srv.is_enabled

Configuration files
^^^^^^^^^^^^^^^^^^^

Using the file module from the host fixture we can ensure that all config
files exist, have the correct owner and the correct permissions.

.. code-block:: python
   :linenos: table
   :hl_lines: 9 12

   import pytest

   @pytest.mark.parametrize('name', [
       ('/var/lib/pancake/wsgi.py'),
       ('/etc/apache2/vhosts.d/pancake.conf'),
       ('/var/lib/pancake/pancakes.json')
   ])
   def test_pancake_config_files(host, name):
       wsgi = host.file(name)

       assert wsgi.exists
       assert wsgi.is_file
       assert wsgi.user == 'pancake'
       assert wsgi.group == 'pancake'
       assert oct(wsgi.mode) == '0o644'

Project git directory
^^^^^^^^^^^^^^^^^^^^^

The file module can also be used to check directory attributes. Here we ensure
the project git directory is in place and owned by the main instance user.
For openSUSE Leap EC2 images this user is ec2-user.

.. code-block:: python
   :linenos: table
   :hl_lines: 2 5

   def test_pancake_repo(host):
       wsgi = host.file('/home/ec2-user/projects/pancake')

       assert wsgi.exists
       assert wsgi.is_directory
       assert wsgi.user == 'ec2-user'
       assert wsgi.group == 'users'
       assert oct(wsgi.mode) == '0o755'

Instance OS
^^^^^^^^^^^

Confirm the instance is indeed a Leap 15.1 instance based on the
/etc/os-release data. This uses a pytest fixture which allows for
code reusability. The fixture is inline but it could also be stored in
a conftest.py file which would make it usable by all test modules.

.. code-block:: python
   :linenos: table
   :hl_lines: 1 17 18

   @pytest.fixture()
   def get_release_value(host):
       def f(key):
           release = host.file('/etc/os-release')
           value = None
           key += '='

           for line in release.content_string.split('\n'):
               if line.startswith(key):
                   value = line[len(key):].replace('"', '').replace("'", '')
                   value = value.strip()
                   break

           return value
       return f

   def test_instance_os_name(get_release_value):
       name = get_release_value('PRETTY_NAME')
       assert name == 'openSUSE Leap 15.1'

App endpoints
^^^^^^^^^^^^^

This step is optional. The app is deployed by configuration management
but would ideally be tested by it's own CI/CD pipeline. These examples
show how you can run arbitrary commands against the instance using the
host run module.

.. code-block:: python
   :linenos: table
   :hl_lines: 2 4 5

   def test_pancake_app_get_types(host):
       cmd = host.run('curl http://localhost:5000/pancakes/')

       assert cmd.rc == 0
       assert 'banana' in cmd.stdout
       assert 'plain' in cmd.stdout


   def test_pancake_app_get_type(host):
       cmd = host.run('curl http://localhost:5000/pancakes/banana')

       assert cmd.rc == 0
       assert 'banana' in cmd.stdout
       assert 'walnuts' in cmd.stdout


   def test_pancake_app_add_delete_type(host):
       # Add fake pancake type with no ingredients
       cmd = host.run(
           'curl -H "Content-Type: application/json" '
           '-d \'{"name": "fake", "ingredients": []}\' '
           'http://localhost:5000/pancakes/'
       )

       assert cmd.rc == 0
       assert 'Pancake added' in cmd.stdout
       assert host.run('curl http://localhost:5000/pancakes/fake').rc == 0

       # Delete fake pancake type
       cmd = host.run(
           'curl -X DELETE curl http://localhost:5000/pancakes/fake'
       )
       assert cmd.rc == 0
       assert 'Pancake deleted' in cmd.stdout

       # Confirm fake type deleted
       out = host.run('curl http://localhost:5000/pancakes/fake').stdout
       assert 'Unable to retrieve pancake type' in out

Useful plugins/options
^^^^^^^^^^^^^^^^^^^^^^

* pytest-xdist: Run tests in parallel on multiple cores
* pytest --lf: Run only failed tests from previous execution
* Fixtures: To make code modular and scalable
* Parameterize: To re-run tests with different arguments

Building Salt states
--------------------

Confirm tests fail
^^^^^^^^^^^^^^^^^^

Now that the test suite is in place we can run everything to confirm all tests
fail. The tests are are run against a newly provisioned openSUSE Leap 15.1
instance in AWS.

.. code-block:: bash
   :linenos: table
   :hl_lines: 20 25

   16:54:57 ▶ pytest -v --ssh-config ssh.conf --hosts 0.0.0.0 tests/test_pancake.py
   ================================= test session starts ==========================
   platform linux -- Python 3.7.3, pytest-5.2.1, py-1.8.0, pluggy-0.13.0 -- 
   /home/user/projects/venvs/mash/bin/python3
   cachedir: .pytest_cache
   rootdir: /home/user
   plugins: testinfra-3.2.0, cov-2.8.1
   collected 14 items

   test_pancake_user FAILED                                      [  7%]
   test_required_packages[apache2] FAILED                         [ 14%]
   test_required_packages[python3-Flask] FAILED                   [ 21%]
   test_required_packages[apache2-mod_wsgi-python3] FAILED        [ 28%]
   test_required_packages[git] FAILED                             [ 35%]
   test_apache2_service FAILED                                   [ 42%]
   test_pancake_config_files[/var/lib/pancake/wsgi.py] FAILED     [ 50%]
   test_pancake_config_files[/etc/apache2/vhosts.d/pancake.conf] FAILED [ 57%]
   test_pancake_config_files[/var/lib/pancake/pancakes.json] FAILED [ 64%]
   test_pancake_repo FAILED                                      [ 71%]
   test_instance_os_name PASSED                                  [ 78%]
   test_pancake_app_get_types FAILED                             [ 85%]
   test_pancake_app_get_type FAILED                              [ 92%]
   test_pancake_app_add_delete_type FAILED                       [100%]

   ============================= 13 failed, 1 passed in 4.62s ===================

Everything fails except the os name check. This is expected as os-release
should already match the proper value.

Add states for pancake user
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first state will create a pancake user and a group with the same name.
The user is added to the group and the home directory is set to
/var/lib/pancake.

.. code-block:: yaml
   :linenos: table
   :hl_lines: 2 6 9 11

   pancake-group:
     group.present:
       - name: pancake

   pancake-user:
     user.present:
       - name: pancake
       - fullname: Pancake App User
       - home: /var/lib/pancake
       - groups:
         - pancake
       - require:
         - group: pancake
     group.present: []

Now we can apply the state to create the new user:

.. raw:: html

   &nbsp;

.. code-block:: bash
   :linenos: table
   :hl_lines: 1

   $ sudo salt-call --local state.sls pancake.user

   ...

   Summary for local

   Succeeded: 3 (changed=3)
   Failed:    0

   Total states run:     3
   Total run time: 145.654 ms

All three states were applied successfully so we can re-run the test suite
to confirm that the user test is now passing.

.. code-block:: bash
   :linenos: table
   :hl_lines: 10 25

   16:54:57 ▶ pytest -v --ssh-config ssh.conf --hosts 0.0.0.0 tests/test_pancake.py
   ================================= test session starts =========================
   platform linux -- Python 3.7.3, pytest-5.2.1, py-1.8.0, pluggy-0.13.0 -- 
   /home/user/projects/venvs/mash/bin/python3
   cachedir: .pytest_cache
   rootdir: /home/user
   plugins: testinfra-3.2.0, cov-2.8.1
   collected 14 items

   test_pancake_user PASSED                                      [  7%]
   test_required_packages[apache2] FAILED                         [ 14%]
   test_required_packages[python3-Flask] FAILED                   [ 21%]
   test_required_packages[apache2-mod_wsgi-python3] FAILED        [ 28%]
   test_required_packages[git] FAILED                             [ 35%]
   test_apache2_service FAILED                                   [ 42%]
   test_pancake_config_files[/var/lib/pancake/wsgi.py] FAILED     [ 50%]
   test_pancake_config_files[/etc/apache2/vhosts.d/pancake.conf] FAILED [ 57%]
   test_pancake_config_files[/var/lib/pancake/pancakes.json] FAILED [ 64%]
   test_pancake_repo FAILED                                      [ 71%]
   test_instance_os_name PASSED                                  [ 78%]
   test_pancake_app_get_types FAILED                             [ 85%]
   test_pancake_app_get_type FAILED                              [ 92%]
   test_pancake_app_add_delete_type FAILED                       [100%]

   ============================= 12 failed, 2 passed in 6.50s ===================

Add states for Apache server
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are multiple states required for the Apache server. The app requires
two packages (apache2, apache2-mod_wsgi-python3) and the apache2 service
to be running and enabled.

Also we have the vhost configuration file and the wsgi Python module which
mod_wsgi will be using to run the Flask app.

.. code-block:: yaml
   :linenos: table
   :hl_lines: 5 7 14 19 20 26 27 28 35 36 37

   include:
     - pancake.user

   apache2:
     pkg.latest:
       - refresh: True
     service.running:
       - enable: True
       - reload: True
       - watch:
         - pkg: apache2

   apache2-mod_wsgi-python3:
     pkg.latest:
       - refresh: True
       - require:
         - pkg: apache2

   /etc/apache2/vhosts.d:
     file.directory:
       - user: root
       - group: root
       - mode: 755
       - makedirs: True

   /var/lib/pancake/wsgi.py:
     file.managed:
       - source: salt://pancake/files/wsgi.py
       - user: pancake
       - group: pancake
       - mode: 644
       - require:
         - sls: pancake.user

   /etc/apache2/vhosts.d/pancake.conf:
     file.managed:
       - source: salt://pancake/files/pancake.conf
       - user: pancake
       - group: pancake
       - mode: 644
       - require:
         - file: /etc/apache2/vhosts.d
         - sls: pancake.user

We apply the new states:

.. code-block:: bash
   :linenos: table
   :hl_lines: 1

   $ sudo salt-call --local state.sls pancake.apache

   ...

   Summary for local

   Succeeded: 9 (changed=5)
   Failed:    0

   Total states run:     9
   Total run time:  65.174 s

And finally re-run the test suite to confirm more tests are passing.

.. code-block:: bash
   :linenos: table
   :hl_lines: 11 13 15 16 17

   16:54:57 ▶ pytest -v --ssh-config ssh.conf --hosts 0.0.0.0 tests/test_pancake.py
   ================================= test session starts ==========================
   platform linux -- Python 3.7.3, pytest-5.2.1, py-1.8.0, pluggy-0.13.0 -- 
   /home/user/projects/venvs/mash/bin/python3
   cachedir: .pytest_cache
   rootdir: /home/user
   plugins: testinfra-3.2.0, cov-2.8.1
   collected 14 items

   test_pancake_user PASSED                                      [  7%]
   test_required_packages[apache2] PASSED                         [ 14%]
   test_required_packages[python3-Flask] FAILED                   [ 21%]
   test_required_packages[apache2-mod_wsgi-python3] PASSED        [ 28%]
   test_required_packages[git] FAILED                             [ 35%]
   test_apache2_service PASSED                                   [ 42%]
   test_pancake_config_files[/var/lib/pancake/wsgi.py] PASSED     [ 50%]
   test_pancake_config_files[/etc/apache2/vhosts.d/pancake.conf] PASSED [ 57%]
   test_pancake_config_files[/var/lib/pancake/pancakes.json] FAILED [ 64%]
   test_pancake_repo FAILED                                      [ 71%]
   test_instance_os_name PASSED                                  [ 78%]
   test_pancake_app_get_types FAILED                             [ 85%]
   test_pancake_app_get_type FAILED                              [ 92%]
   test_pancake_app_add_delete_type FAILED                       [100%]

   ============================= 7 failed, 7 passed in 6.81s =====================

Add states for pancake app
^^^^^^^^^^^^^^^^^^^^^^^^^^

The final set of states are for the pancake app itself. These states will pull
the Flask code from GitHub and install the app in development mode. Prior to
this both the Git and Flask system packages are installed if necessary. Then
the pancake json database file is copied to the pancake user home directory.

.. code-block:: yaml
   :linenos: table
   :hl_lines: 4 5 12 13 16 17 20 21 22 30 31 36 37 38

   include:
     - pancake.user

   /home/ec2-user/projects/pancake:
     file.directory:
       - user: ec2-user
       - group: users
       - mode: 755
       - makedirs: True

   git package is installed:
     pkg.installed:
       - name: git

   python3-Flask installed:
     pkg.installed:
       - name: python3-Flask

   pancake-code:
     git.latest:
       - name: https://github.com/smarlowucf/glowing-pancake.git
       - target: /home/ec2-user/projects/pancake/
       - user: ec2-user
       - branch: master
       - require:
         - pkg: git
         - pkg: python3-Flask

   pancake-dev:
     cmd.run:
       - name: sudo python3 setup.py develop
       - cwd: /home/ec2-user/projects/pancake
       - require:
         - git: pancake-code

   /var/lib/pancake/pancakes.json:
     file.managed:
       - source: salt://pancake/files/pancakes.json
       - user: pancake
       - group: pancake
       - mode: 644
       - require:
         - sls: pancake.user

We apply the new states:

.. code-block:: bash
   :linenos: table
   :hl_lines: 1

   $ sudo salt-call --local state.sls pancake.apache

   ...

   Summary for local

   Succeeded: 9 (changed=6)
   Failed:    0

   Total states run:     9
   Total run time:  60.001 s

With all states run we can confirm the test suite.

.. code-block:: bash
   :linenos: table
   :hl_lines: 12 14 18 19

   16:54:57 ▶ pytest -v --ssh-config ssh.conf --hosts 0.0.0.0 tests/test_pancake.py
   ================================= test session starts ==========================
   platform linux -- Python 3.7.3, pytest-5.2.1, py-1.8.0, pluggy-0.13.0 -- 
   /home/user/projects/venvs/mash/bin/python3
   cachedir: .pytest_cache
   rootdir: /home/user
   plugins: testinfra-3.2.0, cov-2.8.1
   collected 14 items

   test_pancake_user PASSED                                      [  7%]
   test_required_packages[apache2] PASSED                         [ 14%]
   test_required_packages[python3-Flask] PASSED                   [ 21%]
   test_required_packages[apache2-mod_wsgi-python3] PASSED        [ 28%]
   test_required_packages[git] PASSED                             [ 35%]
   test_apache2_service PASSED                                   [ 42%]
   test_pancake_config_files[/var/lib/pancake/wsgi.py] PASSED     [ 50%]
   test_pancake_config_files[/etc/apache2/vhosts.d/pancake.conf] PASSED [ 57%]
   test_pancake_config_files[/var/lib/pancake/pancakes.json] PASSED [ 64%]
   test_pancake_repo PASSED                                      [ 71%]
   test_instance_os_name PASSED                                  [ 78%]
   test_pancake_app_get_types FAILED                             [ 85%]
   test_pancake_app_get_type FAILED                              [ 92%]
   test_pancake_app_add_delete_type FAILED                       [100%]

   ============================= 3 failed, 11 passed in 8.08s ===================

All of the app tests are still failing. For now we can manually restart Apache
and confirm the app is running.

.. code-block:: bash
   :linenos: table

   sudo systemctl restart apache2

Re-run tests:

.. code-block:: bash
   :linenos: table
   :hl_lines: 21 22 23

   16:54:57 ▶ pytest -v --ssh-config ssh.conf --hosts 0.0.0.0 tests/test_pancake.py
   ================================= test session starts ==========================
   platform linux -- Python 3.7.3, pytest-5.2.1, py-1.8.0, pluggy-0.13.0 -- 
   /home/user/projects/venvs/mash/bin/python3
   cachedir: .pytest_cache
   rootdir: /home/user
   plugins: testinfra-3.2.0, cov-2.8.1
   collected 14 items

   test_pancake_user PASSED                                      [  7%]
   test_required_packages[apache2] PASSED                         [ 14%]
   test_required_packages[python3-Flask] PASSED                   [ 21%]
   test_required_packages[apache2-mod_wsgi-python3] PASSED        [ 28%]
   test_required_packages[git] PASSED                             [ 35%]
   test_apache2_service PASSED                                   [ 42%]
   test_pancake_config_files[/var/lib/pancake/wsgi.py] PASSED     [ 50%]
   test_pancake_config_files[/etc/apache2/vhosts.d/pancake.conf] PASSED [ 57%]
   test_pancake_config_files[/var/lib/pancake/pancakes.json] PASSED [ 64%]
   test_pancake_repo PASSED                                      [ 71%]
   test_instance_os_name PASSED                                  [ 78%]
   test_pancake_app_get_types PASSED                             [ 85%]
   test_pancake_app_get_type PASSED                              [ 92%]
   test_pancake_app_add_delete_type PASSED                       [100%]

   ============================= 14 passed in 8.82s ==========================

The problem here is that the app states are not properly watched by the Apache
server state. Therefore it is not notified to restart when the new vhost config
and wsgi module are in place.

Modifying the server state to watch for changes in the vhost state should
handle an automatic restart.

.. code-block:: yaml
   :linenos: table
   :hl_lines: 1 4 7 9

   apache2:
     pkg.latest:
       - refresh: True
     service.running:
       - enable: True
       - reload: True
       - watch:
         - pkg: apache2
         - file: /etc/apache2/vhosts.d/pancake.conf
