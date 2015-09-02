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

    # initiate package installation
    Manifest().process()


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



class CommandLineTools:

    shell = Shell()

    def __init__(self):
        pass

    def describe(self):
        return 'command line tools'

    def check(self):
        if self.shell.call_out(['/bin/sh', '-c', 'xcode-select -p 2> /dev/null'])['result'] is not 0:
            return False
        return True

    def install(self):
        # sets internal flag which causes software update to look for CLI tool packages
        self.shell.call('touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress')

        # retrieve available CLI tool packages to install
        ver = self.shell.call_out(['/bin/sh', '-c', "softwareupdate -l | grep '* Command Line'"])['output'][0]
        ver = ver.split('\n')[0].strip(' *')  # grab first item (in case of beta OS)
        self.shell.ohay('Found "%s"' % ver)

        # install the package
        self.shell.ohay('Installing via Software Update')
        self.shell.call(['softwareupdate', '-i', ver, '-v'])


class Brew:

    shell = Shell()
    packages = []
    casks = []

    def __init__(self, packages, casks):
        self.packages = packages
        self.casks = casks

    def describe(self):
        return 'brew'

    def check(self):
        result = True

        if os.path.exists('/usr/local/bin/brew') is False:
            self.shell.ohay('brew not installed')
            return False

        for name in self.packages:
            self.shell.ohay('- checking %s' % name)
            if self.check_keg(name) is False:
                self.shell.ohay('- missing %s' % name)
                result = False

        for cask in self.casks:
            self.shell.ohay('- checking cask %s' % cask)
            if self.check_keg(cask, 'cask') is False:
                self.shell.ohay('- missing cask %s' % cask)
                result = False

        return result

    def install(self):
        if os.path.exists('/usr/local/bin/brew') is False:
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

        for name in self.packages:
            if self.check_keg(name) is False:
                self.shell.ohay('- tapping %s' % name)
                self.shell.call('/usr/local/bin/brew install %s' % name)

        for name in self.casks:
            if self.check_keg(name, 'cask') is False:
                self.shell.ohay('- tapping cask %s' % name)
                self.shell.call('/usr/local/bin/brew cask install %s' % name)

    def check_keg(self, name, type = ''):
        if self.shell.call(['/bin/sh', '-c', 'brew %s list %s > /dev/null 2>&1' % (type, name)])['result'] is 1:
            return False
        return True

class Textmate:

    shell = Shell()

    def __init__(self):
        pass

    def describe(self):
        return 'textmate'

    def check(self):
        if os.path.exists('/Applications/TextMate.app'):
            return True
        return False

    def install(self):
        print 'Finding latest version'
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

class Dropbox:

    shell = Shell()

    def __init__(self):
        pass

    def describe(self):
        return 'dropbox'

    def check(self):
        if os.path.exists('/Applications/DropBox.app'):
            return True
        return False

    def install(self):
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

class Shortcuts:

    shell = Shell()

    def __init__(self):
        pass

    def describe(self):
        return 'shortcuts'

    def check(self):
        if os.path.exists('/server') == False:
            return False

        if os.path.exists('/sites') == False:
            return False

        return True

    def install(self):
        print 'Softlinking /server to /Volumes/Server'
        if os.path.exists('/Volumes/Server') == False:
            self.shell.warn('Can not find /Volumes/Server')
            return False

        result = self.shell.call('sudo /bin/ln -s /Volumes/Server /server')['result']
        if result != 0:
            self.shell.warn('Installation of %s failed with error code: %d' % (pkg.describe(), result))
            return False

        print 'Softlinking /sites to /server/sites'
        if os.path.exists('/Volumes/Server/sites') == False:
            if os.path.exists('/Volumes/Server'):
                self.shell.call('mkdir /Volumes/Server/sites')
            else:
                self.shell.warn('Can not find /Volumes/Server')
                return False

        result = self.shell.call('sudo /bin/ln -s /Volumes/Server/sites /sites')['result']
        if result != 0:
            self.shell.warn('Installation of %s failed with error code: %d' % (pkg.describe(), result))
            return False

class Manifest:
    def __init__(self):
        pass

    shell = Shell()
    packages = [
        CommandLineTools(),
        Brew([
            'ack',
            'bash-completion',
            'caskroom/cask/brew-cask',
            'figlet',
            'git',
            'git-flow',
            'hub',
            'md5sha1sum',
            'mysql',
            'pcre',
            'pv',
            'readline',
            'redis',
            'rename',
            'siege',
            'sloccount',
            'sqlite',
            'tree',
            'vagrant-completion',
            'wakeonlan',
            'watch',
            'wget',
            'zlib'
        ],[
            'vagrant',
            'virtualbox',
        ]),
        Textmate(),
        Dropbox(),
        Shortcuts(),
    ]

    def process(self):
        for pkg in self.packages:
            print
            self.shell.ohai('Checking %s package' % pkg.describe())
            if pkg.check() == False:
                self.shell.ohay('Installing %s package' % pkg.describe())
                result = pkg.install()
                if result == False:
                    self.shell.error('Installation of package %s failed' % pkg.describe())
                    exit(1)
            else:
                self.shell.ohay('Package %s is installed.' % pkg.describe())

if __name__ == '__main__':
    main()
