#!/usr/bin/env python

import os
import argparse as ap
import platform
import re
import subprocess as sp
import json
import tempfile as tf
import shutil

sc_name = 'glowbot-py'
tmp = None

def main():
    global tmp
    sh = Shell();

    parser = ap.ArgumentParser(description='Mac OS X Developer Environment Setup')
    parser.add_argument('--tmp', help='used to specify tmp directory when resuming from failed run')

    args = parser.parse_args()

    print str().ljust(80, '#')
    print '## Mac OS X Developer Environment Setup'.ljust(77) + ' ##'
    print str().ljust(80, '#') + '\n'

    # check in on the version of OS X we are running under
    osx_ver = re.match('^(10\.\d+)(\.\d+){0,1}$', platform.mac_ver()[0]).groups()[0]

    if osx_ver != '10.9' and osx_ver != '10.10' and osx_ver != '10.11':
        sh.ohai('This script requires Mac OS X 10.9 or newer (currently on version ' + osx_ver + ')\n')
        exit(1)

    # authenticate via sudo early on to avoid asking later
    if sh.call('sudo echo')['result'] is not 0:
        sh.error('Failed authentication. Please try again!')
        exit(1)

    # setup temp directory
    if args.tmp is not None and os.path.isdir(args.tmp) is True:
        tmp = args.tmp

    if tmp is None:
        tmp = tf.mkdtemp('-' + sc_name)
    print 'tmp: ' + tmp + '\n'

    # Install Command Line Tools if missing
    sh.ohai('Verifying presence of Command Line Tools')
    if sh.call_out(['/bin/sh', '-c', 'xcode-select -p 2> /dev/null'])['result'] is not 0:
        sh.ohay('Tools not found, hunting packages')

        # sets internal flag which causes software update to look for CLI tool packages
        sh.call('touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress')

        # retrieve available CLI tool packages to install
        ver = sh.call_out(['/bin/sh', '-c', "softwareupdate -l | grep '* Command Line'"])['output'][0]
        ver = ver.split('\n')[0].strip(' *')  # grab first item (in case of beta OS)
        sh.ohay('Found "%s"' % ver)

        # install the package
        sh.ohay('Installing via Software Update')
        sh.call(['softwareupdate', '-i', ver, '-v'])

    # initiate package installation
    PackageInstaller().run()


class Shell:
    def __init__(self):
        pass

    def call(self, command, returnOutput=False):
        if type(command) == str:
            command = command.split(' ')

        if returnOutput == True:
            process = sp.Popen(command, stdout=sp.PIPE)
        else:
            process = sp.Popen(command)

        output = process.communicate()
        return {'result': process.returncode, 'output': output}

    def call_out(self, command):
        return self.call(command, True)

    def curl_download(self, url, name, params=''):
        tmpFile = tmp + '/' + name
        self.call(['/bin/sh', '-c', 'curl %s -fkL# %s > %s' % (params, url, tmpFile)])
        return tmpFile

    # For escape codes: http://linuxgazette.net/issue65/padala.html
    def ohai(self, msg):
        print '\x1B[1;34m==> \x1B[1;39m%s\x1B[0;0m' % msg

    def ohay(self, msg):
        print '\x1B[1;32m==> \x1B[0;39m%s\x1B[0;0m' % msg

    def warn(self, msg):
        print '\x1B[4;31mWarning\x1B[0;31m:\x1B[0;39m %s\x1B[0;0m' % msg

    def error(self, msg):
        print '\x1B[4;31mError\x1B[0;31m:\x1B[0;39m %s\x1B[0;0m' % msg


class Package:
    name = str
    type = str

    def __init__(self, name, type=None):
        self.name = name
        self.type = type

    def get_desc(self):
        if self.type is not None:
            return self.type + ':' + self.name
        return self.name


class PackageInstaller:
    def __init__(self):
        pass

    shell = Shell()
    packages = [
        Package('brew'),
        Package('ack', 'brew'),
        Package('composer', 'brew'),
        Package('figlet', 'brew'),
        Package('gettext', 'brew'),
        Package('git', 'brew'),
        Package('git-flow', 'brew'),
        Package('hub', 'brew'),
        Package('iperf', 'brew'),
        Package('jmeter', 'brew'),
        Package('md5sha1sum', 'brew'),
        Package('neon', 'brew'),
        Package('pcre', 'brew'),
        Package('readline', 'brew'),
        Package('redis', 'brew'),
        Package('rename', 'brew'),
        Package('serf', 'brew'),
        Package('siege', 'brew'),
        Package('sloccount', 'brew'),
        Package('sqlite', 'brew'),
        Package('squid', 'brew'),
        Package('subversion', 'brew'),
        Package('tree', 'brew'),
        Package('varnish', 'brew'),
        Package('wakeonlan', 'brew'),
        Package('watch', 'brew'),
        Package('wget', 'brew'),
        Package('zlib', 'brew'),
        Package('textmate'),
        Package('dropbox'),
        Package('server'),
        Package('sites'),
    ]

    def run(self):
        for pkg in self.packages:
            print
            self.shell.ohai('Checking for %s package...' % pkg.get_desc())
            if self.installed(pkg) == False:
                self.shell.ohay('Installing package %s...' % pkg.get_desc())
                result = self.pkg_get_method('ins', pkg)(pkg)
                if result == False:
                    self.shell.error('Installation of package %s failed.' % pkg.get_desc())
                    exit(1)
            else:
                # TODO true reply from .installed sometimes means "Error: No available formula for ..."
                self.shell.ohay('Package %s is installed.' % pkg.get_desc())

    def installed(self, pkg):
        return self.pkg_get_method('check', pkg)(pkg)

    def pkg_get_method(self, op_type, pkg):
        if pkg.type is not None:
            op_type = '%s_%s' % (pkg.type, op_type)
        return getattr(self, 'pkg_%s_%s' % (op_type, pkg.name), getattr(self, 'pkg_%s' % op_type))

    def pkg_ins(self, pkg):
        self.shell.error('Missing pkg_ins method for %s package.' % pkg.get_desc())
        exit(1)

    def pkg_check(self, pkg):
        self.shell.error('Missing pkg_check method for %s package.' % pkg.get_desc())
        exit(1)

    def pkg_ins_brew(self, pkg):
        self.shell.call([
            '/bin/sh', '-c',
            'curl -fsSkL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby'
        ])
        self.shell.ohai('Running brew doctor')

        output = self.shell.call_out('brew doctor')['output']
        if output[0] != 'Your system is ready to brew.\n':
            for line in output:
                if line is not None:
                    print line
            self.shell.ohai('Please resolve the issues brew doctor reported and try again.')
            exit(1)
        else:
            print 'Your system is ready to brew.'

    def pkg_check_brew(self, pkg):
        if os.path.exists('/usr/local/bin/brew'):
            return True
        return False

    def pkg_brew_ins(self, pkg):
        self.shell.call('/usr/local/bin/brew install %s' % pkg.name)

    def pkg_brew_check(self, pkg):
        output = self.shell.call_out('/usr/local/bin/brew info %s' % pkg.name)['output'][0].split('\n')
        for line in output:
            if line == 'Not installed':
                return False
            elif line.find('Error:') != -1:
                self.shell.ohai(line)
                exit(1)
        return True

    def pkg_ins_textmate(self, pkg):
        print 'Finding the latest version'
        release = 'https://api.textmate.org/downloads/release'

        print 'Downloading ' + release
        tmpFile = self.shell.curl_download(release, 'TextMate2-Release.tbz')
        self.shell.call(['/usr/bin/tar', '-xjf', tmpFile, '-C', '/Applications/'])
        os.unlink(tmpFile)

        print 'Installing command line tool'
        shutil.copy('/Applications/TextMate.app/Contents/Resources/mate', '/usr/local/bin/mate')
        mate_ver = self.shell.call_out('/usr/local/bin/mate --version')['output'][0].split(' ')[1]
        self.shell.call('/usr/bin/defaults write com.macromates.TextMate.preview mateInstallPath /usr/local/bin/mate')
        self.shell.call('/usr/bin/defaults write com.macromates.TextMate.preview mateInstallVersion ' + mate_ver)
        self.shell.call('/usr/bin/defaults write com.macromates.TextMate mateInstallPath /usr/local/bin/mate')
        self.shell.call('/usr/bin/defaults write com.macromates.TextMate mateInstallVersion ' + mate_ver)

    def pkg_check_textmate(self, pkg):
        if os.path.exists('/Applications/TextMate.app'):
            return True
        return False

    def pkg_ins_dropbox(self, pkg):
        print 'Downloading Dropbox for Mac'
        tmpFile = self.shell.curl_download('https://www.dropbox.com/download?plat=mac', 'dropbox.dmg')

        print 'Mouting disk image'
        mountPoint = self.shell.call_out(
                '/usr/bin/hdiutil mount ' + tmpFile
            )['output'][0].strip().split('\n').pop().strip().split('\t').pop()

        print 'Copying application'
        self.shell.call(['/bin/cp', '-a', mountPoint + '/Dropbox.app', '/Applications/Dropbox.app'])
        self.shell.call(['/usr/bin/hdiutil', 'unmount', '-quiet', mountPoint])

        print 'Launching application'
        self.shell.call(['/usr/bin/open', '/Applications/Dropbox.app'])

        os.unlink(tmpFile)

        print 'Installation complete!'

    def pkg_check_dropbox(self, pkg):
        if os.path.exists('/Applications/DropBox.app'):
            return True
        return False

    def pkg_ins_sites(self, pkg):
        print 'Softlinking /sites to /server/sites'
        if os.path.exists('/Volumes/Server/sites') == False:
            if os.path.exists('/Volumes/Server'):
                self.shell.call('mkdir /Volumes/Server/sites')
            else:
                self.shell.warn('Can not find /Volumes/Server')
                return False

        result = self.shell.call('sudo /bin/ln -s /Volumes/Server/sites /sites')['result']
        if result != 0:
            self.shell.warn('Installation of %s failed with error code: %d' % (pkg.get_desc(), result))
            return False

    def pkg_check_sites(self, pkg):
        if os.path.exists('/sites'):
            return True
        return False

    def pkg_ins_server(self, pkg):
        print 'Softlinking /server to /Volumes/Server'
        if os.path.exists('/Volumes/Server') == False:
            self.shell.warn('Can not find /Volumes/Server')
            return False

        result = self.shell.call('sudo /bin/ln -s /Volumes/Server /server')['result']
        if result != 0:
            self.shell.warn('Installation of %s failed with error code: %d' % (pkg.get_desc(), result))
            return False

    def pkg_check_server(self, pkg):
        if os.path.exists('/server'):
            return True
        return False

if __name__ == '__main__':
    main()
