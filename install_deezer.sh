#!/bin/bash

# Maintainer: Ángel Careaga <ing.angelcareaga@gmail.com>

# Author base: Ilya Gulya <ilyagulya@gmail.com> 
# URL base: https://aur.archlinux.org/packages/deezer/

#METADATA
pkgname="deezer"
pkgver=4.0.5
pkgrel=1
pkgdesc="A proprietary music streaming service"
arch=('x86_64')
url="https://www.deezer.com/"
license=('custom:"Copyright (c) 2006-2018 Deezer S.A."')
depends=('electron>=3.0.10')
provides=('deezer')
options=('!strip')
makedepends=('p7zip')
source=(
"$pkgname-$pkgver-setup.exe::https://www.deezer.com/desktop/download/artifact/win32/x86/$pkgver"
"$pkgname.desktop"
)
md5sums=('cd8d1866cccc821924b37267060c005e'
         '6787e48a44061671e326ababd1a2ea8d')

# Verify the system for use correct packages
verifyOS(){
    if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        ...
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        ...
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    # Call 2nd step
    verifyRequeriments
}

# Verify depends
verifyRequeriments(){
    OSTemp=${OS,,}
    nodeIsInstalled=false
    electronIsInstalled=false
    p7zipIsIntalled=false

    # Verify for Fedora
    if [ $OSTemp = 'fedora' ]; then
        # Installing others
        pkcon install libXScrnSaver
        resNode=$(rpm -qa | grep -i nodejs | xargs)
        resElectron=$(npm list -g --depth 0 | grep electron | xargs)
        resp7zip=$(rpm -qa | grep -i p7zip | xargs)
        if [[ $resNode == *"node"* ]]; then
            nodeIsInstalled=true
            if [[ $resElectron == *"electron@3.1.1" ]]; then
                electronIsInstalled=true
                else
                electronIsInstalled=false
            fi
            else
            nodeIsInstalled=false
        fi
        if [[ $resp7zip == *"p7zip"* ]]; then
            p7zipIsIntalled=true
            else
            p7zipIsIntalled=false
        fi
    fi

    # Show results prerequisites
    if [[ $nodeIsInstalled = true && $electronIsInstalled = true && $p7zipIsIntalled = true ]]; then
        echo "OS: $OS"
        echo "Node: $resNode"
        echo "Electron: $resElectron"
        echo "p7zip: $resp7zip "
        echo "Prerequisites found..."
        echo "Continuing..."
        # Call 3 step
        packageAndInstall
        elif [ $nodeIsInstalled == false]; then
        echo "Failure to find prerequisites"
        echo "Please install the following:"
        echo "| NODE: v10"
        elif [ $electronIsInstalled == false ]; then
        echo "| ELECTRON: v3.1.1"
        elif [ $p7zipIsIntalled == false ]; then
        echo "| p7zip"
    fi
}

# Installing; Unzip exe and deploy
packageAndInstall() {

    { # try
        downloadedFile=false
        if [ ! -f assets/$pkgname-$pkgver-setup.exe ]; then
            echo "Downloading..."
            echo "..."
            echo $pkgname-$pkgver-setup.exe
            if wget https://www.deezer.com/desktop/download/artifact/win32/x86/$pkgver -O assets/$pkgname-$pkgver-setup.exe
            then
                echo "..."
                else
                echo "The download could not be completed, eliminating..."
                rm assets/$pkgname-$pkgver-setup.exe
            fi
        else
            echo "Already downloaded ... Continuing"
            # Actions file
            mkdir -p "$pkgdir"/usr/share/deezer
            mkdir -p "$pkgdir"/usr/share/applications
            mkdir -p "$pkgdir"/usr/bin/
            mkdir -p temp

            # Extract app from installer
            7z x -so assets/$pkgname-$pkgver-setup.exe "\$PLUGINSDIR/app-32.7z" > temp/app-32.7z
            # Extract electron bundle from app archive
            7z x -so temp/app-32.7z "resources/app.asar" > temp/app.asar
            # Extract icon from app archive
            7z x -so temp/app-32.7z "resources/build/win/app.ico" > temp/app.ico

            echo "#!/bin/sh" > temp/deezer
            echo "/usr/bin/electron /usr/share/deezer/app.asar" >> temp/deezer

            install -Dm644 temp/app.asar "$pkgdir"/usr/share/deezer/app.asar
            install -Dm644 temp/app.ico "$pkgdir"/usr/share/deezer/app.ico
            install -Dm644 "assets/$pkgname".desktop "$pkgdir"/usr/share/applications/
            install -Dm755 temp/deezer "$pkgdir"/usr/bin/deezer

            # Clean call
            clean
        fi
    } || { # catch
        echo "###############################################"
        echo "..."
        echo "Can't install file, cleaned..."
        echo "..."
        echo "Removing $pkgname-$pkgver-setup.exe"
        rm assets/$pkgname-$pkgver-setup.exe
    }
    
}

clean(){
    echo "Temp cleaned..."
    rm temp/app-32.7z
    rm temp/app.asar
    rm temp/app.ico
    rm temp/deezer 
}

## RUN
verifyOS

