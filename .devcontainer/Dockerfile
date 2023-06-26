FROM mcr.microsoft.com/dotnet/sdk:7.0-jammy AS build

RUN apt-get update && apt-get -y upgrade

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    gnupg \
	curl \
    && rm -rf /var/lib/apt/lists/*

# Necessary to avoid error when working with Notebooks in containers: "Kusto client failed to perform authentication: 'Unable to open a web page using xdg-open, gnome-open, kfmclient or wslview tools"
RUN apt-get update && apt-get install -y xdg-utils

# Download the Microsoft repository GPG keys
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && dpkg -i packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
RUN dpkg -i packages-microsoft-prod.deb
# Update the list of packages after we added packages.microsoft.com
#RUN apt-get update && apt-get install -y powershell

#RUN apt-get install iputils-ping -y

#  Install the latest stable Git version: https://itsfoss.com/install-git-ubuntu/ (not included in mcr.microsoft.com/dotnet/runtime)
#RUN apt-get update && apt install software-properties-common -y && add-apt-repository ppa:git-core/ppa -y && apt update && apt install git -y
#RUN apt install software-properties-common -y
#RUN add-apt-repository ppa:git-core/ppa -y
#RUN apt update && apt install git -y
#RUN apt install git -y
#RUN apt-get install lynx

RUN useradd --create-home vscode

#RUN wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v14.32.2/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
#RUN chmod +x /usr/local/bin/oh-my-posh

#RUN apt-get update;apt-get install openssh-client -y

#ARG VARIANT=7

#FROM mcr.microsoft.com/azure-functions/powershell:3.0-powershell7-core-tools

### https://blog.nillsf.com/index.php/2021/05/10/how-to-install-powershell-modules-in-a-visual-studio-code-devcontainer/
#RUN pwsh -Command Set-PSRepository -Name PSGallery -InstallationPolicy Trusted && \
#    pwsh -Command Install-Module -Name Az.Accounts -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Billing -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Compute -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Network -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Resources -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Security -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Storage -Scope AllUsers -Repository PSGallery && \
#    pwsh -Command Install-Module -Name Az.Subscription -Scope AllUsers -Repository PSGallery
    
#RUN pwsh import-Module -Name ExchangeOnlineManagement
#RUN pwsh Import-Module -Name Microsoft.Online.SharePoint.PowerShell

##CMD [ "pwsh" ]
SHELL ["pwsh", "-Command"]
###

# Switch to non-root user:
WORKDIR /home/vscode
USER vscode